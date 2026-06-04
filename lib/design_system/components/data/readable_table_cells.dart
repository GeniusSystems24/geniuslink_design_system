// ============================================================
// ReadableTable — TYPED CELL RENDERERS.
// ------------------------------------------------------------
// Phase 06 of the new-requirements work: bring EditableTable's typed column
// kinds (text / number / enum badge / date / time / color / progress / link) to
// the read-only ReadableTable, so call sites declare a column's KIND and get
// consistent formatting + affordances instead of hand-writing a `cell` builder.
//
// These are the concrete widgets the `ReadableColumn.<kind>` factories
// (readable_table_models.dart) delegate to. They are intentionally theme-driven
// and dependency-free (no intl) so the kit stays light; swap in `DateFormat` /
// `NumberFormat` at the call site via the factory's `format` hook if needed.
//
//   File: lib/design_system/components/data/readable_table_cells.dart
// ============================================================

import 'package:flutter/material.dart';
import 'editable_table_theme.dart' show EditableTableTheme; // shared tokens

/// Static builders, one per [ReadableColumnType]. Held in a class purely as a
/// namespace so the model can reference `ReadableCells.number(...)` etc.
class ReadableCells {
  ReadableCells._();

  static TextStyle _mono(BuildContext c) =>
      const TextStyle(fontFamily: 'JetBrainsMono', fontFeatures: [FontFeature.tabularFigures()], fontSize: 13);

  // ── text (optionally bilingual / two-line) ───────────────────────────────
  static Widget text(String value, {String? secondary, TextAlign? align}) => Builder(
        builder: (c) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(value, style: const TextStyle(fontSize: 13)),
            if (secondary != null && secondary.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(secondary,
                    style: TextStyle(fontSize: 12, color: Theme.of(c).hintColor)),
              ),
          ],
        ),
      );

  // ── number (grouped, fixed decimals, right-aligned, optional sign color) ──
  static Widget number(num value, {int decimals = 2, String? suffix, bool colorSign = false}) =>
      Builder(builder: (c) {
        final s = _group(value, decimals);
        final neg = value < 0;
        return Align(
          alignment: Alignment.centerRight,
          child: Text(
            suffix == null ? s : '$s\u202F$suffix',
            style: _mono(c).copyWith(
              color: colorSign ? (neg ? const Color(0xFFEF4444) : const Color(0xFF1DB88A)) : null,
            ),
          ),
        );
      });

  // ── enum badge (coloured pill) ───────────────────────────────────────────
  static Widget badge(String tag, {Color Function(String)? color}) => Builder(builder: (c) {
        final col = color?.call(tag) ?? Theme.of(c).hintColor;
        return Align(
          alignment: Alignment.centerLeft,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
            decoration: BoxDecoration(
              color: col.withOpacity(0.16),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(tag,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: col)),
          ),
        );
      });

  // ── date (formatted, monospace) ──────────────────────────────────────────
  static Widget date(DateTime value, {String Function(DateTime)? format}) => Builder(
        builder: (c) => Text(
          format?.call(value) ??
              '${value.year.toString().padLeft(4, '0')}-'
                  '${value.month.toString().padLeft(2, '0')}-'
                  '${value.day.toString().padLeft(2, '0')}',
          style: _mono(c),
        ),
      );

  // ── time (HH:mm, monospace) ──────────────────────────────────────────────
  static Widget time(String hhmm) => Builder(builder: (c) => Text(hhmm, style: _mono(c)));

  // ── colour (swatch + hex) ────────────────────────────────────────────────
  static Widget color(String hex) => Builder(builder: (c) {
        final parsed = _parseHex(hex);
        return Row(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: parsed,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.black.withOpacity(0.2)),
            ),
          ),
          const SizedBox(width: 8),
          Text(hex.toUpperCase(), style: _mono(c)),
        ]);
      });

  // ── progress (labelled bar) ──────────────────────────────────────────────
  static Widget progress(double ratio) => Builder(builder: (c) {
        final r = (ratio > 1 ? ratio / 100 : ratio).clamp(0.0, 1.0);
        return Row(children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: r,
                minHeight: 6,
                backgroundColor: Theme.of(c).dividerColor,
                valueColor: const AlwaysStoppedAnimation(Color(0xFF2A6FDB)),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text('${(r * 100).round()}%', style: _mono(c).copyWith(fontSize: 12)),
        ]);
      });

  // ── link affordance ──────────────────────────────────────────────────────
  static Widget link(String text, {VoidCallback? onTap}) => Builder(builder: (c) {
        final color = Theme.of(c).colorScheme.primary;
        return InkWell(
          onTap: onTap,
          child: Text(text,
              style: TextStyle(fontSize: 13, color: color, decoration: TextDecoration.underline)),
        );
      });

  // ── helpers ──────────────────────────────────────────────────────────────
  static String _group(num value, int decimals) {
    final fixed = value.toStringAsFixed(decimals < 0 ? 0 : decimals);
    final parts = fixed.split('.');
    final intPart = parts[0].replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
    return parts.length > 1 ? '$intPart.${parts[1]}' : intPart;
  }

  static Color _parseHex(String hex) {
    var h = hex.replaceAll('#', '').trim();
    if (h.length == 6) h = 'FF$h';
    return Color(int.tryParse(h, radix: 16) ?? 0xFF888888);
  }
}
