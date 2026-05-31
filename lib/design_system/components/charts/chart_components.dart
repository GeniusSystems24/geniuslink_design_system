// ============================================================
// GeniusLink Design System — Chart components.
// Source parity: components-charts.html.
// Architecture: MVC drawing widgets. Data is model input, CustomPainter is view.
// ============================================================

import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../tokens.dart';
import '../core/core_components.dart';

class GLChartFrame extends StatelessWidget {
  final String title;
  final Widget child;
  final List<Widget> legend;
  final double height;
  const GLChartFrame({super.key, required this.title, required this.child, this.legend = const [], this.height = 220});

  @override
  Widget build(BuildContext context) {
    final s = GeniusThemeData.of(context);
    return GLCard(
      padding: 16,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(title, style: TextStyle(fontFamily: GeniusThemeData.displayFont, fontSize: 14.5, fontWeight: FontWeight.w800, color: s.fg1))),
          ...legend,
        ]),
        const SizedBox(height: 14),
        SizedBox(height: height, child: child),
      ]),
    );
  }
}

class GLChartLegendItem extends StatelessWidget {
  final String label;
  final Color color;
  const GLChartLegendItem({super.key, required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsetsDirectional.only(start: 10),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontFamily: GeniusThemeData.bodyFont, fontSize: 11.5, color: GeniusThemeData.of(context).fg3)),
        ]),
      );
}

class GLLineAreaChart extends StatelessWidget {
  final List<double> values;
  final bool area;
  final Color color;
  const GLLineAreaChart({super.key, this.values = const [24, 29, 31, 28, 36, 42, 39, 45, 52, 49, 58, 64], this.area = true, this.color = GeniusThemeData.blue500});

  @override
  Widget build(BuildContext context) => CustomPaint(painter: _LineAreaPainter(values: values, area: area, color: color, theme: GeniusThemeData.of(context)), child: const SizedBox.expand());
}

class _LineAreaPainter extends CustomPainter {
  final List<double> values;
  final bool area;
  final Color color;
  final GeniusThemeData theme;
  const _LineAreaPainter({required this.values, required this.area, required this.color, required this.theme});

  @override
  void paint(Canvas canvas, Size size) {
    _grid(canvas, size, theme);
    if (values.isEmpty) return;
    final minV = values.reduce(math.min);
    final maxV = values.reduce(math.max);
    final span = (maxV - minV).abs() < .001 ? 1 : maxV - minV;
    Offset point(int i) {
      final x = values.length == 1 ? size.width / 2 : (i / (values.length - 1)) * size.width;
      final y = size.height - ((values[i] - minV) / span) * (size.height * .78) - size.height * .1;
      return Offset(x, y);
    }
    final path = Path()..moveTo(point(0).dx, point(0).dy);
    for (var i = 1; i < values.length; i++) {
      final p = point(i);
      path.lineTo(p.dx, p.dy);
    }
    if (area) {
      final areaPath = Path.from(path)
        ..lineTo(size.width, size.height)
        ..lineTo(0, size.height)
        ..close();
      canvas.drawPath(areaPath, Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [color.withOpacity(.26), color.withOpacity(0)]).createShader(Offset.zero & size));
    }
    canvas.drawPath(path, Paint()..color = color..strokeWidth = 2.6..style = PaintingStyle.stroke..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round);
    for (var i = 0; i < values.length; i++) {
      final p = point(i);
      canvas.drawCircle(p, 3.2, Paint()..color = theme.surface);
      canvas.drawCircle(p, 3.2, Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 2);
    }
  }

  @override
  bool shouldRepaint(covariant _LineAreaPainter oldDelegate) => oldDelegate.values != values || oldDelegate.area != area || oldDelegate.color != color || oldDelegate.theme != theme;
}

class GLBarChart extends StatelessWidget {
  final List<double> values;
  final Color color;
  const GLBarChart({super.key, this.values = const [42, 66, 52, 78, 64, 92, 72, 88], this.color = GeniusThemeData.blue500});

  @override
  Widget build(BuildContext context) => CustomPaint(painter: _BarPainter(values: values, color: color, theme: GeniusThemeData.of(context)), child: const SizedBox.expand());
}

class _BarPainter extends CustomPainter {
  final List<double> values;
  final Color color;
  final GeniusThemeData theme;
  const _BarPainter({required this.values, required this.color, required this.theme});

  @override
  void paint(Canvas canvas, Size size) {
    _grid(canvas, size, theme);
    if (values.isEmpty) return;
    final maxV = values.reduce(math.max);
    final gap = 8.0;
    final w = (size.width - gap * (values.length - 1)) / values.length;
    for (var i = 0; i < values.length; i++) {
      final h = (values[i] / (maxV == 0 ? 1 : maxV)) * (size.height * .82);
      final rect = RRect.fromRectAndRadius(Rect.fromLTWH(i * (w + gap), size.height - h, w, h), const Radius.circular(6));
      canvas.drawRRect(rect, Paint()..color = color.withOpacity(.86));
    }
  }

  @override
  bool shouldRepaint(covariant _BarPainter oldDelegate) => oldDelegate.values != values || oldDelegate.color != color || oldDelegate.theme != theme;
}

class GLDonutChart extends StatelessWidget {
  final Map<String, double> slices;
  final List<Color> colors;
  final String centerLabel;
  const GLDonutChart({super.key, this.slices = const {'Sales': 46, 'Services': 32, 'Other': 22}, this.colors = const [GeniusThemeData.blue500, GeniusThemeData.success500, GeniusThemeData.warning500], this.centerLabel = '100%'});

  @override
  Widget build(BuildContext context) {
    final s = GeniusThemeData.of(context);
    return Column(children: [
      Expanded(child: CustomPaint(painter: _DonutPainter(values: slices.values.toList(), colors: colors, theme: s), child: Center(child: Text(centerLabel, style: TextStyle(fontFamily: GeniusThemeData.displayFont, fontSize: 22, fontWeight: FontWeight.w800, color: s.fg1))))),
      const SizedBox(height: 12),
      Wrap(spacing: 12, runSpacing: 8, alignment: WrapAlignment.center, children: [
        for (var i = 0; i < slices.length; i++) GLChartLegendItem(label: slices.keys.elementAt(i), color: colors[i % colors.length]),
      ]),
    ]);
  }
}

class _DonutPainter extends CustomPainter {
  final List<double> values;
  final List<Color> colors;
  final GeniusThemeData theme;
  const _DonutPainter({required this.values, required this.colors, required this.theme});

  @override
  void paint(Canvas canvas, Size size) {
    final total = values.fold<double>(0, (a, b) => a + b);
    final center = size.center(Offset.zero);
    final radius = math.min(size.width, size.height) * .38;
    final paint = Paint()..style = PaintingStyle.stroke..strokeWidth = radius * .28..strokeCap = StrokeCap.round;
    var start = -math.pi / 2;
    if (total <= 0) {
      paint.color = theme.border;
      canvas.drawCircle(center, radius, paint);
      return;
    }
    for (var i = 0; i < values.length; i++) {
      final sweep = (values[i] / total) * math.pi * 2;
      paint.color = colors[i % colors.length];
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), start, sweep - .035, false, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) => oldDelegate.values != values || oldDelegate.colors != colors || oldDelegate.theme != theme;
}

class GLProgressRing extends StatelessWidget {
  final double value;
  final String label;
  final Color color;
  const GLProgressRing({super.key, this.value = .72, this.label = '72%', this.color = GeniusThemeData.success500});

  @override
  Widget build(BuildContext context) {
    final s = GeniusThemeData.of(context);
    return SizedBox(
      width: 128,
      height: 128,
      child: CustomPaint(
        painter: _RingPainter(value: value, color: color, theme: s),
        child: Center(child: Text(label, style: TextStyle(fontFamily: GeniusThemeData.displayFont, fontSize: 24, fontWeight: FontWeight.w800, color: s.fg1))),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double value;
  final Color color;
  final GeniusThemeData theme;
  const _RingPainter({required this.value, required this.color, required this.theme});
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paint = Paint()..style = PaintingStyle.stroke..strokeWidth = 10..strokeCap = StrokeCap.round;
    paint.color = theme.inputBg;
    canvas.drawArc(rect.deflate(8), 0, math.pi * 2, false, paint);
    paint.color = color;
    canvas.drawArc(rect.deflate(8), -math.pi / 2, value.clamp(0, 1).toDouble() * math.pi * 2, false, paint);
  }
  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) => oldDelegate.value != value || oldDelegate.color != color || oldDelegate.theme != theme;
}

class GLKpiSparkline extends StatelessWidget {
  final String label;
  final String value;
  final String delta;
  final bool up;
  final List<double> data;
  const GLKpiSparkline({super.key, required this.label, required this.value, this.delta = '+8.2%', this.up = true, this.data = const [4, 5, 4, 7, 6, 8, 9]});

  @override
  Widget build(BuildContext context) {
    final s = GeniusThemeData.of(context);
    final c = up ? GeniusThemeData.success500 : GeniusThemeData.danger500;
    return GLCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(fontFamily: GeniusThemeData.bodyFont, fontSize: 11.5, fontWeight: FontWeight.w700, color: s.fg3)),
        const SizedBox(height: 8),
        Text(value, style: TextStyle(fontFamily: GeniusThemeData.displayFont, fontSize: 24, fontWeight: FontWeight.w800, color: s.fg1)),
        const SizedBox(height: 6),
        Text('${up ? '▲' : '▼'} $delta', style: TextStyle(fontFamily: GeniusThemeData.bodyFont, fontSize: 12, fontWeight: FontWeight.w700, color: c)),
        const SizedBox(height: 8),
        SizedBox(height: 36, child: GLLineAreaChart(values: data, area: false, color: c)),
      ]),
    );
  }
}

class GLChartState extends StatelessWidget {
  final String title;
  final String state;
  final VoidCallback? onRetry;
  const GLChartState({super.key, this.title = 'Revenue trend', this.state = 'empty', this.onRetry});

  @override
  Widget build(BuildContext context) {
    final tone = state == 'error' ? GLStateTone.danger : GLStateTone.neutral;
    return GLCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: TextStyle(fontFamily: GeniusThemeData.displayFont, fontWeight: FontWeight.w800, color: GeniusThemeData.of(context).fg1)),
        const SizedBox(height: 14),
        Expanded(
          child: state == 'loading'
              ? const Center(child: GLSpinner(size: 28))
              : GLStateView(icon: state == 'error' ? 'alert' : 'poll', title: state == 'error' ? "Couldn't load chart" : 'No data for this period', body: state == 'error' ? 'Retry after the data service becomes available.' : 'Posted records will appear once the period has data.', actionLabel: state == 'error' ? 'Retry' : null, onAction: onRetry, tone: tone),
        ),
      ]),
    );
  }
}

void _grid(Canvas canvas, Size size, GeniusThemeData theme) {
  final p = Paint()..color = theme.border..strokeWidth = 1;
  for (var i = 1; i < 4; i++) {
    final y = size.height * i / 4;
    canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
  }
}
