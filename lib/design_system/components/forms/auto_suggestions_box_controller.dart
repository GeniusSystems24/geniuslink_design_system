// ============================================================
// AutoSuggestionsBox — CONTROLLER  (generic over the value type `T`).
// ------------------------------------------------------------
// The single source of truth for one box: the typed text, the current result
// list, which row is highlighted, whether the overlay is open, and the async
// loading / error state. The view (AutoSuggestionsBox) is a thin render of this
// and forwards every keystroke / arrow / Enter here.
//
// Querying is debounced and race-safe: each [setQuery] bumps a sequence number;
// a late async response whose sequence is stale is dropped, so fast typing
// never flickers an old result set. A static (sync) source resolves inline with
// no spinner.
//
//   final c = AutoSuggestionsBoxController<City>(source: citySource);
//   c.addListener(() => /* rebuild */);
//   ...
//   c.text;            // current input
//   c.results;         // current matches
//   c.highlighted;     // the focused row (for Enter)
//   c.select(item);    // commit a row
//
//   File: lib/design_system/components/forms/auto_suggestions_box_controller.dart
// ============================================================

import 'dart:async';
import 'package:flutter/widgets.dart';
import 'auto_suggestions_box_models.dart';

class AutoSuggestionsBoxController<T> extends ChangeNotifier {
  AutoSuggestionsBoxController({
    required AutoSuggestionsSource<T> source,
    TextEditingController? textController,
    String? initialText,
    AutoSuggestion<T>? initialValue,
    this.debounce = const Duration(milliseconds: 180),
    this.minChars = 0,
    this.maxResults = 50,
    this.allowFreeText = true,
    this.multiSelect = false,
    List<AutoSuggestion<T>>? initialSelected,
  })  : _source = source,
        _ownsText = textController == null,
        text = textController ?? TextEditingController(text: initialValue?.label ?? initialText ?? '') {
    _selected = initialValue;
    if (initialSelected != null) _selectedItems.addAll(initialSelected);
    text.addListener(_onTextChanged);
    _lastText = text.text;
    // Seed the initial (empty-query) result set so opening shows everything.
    _run(text.text, immediate: true);
  }

  AutoSuggestionsSource<T> _source;
  final bool _ownsText;

  /// The field's text controller (shared with the `TextField` in the view).
  final TextEditingController text;

  /// Debounce window before an async query fires (sync sources ignore it).
  final Duration debounce;

  /// Don't query until at least this many characters are typed (0 = always).
  final int minChars;

  /// Hard cap on how many rows the overlay shows.
  final int maxResults;

  /// Whether committing arbitrary typed text (not a suggestion) is allowed.
  bool allowFreeText;

  /// When true the box keeps a *set* of chosen items: tapping / Enter toggles a
  /// row's membership and the overlay stays open (instead of committing one
  /// value and closing). Read the chosen rows from [selectedItems].
  final bool multiSelect;

  // ── state ──────────────────────────────────────────────────
  List<AutoSuggestion<T>> _results = const [];
  int _highlighted = -1;
  bool _open = false;
  bool _loading = false;
  Object? _error;
  AutoSuggestion<T>? _selected;

  int _seq = 0; // race guard for async
  Timer? _debounceTimer;
  String _lastText = '';
  bool _muteText = false; // suppress _onTextChanged during programmatic writes
  final List<AutoSuggestion<T>> _selectedItems = []; // multi-select set (ordered)

  // ── reads ──────────────────────────────────────────────────
  String get query => text.text;
  List<AutoSuggestion<T>> get results => _results;
  bool get hasResults => _results.isNotEmpty;
  int get highlightedIndex => _highlighted;
  AutoSuggestion<T>? get highlighted =>
      (_highlighted >= 0 && _highlighted < _results.length) ? _results[_highlighted] : null;
  bool get isOpen => _open;
  bool get isLoading => _loading;
  Object? get error => _error;

  /// The last committed suggestion (null after a free-text commit or clear).
  AutoSuggestion<T>? get selected => _selected;

  /// The committed typed value when free-text is allowed and no row matched.
  T? get value => _selected?.value;

  bool isHighlighted(int i) => i == _highlighted;

  // ── multi-select ───────────────────────────────────────────
  /// The chosen rows (multi-select), in pick order.
  List<AutoSuggestion<T>> get selectedItems => List.unmodifiable(_selectedItems);

  /// The chosen values (multi-select), in pick order.
  List<T> get selectedValues => [for (final s in _selectedItems) s.value];

  /// Whether [value] is in the multi-select set.
  bool isSelectedValue(T value) {
    for (final s in _selectedItems) {
      if (s.value == value) return true;
    }
    return false;
  }

  /// Toggle [item] in the multi-select set; keeps the overlay open and the query
  /// untouched. Returns true if the item is now selected.
  bool toggleSelected(AutoSuggestion<T> item) {
    final i = _selectedItems.indexWhere((s) => s.value == item.value);
    final nowSelected = i < 0;
    if (nowSelected) {
      _selectedItems.add(item);
    } else {
      _selectedItems.removeAt(i);
    }
    notifyListeners();
    return nowSelected;
  }

  /// Remove a value from the multi-select set (e.g. a chip's ×).
  void removeSelectedValue(T value) {
    final before = _selectedItems.length;
    _selectedItems.removeWhere((s) => s.value == value);
    if (_selectedItems.length != before) notifyListeners();
  }

  /// Replace the whole multi-select set.
  void setSelectedItems(List<AutoSuggestion<T>> items) {
    _selectedItems
      ..clear()
      ..addAll(items);
    notifyListeners();
  }

  /// Clear the multi-select set.
  void clearSelection() {
    if (_selectedItems.isEmpty) return;
    _selectedItems.clear();
    notifyListeners();
  }

  /// Swap the data source at runtime (e.g. switching match strategy) and re-run.
  set source(AutoSuggestionsSource<T> s) {
    _source = s;
    _run(text.text, immediate: true);
  }

  AutoSuggestionsSource<T> get source => _source;

  // ── opening / closing ──────────────────────────────────────
  void open() {
    if (_open) return;
    _open = true;
    // Re-run so a stale list (or first open) is fresh; highlight first row.
    _run(text.text, immediate: true);
    notifyListeners();
  }

  void close() {
    if (!_open) return;
    _open = false;
    _highlighted = -1;
    _debounceTimer?.cancel();
    notifyListeners();
  }

  void toggle() => _open ? close() : open();

  // ── typing ─────────────────────────────────────────────────
  void _onTextChanged() {
    if (_muteText) return;
    if (text.text == _lastText) return;
    _lastText = text.text;
    // Typing invalidates a prior committed selection (until re-picked).
    if (_selected != null && _selected!.label != text.text) _selected = null;
    if (!_open) _open = true;
    _run(text.text);
  }

  /// Programmatically set the field text without triggering a query churn loop.
  void setText(String value, {bool moveCursorToEnd = true}) {
    _muteText = true;
    text.value = TextEditingValue(
      text: value,
      selection: moveCursorToEnd ? TextSelection.collapsed(offset: value.length) : text.selection,
    );
    _lastText = value;
    _muteText = false;
  }

  void _run(String raw, {bool immediate = false}) {
    _debounceTimer?.cancel();
    final q = raw.trim();
    if (q.length < minChars) {
      _results = const [];
      _highlighted = -1;
      _loading = false;
      notifyListeners();
      return;
    }
    final mySeq = ++_seq;

    void deliver(List<AutoSuggestion<T>> list) {
      if (mySeq != _seq) return; // a newer query superseded us
      _results = list.length > maxResults ? list.sublist(0, maxResults) : list;
      _highlighted = _results.isEmpty ? -1 : 0;
      _loading = false;
      _error = null;
      notifyListeners();
    }

    final result = _source.query(raw);
    if (result is Future<List<AutoSuggestion<T>>>) {
      _loading = true;
      notifyListeners();
      final fire = () {
        result.then(deliver).catchError((Object e) {
          if (mySeq != _seq) return;
          _error = e;
          _loading = false;
          _results = const [];
          _highlighted = -1;
          notifyListeners();
        });
      };
      if (immediate || debounce == Duration.zero) {
        fire();
      } else {
        _debounceTimer = Timer(debounce, fire);
      }
    } else {
      deliver(result);
    }
  }

  /// Force a re-query of the current text (e.g. after the source changed).
  void refresh() => _run(text.text, immediate: true);

  // ── keyboard navigation ────────────────────────────────────
  /// Move the highlight by [delta] rows, skipping disabled entries, wrapping at
  /// the ends. Opens the overlay if closed.
  void moveHighlight(int delta) {
    if (!_open) {
      open();
      return;
    }
    if (_results.isEmpty) return;
    var i = _highlighted;
    final n = _results.length;
    for (var step = 0; step < n; step++) {
      i = (i + delta) % n;
      if (i < 0) i += n;
      if (_results[i].enabled) break;
    }
    _highlighted = i;
    notifyListeners();
  }

  void highlightAt(int i) {
    if (i == _highlighted) return;
    _highlighted = (i >= 0 && i < _results.length) ? i : -1;
    notifyListeners();
  }

  // ── committing ─────────────────────────────────────────────
  /// Commit [item]: writes its label into the field, records it as [selected],
  /// and closes the overlay. Returns the committed suggestion.
  AutoSuggestion<T> select(AutoSuggestion<T> item) {
    _selected = item;
    setText(item.label);
    _open = false;
    _highlighted = -1;
    notifyListeners();
    return item;
  }

  /// Commit whatever's highlighted (Enter). Returns the picked suggestion, or
  /// null when there was nothing to pick (caller may treat as free-text submit).
  AutoSuggestion<T>? commitHighlighted() {
    final h = highlighted;
    if (h != null && h.enabled) return select(h);
    return null;
  }

  /// Clear the field, selection and results.
  void clear() {
    setText('');
    _selected = null;
    _results = const [];
    _highlighted = -1;
    _error = null;
    notifyListeners();
    _run('', immediate: true);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    text.removeListener(_onTextChanged);
    if (_ownsText) text.dispose();
    super.dispose();
  }
}
