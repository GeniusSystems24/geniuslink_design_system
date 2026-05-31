import 'package:flutter/material.dart';
import 'package:geniuslink_design_system/geniuslink_design_system.dart';

class TableDemo extends StatefulWidget {
  const TableDemo({super.key});

  @override
  State<TableDemo> createState() => _TableDemoState();
}

class _TableDemoState extends State<TableDemo> {
  late final GLTableController controller = GLTableController(rows: glSampleRows());

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => GLShell(
        title: 'Editable Table',
        subtitle: 'TrinaGrid-powered editing · filters · keyboard navigation · selection · resizing',
        children: [
          GLSection(
            title: 'TrinaGrid-backed table',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    GLButton(
                      label: 'Add row',
                      icon: 'plus',
                      onPressed: () {
                        final next = controller.rows.length + 1;
                        controller.addRow(
                          GLTableRowModel(
                            id: '$next',
                            cells: {
                              'account': 'New ledger line $next',
                              'code': '10$next',
                              'debit': next * 950,
                              'credit': 0,
                              'status': 'review',
                            },
                          ),
                        );
                      },
                    ),
                    GLButton(
                      label: 'Delete selected',
                      icon: 'trash',
                      variant: GLButtonVariant.secondary,
                      onPressed: controller.deleteSelected,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                GLEditableTable(
                  controller: controller,
                  columns: glSampleColumns(),
                  showFilters: true,
                  minGridHeight: 340,
                  onCellChanged: (change) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Updated ${change.rowId}.${change.columnKey} → ${change.value}')),
                    );
                  },
                ),
              ],
            ),
          ),
          GLSection(
            title: 'Responsive cards fallback',
            child: GLEditableTable(
              controller: controller,
              columns: glSampleColumns(),
              responsiveCards: true,
              minGridHeight: 300,
            ),
          ),
          const GLSection(title: 'States', children: [
            GLSpec(label: 'Loading', child: GLTableStateBox(kind: 'loading')),
            GLSpec(label: 'Empty', child: GLTableStateBox(kind: 'empty')),
            GLSpec(label: 'Error', child: GLTableStateBox(kind: 'error')),
          ]),
        ],
      );
}
