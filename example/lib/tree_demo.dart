// ============================================================
// Tree — demo gallery.
// Shows the SAME widget configured two different ways (a project file
// explorer and a checkable category outline), proving it's customised purely
// through its node data + a few flags. Includes a dark/light toggle and a
// live count readout fed by the widget's callbacks.
//   File: example/lib/tree_demo.dart
// ============================================================

import 'package:flutter/material.dart';
import 'package:geniuslink_design_system/geniuslink_tree.dart';

class TreeDemo extends StatefulWidget {
  const TreeDemo({super.key});
  @override
  State<TreeDemo> createState() => _TreeDemoState();
}

class _TreeDemoState extends State<TreeDemo> {
  bool _light = true;

  // ── a project file explorer ──
  final _files = const [
    TreeNode(id: 'src', label: 'src', folder: true, children: [
      TreeNode(id: 'src/app', label: 'app', folder: true, children: [
        TreeNode(id: 'src/app/main.dart', label: 'main.dart'),
        TreeNode(id: 'src/app/router.dart', label: 'router.dart'),
      ]),
      TreeNode(id: 'src/ui', label: 'ui', folder: true, children: [
        TreeNode(id: 'src/ui/tree.dart', label: 'tree.dart', badge: 'edited'),
        TreeNode(id: 'src/ui/theme.dart', label: 'theme.dart'),
        TreeNode(id: 'src/ui/widgets', label: 'widgets', folder: true, children: [
          TreeNode(id: 'src/ui/widgets/button.dart', label: 'button.dart'),
          TreeNode(id: 'src/ui/widgets/badge.dart', label: 'badge.dart'),
        ]),
      ]),
      TreeNode(id: 'src/utils.dart', label: 'utils.dart'),
    ]),
    TreeNode(id: 'assets', label: 'assets', folder: true, children: [
      TreeNode(id: 'assets/logo.svg', label: 'logo.svg'),
      TreeNode(id: 'assets/fonts', label: 'fonts', folder: true, children: [
        TreeNode(id: 'assets/fonts/Inter.ttf', label: 'Inter.ttf'),
      ]),
    ]),
    TreeNode(id: 'pubspec.yaml', label: 'pubspec.yaml', badge: 'yaml'),
    TreeNode(id: 'README.md', label: 'README.md'),
  ];

  // ── a checkable category outline ──
  final _categories = const [
    TreeNode(id: 'fin', label: 'Finance', folder: true, children: [
      TreeNode(id: 'fin/assets', label: 'Assets', folder: true, children: [
        TreeNode(id: 'fin/assets/cash', label: 'Cash & equivalents'),
        TreeNode(id: 'fin/assets/recv', label: 'Receivables'),
      ]),
      TreeNode(id: 'fin/liab', label: 'Liabilities', folder: true, children: [
        TreeNode(id: 'fin/liab/pay', label: 'Payables'),
        TreeNode(id: 'fin/liab/loans', label: 'Loans'),
      ]),
    ]),
    TreeNode(id: 'ops', label: 'Operations', folder: true, children: [
      TreeNode(id: 'ops/people', label: 'People'),
      TreeNode(id: 'ops/supply', label: 'Supply chain'),
    ]),
  ];

  int _fileCount = 0;
  int _checked = 0;

  late final TreeController _fileCtrl =
      TreeController(roots: _files, expanded: {'src', 'src/ui', 'assets'});

  @override
  void initState() {
    super.initState();
    _fileCount = _fileCtrl.nodeCount;
  }

  @override
  void dispose() {
    _fileCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ext = _light ? TreeThemeData.light : TreeThemeData.dark;
    return Theme(
      data: ThemeData(
        brightness: _light ? Brightness.light : Brightness.dark,
        useMaterial3: true,
        fontFamily: TreeThemeData.bodyFont,
        scaffoldBackgroundColor: ext.bg,
        extensions: [ext],
      ),
      child: Builder(builder: (context) {
        final t = TreeThemeData.of(context);
        return Scaffold(
          backgroundColor: t.bg,
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 880),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(28, 40, 28, 80),
                  children: [
                    // header
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('GENIUSLINK DESIGN SYSTEM',
                                  style: TextStyle(
                                      fontFamily: TreeThemeData.bodyFont,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.6,
                                      color: TreeThemeData.accent)),
                              const SizedBox(height: 10),
                              Text('Tree',
                                  style: TextStyle(
                                      fontFamily: TreeThemeData.displayFont,
                                      fontSize: 34,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.6,
                                      color: t.fg1)),
                              const SizedBox(height: 8),
                              Text(
                                'A customisable, hierarchical tree view — built MVC. The same widget, '
                                'configured two ways purely through its node data and a few flags.',
                                style: TextStyle(fontFamily: TreeThemeData.bodyFont, fontSize: 14, height: 1.5, color: t.fg3),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        _ThemeToggle(light: _light, onChanged: (v) => setState(() => _light = v)),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // file explorer
                    _SectionTitle('Project explorer', '$_fileCount items · rename, drag-free reorder via menu, undo/redo', t),
                    const SizedBox(height: 14),
                    SizedBox(
                      height: 420,
                      child: Tree(
                        controller: _fileCtrl,
                        onSelected: (n) {},
                        onChanged: (_) => setState(() => _fileCount = _fileCtrl.nodeCount),
                      ),
                    ),

                    const SizedBox(height: 40),

                    // checkable categories
                    _SectionTitle('Category picker',
                        _checked > 0 ? '$_checked leaves selected' : 'Tri-state checkboxes, same component', t),
                    const SizedBox(height: 14),
                    SizedBox(
                      height: 340,
                      child: Tree(
                        roots: _categories,
                        initiallyExpanded: const {'fin', 'fin/assets', 'ops'},
                        showCheckboxes: true,
                        editable: false,
                        showSearch: true,
                        onCheckedChanged: (ids) => setState(() => _checked = ids.length),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title, sub;
  final TreeThemeData t;
  const _SectionTitle(this.title, this.sub, this.t);
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: TextStyle(
                fontFamily: TreeThemeData.displayFont, fontSize: 18, fontWeight: FontWeight.w700, color: t.fg1)),
        const SizedBox(height: 3),
        Text(sub, style: TextStyle(fontFamily: TreeThemeData.bodyFont, fontSize: 12.5, color: t.fg3)),
      ],
    );
  }
}

class _ThemeToggle extends StatelessWidget {
  final bool light;
  final ValueChanged<bool> onChanged;
  const _ThemeToggle({required this.light, required this.onChanged});
  @override
  Widget build(BuildContext context) {
    final t = TreeThemeData.of(context);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => onChanged(!light),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: t.surface,
            border: Border.all(color: t.border),
            borderRadius: BorderRadius.circular(TreeThemeData.radiusMd),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(light ? Icons.light_mode_outlined : Icons.dark_mode_outlined, size: 15, color: t.fg2),
            const SizedBox(width: 8),
            Text(light ? 'Light' : 'Dark',
                style: TextStyle(fontFamily: TreeThemeData.bodyFont, fontSize: 13, fontWeight: FontWeight.w600, color: t.fg1)),
          ]),
        ),
      ),
    );
  }
}
