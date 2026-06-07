// ============================================================
// AutoSuggestionsBox — MODEL  (generic over the suggestion's value type `T`).
// ------------------------------------------------------------
// The data types the box renders and the *source* that produces matches for a
// query. A source is either static (an in-memory list filtered by a match
// strategy) or async (a `Future` callback — remote search, a database, etc.).
//
//   • AutoSuggestion<T>      — one row: a typed `value` + display `label`
//                              (+ optional description / icon / group).
//   • AutoSuggestionMatch    — how a query is tested against a label
//                              (contains · prefix · words · fuzzy).
//   • AutoSuggestionsSource  — query(text) → list. Factories:
//        .list(items)        static, filtered by [match]
//        .strings(values)    static, from plain strings
//        .async(fetch)       any Future<List<AutoSuggestion>>
//   • HighlightSpan          — a [start,end) slice of a label that matched,
//                              used by the view to bold the hit.
//
//   File: lib/design_system/components/forms/auto_suggestions_box_models.dart
// ============================================================

import 'dart:async';
import 'package:flutter/widgets.dart';

/// One suggestion row. [value] is what the host receives on select; [label] is
/// the text shown and matched against.
@immutable
class AutoSuggestion<T> {
  /// The strongly-typed payload handed back via `onSelected`.
  final T value;

  /// Primary display text — also the text matched against the query.
  final String label;

  /// Optional secondary line (e.g. a code, email, or hint).
  final String? description;

  /// Optional leading glyph.
  final IconData? icon;

  /// Optional section key. When any visible suggestion carries a [group], the
  /// list renders sticky-style section headers in first-seen order.
  final String? group;

  /// Extra haystack text matched in addition to [label] (synonyms, codes…),
  /// never shown. e.g. `keywords: ['usd', 'dollar']`.
  final List<String> keywords;

  /// When false the row is shown but cannot be picked (a header-like entry).
  final bool enabled;

  const AutoSuggestion({
    required this.value,
    required this.label,
    this.description,
    this.icon,
    this.group,
    this.keywords = const [],
    this.enabled = true,
  });

  /// The full lower-cased haystack (label + keywords) matched against a query.
  String get haystack => ([label, ...keywords]).join(' ').toLowerCase();

  AutoSuggestion<T> copyWith({
    T? value,
    String? label,
    String? description,
    IconData? icon,
    String? group,
    List<String>? keywords,
    bool? enabled,
  }) =>
      AutoSuggestion<T>(
        value: value ?? this.value,
        label: label ?? this.label,
        description: description ?? this.description,
        icon: icon ?? this.icon,
        group: group ?? this.group,
        keywords: keywords ?? this.keywords,
        enabled: enabled ?? this.enabled,
      );

  @override
  bool operator ==(Object other) =>
      other is AutoSuggestion<T> && other.value == value && other.label == label;

  @override
  int get hashCode => Object.hash(value, label);
}

/// How a query string is tested against a suggestion's haystack.
enum AutoSuggestionMatch {
  /// Substring anywhere (default).
  contains,

  /// Haystack must start with the query.
  prefix,

  /// Every whitespace-separated token of the query must appear (any order).
  words,

  /// Subsequence/fuzzy — the query's characters appear in order, gaps allowed.
  fuzzy,
}

/// A `[start, end)` slice of a label that matched the query — the view bolds it.
@immutable
class HighlightSpan {
  final int start;
  final int end;
  const HighlightSpan(this.start, this.end);
}

/// Produces suggestions for a query. Subclass for custom behaviour, or use the
/// [AutoSuggestionsSource.list] / `.strings` / `.async` factories.
abstract class AutoSuggestionsSource<T> {
  const AutoSuggestionsSource();

  /// Return the matches for [query] (may be sync or a Future). An empty query
  /// is expected to return the "initial"/all set (capped by the view).
  FutureOr<List<AutoSuggestion<T>>> query(String query);

  /// Whether results arrive asynchronously (drives the loading spinner).
  bool get isAsync => false;

  /// Static, in-memory list filtered locally by [match].
  factory AutoSuggestionsSource.list(
    List<AutoSuggestion<T>> items, {
    AutoSuggestionMatch match,
    bool caseSensitive,
  }) = _ListSource<T>;

  /// Async source — any `Future`-returning search (debounced by the controller).
  factory AutoSuggestionsSource.async(
    Future<List<AutoSuggestion<T>>> Function(String query) fetch,
  ) = _AsyncSource<T>;
}

/// Convenience builder for a plain `List<String>` (value == label).
class StringSuggestions {
  StringSuggestions._();

  /// A static source over plain strings.
  static AutoSuggestionsSource<String> source(
    List<String> values, {
    AutoSuggestionMatch match = AutoSuggestionMatch.contains,
  }) =>
      AutoSuggestionsSource.list(
        [for (final v in values) AutoSuggestion<String>(value: v, label: v)],
        match: match,
      );
}

class _ListSource<T> extends AutoSuggestionsSource<T> {
  final List<AutoSuggestion<T>> items;
  final AutoSuggestionMatch match;
  final bool caseSensitive;
  const _ListSource(this.items, {this.match = AutoSuggestionMatch.contains, this.caseSensitive = false});

  @override
  List<AutoSuggestion<T>> query(String query) {
    final q = caseSensitive ? query.trim() : query.trim().toLowerCase();
    if (q.isEmpty) return List<AutoSuggestion<T>>.of(items);
    final out = <AutoSuggestion<T>>[];
    for (final s in items) {
      final hay = caseSensitive ? ([s.label, ...s.keywords].join(' ')) : s.haystack;
      if (AutoSuggestionMatching.test(hay, q, match)) out.add(s);
    }
    // Stable, relevance-ish ordering: prefix hits first, then by match index.
    out.sort((a, b) {
      final ha = caseSensitive ? a.label : a.label.toLowerCase();
      final hb = caseSensitive ? b.label : b.label.toLowerCase();
      final ia = ha.indexOf(q), ib = hb.indexOf(q);
      final ra = ia < 0 ? 1 << 20 : ia, rb = ib < 0 ? 1 << 20 : ib;
      if (ra != rb) return ra - rb;
      return ha.length - hb.length;
    });
    return out;
  }
}

class _AsyncSource<T> extends AutoSuggestionsSource<T> {
  final Future<List<AutoSuggestion<T>>> Function(String query) fetch;
  const _AsyncSource(this.fetch);
  @override
  bool get isAsync => true;
  @override
  Future<List<AutoSuggestion<T>>> query(String query) => fetch(query);
}

/// Pure matching + highlight helpers (shared by sources and the view).
class AutoSuggestionMatching {
  AutoSuggestionMatching._();

  /// Test a (already-cased) [haystack] against a (already-cased) [query].
  static bool test(String haystack, String query, AutoSuggestionMatch mode) {
    if (query.isEmpty) return true;
    switch (mode) {
      case AutoSuggestionMatch.contains:
        return haystack.contains(query);
      case AutoSuggestionMatch.prefix:
        return haystack.startsWith(query);
      case AutoSuggestionMatch.words:
        return query.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).every(haystack.contains);
      case AutoSuggestionMatch.fuzzy:
        return _isSubsequence(query, haystack);
    }
  }

  static bool _isSubsequence(String needle, String hay) {
    var i = 0;
    for (var j = 0; j < hay.length && i < needle.length; j++) {
      if (hay[j] == needle[i]) i++;
    }
    return i == needle.length;
  }

  /// Compute highlight spans of [query] within [label] for bolding. Returns the
  /// contiguous match for contains/prefix/words tokens, or per-character spans
  /// for fuzzy. Empty when nothing lines up.
  static List<HighlightSpan> spans(String label, String query, AutoSuggestionMatch mode) {
    if (query.trim().isEmpty) return const [];
    final lower = label.toLowerCase();
    final q = query.trim().toLowerCase();

    List<HighlightSpan> contiguous(String token) {
      final spans = <HighlightSpan>[];
      var from = 0;
      while (true) {
        final i = lower.indexOf(token, from);
        if (i < 0) break;
        spans.add(HighlightSpan(i, i + token.length));
        from = i + token.length;
      }
      return spans;
    }

    switch (mode) {
      case AutoSuggestionMatch.contains:
      case AutoSuggestionMatch.prefix:
        return contiguous(q);
      case AutoSuggestionMatch.words:
        final spans = <HighlightSpan>[];
        for (final t in q.split(RegExp(r'\s+')).where((t) => t.isNotEmpty)) {
          spans.addAll(contiguous(t));
        }
        spans.sort((a, b) => a.start - b.start);
        return _merge(spans);
      case AutoSuggestionMatch.fuzzy:
        final spans = <HighlightSpan>[];
        var i = 0;
        for (var j = 0; j < lower.length && i < q.length; j++) {
          if (lower[j] == q[i]) {
            spans.add(HighlightSpan(j, j + 1));
            i++;
          }
        }
        return i == q.length ? _merge(spans) : const [];
    }
  }

  static List<HighlightSpan> _merge(List<HighlightSpan> spans) {
    if (spans.length < 2) return spans;
    final out = <HighlightSpan>[spans.first];
    for (var k = 1; k < spans.length; k++) {
      final last = out.last;
      final s = spans[k];
      if (s.start <= last.end) {
        out[out.length - 1] = HighlightSpan(last.start, s.end > last.end ? s.end : last.end);
      } else {
        out.add(s);
      }
    }
    return out;
  }
}
