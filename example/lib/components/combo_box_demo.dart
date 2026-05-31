import 'package:flutter/material.dart';
import 'package:geniuslink_design_system/geniuslink_design_system.dart';

class ComboBoxDemo extends StatelessWidget {
  const ComboBoxDemo({super.key});

  static const _options = [
    GLComboOption(value: 'cash', label: 'Cash on hand', subtitle: '1010 · Current assets', icon: 'book'),
    GLComboOption(value: 'sales', label: 'Sales revenue', subtitle: '4100 · Revenue', icon: 'chart'),
    GLComboOption(value: 'inventory', label: 'Inventory variance', subtitle: '5140 · Expenses', icon: 'store'),
  ];

  @override
  Widget build(BuildContext context) => GLShell(
        title: 'ComboBox',
        subtitle: 'Single · multi · async · empty and error states',
        children: [
          GLSection(title: 'Combo inputs', children: [
            const GLSpec(label: 'Single Select', child: GLComboBox<String>(label: 'Account', options: _options, icon: 'book')),
            const GLSpec(label: 'Multi Select', child: GLComboBox<String>(label: 'Filters', options: _options, multi: true, icon: 'filter')),
            GLSpec(label: 'Async', child: GLComboBox<String>(label: 'Remote Account', icon: 'search', asyncLoader: (query) async {
              await Future<void>.delayed(const Duration(milliseconds: 250));
              return _options.where((o) => o.label.toLowerCase().contains(query.toLowerCase())).toList();
            })),
            const GLSpec(label: 'Empty', child: GLComboBox<String>(label: 'Empty', options: [], icon: 'search')),
          ]),
        ],
      );
}
