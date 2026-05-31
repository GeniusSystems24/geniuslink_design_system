import 'package:flutter/material.dart';
import 'package:geniuslink_design_system/geniuslink_design_system.dart';

class FoundationsDemo extends StatelessWidget {
  const FoundationsDemo({super.key});
  @override
  Widget build(BuildContext context) => GLShell(
        title: 'Foundations',
        subtitle: 'Tokens · theme · typography · spacing · motion',
        children: [
          GLSection(title: 'Colors', children: [
            _Swatch('Primary', GeniusThemeData.blue500),
            _Swatch('Success', GeniusThemeData.success500),
            _Swatch('Warning', GeniusThemeData.warning500),
            _Swatch('Danger', GeniusThemeData.danger500),
          ]),
          const GLSection(title: 'Motion', child: GLMotionTokensView()),
        ],
      );
}

class _Swatch extends StatelessWidget {
  final String label;
  final Color color;
  const _Swatch(this.label, this.color);
  @override
  Widget build(BuildContext context) => GLSpec(label: label, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: Container(decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(GeniusThemeData.radiusLg)))),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(color: GeniusThemeData.of(context).fg1, fontWeight: FontWeight.w700)),
      ]));
}
