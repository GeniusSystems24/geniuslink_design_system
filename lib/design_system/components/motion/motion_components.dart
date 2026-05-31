// ============================================================
// GeniusLink Design System — Motion components and demos.
// Source parity: motion.html + tokens.css motion section.
// Architecture: view components driven by token durations/curves.
// ============================================================

import 'package:flutter/material.dart';
import '../../tokens.dart';
import '../core/core_components.dart';
import '../skeletons/skeleton_components.dart';

class GLPressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  const GLPressable({super.key, required this.child, this.onTap});

  @override
  State<GLPressable> createState() => _GLPressableState();
}

class _GLPressableState extends State<GLPressable> {
  bool _hover = false;
  bool _down = false;
  @override
  Widget build(BuildContext context) => MouseRegion(
        cursor: widget.onTap == null ? SystemMouseCursors.basic : SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() { _hover = false; _down = false; }),
        child: GestureDetector(
          onTapDown: (_) => setState(() => _down = true),
          onTapCancel: () => setState(() => _down = false),
          onTapUp: (_) => setState(() => _down = false),
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: GeniusThemeData.durBase,
            curve: GeniusThemeData.easeStandard,
            transform: Matrix4.identity()
              ..translate(0.0, _hover ? -2.0 : 0.0)
              ..scale(_down ? .985 : 1.0),
            child: widget.child,
          ),
        ),
      );
}

class GLMotionTokenRow extends StatelessWidget {
  final String token;
  final String value;
  final String description;
  const GLMotionTokenRow({super.key, required this.token, required this.value, required this.description});

  @override
  Widget build(BuildContext context) {
    final s = GeniusThemeData.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(width: 140, child: Text(token, style: const TextStyle(fontFamily: GeniusThemeData.monoFont, fontSize: 12, fontWeight: FontWeight.w800, color: GeniusThemeData.blue500))),
        SizedBox(width: 72, child: Text(value, style: TextStyle(fontFamily: GeniusThemeData.monoFont, fontSize: 12, color: s.fg2))),
        Expanded(child: Text(description, style: TextStyle(fontFamily: GeniusThemeData.bodyFont, fontSize: 12.5, height: 1.4, color: s.fg3))),
      ]),
    );
  }
}

class GLMotionTokensView extends StatelessWidget {
  const GLMotionTokensView({super.key});
  @override
  Widget build(BuildContext context) => const GLCard(
        child: Column(children: [
          GLMotionTokenRow(token: 'durFast', value: '100ms', description: 'Hover tint and icon swaps.'),
          GLMotionTokenRow(token: 'durBase', value: '150ms', description: 'Default color/background transitions.'),
          GLMotionTokenRow(token: 'durModerate', value: '200ms', description: 'Expand/collapse and accordions.'),
          GLMotionTokenRow(token: 'durSlow', value: '300ms', description: 'Dialog and bottom sheet entrance.'),
          GLMotionTokenRow(token: 'stagger', value: '40ms', description: 'List/message entrance offset.'),
        ]),
      );
}

class GLStaggeredList extends StatefulWidget {
  final List<String> items;
  const GLStaggeredList({super.key, this.items = const ['Create store', 'Post journal', 'Issue inventory', 'Back to list']});

  @override
  State<GLStaggeredList> createState() => _GLStaggeredListState();
}

class _GLStaggeredListState extends State<GLStaggeredList> {
  bool _show = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => setState(() => _show = true));
  }

  @override
  Widget build(BuildContext context) => Column(children: [
        for (var i = 0; i < widget.items.length; i++)
          AnimatedSlide(
            duration: GeniusThemeData.durModerate + Duration(milliseconds: GeniusThemeData.stagger.inMilliseconds * i),
            curve: GeniusThemeData.easeOut,
            offset: _show ? Offset.zero : const Offset(0, .12),
            child: AnimatedOpacity(
              duration: GeniusThemeData.durModerate + Duration(milliseconds: GeniusThemeData.stagger.inMilliseconds * i),
              opacity: _show ? 1 : 0,
              child: Padding(padding: const EdgeInsets.only(bottom: 8), child: GLListTile(icon: i == 0 ? 'store' : i == 1 ? 'book' : 'check', title: widget.items[i], subtitle: 'Token-driven entrance')),
            ),
          ),
      ]);
}

class GLShimmerDemo extends StatelessWidget {
  const GLShimmerDemo({super.key});
  @override
  Widget build(BuildContext context) => const GLCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [GLSkeletonBone(width: 180, height: 14), SizedBox(height: 12), GLTextSkeleton(lines: 3)]));
}
