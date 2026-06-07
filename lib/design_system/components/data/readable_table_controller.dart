// ============================================================
// ReadableTable — CONTROLLER.
// ------------------------------------------------------------
// The single source of truth for the read-only display grid, as a
// ChangeNotifier. The view (ReadableTable) is a thin render of this state and
// forwards every gesture/key here. The same controller is exposed to row /
// page content via an InheritedNotifier so any descendant can drive the grid:
//
//   final t = ReadableTableController.of<Account>(context); // may be null
//   t?.selectRowsWhere((a) => a.overdue);
//
// Generic over the row value type T. Rich, intention-revealing operations:
//
//   SELECT rows by   index · value · where
//   ADD    rows by   index · where · end
//   DELETE rows by   index · where · value
//   REPLACE row by   index · value · where · firstWhere
//   FILTER rows by   per-column predicates (AND / OR) + a cross-column search
//
// plus cell selection (cell modes), keyboard navigation and click-to-sort.
//
// ── Data model: MASTER vs. VIEW ─────────────────────────────────────────────
// `_all` is the immutable-ordered MASTER row set every mutation edits. The
// VIEW (`_rows`) is derived from it on every change as `sort(filter(_all))`;
// `_viewMaster[i]` is the master index of visible row i. The view renders the
// VIEW and addresses rows by their VISIBLE position; the controller translates
// to MASTER at the boundary. Selection is stored in MASTER space (so it is
// stable across sort) and pruned to the currently-visible rows on each rebuild
// — "you can only select what you can see". Structural edits remap selection by
// value identity; everything funnels through `_recompute()`.
//
//   File: lib/design_system/components/data/readable_table_controller.dart
// ============================================================

import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'readable_table_models.dart';
import 'readable_table_filter.dart';

class ReadableTableController<T> extends ChangeNotifier {
  ReadableTableController({
    required List<ReadableColumn<T>> columns,
    List<T>? rows,
    this.selectionMode = ReadableSelectionMode.none,
    Set<int>? selectedRows,
    Set<ReadableCell>? selectedCells,
    int? sortColumn,
    bool sortAscending = true,
    List<ReadableFilter>? filters,
    ReadableFilterJoin filterJoin = ReadableFilterJoin.all,
    String query = '',
    Iterable<int>? quickSearchColumns,
    ReadableFilterGroup? filterGroup,
  })  : columns = List.unmodifiable(columns),
        _all = [...?rows] {
    _order.addAll(List<int>.generate(columns.length, (i) => i));
    _selRows.addAll(selectedRows ?? const {});
    _selCells.addAll(selectedCells ?? const {});
    if (filters != null) _filters.addAll(filters);
    _join = filterJoin;
    _query = query;
    if (quickSearchColumns != null) _quickCols = {...quickSearchColumns};
    if (sortColumn != null && sortColumn >= 0 && sortColumn < columns.length) {
      _sortCol = sortColumn;
      _sortDir = sortAscending ? ReadableSortDir.asc : ReadableSortDir.desc;
    }
    if (filterGroup != null && filterGroup.isNotEmpty) _filterGroup = filterGroup;
    _recompute(notify: false);
  }

  final List<ReadableColumn<T>> columns;

  /// What the user can select. Mutable so the view's `selectionMode:` can
  /// drive it; clears the selection when the kind of selection changes.
  ReadableSelectionMode selectionMode;

  // ── data: master + derived view ────────────────────────────
  final List<T> _all; // MASTER — mutation-ordered
  List<T> _rows = []; // VIEW — sort(filter(_all))
  List<int> _viewMaster = []; // master index for each visible row

  // selection (MASTER space; pruned to visible on rebuild)
  final Set<int> _selRows = {};
  final Set<ReadableCell> _selCells = {}; // .row = master index, .col = logical

  int _activeMaster = 0;
  int _activeCol = 0;
  int _anchorMaster = 0;
  int _anchorCol = 0;

  int? _sortCol;
  ReadableSortDir _sortDir = ReadableSortDir.none;

  // filter state
  final List<ReadableFilter> _filters = [];
  ReadableFilterJoin _join = ReadableFilterJoin.all;
  String _query = '';
  Set<int>? _quickCols; // null = search every column
  ReadableFilterGroup? _filterGroup; // nested tree (FilterEditingView); supersedes _filters when set
  final Map<int, ReadableFilter> _columnFilters = {}; // inline per-column header filters (ANDed on top)

  // Column layout: a visual→logical order list (drag-to-reorder) and per-column
  // width overrides (drag-to-resize), both keyed so selection / sort logic can
  // keep working in stable LOGICAL indices while the header paints visually.
  final List<int> _order = [];
  final Map<int, double> _widthOverride = {};

  /// Min / max a column can be dragged to (px).
  static const double columnMinWidth = 64;
  static const double columnMaxWidth = 520;

  // ── reads ──────────────────────────────────────────────────
  /// The currently-visible rows (after filter + sort).
  List<T> get rows => List.unmodifiable(_rows);

  /// Every row, ignoring the filter (master order).
  List<T> get allRows => List.unmodifiable(_all);

  /// Number of VISIBLE rows (after filtering).
  int get rowCount => _rows.length;

  /// Number of rows before filtering.
  int get totalRowCount => _all.length;

  int get colCount => columns.length;

  /// The visible row at [index].
  T rowAt(int index) => _rows[index];

  Set<int> get selectedRowIndices => Set<int>.from(_selRows);

  /// Selected row **values**, in visible (top-to-bottom) order.
  List<T> get selectedRows =>
      [for (var v = 0; v < _viewMaster.length; v++) if (_selRows.contains(_viewMaster[v])) _rows[v]];

  /// Selected cells, translated to VISIBLE row addresses.
  Set<ReadableCell> get selectedCells {
    final out = <ReadableCell>{};
    for (final c in _selCells) {
      final v = _visibleOf(c.row);
      if (v >= 0) out.add(ReadableCell(v, c.col));
    }
    return out;
  }

  int get selectedCount => _isCellMode ? _selCells.length : _selRows.length;

  int get activeRow {
    final v = _visibleOf(_activeMaster);
    return v < 0 ? 0 : v;
  }

  int get activeCol => _activeCol;
  int? get sortColumn => _sortCol;
  ReadableSortDir get sortDir => _sortDir;

  bool isRowSelected(int visibleIndex) => _selRows.contains(_masterOf(visibleIndex));
  bool isCellSelected(int visibleRow, int col) => _selCells.contains(ReadableCell(_masterOf(visibleRow), col));

  // ── visible ↔ master translation ───────────────────────────
  int _masterOf(int visible) => (visible >= 0 && visible < _viewMaster.length) ? _viewMaster[visible] : -1;
  int _visibleOf(int master) => _viewMaster.indexOf(master);

  // ════════════════════════════════════════════════════════════
  // FILTERING — per-column predicates (AND/OR) + cross-column search
  // ════════════════════════════════════════════════════════════

  /// The active filter predicates (in chip order).
  List<ReadableFilter> get filters => List.unmodifiable(_filters);

  /// How the filters combine (all = AND, any = OR).
  ReadableFilterJoin get filterJoin => _join;

  /// The cross-column quick-search string.
  String get query => _query;

  /// The logical columns the quick-search scans, or null for every column.
  Set<int>? get quickSearchColumns => _quickCols == null ? null : Set<int>.unmodifiable(_quickCols!);

  /// Whether any filter or the quick-search is actually narrowing the rows.
  bool get isFiltered =>
      _query.trim().isNotEmpty ||
      (_filterGroup?.isActive ?? false) ||
      _filters.any((f) => f.enabled && f.isComplete) ||
      _columnFilters.values.any((f) => f.isActive);

  /// Whether any filter chip or query exists (even if disabled / incomplete).
  bool get hasFilters =>
      _filters.isNotEmpty || _query.isNotEmpty || (_filterGroup?.isNotEmpty ?? false) || _columnFilters.isNotEmpty;

  /// Whether a column can be filtered (we can read a value from it).
  bool isColumnFilterable(int ci) =>
      ci >= 0 && ci < columns.length && (columns[ci].sortKey != null || columns[ci].copyText != null);

  /// The distinct, sorted string values present in column [ci] — feeds the
  /// editor's `is any of` chips and `is` dropdown.
  List<String> distinctValues(int ci) {
    if (ci < 0 || ci >= columns.length) return const [];
    final c = columns[ci];
    final set = <String>{};
    for (final v in _all) {
      final s = (c.copyText?.call(v) ?? c.sortKey?.call(v)?.toString() ?? '').trim();
      if (s.isNotEmpty) set.add(s);
    }
    return set.toList()..sort();
  }

  set quickSearchColumns(Iterable<int>? cols) {
    _quickCols = cols == null ? null : {...cols};
    _recompute();
  }

  /// The nested filter tree edited by a [ReadableFilterEditingView], or null
  /// when only the flat [filters] list is in use.
  ReadableFilterGroup? get filterGroup => _filterGroup;

  /// Set (or clear) the nested filter tree. When non-empty it supersedes the
  /// flat [filters] list for structured filtering; the quick-search still
  /// applies on top. Pass null or an empty group to clear it.
  void setFilterGroup(ReadableFilterGroup? group) {
    final next = (group == null || group.isEmpty) ? null : group;
    if (next == _filterGroup) return;
    _filterGroup = next;
    _recompute();
  }

  /// Set the cross-column search string (empty clears it).
  void setQuery(String q) {
    if (q == _query) return;
    _query = q;
    _recompute();
  }

  /// Switch AND ⇄ OR for the filter list.
  void setFilterJoin(ReadableFilterJoin join) {
    if (join == _join) return;
    _join = join;
    _recompute();
  }

  /// Append a filter predicate.
  void addFilter(ReadableFilter filter) {
    _filters.add(filter);
    _recompute();
  }

  /// Insert a filter at [index].
  void insertFilterAt(int index, ReadableFilter filter) {
    _filters.insert(index.clamp(0, _filters.length), filter);
    _recompute();
  }

  /// Replace the filter at [index].
  void updateFilterAt(int index, ReadableFilter filter) {
    if (index < 0 || index >= _filters.length) return;
    _filters[index] = filter;
    _recompute();
  }

  /// Remove the filter at [index].
  void removeFilterAt(int index) {
    if (index < 0 || index >= _filters.length) return;
    _filters.removeAt(index);
    _recompute();
  }

  /// Toggle (or set) a filter's enabled flag — keeps the chip, stops applying.
  void toggleFilterAt(int index, [bool? on]) {
    if (index < 0 || index >= _filters.length) return;
    final f = _filters[index];
    _filters[index] = f.copyWith(enabled: on ?? !f.enabled);
    _recompute();
  }

  /// Replace the whole filter list.
  void setFilters(List<ReadableFilter> filters) {
    _filters
      ..clear()
      ..addAll(filters);
    _recompute();
  }

  /// Drop every filter (flat list + nested tree + inline column filters) and
  /// the quick-search.
  void clearFilters() {
    if (_filters.isEmpty && _query.isEmpty && _filterGroup == null && _columnFilters.isEmpty) return;
    _filters.clear();
    _filterGroup = null;
    _columnFilters.clear();
    _query = '';
    _recompute();
  }

  // ── inline per-column filters (the header filter row) ──────────────────────
  /// The inline filter active on logical column [ci], or null.
  ReadableFilter? columnFilter(int ci) => _columnFilters[ci];

  /// An unmodifiable view of every inline column filter, keyed by logical index.
  Map<int, ReadableFilter> get columnFilters => Map.unmodifiable(_columnFilters);

  /// Whether any inline column filter is currently narrowing the rows.
  bool get hasColumnFilters => _columnFilters.values.any((f) => f.isActive);

  /// Set (or clear) the inline filter on logical column [ci]. Pass null, or a
  /// filter that isn't [ReadableFilter.isComplete], to clear it. Inline column
  /// filters AND together and AND on top of the quick-search and the structured
  /// filters, so the header row narrows whatever is already shown.
  void setColumnFilter(int ci, ReadableFilter? filter) {
    if (ci < 0 || ci >= columns.length) return;
    final existing = _columnFilters[ci];
    if (filter == null || !filter.isComplete) {
      if (existing == null) return;
      _columnFilters.remove(ci);
    } else {
      final next = filter.columnIndex == ci ? filter : filter.copyWith(columnIndex: ci);
      if (existing == next) return;
      _columnFilters[ci] = next;
    }
    _recompute();
  }

  /// A convenience for the most common header filter: a case-insensitive
  /// `contains` on column [ci]. Empty [text] clears it.
  void setColumnSearch(int ci, String text) {
    final t = text.trim();
    setColumnFilter(ci, t.isEmpty ? null : ReadableFilter.text(ci, ReadableFilterOp.contains, t));
  }

  /// Drop every inline column filter (keeps the structured filters + search).
  void clearColumnFilters() {
    if (_columnFilters.isEmpty) return;
    _columnFilters.clear();
    _recompute();
  }

  /// Does a row value pass the quick-search AND the filter list?
  bool _passes(T value) {
    final q = _query.trim().toLowerCase();
    if (q.isNotEmpty) {
      var any = false;
      for (var ci = 0; ci < columns.length; ci++) {
        if (_quickCols != null && !_quickCols!.contains(ci)) continue;
        final c = columns[ci];
        final s = (c.copyText?.call(value) ?? c.sortKey?.call(value)?.toString() ?? '');
        if (s.toLowerCase().contains(q)) {
          any = true;
          break;
        }
      }
      if (!any) return false;
    }
    // inline per-column filters — ANDed on top of everything else.
    if (_columnFilters.isNotEmpty) {
      for (final entry in _columnFilters.entries) {
        final ci = entry.key;
        final f = entry.value;
        if (!f.isActive) continue;
        if (ci < 0 || ci >= columns.length) continue;
        if (!f.test(columns[ci], value)) return false;
      }
    }
    // structured filtering: the nested tree wins when present, else flat list.
    if (_filterGroup != null && _filterGroup!.isActive) {
      return _filterGroup!.matches(columns, value);
    }
    final active = [
      for (final f in _filters)
        if (f.enabled && f.isComplete && f.columnIndex >= 0 && f.columnIndex < columns.length) f
    ];
    if (active.isEmpty) return true;
    if (_join == ReadableFilterJoin.all) {
      for (final f in active) {
        if (!f.test(columns[f.columnIndex], value)) return false;
      }
      return true;
    } else {
      for (final f in active) {
        if (f.test(columns[f.columnIndex], value)) return true;
      }
      return false;
    }
  }

  // ════════════════════════════════════════════════════════════
  // COLUMN LAYOUT — visual order (reorder) + width overrides (resize)
  // ════════════════════════════════════════════════════════════

  /// The current visual order as a list of LOGICAL column indices.
  List<int> get columnOrder => List<int>.unmodifiable(_order);

  /// The logical column index shown at visual position [visual].
  int logicalColumnAt(int visual) => _order.isEmpty ? visual : _order[visual.clamp(0, _order.length - 1)];

  /// The column shown at visual position [visual].
  ReadableColumn<T> columnAt(int visual) => columns[logicalColumnAt(visual)];

  /// The effective width of the column at visual position [visual]: a drag
  /// override if any, else the column's declared fixed [ReadableColumn.width].
  /// Returns null when the column should flex (no override, no fixed width).
  double? widthOf(int visual) {
    final li = logicalColumnAt(visual);
    return _widthOverride[li] ?? columns[li].width;
  }

  /// Whether the column at [visual] currently has a drag-resize override.
  bool hasWidthOverride(int visual) => _widthOverride.containsKey(logicalColumnAt(visual));

  /// Resize the column at visual position [visual] by [delta] px (drag), clamped
  /// to [columnMinWidth]..[columnMaxWidth]. A flex column becomes fixed-width on
  /// first resize. Pass an RTL-mirrored delta from the view.
  void resizeColumn(int visual, double delta,
      {double min = columnMinWidth, double max = columnMaxWidth}) {
    final li = logicalColumnAt(visual);
    final base = _widthOverride[li] ?? columns[li].width ?? 160.0;
    _widthOverride[li] = (base + delta).clamp(min, max);
    notifyListeners();
  }

  /// Drop the resize override for the column at [visual] (double-tap the handle
  /// to restore its declared width / flex).
  void resetColumnWidth(int visual) {
    if (_widthOverride.remove(logicalColumnAt(visual)) != null) notifyListeners();
  }

  /// Move the column at visual position [fromVisual] to [toVisual] (header
  /// drag-and-drop). Only the visual order changes; logical indices — and so
  /// the selection, sort column and cell addresses — are untouched.
  void moveColumn(int fromVisual, int toVisual) {
    if (_order.isEmpty) return;
    final from = fromVisual.clamp(0, _order.length - 1);
    var to = toVisual.clamp(0, _order.length - 1);
    if (from == to) return;
    final li = _order.removeAt(from);
    _order.insert(to, li);
    notifyListeners();
  }

  bool get _isRowMode =>
      selectionMode == ReadableSelectionMode.singleRow || selectionMode == ReadableSelectionMode.multiRow;
  bool get _isCellMode =>
      selectionMode == ReadableSelectionMode.singleCell || selectionMode == ReadableSelectionMode.multiCell;
  bool get _isMulti =>
      selectionMode == ReadableSelectionMode.multiRow || selectionMode == ReadableSelectionMode.multiCell;
  bool get isInteractive => selectionMode != ReadableSelectionMode.none;

  // ── selection-mode swap ────────────────────────────────────
  void setSelectionMode(ReadableSelectionMode mode) {
    if (mode == selectionMode) return;
    selectionMode = mode;
    _selRows.clear();
    _selCells.clear();
    notifyListeners();
  }

  // ════════════════════════════════════════════════════════════
  // SELECT ROWS — by index · value · where (VISIBLE indices in / out)
  // ════════════════════════════════════════════════════════════

  /// Select the row at visible [index]. [additive] toggles it within the
  /// existing selection (multi only); [range] extends from the anchor.
  void selectRowAt(int index, {bool additive = false, bool range = false}) {
    if (!_isRowMode) return;
    final master = _masterOf(index);
    if (master < 0) return;
    _activeMaster = master;
    if (selectionMode == ReadableSelectionMode.singleRow) {
      _selRows
        ..clear()
        ..add(master);
      _anchorMaster = master;
    } else if (range) {
      var anchorV = _visibleOf(_anchorMaster);
      if (anchorV < 0) anchorV = index;
      final lo = math.min(anchorV, index);
      final hi = math.max(anchorV, index);
      if (!additive) _selRows.clear();
      for (var i = lo; i <= hi; i++) {
        final m = _masterOf(i);
        if (m >= 0) _selRows.add(m);
      }
    } else if (additive) {
      _selRows.contains(master) ? _selRows.remove(master) : _selRows.add(master);
      _anchorMaster = master;
    } else {
      _selRows
        ..clear()
        ..add(master);
      _anchorMaster = master;
    }
    notifyListeners();
  }

  /// Select the first visible row whose value `==` [value].
  void selectRowByValue(T value, {bool additive = false}) {
    final m = _all.indexOf(value);
    if (m < 0) return;
    final v = _visibleOf(m);
    if (v >= 0) selectRowAt(v, additive: additive);
  }

  /// Select every visible row matching [test]. Replaces the selection unless
  /// [additive]. In single-row mode only the last match survives.
  void selectRowsWhere(bool Function(T value) test, {bool additive = false}) {
    if (!_isRowMode) return;
    if (!additive) _selRows.clear();
    int? lastMaster;
    for (var v = 0; v < _viewMaster.length; v++) {
      final m = _viewMaster[v];
      if (test(_all[m])) {
        _selRows.add(m);
        lastMaster = m;
      }
    }
    if (selectionMode == ReadableSelectionMode.singleRow && _selRows.length > 1 && lastMaster != null) {
      _selRows
        ..clear()
        ..add(lastMaster);
    }
    if (lastMaster != null) _activeMaster = lastMaster;
    notifyListeners();
  }

  /// Select all VISIBLE rows (multi-row) — no-op in other modes.
  void selectAllRows() {
    if (selectionMode != ReadableSelectionMode.multiRow) return;
    _selRows
      ..clear()
      ..addAll(_viewMaster);
    notifyListeners();
  }

  void clearSelection() {
    if (_selRows.isEmpty && _selCells.isEmpty) return;
    _selRows.clear();
    _selCells.clear();
    notifyListeners();
  }

  // ── cell selection (cell modes) ────────────────────────────
  void selectCellAt(int visibleRow, int col, {bool additive = false, bool range = false}) {
    if (!_isCellMode || col < 0 || col >= colCount) return;
    final master = _masterOf(visibleRow);
    if (master < 0) return;
    _activeMaster = master;
    _activeCol = col;
    if (selectionMode == ReadableSelectionMode.singleCell) {
      _selCells
        ..clear()
        ..add(ReadableCell(master, col));
      _anchorMaster = master;
      _anchorCol = col;
    } else if (range) {
      var anchorV = _visibleOf(_anchorMaster);
      if (anchorV < 0) anchorV = visibleRow;
      final loV = math.min(anchorV, visibleRow);
      final hiV = math.max(anchorV, visibleRow);
      final loC = math.min(_anchorCol, col);
      final hiC = math.max(_anchorCol, col);
      if (!additive) _selCells.clear();
      for (var vr = loV; vr <= hiV; vr++) {
        final m = _masterOf(vr);
        if (m < 0) continue;
        for (var c = loC; c <= hiC; c++) {
          _selCells.add(ReadableCell(m, c));
        }
      }
    } else if (additive) {
      final cell = ReadableCell(master, col);
      _selCells.contains(cell) ? _selCells.remove(cell) : _selCells.add(cell);
      _anchorMaster = master;
      _anchorCol = col;
    } else {
      _selCells
        ..clear()
        ..add(ReadableCell(master, col));
      _anchorMaster = master;
      _anchorCol = col;
    }
    notifyListeners();
  }

  void selectAllCells() {
    if (selectionMode != ReadableSelectionMode.multiCell) return;
    _selCells.clear();
    for (final m in _viewMaster) {
      for (var c = 0; c < colCount; c++) {
        _selCells.add(ReadableCell(m, c));
      }
    }
    notifyListeners();
  }

  // ════════════════════════════════════════════════════════════
  // ADD ROWS — by index · where · end
  // ════════════════════════════════════════════════════════════

  /// Append [value] as the last row.
  void addRow(T value) => _structural(() => _all.add(value));

  /// Insert [value] near visible [index] (clamped). With a filter active the
  /// row lands next to the corresponding master row.
  void insertRowAt(int index, T value) => _structural(() {
        final master = (index >= 0 && index < _viewMaster.length) ? _viewMaster[index] : _all.length;
        _all.insert(master.clamp(0, _all.length), value);
      });

  /// Insert [value] adjacent to rows matching [test] — [after] the match by
  /// default, or before it. With [firstOnly] (default) only the first match is
  /// used; otherwise [value] is inserted next to every match.
  void addRowWhere(bool Function(T value) test, T value, {bool after = true, bool firstOnly = true}) {
    _structural(() {
      final hits = <int>[];
      for (var i = 0; i < _all.length; i++) {
        if (test(_all[i])) {
          hits.add(i);
          if (firstOnly) break;
        }
      }
      for (final i in hits.reversed) {
        _all.insert(after ? i + 1 : i, value);
      }
    });
  }

  // ════════════════════════════════════════════════════════════
  // DELETE ROWS — by index · where · value
  // ════════════════════════════════════════════════════════════

  /// Remove the row at visible [index].
  void deleteRowAt(int index) {
    final master = _masterOf(index);
    if (master < 0 || master >= _all.length) return;
    _structural(() => _all.removeAt(master));
  }

  /// Remove the first master row whose value `==` [value].
  void deleteRowByValue(T value) {
    final i = _all.indexOf(value);
    if (i >= 0) _structural(() => _all.removeAt(i));
  }

  /// Remove every row matching [test]. Returns the number removed.
  int deleteRowsWhere(bool Function(T value) test) {
    final before = _all.length;
    _structural(() => _all.removeWhere(test));
    return before - _all.length;
  }

  /// Remove every currently-selected (visible) row.
  void deleteSelectedRows() {
    if (_selRows.isEmpty) return;
    final values = [for (final m in _selRows) if (m >= 0 && m < _all.length) _all[m]];
    _structural(() {
      for (final v in values) {
        final i = _all.indexOf(v);
        if (i >= 0) _all.removeAt(i);
      }
    });
  }

  // ════════════════════════════════════════════════════════════
  // COPY — selection → tab-separated values (spreadsheet-ready)
  // ════════════════════════════════════════════════════════════

  String _cellTextMaster(int master, int col) {
    if (master < 0 || master >= _all.length || col < 0 || col >= columns.length) return '';
    final c = columns[col];
    final v = _all[master];
    final raw = c.copyText?.call(v) ?? c.sortKey?.call(v) ?? v;
    return _sanitize(raw.toString());
  }

  /// Plain-text value of the VISIBLE cell (row, col), via the column's
  /// [ReadableColumn.copyText] → [ReadableColumn.sortKey] → toString chain.
  String cellText(int visibleRow, int col) => _cellTextMaster(_masterOf(visibleRow), col);

  /// Strip tabs/newlines that would corrupt the TSV grid (cells are single
  /// fields). Spreadsheets re-wrap on paste, so collapsing to spaces is safe.
  String _sanitize(String s) => s.replaceAll('\t', ' ').replaceAll(RegExp(r'[\r\n]+'), ' ');

  /// Serialize the current selection to a TSV string (visible order):
  ///   • row modes  → every column of each selected row
  ///   • cell modes → the bounding rectangle of the selected cells; cells
  ///     inside the rectangle but not selected are emitted as empty fields.
  /// Returns '' when nothing is selected.
  String copySelectionAsTsv({bool includeHeader = false}) {
    final rowsBuf = <String>[];
    if (_isCellMode) {
      if (_selCells.isEmpty) return '';
      final pairs = <ReadableCell>[];
      for (final c in _selCells) {
        final v = _visibleOf(c.row);
        if (v >= 0) pairs.add(ReadableCell(v, c.col));
      }
      if (pairs.isEmpty) return '';
      final rs = pairs.map((c) => c.row).toSet().toList()..sort();
      final cs = pairs.map((c) => c.col).toSet().toList()..sort();
      final minR = rs.first, maxR = rs.last, minC = cs.first, maxC = cs.last;
      final picked = {for (final c in pairs) (c.row * 100000 + c.col)};
      if (includeHeader) {
        rowsBuf.add([for (var c = minC; c <= maxC; c++) _sanitize(columns[c].label)].join('\t'));
      }
      for (var r = minR; r <= maxR; r++) {
        final line = <String>[];
        for (var c = minC; c <= maxC; c++) {
          line.add(picked.contains(r * 100000 + c) ? _cellTextMaster(_masterOf(r), c) : '');
        }
        rowsBuf.add(line.join('\t'));
      }
    } else {
      if (_selRows.isEmpty) return '';
      final visibleRows = [for (var v = 0; v < _viewMaster.length; v++) if (_selRows.contains(_viewMaster[v])) v];
      if (visibleRows.isEmpty) return '';
      if (includeHeader) {
        rowsBuf.add([for (final c in columns) _sanitize(c.label)].join('\t'));
      }
      for (final r in visibleRows) {
        rowsBuf.add([for (var c = 0; c < columns.length; c++) _cellTextMaster(_masterOf(r), c)].join('\t'));
      }
    }
    return rowsBuf.join('\n');
  }

  /// Copy the current selection to the system clipboard as TSV. Returns the
  /// number of rows written (0 ⇒ nothing selected).
  Future<int> copySelectionToClipboard({bool includeHeader = false}) async {
    final tsv = copySelectionAsTsv(includeHeader: includeHeader);
    if (tsv.isEmpty) return 0;
    await Clipboard.setData(ClipboardData(text: tsv));
    return '\n'.allMatches(tsv).length + 1;
  }

  // ════════════════════════════════════════════════════════════
  // REPLACE ROW — by index · value · where · firstWhere
  // ════════════════════════════════════════════════════════════

  /// Replace the visible row at [index] with [value].
  void replaceRowAt(int index, T value) {
    final master = _masterOf(index);
    if (master < 0 || master >= _all.length) return;
    _structural(() => _all[master] = value);
  }

  /// Replace the first master row equal to [oldValue] with [newValue].
  void replaceRowByValue(T oldValue, T newValue) {
    final i = _all.indexOf(oldValue);
    if (i >= 0) _structural(() => _all[i] = newValue);
  }

  /// Replace every row matching [test] with `update(currentValue)`. Returns
  /// the number replaced.
  int replaceRowsWhere(bool Function(T value) test, T Function(T value) update) {
    var n = 0;
    _structural(() {
      for (var i = 0; i < _all.length; i++) {
        if (test(_all[i])) {
          _all[i] = update(_all[i]);
          n++;
        }
      }
    });
    return n;
  }

  /// Replace only the first row matching [test] with `update(currentValue)`.
  void replaceFirstWhere(bool Function(T value) test, T Function(T value) update) {
    _structural(() {
      for (var i = 0; i < _all.length; i++) {
        if (test(_all[i])) {
          _all[i] = update(_all[i]);
          break;
        }
      }
    });
  }

  /// Replace the entire row set (e.g. load from a data source). Clears the
  /// selection; keeps the sort + filter applied.
  void setRows(List<T> values) {
    _all
      ..clear()
      ..addAll(values);
    _selRows.clear();
    _selCells.clear();
    _recompute();
  }

  // ════════════════════════════════════════════════════════════
  // SORT
  // ════════════════════════════════════════════════════════════

  /// Click a sortable header: cycles asc → desc. The view is rebuilt; the
  /// selection (master space) follows its rows automatically.
  void sortByColumn(int ci) {
    if (ci < 0 || ci >= colCount || !columns[ci].sortable) return;
    final dir = (_sortCol == ci && _sortDir == ReadableSortDir.asc) ? ReadableSortDir.desc : ReadableSortDir.asc;
    _sortCol = ci;
    _sortDir = dir;
    _recompute();
  }

  /// Clear the sort indicator (restores master order under the filter).
  void clearSort() {
    if (_sortCol == null) return;
    _sortCol = null;
    _sortDir = ReadableSortDir.none;
    _recompute();
  }

  // ════════════════════════════════════════════════════════════
  // RECOMPUTE — rebuild the VIEW from the MASTER (filter + sort)
  // ════════════════════════════════════════════════════════════
  void _recompute({bool notify = true}) {
    final masters = <int>[];
    for (var i = 0; i < _all.length; i++) {
      if (_passes(_all[i])) masters.add(i);
    }
    if (_sortCol != null && _sortDir != ReadableSortDir.none) {
      final col = columns[_sortCol!];
      final mul = _sortDir == ReadableSortDir.asc ? 1 : -1;
      masters.sort((a, b) {
        final ka = col.sortKey?.call(_all[a]) ?? _all[a].toString();
        final kb = col.sortKey?.call(_all[b]) ?? _all[b].toString();
        int cmp;
        try {
          cmp = Comparable.compare(ka, kb);
        } catch (_) {
          cmp = ka.toString().compareTo(kb.toString());
        }
        return cmp * mul;
      });
    }
    _viewMaster = masters;
    _rows = [for (final m in masters) _all[m]];

    // prune selection to visible rows
    final visible = masters.toSet();
    _selRows.retainWhere(visible.contains);
    _selCells.removeWhere((c) => !visible.contains(c.row) || c.col >= colCount);
    if (!visible.contains(_activeMaster)) _activeMaster = masters.isEmpty ? 0 : masters.first;
    if (!visible.contains(_anchorMaster)) _anchorMaster = masters.isEmpty ? 0 : masters.first;
    _activeCol = _activeCol.clamp(0, colCount == 0 ? 0 : colCount - 1);
    _anchorCol = _anchorCol.clamp(0, colCount == 0 ? 0 : colCount - 1);

    if (notify) notifyListeners();
  }

  // ════════════════════════════════════════════════════════════
  // KEYBOARD NAVIGATION (driven by the view; VISIBLE space)
  // ════════════════════════════════════════════════════════════
  void moveActive(int dRow, int dCol, {bool extend = false}) {
    if (_rows.isEmpty) return;
    final curV = _visibleOf(_activeMaster);
    final baseV = curV < 0 ? 0 : curV;
    final lastRow = _rows.length - 1;
    final lastCol = colCount - 1;
    final nr = (baseV + dRow).clamp(0, lastRow);
    final nc = _isCellMode ? (_activeCol + dCol).clamp(0, lastCol) : _activeCol;
    if (_isRowMode) {
      selectRowAt(nr, range: extend && _isMulti);
    } else if (_isCellMode) {
      selectCellAt(nr, nc, range: extend && _isMulti);
    }
  }

  void moveActiveTo(int row, int col, {bool extend = false}) {
    if (_rows.isEmpty) return;
    final r = row.clamp(0, _rows.length - 1);
    final c = col.clamp(0, colCount - 1);
    if (_isRowMode) {
      selectRowAt(r, range: extend && _isMulti);
    } else if (_isCellMode) {
      selectCellAt(r, c, range: extend && _isMulti);
    }
  }

  void toggleActive() {
    final v = _visibleOf(_activeMaster);
    final r = v < 0 ? 0 : v;
    if (_isRowMode) {
      selectRowAt(r, additive: _isMulti);
    } else if (_isCellMode) {
      selectCellAt(r, _activeCol, additive: _isMulti);
    }
  }

  void selectAll() => _isCellMode ? selectAllCells() : selectAllRows();

  // ── internals ──────────────────────────────────────────────
  /// Runs a structural mutation on the MASTER list, then remaps the selection /
  /// cursor by value identity so they keep pointing at the same rows, and
  /// rebuilds the view.
  void _structural(void Function() mutate) {
    final selValues = [for (final m in _selRows) if (m >= 0 && m < _all.length) _all[m]];
    final cellPairs = [
      for (final c in _selCells) if (c.row >= 0 && c.row < _all.length) MapEntry(_all[c.row], c.col)
    ];
    final activeValue = (_activeMaster >= 0 && _activeMaster < _all.length) ? _all[_activeMaster] : null;
    mutate();
    _selRows.clear();
    for (final v in selValues) {
      final i = _all.indexOf(v);
      if (i >= 0) _selRows.add(i);
    }
    _selCells.clear();
    for (final e in cellPairs) {
      final i = _all.indexOf(e.key);
      if (i >= 0 && e.value < colCount) _selCells.add(ReadableCell(i, e.value));
    }
    if (activeValue != null) {
      final i = _all.indexOf(activeValue);
      if (i >= 0) _activeMaster = i;
    }
    _recompute();
  }

  // ── inherited lookup ───────────────────────────────────────
  static ReadableTableController<T>? of<T>(BuildContext context) =>
      (context.dependOnInheritedWidgetOfExactType<ReadableTableScope>()?.controller) as ReadableTableController<T>?;

  static ReadableTableController<T>? read<T>(BuildContext context) =>
      ((context.getElementForInheritedWidgetOfExactType<ReadableTableScope>()?.widget as ReadableTableScope?)
          ?.controller) as ReadableTableController<T>?;
}

/// Exposes a [ReadableTableController] to descendants; rebuilds dependents on
/// notify. (Untyped at the inherited layer; `of<T>` casts on read.)
class ReadableTableScope extends InheritedNotifier<ChangeNotifier> {
  const ReadableTableScope({super.key, required this.controller, required super.child})
      : super(notifier: controller);

  final ChangeNotifier controller;
}
