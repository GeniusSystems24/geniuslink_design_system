import 'package:flutter/material.dart';
import 'package:geniuslink_design_system/geniuslink_design_system.dart';

class MotionDemo extends StatelessWidget {
  const MotionDemo({super.key});
  @override
  Widget build(BuildContext context) => GLShell(
        title: 'Motion',
        subtitle: 'Token durations · easing · press feedback · shimmer · stagger',
        children: [
          const GLSection(title: 'Tokens', child: GLMotionTokensView()),
          GLSection(title: 'Demos', children: [
            GLSpec(label: 'Press', child: Center(child: GLPressable(child: const GLButton(label: 'Post Entry', icon: 'check')))),
            const GLSpec(label: 'Shimmer', child: GLShimmerDemo()),
            const GLSpec(label: 'Stagger', child: GLStaggeredList()),
          ]),
        ],
      );
}
