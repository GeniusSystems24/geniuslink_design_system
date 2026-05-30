// ============================================================
// GeniusLink — BrowserStyleTabBar example app.
// A realistic embed: a workspace shell (nav rail + window chrome) hosting
// the tab strip, plus the full component gallery. Toggle dark/light.
//   Run:  cd flutter/example && flutter pub get && flutter run -d chrome
// ============================================================

import 'package:flutter/material.dart';
import 'package:browser_style_tabs/browser_style_tabs.dart';

void main() => runApp(const ExampleApp());

class ExampleApp extends StatefulWidget {
  const ExampleApp({super.key});
  @override
  State<ExampleApp> createState() => _ExampleAppState();
}

class _ExampleAppState extends State<ExampleApp> {
  bool _light = false;
  int _screen = 0; // 0 = workspace, 1 = gallery

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GeniusLink · Example',
      debugShowCheckedModeBanner: false,
      theme: GLTheme.light,
      darkTheme: GLTheme.dark,
      themeMode: _light ? ThemeMode.light : ThemeMode.dark,
      supportedLocales: const [Locale('en'), Locale('ar')],
      home: _screen == 1
          // The documentation gallery shipped with the package.
          ? BrowserTabsDemo(light: _light, onToggleTheme: (v) => setState(() => _light = v))
          // A realistic product shell embedding the component.
          : WorkspaceScreen(
              light: _light,
              onToggleTheme: (v) => setState(() => _light = v),
              onOpenGallery: () => setState(() => _screen = 1),
            ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// WORKSPACE SHELL — nav rail + window chrome + BrowserStyleTabBar
// ════════════════════════════════════════════════════════════
class WorkspaceScreen extends StatefulWidget {
  final bool light;
  final ValueChanged<bool> onToggleTheme;
  final VoidCallback onOpenGallery;
  const WorkspaceScreen({super.key, required this.light, required this.onToggleTheme, required this.onOpenGallery});
  @override
  State<WorkspaceScreen> createState() => _WorkspaceScreenState();
}

class _WorkspaceScreenState extends State<WorkspaceScreen> {
  int _nav = 0;

  @override
  Widget build(BuildContext context) {
    final s = GLSurfaces.of(context);
    return Scaffold(
      backgroundColor: s.bg,
      body: SafeArea(
        child: Row(
          children: [
            _NavRail(
              selected: _nav,
              onSelect: (i) => setState(() => _nav = i),
              light: widget.light,
              onToggleTheme: widget.onToggleTheme,
              onOpenGallery: widget.onOpenGallery,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(28, 24, 28, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // top bar
                    Row(
                      children: [
                        Text('Workspace',
                            style: TextStyle(
                                fontFamily: GLFonts.display, fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.6, color: s.fg1)),
                        const SizedBox(width: 12),
                        const _Pill('GeniusLink Co.'),
                        const Spacer(),
                        _AvatarChip(name: 'Mohammed Nasser', role: 'Accountant'),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // window chrome hosting the component
                    Expanded(
                      child: _Window(
                        child: const BrowserStyleTabBar(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── left navigation rail ──
class _NavRail extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onSelect;
  final bool light;
  final ValueChanged<bool> onToggleTheme;
  final VoidCallback onOpenGallery;
  const _NavRail({
    required this.selected,
    required this.onSelect,
    required this.light,
    required this.onToggleTheme,
    required this.onOpenGallery,
  });

  static const _items = [
    (Icons.dashboard_outlined, 'Overview'),
    (Icons.menu_book_outlined, 'Ledger'),
    (Icons.storefront_outlined, 'Branches'),
    (Icons.bar_chart_rounded, 'Reports'),
    (Icons.people_alt_outlined, 'People'),
  ];

  @override
  Widget build(BuildContext context) {
    final s = GLSurfaces.of(context);
    return Container(
      width: 76,
      decoration: BoxDecoration(
        color: s.surface,
        border: Border(right: BorderSide(color: s.border)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 18),
          // brand mark
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: GLColors.blue500, borderRadius: BorderRadius.circular(GLRadius.md)),
            child: const Text('G', style: TextStyle(fontFamily: GLFonts.display, fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
          ),
          const SizedBox(height: 22),
          for (int i = 0; i < _items.length; i++)
            _RailItem(icon: _items[i].$1, label: _items[i].$2, selected: i == selected, onTap: () => onSelect(i)),
          const Spacer(),
          _RailItem(icon: Icons.widgets_outlined, label: 'Gallery', selected: false, onTap: onOpenGallery),
          _RailItem(
            icon: light ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
            label: light ? 'Dark' : 'Light',
            selected: false,
            onTap: () => onToggleTheme(!light),
          ),
          const SizedBox(height: 14),
        ],
      ),
    );
  }
}

class _RailItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _RailItem({required this.icon, required this.label, required this.selected, required this.onTap});
  @override
  State<_RailItem> createState() => _RailItemState();
}

class _RailItemState extends State<_RailItem> {
  bool _hover = false;
  @override
  Widget build(BuildContext context) {
    final s = GLSurfaces.of(context);
    final on = widget.selected;
    final color = on ? GLColors.blue500 : (_hover ? s.fg1 : s.fg3);
    return Tooltip(
      message: widget.label,
      waitDuration: const Duration(milliseconds: 400),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: Container(
            width: 48,
            height: 44,
            margin: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: on ? GLColors.blue500.withOpacity(0.12) : (_hover ? s.hover : Colors.transparent),
              borderRadius: BorderRadius.circular(GLRadius.md),
            ),
            child: Icon(widget.icon, size: 21, color: color),
          ),
        ),
      ),
    );
  }
}

// ── faux app-window chrome around the component ──
class _Window extends StatelessWidget {
  final Widget child;
  const _Window({required this.child});
  @override
  Widget build(BuildContext context) {
    final s = GLSurfaces.of(context);
    return Container(
      decoration: BoxDecoration(
        color: s.bg,
        border: Border.all(color: s.border),
        borderRadius: BorderRadius.circular(GLRadius.xl),
        boxShadow: GLShadows.card,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // title bar (traffic lights + address)
          Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: s.border))),
            child: Row(
              children: [
                _dot(const Color(0xFFEF4444)),
                const SizedBox(width: 7),
                _dot(const Color(0xFFF59E0B)),
                const SizedBox(width: 7),
                _dot(const Color(0xFF22C55E)),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    height: 24,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: s.surface, borderRadius: BorderRadius.circular(GLRadius.sm)),
                    child: Text('app.geniuslink.co / workspace',
                        style: TextStyle(fontFamily: GLFonts.mono, fontSize: 11.5, color: s.fg3)),
                  ),
                ),
                const SizedBox(width: 60),
              ],
            ),
          ),
          // the component embeds directly under the chrome
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: child,
            ),
          ),
        ],
      ),
    );
  }

  Widget _dot(Color c) => Container(width: 11, height: 11, decoration: BoxDecoration(color: c, shape: BoxShape.circle));
}

// ── small shared bits ──
class _Pill extends StatelessWidget {
  final String text;
  const _Pill(this.text);
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: GLColors.blue500.withOpacity(0.14), borderRadius: BorderRadius.circular(999)),
      child: Text(text,
          style: const TextStyle(fontFamily: GLFonts.body, fontSize: 11.5, fontWeight: FontWeight.w700, color: GLColors.blue500)),
    );
  }
}

class _AvatarChip extends StatelessWidget {
  final String name, role;
  const _AvatarChip({required this.name, required this.role});
  @override
  Widget build(BuildContext context) {
    final s = GLSurfaces.of(context);
    final initials = name.split(' ').where((w) => w.isNotEmpty).take(2).map((w) => w[0]).join();
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(name, style: TextStyle(fontFamily: GLFonts.body, fontSize: 13, fontWeight: FontWeight.w600, color: s.fg1)),
            Text(role, style: TextStyle(fontFamily: GLFonts.body, fontSize: 11.5, color: s.fg3)),
          ],
        ),
        const SizedBox(width: 10),
        Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: HSLColor.fromAHSL(1, 250, 0.42, 0.40).toColor(), shape: BoxShape.circle),
          child: Text(initials, style: const TextStyle(fontFamily: GLFonts.display, fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
        ),
      ],
    );
  }
}
