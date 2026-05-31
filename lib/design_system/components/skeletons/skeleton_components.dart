// ============================================================
// GeniusLink Design System — Skeleton loaders.
// Source parity: components-skeletons.html.
// Architecture: view-only components with a single SkeletonMode model.
// ============================================================

import 'package:flutter/material.dart';
import '../../tokens.dart';
import '../core/core_components.dart';

enum GLSkeletonMode { shimmer, pulse, still }

class GLSkeletonBone extends StatefulWidget {
  final double? width;
  final double height;
  final double radius;
  final GLSkeletonMode mode;
  const GLSkeletonBone({super.key, this.width, this.height = 12, this.radius = 6, this.mode = GLSkeletonMode.shimmer});

  @override
  State<GLSkeletonBone> createState() => _GLSkeletonBoneState();
}

class _GLSkeletonBoneState extends State<GLSkeletonBone> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: GeniusThemeData.durSlower)..repeat(reverse: widget.mode == GLSkeletonMode.pulse);

  @override
  void didUpdateWidget(covariant GLSkeletonBone oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mode != widget.mode) {
      _controller.stop();
      if (widget.mode != GLSkeletonMode.still) _controller.repeat(reverse: widget.mode == GLSkeletonMode.pulse);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = GeniusThemeData.of(context);
    if (widget.mode == GLSkeletonMode.still) return _box(s.inputBg);
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        if (widget.mode == GLSkeletonMode.pulse) return Opacity(opacity: 0.55 + _controller.value * .35, child: _box(s.inputBg));
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            gradient: LinearGradient(
              begin: Alignment(-1.4 + _controller.value * 2.8, 0),
              end: Alignment(-.4 + _controller.value * 2.8, 0),
              colors: [s.inputBg, s.hover, s.inputBg],
            ),
          ),
        );
      },
    );
  }

  Widget _box(Color color) => Container(width: widget.width, height: widget.height, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(widget.radius)));
}

class GLTextSkeleton extends StatelessWidget {
  final GLSkeletonMode mode;
  final int lines;
  const GLTextSkeleton({super.key, this.mode = GLSkeletonMode.shimmer, this.lines = 3});
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        for (var i = 0; i < lines; i++) ...[
          GLSkeletonBone(width: i == lines - 1 ? 160 : null, height: 12, mode: mode),
          if (i < lines - 1) const SizedBox(height: 8),
        ]
      ]);
}

class GLAvatarSkeleton extends StatelessWidget {
  final GLSkeletonMode mode;
  final double size;
  const GLAvatarSkeleton({super.key, this.mode = GLSkeletonMode.shimmer, this.size = 36});
  @override
  Widget build(BuildContext context) => GLSkeletonBone(width: size, height: size, radius: size / 2, mode: mode);
}

class GLCardSkeleton extends StatelessWidget {
  final GLSkeletonMode mode;
  const GLCardSkeleton({super.key, this.mode = GLSkeletonMode.shimmer});
  @override
  Widget build(BuildContext context) => GLCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [GLAvatarSkeleton(mode: mode), const SizedBox(width: 12), Expanded(child: GLTextSkeleton(mode: mode, lines: 2))]),
          const SizedBox(height: 18),
          GLSkeletonBone(height: 90, radius: GeniusThemeData.radiusLg, mode: mode),
        ]),
      );
}

class GLListSkeleton extends StatelessWidget {
  final GLSkeletonMode mode;
  final int rows;
  const GLListSkeleton({super.key, this.mode = GLSkeletonMode.shimmer, this.rows = 4});
  @override
  Widget build(BuildContext context) => GLCard(
        child: Column(children: [
          for (var i = 0; i < rows; i++) ...[
            Row(children: [GLAvatarSkeleton(mode: mode), const SizedBox(width: 12), Expanded(child: GLTextSkeleton(mode: mode, lines: 2))]),
            if (i < rows - 1) const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: GLDivider()),
          ]
        ]),
      );
}

class GLTableSkeleton extends StatelessWidget {
  final GLSkeletonMode mode;
  final int rows;
  final int columns;
  const GLTableSkeleton({super.key, this.mode = GLSkeletonMode.shimmer, this.rows = 5, this.columns = 4});
  @override
  Widget build(BuildContext context) => GLCard(
        child: Column(children: [
          Row(children: [for (var c = 0; c < columns; c++) Expanded(child: Padding(padding: const EdgeInsetsDirectional.only(end: 10), child: GLSkeletonBone(height: 10, mode: mode)))]),
          const SizedBox(height: 12),
          for (var r = 0; r < rows; r++) ...[
            Row(children: [for (var c = 0; c < columns; c++) Expanded(child: Padding(padding: const EdgeInsetsDirectional.only(end: 10), child: GLSkeletonBone(height: 14, mode: mode)))]),
            if (r < rows - 1) const SizedBox(height: 12),
          ],
        ]),
      );
}

class GLChatSkeleton extends StatelessWidget {
  final GLSkeletonMode mode;
  const GLChatSkeleton({super.key, this.mode = GLSkeletonMode.shimmer});
  @override
  Widget build(BuildContext context) => GLCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [GLAvatarSkeleton(mode: mode), const SizedBox(width: 12), Expanded(child: GLTextSkeleton(mode: mode, lines: 2))]),
          const SizedBox(height: 16),
          Align(alignment: Alignment.centerLeft, child: GLSkeletonBone(width: 220, height: 42, radius: 14, mode: mode)),
          const SizedBox(height: 10),
          Align(alignment: Alignment.centerRight, child: GLSkeletonBone(width: 190, height: 42, radius: 14, mode: mode)),
          const SizedBox(height: 10),
          Align(alignment: Alignment.centerLeft, child: GLSkeletonBone(width: 260, height: 42, radius: 14, mode: mode)),
        ]),
      );
}

class GLDashboardCardSkeleton extends StatelessWidget {
  final GLSkeletonMode mode;
  const GLDashboardCardSkeleton({super.key, this.mode = GLSkeletonMode.shimmer});
  @override
  Widget build(BuildContext context) => GLCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          GLSkeletonBone(width: 90, height: 11, mode: mode),
          const SizedBox(height: 12),
          GLSkeletonBone(width: 140, height: 26, radius: 8, mode: mode),
          const SizedBox(height: 14),
          GLSkeletonBone(height: 52, radius: GeniusThemeData.radiusLg, mode: mode),
        ]),
      );
}

class GLChartSkeleton extends StatelessWidget {
  final GLSkeletonMode mode;
  const GLChartSkeleton({super.key, this.mode = GLSkeletonMode.shimmer});
  @override
  Widget build(BuildContext context) => GLCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          GLSkeletonBone(width: 130, height: 14, mode: mode),
          const SizedBox(height: 18),
          Expanded(child: GLSkeletonBone(radius: GeniusThemeData.radiusLg, mode: mode)),
        ]),
      );
}
