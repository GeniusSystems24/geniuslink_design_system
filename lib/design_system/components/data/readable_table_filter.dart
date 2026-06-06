// ============================================================
// ReadableTable — FILTER MODEL.
// ------------------------------------------------------------
// The advanced, typed filter layer for the read-only display grid. A filter is
// one immutable predicate over a single column; the controller AND/ORs a list
// of them (plus an optional cross-column quick-search) to derive the visible
// rows from the master row set.
//
//   • ReadableFilterOp    — the operator (contains · equals · between · is any
//                           of · is empty …). The set offered per column is a
//                           function of that column's ReadableColumnType.
//   • ReadableFilterArity — how many operands an operator takes (none · one ·
//                           two · set) — drives the editor UI.
//   • ReadableFilter      — one predicate: a LOGICAL column index, an operator,
//                           its operand(s), and an enabled flag. `test(col, v)`
//                           evaluates it against a row value using the column's
//                           own `sortKey` (comparable) / `copyText` (string).
//   • ReadableFilterJoin  — how the controller combines several filters (all =
//                           AND, any = OR).
//   • ReadableFilterCatalog — operator metadata: which ops a type supports,
//                           their arity, a human label (date-aware) and a
//                           one-line summary of a configured filter.
//
//   File: lib/design_system/components/data/readable_table_filter.dart
// ============================================================

import 'package:flutter/foundation.dart';
import 'readable_table_models.dart';

/// How several filters combine into one predicate.
enum ReadableFilterJoin {
  /// Every enabled filter must match (AND).
  all,

  /// Any enabled filter may match (OR).
  any,
}

/// The number / shape of operands an operator needs — drives the editor UI.
enum ReadableFilterArity {
  /// No operand (e.g. `is empty`).
  none,

  /// A single operand (text / number / date).
  one,

  /// A low + high pair (`is between`).
  two,

  /// A set of allowed values (`is any of` / `is none of`).
  set,
}

/// A single column predicate operator.
enum ReadableFilterOp {
  contains,
  notContains,
  startsWith,
  endsWith,
  equals,
  notEquals,
  greater,
  greaterOrEqual,
  less,
  lessOrEqual,
  between,
  isAnyOf,
  isNoneOf,
  isEmpty,
  isNotEmpty,
}

/// One immutable filter predicate over a single (logical) column.
///
/// Operands are stored loosely so one class covers every kind: [value] /
/// [value2] hold a `String` (text), `num` (number) or `DateTime` (date) per the
/// operator + column type, and [options] holds the allowed set for
/// `isAnyOf` / `isNoneOf`. Build them by hand or via the ergonomic factories.
@immutable
class ReadableFilter {
  /// The LOGICAL column index this predicate tests (stable across visual
  /// reorder — the same index space as the controller's `columns`).
  final int columnIndex;

  /// The operator.
  final ReadableFilterOp op;

  /// Primary operand (text `String`, `num`, or `DateTime`). Null for arity
  /// [ReadableFilterArity.none] / [ReadableFilterArity.set].
  final Object? value;

  /// Upper bound for [ReadableFilterOp.between].
  final Object? value2;

  /// Allowed values for [ReadableFilterOp.isAnyOf] / [ReadableFilterOp.isNoneOf].
  final Set<String> options;

  /// When false the predicate is kept (as a chip) but not applied.
  final bool enabled;

  const ReadableFilter({
    required this.columnIndex,
    required this.op,
    this.value,
    this.value2,
    this.options = const {},
    this.enabled = true,
  });

  // ── ergonomic factories ────────────────────────────────────
  factory ReadableFilter.text(int columnIndex, ReadableFilterOp op, [String? value]) =>
      ReadableFilter(columnIndex: columnIndex, op: op, value: value);

  factory ReadableFilter.number(int columnIndex, ReadableFilterOp op, num value, [num? value2]) =>
      ReadableFilter(columnIndex: columnIndex, op: op, value: value, value2: value2);

  factory ReadableFilter.date(int columnIndex, ReadableFilterOp op, DateTime value, [DateTime? value2]) =>
      ReadableFilter(columnIndex: columnIndex, op: op, value: value, value2: value2);

  factory ReadableFilter.anyOf(int columnIndex, Iterable<String> options, {bool exclude = false}) =>
      ReadableFilter(
        columnIndex: columnIndex,
        op: exclude ? ReadableFilterOp.isNoneOf : ReadableFilterOp.isAnyOf,
        options: {...options},
      );

  ReadableFilter copyWith({
    int? columnIndex,
    ReadableFilterOp? op,
    Object? value,
    Object? value2,
    Set<String>? options,
    bool? enabled,
    bool clearValue = false,
    bool clearValue2 = false,
  }) =>
      ReadableFilter(
        columnIndex: columnIndex ?? this.columnIndex,
        op: op ?? this.op,
        value: clearValue ? null : (value ?? this.value),
        value2: clearValue2 ? null : (value2 ?? this.value2),
        options: options ?? this.options,
        enabled: enabled ?? this.enabled,
      );

  /// The operand shape this filter's operator needs.
  ReadableFilterArity get arity => ReadableFilterCatalog.arity(op);

  /// Whether this filter is configured enough to evaluate (has its operands).
  bool get isComplete {
    switch (arity) {
      case ReadableFilterArity.none:
        return true;
      case ReadableFilterArity.one:
        return value != null && value.toString().trim().isNotEmpty;
      case ReadableFilterArity.two:
        return value != null && value2 != null;
      case ReadableFilterArity.set:
        return options.isNotEmpty;
    }
  }

  /// Evaluate this predicate against one row [row], reading it through the
  /// column's own accessors (`copyText` for text ops, `sortKey` for ordered
  /// comparisons). An incomplete or out-of-range filter matches everything
  /// (so a half-built chip never hides rows).
  bool test<T>(ReadableColumn<T> column, T row) {
    if (!enabled || !isComplete) return true;

    String text() {
      final raw = column.copyText?.call(row) ?? column.sortKey?.call(row);
      return (raw ?? '').toString();
    }

    Comparable<Object?>? key() => column.sortKey?.call(row) as Comparable<Object?>?;

    switch (op) {
      case ReadableFilterOp.contains:
        return text().toLowerCase().contains(_s(value).toLowerCase());
      case ReadableFilterOp.notContains:
        return !text().toLowerCase().contains(_s(value).toLowerCase());
      case ReadableFilterOp.startsWith:
        return text().toLowerCase().startsWith(_s(value).toLowerCase());
      case ReadableFilterOp.endsWith:
        return text().toLowerCase().endsWith(_s(value).toLowerCase());
      case ReadableFilterOp.equals:
        return _eq(column.type, key(), text(), value);
      case ReadableFilterOp.notEquals:
        return !_eq(column.type, key(), text(), value);
      case ReadableFilterOp.greater:
        return _cmp(key(), value) > 0;
      case ReadableFilterOp.greaterOrEqual:
        return _cmp(key(), value) >= 0;
      case ReadableFilterOp.less:
        return _cmp(key(), value) < 0;
      case ReadableFilterOp.lessOrEqual:
        return _cmp(key(), value) <= 0;
      case ReadableFilterOp.between:
        return _cmp(key(), value) >= 0 && _cmp(key(), value2) <= 0;
      case ReadableFilterOp.isAnyOf:
        return options.contains(text());
      case ReadableFilterOp.isNoneOf:
        return !options.contains(text());
      case ReadableFilterOp.isEmpty:
        return text().trim().isEmpty;
      case ReadableFilterOp.isNotEmpty:
        return text().trim().isNotEmpty;
    }
  }

  static String _s(Object? v) => v?.toString() ?? '';

  /// Equality that respects the column's data kind: numbers compare
  /// numerically, dates by instant, everything else case-insensitively.
  static bool _eq(ReadableColumnType type, Comparable? key, String text, Object? operand) {
    if (operand == null) return false;
    if ((type == ReadableColumnType.number || type == ReadableColumnType.progress) &&
        key is num &&
        operand is num) {
      return key == operand;
    }
    if (type == ReadableColumnType.date && key is DateTime && operand is DateTime) {
      return key.year == operand.year && key.month == operand.month && key.day == operand.day;
    }
    return text.toLowerCase() == operand.toString().toLowerCase();
  }

  /// Three-way compare of a row's comparable [key] against an [operand]. A null
  /// key sorts before everything; mismatched types fall back to string compare.
  static int _cmp(Comparable? key, Object? operand) {
    if (operand == null) return 0;
    if (key == null) return -1;
    if (key is num && operand is num) return key.compareTo(operand);
    if (key is DateTime && operand is DateTime) return key.compareTo(operand);
    try {
      return Comparable.compare(key, operand as Comparable);
    } catch (_) {
      return key.toString().toLowerCase().compareTo(operand.toString().toLowerCase());
    }
  }

  @override
  bool operator ==(Object other) =>
      other is ReadableFilter &&
      other.columnIndex == columnIndex &&
      other.op == op &&
      other.value == value &&
      other.value2 == value2 &&
      other.enabled == enabled &&
      setEquals(other.options, options);

  @override
  int get hashCode => Object.hash(columnIndex, op, value, value2, enabled, Object.hashAllUnordered(options));
}

/// Operator metadata: which operators a column type supports, their arity, a
/// human (date-aware) label, and a one-line summary of a configured filter.
class ReadableFilterCatalog {
  const ReadableFilterCatalog._();

  /// The operators offered for a column of [type].
  static List<ReadableFilterOp> opsFor(ReadableColumnType type) {
    switch (type) {
      case ReadableColumnType.text:
      case ReadableColumnType.link:
        return const [
          ReadableFilterOp.contains,
          ReadableFilterOp.notContains,
          ReadableFilterOp.equals,
          ReadableFilterOp.notEquals,
          ReadableFilterOp.startsWith,
          ReadableFilterOp.endsWith,
          ReadableFilterOp.isEmpty,
          ReadableFilterOp.isNotEmpty,
        ];
      case ReadableColumnType.number:
      case ReadableColumnType.progress:
        return const [
          ReadableFilterOp.equals,
          ReadableFilterOp.notEquals,
          ReadableFilterOp.greater,
          ReadableFilterOp.greaterOrEqual,
          ReadableFilterOp.less,
          ReadableFilterOp.lessOrEqual,
          ReadableFilterOp.between,
        ];
      case ReadableColumnType.enumBadge:
        return const [
          ReadableFilterOp.isAnyOf,
          ReadableFilterOp.isNoneOf,
          ReadableFilterOp.equals,
          ReadableFilterOp.notEquals,
        ];
      case ReadableColumnType.date:
        return const [
          ReadableFilterOp.equals,
          ReadableFilterOp.less, // is before
          ReadableFilterOp.greater, // is after
          ReadableFilterOp.between,
          ReadableFilterOp.lessOrEqual,
          ReadableFilterOp.greaterOrEqual,
        ];
      case ReadableColumnType.time:
        return const [
          ReadableFilterOp.equals,
          ReadableFilterOp.less,
          ReadableFilterOp.greater,
          ReadableFilterOp.between,
        ];
      case ReadableColumnType.color:
        return const [
          ReadableFilterOp.equals,
          ReadableFilterOp.notEquals,
          ReadableFilterOp.isAnyOf,
          ReadableFilterOp.isNoneOf,
        ];
    }
  }

  /// The operand shape an operator needs.
  static ReadableFilterArity arity(ReadableFilterOp op) {
    switch (op) {
      case ReadableFilterOp.isEmpty:
      case ReadableFilterOp.isNotEmpty:
        return ReadableFilterArity.none;
      case ReadableFilterOp.between:
        return ReadableFilterArity.two;
      case ReadableFilterOp.isAnyOf:
      case ReadableFilterOp.isNoneOf:
        return ReadableFilterArity.set;
      default:
        return ReadableFilterArity.one;
    }
  }

  /// Whether an operator's operand is an ordered/temporal/numeric quantity
  /// (vs. free text) — lets the editor pick a number / date input.
  static bool isOrdered(ReadableFilterOp op) {
    switch (op) {
      case ReadableFilterOp.greater:
      case ReadableFilterOp.greaterOrEqual:
      case ReadableFilterOp.less:
      case ReadableFilterOp.lessOrEqual:
      case ReadableFilterOp.between:
        return true;
      default:
        return false;
    }
  }

  /// A human label for an operator, tuned to the column [type] (dates read
  /// "is before / is after" where numbers read "is less / greater than").
  static String label(ReadableFilterOp op, ReadableColumnType type) {
    final temporal = type == ReadableColumnType.date || type == ReadableColumnType.time;
    switch (op) {
      case ReadableFilterOp.contains:
        return 'contains';
      case ReadableFilterOp.notContains:
        return 'does not contain';
      case ReadableFilterOp.startsWith:
        return 'starts with';
      case ReadableFilterOp.endsWith:
        return 'ends with';
      case ReadableFilterOp.equals:
        return temporal ? 'is on' : 'is';
      case ReadableFilterOp.notEquals:
        return temporal ? 'is not on' : 'is not';
      case ReadableFilterOp.greater:
        return temporal ? 'is after' : 'is greater than';
      case ReadableFilterOp.greaterOrEqual:
        return temporal ? 'is on or after' : 'is ≥';
      case ReadableFilterOp.less:
        return temporal ? 'is before' : 'is less than';
      case ReadableFilterOp.lessOrEqual:
        return temporal ? 'is on or before' : 'is ≤';
      case ReadableFilterOp.between:
        return 'is between';
      case ReadableFilterOp.isAnyOf:
        return 'is any of';
      case ReadableFilterOp.isNoneOf:
        return 'is none of';
      case ReadableFilterOp.isEmpty:
        return 'is empty';
      case ReadableFilterOp.isNotEmpty:
        return 'is not empty';
    }
  }

  /// A one-line, human summary of a configured [filter] for the column [label]
  /// — e.g. `Account contains "cash"`, `Balance is between 0 and 5,000`.
  static String summary(ReadableFilter filter, ReadableColumn column, {String? label}) {
    final col = label ?? (column.label.isEmpty ? 'Column' : column.label);
    final op = ReadableFilterCatalog.label(filter.op, column.type);
    switch (filter.arity) {
      case ReadableFilterArity.none:
        return '$col $op';
      case ReadableFilterArity.one:
        return '$col $op ${_fmt(filter.value, column.type)}';
      case ReadableFilterArity.two:
        return '$col $op ${_fmt(filter.value, column.type)} and ${_fmt(filter.value2, column.type)}';
      case ReadableFilterArity.set:
        final list = filter.options.toList()..sort();
        final shown = list.take(3).join(', ');
        final extra = list.length > 3 ? ' +${list.length - 3}' : '';
        return '$col $op $shown$extra';
    }
  }

  static String _fmt(Object? v, ReadableColumnType type) {
    if (v == null) return '—';
    if (v is DateTime) {
      String two(int n) => n.toString().padLeft(2, '0');
      return '${v.year}-${two(v.month)}-${two(v.day)}';
    }
    if (v is num) {
      final s = v == v.roundToDouble() ? v.toInt().toString() : v.toString();
      // light thousands grouping for readability
      final neg = s.startsWith('-');
      final digits = neg ? s.substring(1) : s;
      final parts = digits.split('.');
      final intPart = parts[0];
      final buf = StringBuffer();
      for (var i = 0; i < intPart.length; i++) {
        if (i > 0 && (intPart.length - i) % 3 == 0) buf.write(',');
        buf.write(intPart[i]);
      }
      final grouped = parts.length > 1 ? '${buf.toString()}.${parts[1]}' : buf.toString();
      return '${neg ? '-' : ''}$grouped';
    }
    return '"$v"';
  }
}
