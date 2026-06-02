// ============================================================
// Figma-style design editor shell.
// Dark editor chrome: tools rail + layers panel · the tab bar as the open
// design files · right inspector. Each tab's page is a mock CANVAS rendered
// via pageBuilder — and the canvas drives the strip through
// BrowserStyleTabBarController.of(context): "Add frame" appends a shape and
// marks the file dirty, so the hover thumbnail updates live and the unsaved
// dot appears. Close a dirty file → confirm dialog.
//   File: example/lib/figma_app.dart
// ============================================================

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:geniuslink_design_system/geniuslink_browser_tabs.dart';
import 'shell_kit.dart';

// A shape placed on a design canvas.
class _Shape {
  final Offset pos;
  final Size size;
  final Color color;
  final bool circle;
  const _Shape(this.pos, this.size, this.color, {this.circle = false});
}

class FigmaApp extends StatefulWidget {
  const FigmaApp({super.key});
  @override
  State<FigmaApp> createState() => _FigmaAppState();
}

class _FigmaAppState extends State<FigmaApp> {
  late final BrowserStyleTabBarController _ctrl;
  int _tool = 0;
  final _rng = math.Random(7);

  // Per-file canvas content (persists across tab switches).
  final Map<int, List<_Shape>> _canvas = {};

  static const _palette = [
    Color(0xFF7B61FF), Color(0xFF1ABCFE), Color(0xFF0ACF83), Color(0xFFFF7262), Color(0xFFF24E1E), Color(0xFFFFC700),
  ];
  static const _tools = [
    (Icons.near_me, 'Move'),
    (Icons.crop_square, 'Frame'),
    (Icons.category_outlined, 'Shape'),
    (Icons.edit_outlined, 'Pen'),
    (Icons.text_fields, 'Text'),
    (Icons.comment_outlined, 'Comment'),
  ];

  @override
  void initState() {
    super.initState();
    _ctrl = BrowserStyleTabBarController(
      tabs: [
        BrowserTab(id: 1, title: 'Design System', kind: GLTabKind.store, pinned: true),
        BrowserTab(id: 2, title: 'Mobile App — Onboarding', kind: GLTabKind.chart, dirty: true),
        BrowserTab(id: 3, title: 'Marketing Site', kind: GLTabKind.globe),
        BrowserTab(id: 4, title: 'Icon Set', kind: GLTabKind.user),
        BrowserTab(id: 5, title: 'Wireframes — v3', kind: GLTabKind.doc),
      ],
      activeId: 2,
    );
    // seed each file with a few shapes
    for (final t in _ctrl.tabs) {
      _canvas[t.id] = List.generate(3 + _rng.nextInt(3), (_) => _randShape());
    }
  }

  _Shape _randShape() {
    final w = 60.0 + _rng.nextInt(140);
    final h = 50.0 + _rng.nextInt(120);
    return _Shape(
      Offset(_rng.nextInt(420).toDouble(), _rng.nextInt(240).toDouble()),
      Size(w, h),
      _palette[_rng.nextInt(_palette.length)],
      circle: _rng.nextBool() && _rng.nextBool(),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _addShapeTo(int id) {
    setState(() => (_canvas[id] ??= []).add(_randShape()));
    _ctrl.setDirty(id, true); // controller used from the page
  }

  @override
  Widget build(BuildContext context) {
    return themed(
      brightness: Brightness.dark,
      ext: designStudioTheme,
      child: Builder(builder: (context) {
        final s = BrowserStyleTabBarThemeData.of(context);
        return Scaffold(
          backgroundColor: s.bg,
          body: SafeArea(
            child: Column(
              children: [
                _topBar(s),
                Expanded(
                  child: Row(
                    children: [
                      _toolsAndLayers(s),
                      // ── center: open files as tabs, canvas pages via pageBuilder ──
                      Expanded(
                        child: Container(
                          color: const Color(0xFF1A1A1A),
                          padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                          child: BrowserStyleTabBar(
                            controller: _ctrl,
                            pageBuilder: (ctx, tab) => _CanvasPage(
                              tab: tab,
                              shapes: _canvas[tab.id] ?? const [],
                            ),
                          ),
                        ),
                      ),
                      _inspector(s),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _topBar(BrowserStyleTabBarThemeData s) {
    final active = _ctrl.activeTab;
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(color: const Color(0xFF2C2C2C), border: Border(bottom: BorderSide(color: s.border))),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: const Color(0xFF7B61FF), borderRadius: BorderRadius.circular(BrowserStyleTabBarThemeData.radiusMd)),
            child: const Icon(Icons.bubble_chart, size: 17, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Icon(Icons.cloud_done_outlined, size: 16, color: s.fg3),
          const SizedBox(width: 8),
          Text(active?.title ?? 'Untitled',
              style: TextStyle(fontFamily: BrowserStyleTabBarThemeData.bodyFont, fontSize: 13, fontWeight: FontWeight.w600, color: s.fg1)),
          if (active?.dirty ?? false)
            const Padding(
              padding: EdgeInsets.only(left: 8),
              child: Text('• Unsaved', style: TextStyle(fontFamily: BrowserStyleTabBarThemeData.bodyFont, fontSize: 12, color: BrowserStyleTabBarThemeData.warning)),
            ),
          const Spacer(),
          // zoom + present + share
          _segment(s, '100%'),
          const SizedBox(width: 10),
          const GhostIconButton(Icons.play_arrow_rounded, tooltip: 'Present', iconSize: 20),
          const SizedBox(width: 4),
          Container(
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            alignment: Alignment.center,
            decoration: BoxDecoration(color: const Color(0xFF7B61FF), borderRadius: BorderRadius.circular(BrowserStyleTabBarThemeData.radiusMd)),
            child: const Text('Share', style: TextStyle(fontFamily: BrowserStyleTabBarThemeData.bodyFont, fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
          ),
          const SizedBox(width: 10),
          _avatar('AK', const Color(0xFF0ACF83)),
        ],
      ),
    );
  }

  Widget _segment(BrowserStyleTabBarThemeData s, String label) => Container(
        height: 30,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(color: s.inputBg, borderRadius: BorderRadius.circular(BrowserStyleTabBarThemeData.radiusMd)),
        child: Row(children: [
          Text(label, style: TextStyle(fontFamily: BrowserStyleTabBarThemeData.bodyFont, fontSize: 12.5, color: s.fg1)),
          const SizedBox(width: 4),
          Icon(Icons.expand_more, size: 15, color: s.fg3),
        ]),
      );

  Widget _toolsAndLayers(BrowserStyleTabBarThemeData s) {
    return Row(
      children: [
        // tools rail
        Container(
          width: 48,
          color: s.surface,
          child: Column(
            children: [
              const SizedBox(height: 10),
              for (int i = 0; i < _tools.length; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: GhostIconButton(
                    _tools[i].$1,
                    tooltip: _tools[i].$2,
                    size: 36,
                    iconSize: 19,
                    active: i == _tool,
                    onTap: () => setState(() => _tool = i),
                  ),
                ),
            ],
          ),
        ),
        // layers panel
        SidePanel(
          width: 232,
          rightBorder: BorderSide(color: s.border),
          children: [
            const PanelHeader('Layers'),
            ..._ctrl.tabs.map((t) => _layerFileGroup(s, t)),
          ],
        ),
      ],
    );
  }

  Widget _layerFileGroup(BrowserStyleTabBarThemeData s, BrowserTab t) {
    final active = _ctrl.isActive(t.id);
    final shapes = _canvas[t.id] ?? const [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => _ctrl.select(t.id),
          child: Container(
            color: active ? BrowserStyleTabBarThemeData.accent.withOpacity(0.14) : Colors.transparent,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            child: Row(children: [
              Icon(Icons.folder_outlined, size: 15, color: active ? BrowserStyleTabBarThemeData.accent : s.fg3),
              const SizedBox(width: 8),
              Expanded(
                child: Text(t.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontFamily: BrowserStyleTabBarThemeData.bodyFont,
                        fontSize: 12.5,
                        fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                        color: active ? s.fg1 : s.fg2)),
              ),
              Text('${shapes.length}', style: TextStyle(fontFamily: BrowserStyleTabBarThemeData.monoFont, fontSize: 11, color: s.fg3)),
            ]),
          ),
        ),
        if (active)
          for (int i = 0; i < shapes.length; i++)
            Padding(
              padding: const EdgeInsets.only(left: 30, top: 2, bottom: 2, right: 12),
              child: Row(children: [
                Container(width: 10, height: 10, decoration: BoxDecoration(color: shapes[i].color, borderRadius: BorderRadius.circular(shapes[i].circle ? 6 : 2))),
                const SizedBox(width: 8),
                Text('${shapes[i].circle ? "Ellipse" : "Rectangle"} ${i + 1}',
                    style: TextStyle(fontFamily: BrowserStyleTabBarThemeData.bodyFont, fontSize: 12, color: s.fg2)),
              ]),
            ),
      ],
    );
  }

  Widget _inspector(BrowserStyleTabBarThemeData s) {
    return SidePanel(
      width: 240,
      leftBorder: BorderSide(color: s.border),
      children: [
        const PanelHeader('Design'),
        _inspectRow(s, 'Align', child: Row(children: [
          for (final ic in [Icons.align_horizontal_left, Icons.align_horizontal_center, Icons.align_horizontal_right, Icons.align_vertical_top, Icons.align_vertical_center, Icons.align_vertical_bottom])
            Padding(padding: const EdgeInsets.only(right: 2), child: GhostIconButton(ic, size: 28, iconSize: 15)),
        ])),
        Divider(color: s.border, height: 18),
        _inspectRow(s, 'Frame', child: Wrap(spacing: 8, runSpacing: 8, children: [
          _field(s, 'X', '24'), _field(s, 'Y', '40'), _field(s, 'W', '375'), _field(s, 'H', '812'),
        ])),
        Divider(color: s.border, height: 18),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(children: [
            Text('Fill', style: TextStyle(fontFamily: BrowserStyleTabBarThemeData.monoFont, fontSize: 10.5, fontWeight: FontWeight.w700, letterSpacing: 0.8, color: s.fg3)),
            const Spacer(),
          ]),
        ),
        const SizedBox(height: 8),
        for (final c in _palette.take(3))
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(children: [
              Container(width: 18, height: 18, decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(4), border: Border.all(color: s.border))),
              const SizedBox(width: 8),
              Text('#${c.value.toRadixString(16).substring(2).toUpperCase()}',
                  style: TextStyle(fontFamily: BrowserStyleTabBarThemeData.monoFont, fontSize: 12, color: s.fg1)),
            ]),
          ),
      ],
    );
  }

  Widget _inspectRow(BrowserStyleTabBarThemeData s, String label, {required Widget child}) => Padding(
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label.toUpperCase(), style: TextStyle(fontFamily: BrowserStyleTabBarThemeData.monoFont, fontSize: 10.5, fontWeight: FontWeight.w700, letterSpacing: 0.8, color: s.fg3)),
          const SizedBox(height: 8),
          child,
        ]),
      );

  Widget _field(BrowserStyleTabBarThemeData s, String label, String value) => Container(
        width: 96,
        height: 30,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(color: s.inputBg, borderRadius: BorderRadius.circular(BrowserStyleTabBarThemeData.radiusSm)),
        child: Row(children: [
          Text(label, style: TextStyle(fontFamily: BrowserStyleTabBarThemeData.monoFont, fontSize: 11, color: s.fg3)),
          const SizedBox(width: 6),
          Text(value, style: TextStyle(fontFamily: BrowserStyleTabBarThemeData.bodyFont, fontSize: 12.5, color: s.fg1)),
        ]),
      );

  Widget _avatar(String initials, Color color) => Container(
        width: 30,
        height: 30,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: Text(initials, style: const TextStyle(fontFamily: BrowserStyleTabBarThemeData.displayFont, fontSize: 11.5, fontWeight: FontWeight.w700, color: Colors.white)),
      );
}

// ── the canvas page (rendered per tab) ──────────────────────
class _CanvasPage extends StatelessWidget {
  final BrowserTab tab;
  final List<_Shape> shapes;
  const _CanvasPage({required this.tab, required this.shapes});

  @override
  Widget build(BuildContext context) {
    final s = BrowserStyleTabBarThemeData.of(context);
    // pages reach the strip through the controller
    final ctrl = BrowserStyleTabBarController.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Text(tab.title, style: TextStyle(fontFamily: BrowserStyleTabBarThemeData.displayFont, fontSize: 18, fontWeight: FontWeight.w700, color: s.fg1)),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: s.inputBg, borderRadius: BorderRadius.circular(999)),
            child: Text('${shapes.length} layers', style: TextStyle(fontFamily: BrowserStyleTabBarThemeData.monoFont, fontSize: 11, color: s.fg2)),
          ),
          const Spacer(),
          // ↓ drives the strip from the page: mark dirty + live thumbnail
          _GhostButton(
            icon: Icons.add,
            label: 'Add frame',
            onTap: () {
              final st = context.findAncestorStateOfType<_FigmaAppState>();
              st?._addShapeTo(tab.id);
            },
          ),
          if (ctrl != null && (ctrl.tabById(tab.id)?.dirty ?? false)) ...[
            const SizedBox(width: 8),
            _GhostButton(icon: Icons.check, label: 'Mark saved', onTap: () => ctrl.setDirty(tab.id, false)),
          ],
        ]),
        const SizedBox(height: 14),
        // the artboard
        Container(
          height: 320,
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            border: Border.all(color: s.border),
            borderRadius: BorderRadius.circular(BrowserStyleTabBarThemeData.radiusLg),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              // dotted-ish grid backdrop
              Positioned.fill(child: CustomPaint(painter: _GridPainter(s.border))),
              // a framed artboard
              Positioned(
                left: 28,
                top: 24,
                child: Container(
                  width: 560,
                  height: 272,
                  decoration: BoxDecoration(color: const Color(0xFF222226), borderRadius: BorderRadius.circular(6), boxShadow: BrowserStyleTabBarThemeData.cardShadow),
                  child: Stack(
                    children: [
                      for (final sh in shapes)
                        Positioned(
                          left: sh.pos.dx.clamp(0, 540 - sh.size.width).toDouble(),
                          top: sh.pos.dy.clamp(0, 252 - sh.size.height).toDouble(),
                          child: Container(
                            width: sh.size.width,
                            height: sh.size.height,
                            decoration: BoxDecoration(
                              color: sh.color.withOpacity(0.92),
                              borderRadius: BorderRadius.circular(sh.circle ? 999 : 8),
                            ),
                          ),
                        ),
                      Positioned(
                        left: 6,
                        top: -18,
                        child: Text('Frame · ${tab.title}',
                            style: const TextStyle(fontFamily: BrowserStyleTabBarThemeData.bodyFont, fontSize: 10.5, color: Color(0xFF7B61FF))),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text('Tip: “Add frame” mutates this page — hover the tab to see its live thumbnail update.',
            style: TextStyle(fontFamily: BrowserStyleTabBarThemeData.bodyFont, fontSize: 12, color: s.fg3)),
      ],
    );
  }
}

class _GhostButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _GhostButton({required this.icon, required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final s = BrowserStyleTabBarThemeData.of(context);
    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          height: 30,
          padding: const EdgeInsets.symmetric(horizontal: 11),
          decoration: BoxDecoration(border: Border.all(color: s.borderStrong), borderRadius: BorderRadius.circular(BrowserStyleTabBarThemeData.radiusMd)),
          child: Row(children: [
            Icon(icon, size: 14, color: s.fg1),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontFamily: BrowserStyleTabBarThemeData.bodyFont, fontSize: 12.5, fontWeight: FontWeight.w600, color: s.fg1)),
          ]),
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  final Color color;
  _GridPainter(this.color);
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color.withOpacity(0.5)
      ..strokeWidth = 1;
    const gap = 24.0;
    for (double x = 0; x < size.width; x += gap) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), p);
    }
    for (double y = 0; y < size.height; y += gap) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter old) => old.color != color;
}
