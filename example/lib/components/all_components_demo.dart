import 'package:flutter/material.dart';
import 'package:geniuslink_design_system/geniuslink_design_system.dart';
import 'foundations_demo.dart';
import 'core_components_demo.dart';
import 'domain_components_demo.dart';
import 'charts_demo.dart';
import 'skeletons_demo.dart';
import 'combo_box_demo.dart';
import 'table_demo.dart';
import 'patterns_demo.dart';
import 'motion_demo.dart';

class AllComponentsDemo extends StatelessWidget {
  const AllComponentsDemo({super.key});

  @override
  Widget build(BuildContext context) => GLShell(
        title: 'All Components',
        subtitle: 'Flutter parity gallery for genius_design_system_web/design_system',
        children: [
          GLSection(title: 'Component groups', children: [
            _DemoLink(title: 'Foundations', icon: 'settings', screen: const FoundationsDemo()),
            _DemoLink(title: 'Core', icon: 'plus', screen: const CoreComponentsDemo()),
            _DemoLink(title: 'Domain', icon: 'users', screen: const DomainComponentsDemo()),
            _DemoLink(title: 'Charts', icon: 'chart', screen: const ChartsDemo()),
            _DemoLink(title: 'Skeletons', icon: 'refresh', screen: const SkeletonsDemo()),
            _DemoLink(title: 'ComboBox', icon: 'search', screen: const ComboBoxDemo()),
            _DemoLink(title: 'Editable Table', icon: 'table', screen: const TableDemo()),
            _DemoLink(title: 'Patterns', icon: 'filter', screen: const PatternsDemo()),
            _DemoLink(title: 'Motion', icon: 'refresh', screen: const MotionDemo()),
            _DemoLink(title: 'Browser Tabs', icon: 'globe', screen: const BrowserStyleTabBar()),
          ]),
        ],
      );
}

class _DemoLink extends StatelessWidget {
  final String title;
  final String icon;
  final Widget screen;
  const _DemoLink({required this.title, required this.icon, required this.screen});

  @override
  Widget build(BuildContext context) => GLSpec(
        label: title,
        child: InkWell(
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => Theme(data: Theme.of(context), child: Scaffold(body: SafeArea(child: screen))))),
          child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [GLIcon(icon, size: 30, color: GeniusThemeData.blue500), const SizedBox(height: 10), Text(title, style: TextStyle(color: GeniusThemeData.of(context).fg1, fontWeight: FontWeight.w800))])),
        ),
      );
}
