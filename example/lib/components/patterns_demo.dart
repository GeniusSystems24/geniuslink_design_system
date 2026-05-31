import 'package:flutter/material.dart';
import 'package:geniuslink_design_system/geniuslink_design_system.dart';

class PatternsDemo extends StatelessWidget {
  const PatternsDemo({super.key});
  @override
  Widget build(BuildContext context) => const GLShell(
        title: 'Patterns',
        subtitle: 'Data patterns · confirmation · async and status patterns',
        children: [
          GLSection(title: 'Data patterns', children: [
            GLSpec(label: 'Search + Filter', child: GLSearchFilterPattern()),
            GLSpec(label: 'Pagination', child: GLPagination()),
            GLSpec(label: 'Notification → Navigation', child: GLNotificationNavigationTile()),
          ]),
          GLSection(title: 'Confirmation', children: [
            GLSpec(label: 'Confirm', child: GLConfirmActionCard()),
            GLSpec(label: 'Delete', child: GLConfirmActionCard(danger: true)),
            GLSpec(label: 'Permission', child: GLPermissionRequestCard()),
          ]),
          GLSection(title: 'Async and status', children: [
            GLSpec(label: 'Upload', child: GLUploadPattern()),
            GLSpec(label: 'Message Status', child: GLMessageStatusList()),
            GLSpec(label: 'Offline Sync', child: GLOfflineSyncBanner()),
          ]),
        ],
      );
}
