import 'package:flutter/material.dart';
import 'package:geniuslink_design_system/geniuslink_design_system.dart';

class SkeletonsDemo extends StatelessWidget {
  const SkeletonsDemo({super.key});
  @override
  Widget build(BuildContext context) => const GLShell(
        title: 'Skeletons',
        subtitle: 'Shimmer · pulse · static placeholders for common surfaces',
        children: [
          GLSection(title: 'Skeleton surfaces', children: [
            GLSpec(label: 'Text', child: GLTextSkeleton()),
            GLSpec(label: 'Card', child: GLCardSkeleton()),
            GLSpec(label: 'List', child: GLListSkeleton(rows: 3)),
            GLSpec(label: 'Table', child: GLTableSkeleton(rows: 4)),
            GLSpec(label: 'Chat', child: GLChatSkeleton()),
            GLSpec(label: 'Dashboard', child: GLDashboardCardSkeleton()),
          ]),
        ],
      );
}
