// ============================================================
// ERP Console — PAGE.
// ------------------------------------------------------------
// Renders ONE screen inside the BrowserStyleTabBar content surface: a KPI
// strip on top, then the EditableTable bound to the screen's columns + rows.
// The SAME EditableTable component is reused for every screen — only the data
// changes — proving it's customised purely through its schema.
//   File: example/lib/erp_console_pages.dart
// ============================================================

import 'package:flutter/material.dart';
import 'package:geniuslink_design_system/geniuslink_editable_table.dart';
import 'erp_console_data.dart';

class ErpScreenPage extends StatelessWidget {
  final ErpScreen screen;
  final bool ar;
  const ErpScreenPage({super.key, required this.screen, required this.ar});

  @override
  Widget build(BuildContext context) {
    final t = EditableTableThemeData.of(context);
    return Container(
      color: t.bg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── KPI strip ──
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(24, 22, 24, 8),
            child: Builder(builder: (context) {
              final kpis = screen.kpis(ar);
              return Row(
                children: [
                  for (int i = 0; i < kpis.length; i++) ...[
                    if (i > 0) const SizedBox(width: 14),
                    Expanded(child: _KpiCard(kpi: kpis[i], unit: screen.unit?.call(ar))),
                  ],
                ],
              );
            }),
          ),
          // ── table card ──
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(24, 12, 24, 24),
            child: EditableTable(
              key: ValueKey('${screen.id}-${ar ? 'ar' : 'en'}'),
              columns: screen.columns(ar),
              initialRows: screen.rows(ar),
              showTotals: screen.showTotals,
              totalsLabel: tr(ar, 'Total', 'الإجمالي'),
              unitLabel: screen.unit?.call(ar),
            ),
          ),
        ],
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final Kpi kpi;
  final String? unit;
  const _KpiCard({required this.kpi, this.unit});

  @override
  Widget build(BuildContext context) {
    final t = EditableTableThemeData.of(context);
    final deltaColor = kpi.up ? EditableTableThemeData.success : EditableTableThemeData.danger;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(EditableTableThemeData.radiusLg),
        border: Border.all(color: t.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: EditableTableThemeData.accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(EditableTableThemeData.radiusMd),
                ),
                child: Icon(kpi.icon, size: 17, color: EditableTableThemeData.accent),
              ),
              const Spacer(),
              if (kpi.delta.isNotEmpty)
                Row(
                  children: [
                    Icon(kpi.up ? Icons.arrow_drop_up : Icons.arrow_drop_down, size: 18, color: deltaColor),
                    Text(kpi.delta,
                        style: TextStyle(
                            fontFamily: EditableTableThemeData.monoFont,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: deltaColor)),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: Text(
                  kpi.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontFamily: EditableTableThemeData.displayFont,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                      color: t.fg1),
                ),
              ),
              if (unit != null) ...[
                const SizedBox(width: 5),
                Text(unit!,
                    style: TextStyle(
                        fontFamily: EditableTableThemeData.bodyFont, fontSize: 12, fontWeight: FontWeight.w600, color: t.fg3)),
              ],
            ],
          ),
          const SizedBox(height: 3),
          Text(kpi.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontFamily: EditableTableThemeData.bodyFont, fontSize: 12.5, color: t.fg3)),
        ],
      ),
    );
  }
}
