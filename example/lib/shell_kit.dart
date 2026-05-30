// ============================================================
// shell_kit — shared theming for the style demos.
// ------------------------------------------------------------
// The whole point: ONE component (BrowserStyleTabBar) hosted inside three
// very different product shells, each just registering its own
// BrowserStyleTabBarThemeData. Nothing about the component changes — only
// the surfaces it reads do.
//   File: example/lib/shell_kit.dart
// ============================================================

import 'package:flutter/material.dart';
import 'package:geniuslink_design_system/geniuslink_design_system.dart';

/// Wraps [child] in a ThemeData carrying [ext] so every
/// `BrowserStyleTabBarThemeData.of(context)` below resolves to this shell.
Widget themed({required Brightness brightness, required BrowserStyleTabBarThemeData ext, required Widget child}) {
  return Theme(
    data: ThemeData(
      brightness: brightness,
      useMaterial3: true,
      fontFamily: BrowserStyleTabBarThemeData.bodyFont,
      scaffoldBackgroundColor: ext.bg,
      extensions: [ext],
    ),
    child: child,
  );
}

// ── ERP — clean light SaaS (the component's own .light) ──
const erpLight = BrowserStyleTabBarThemeData.light;
const erpDark = BrowserStyleTabBarThemeData.dark;

// ── Design-tool — dark editor (Figma genre) ──
// Strip darker than the active tab so the open file reads as "raised",
// then the canvas paints its own dark surface via pageBuilder.
const designStudioTheme = BrowserStyleTabBarThemeData(
  bg: Color(0xFF1E1E1E),
  surface: Color(0xFF2C2C2C),
  surface2: Color(0xFF383838),
  inputBg: Color(0xFF3A3A3A),
  hover: Color(0xFF333333),
  border: Color(0xFF383838),
  borderStrong: Color(0xFF4D4D4D),
  fg1: Color(0xFFE6E6E6),
  fg2: Color(0xFFB3B3B3),
  fg3: Color(0xFF8C8C8C),
  fg4: Color(0xFF5C5C5C),
);

// ── Web browser — gray strip, white active tab + content (Chrome genre) ──
const webBrowserTheme = BrowserStyleTabBarThemeData(
  bg: Color(0xFFDEE1E6),
  surface: Color(0xFFFFFFFF),
  surface2: Color(0xFFF1F3F4),
  inputBg: Color(0xFFF1F3F4),
  hover: Color(0xFFE8EAED),
  border: Color(0xFFC4C7CC),
  borderStrong: Color(0xFFBDC1C6),
  fg1: Color(0xFF202124),
  fg2: Color(0xFF3C4043),
  fg3: Color(0xFF5F6368),
  fg4: Color(0xFFBDC1C6),
);

// ── tiny shared atoms ───────────────────────────────────────
/// Flat icon button used across the demo chromes.
class GhostIconButton extends StatefulWidget {
  final IconData icon;
  final String? tooltip;
  final double size;
  final double iconSize;
  final bool active;
  final Color? color;
  final VoidCallback? onTap;
  const GhostIconButton(this.icon, {super.key, this.tooltip, this.size = 32, this.iconSize = 18, this.active = false, this.color, this.onTap});
  @override
  State<GhostIconButton> createState() => _GhostIconButtonState();
}

class _GhostIconButtonState extends State<GhostIconButton> {
  bool _hover = false;
  @override
  Widget build(BuildContext context) {
    final s = BrowserStyleTabBarThemeData.of(context);
    final on = widget.active || _hover;
    final btn = MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          width: widget.size,
          height: widget.size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: on ? s.hover : Colors.transparent,
            borderRadius: BorderRadius.circular(BrowserStyleTabBarThemeData.radiusMd),
          ),
          child: Icon(widget.icon,
              size: widget.iconSize,
              color: widget.color ?? (widget.active ? BrowserStyleTabBarThemeData.accent : (on ? s.fg1 : s.fg3))),
        ),
      ),
    );
    return widget.tooltip == null
        ? btn
        : Tooltip(message: widget.tooltip!, waitDuration: const Duration(milliseconds: 450), child: btn);
  }
}

/// A labelled side-panel column used by the editor shell.
class SidePanel extends StatelessWidget {
  final double width;
  final List<Widget> children;
  final BorderSide? leftBorder;
  final BorderSide? rightBorder;
  const SidePanel({super.key, this.width = 240, required this.children, this.leftBorder, this.rightBorder});
  @override
  Widget build(BuildContext context) {
    final s = BrowserStyleTabBarThemeData.of(context);
    return Container(
      width: width,
      decoration: BoxDecoration(
        color: s.surface,
        border: Border(
          left: leftBorder ?? BorderSide.none,
          right: rightBorder ?? BorderSide.none,
        ),
      ),
      child: ListView(padding: const EdgeInsets.symmetric(vertical: 10), children: children),
    );
  }
}

class PanelHeader extends StatelessWidget {
  final String text;
  final List<Widget> trailing;
  const PanelHeader(this.text, {super.key, this.trailing = const []});
  @override
  Widget build(BuildContext context) {
    final s = BrowserStyleTabBarThemeData.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
      child: Row(
        children: [
          Text(text.toUpperCase(),
              style: TextStyle(
                  fontFamily: BrowserStyleTabBarThemeData.monoFont, fontSize: 10.5, fontWeight: FontWeight.w700, letterSpacing: 0.8, color: s.fg3)),
          const Spacer(),
          ...trailing,
        ],
      ),
    );
  }
}
