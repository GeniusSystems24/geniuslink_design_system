import 'package:flutter/material.dart';
import 'package:geniuslink_design_system/geniuslink_design_system.dart';

class TableDemo extends StatelessWidget {
  const TableDemo({super.key});
  @override
  Widget build(BuildContext context) => GLShell(
        title: 'Editable Table',
        subtitle: 'Inline editing · sorting · selection · responsive cards · states',
        children: [
          GLSection(title: 'Table', child: GLEditableTable(columns: glSampleColumns(), rows: glSampleRows())),
          const GLSection(title: 'States', children: [
            GLSpec(label: 'Loading', child: GLTableStateBox(kind: 'loading')),
            GLSpec(label: 'Empty', child: GLTableStateBox(kind: 'empty')),
            GLSpec(label: 'Error', child: GLTableStateBox(kind: 'error')),
          ]),
        ],
      );
}
