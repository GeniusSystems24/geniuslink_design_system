// ============================================================
// GeniusLink Design System — Reusable patterns.
// Source parity: patterns.html.
// Architecture: MVVM-capable composed views built from core/domain pieces.
// ============================================================

import 'package:flutter/material.dart';
import '../../tokens.dart';
import '../core/core_components.dart';
import '../domain/domain_components.dart';

class GLSearchFilterPattern extends StatelessWidget {
  final TextEditingController? searchController;
  final List<String> filters;
  final String selectedFilter;
  final ValueChanged<String>? onFilterChanged;
  final ValueChanged<String>? onSearchChanged;
  const GLSearchFilterPattern({super.key, this.searchController, this.filters = const ['All', 'Posted', 'Draft'], this.selectedFilter = 'All', this.onFilterChanged, this.onSearchChanged});

  @override
  Widget build(BuildContext context) => Wrap(spacing: 10, runSpacing: 10, crossAxisAlignment: WrapCrossAlignment.center, children: [
        SizedBox(width: 260, child: GLSearchField(controller: searchController, onChanged: onSearchChanged, placeholder: 'Search records…')),
        for (final f in filters) GLChip(label: f, selected: f == selectedFilter, onTap: () => onFilterChanged?.call(f)),
        const GLButton(label: 'Filter', icon: 'filter', variant: GLButtonVariant.secondary),
      ]);
}

class GLPagination extends StatelessWidget {
  final int page;
  final int totalPages;
  final ValueChanged<int>? onChanged;
  const GLPagination({super.key, this.page = 1, this.totalPages = 5, this.onChanged});

  @override
  Widget build(BuildContext context) {
    final s = GeniusThemeData.of(context);
    return Row(mainAxisSize: MainAxisSize.min, children: [
      GLIconButton(icon: 'chevL', onPressed: page > 1 ? () => onChanged?.call(page - 1) : null, tooltip: 'Previous page'),
      for (var p = 1; p <= totalPages; p++)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: InkWell(
            onTap: () => onChanged?.call(p),
            borderRadius: BorderRadius.circular(GeniusThemeData.radiusMd),
            child: Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: p == page ? GeniusThemeData.blue500 : s.inputBg, borderRadius: BorderRadius.circular(GeniusThemeData.radiusMd), border: Border.all(color: p == page ? Colors.transparent : s.border)),
              child: Text('$p', style: TextStyle(fontFamily: GeniusThemeData.monoFont, fontSize: 12, fontWeight: FontWeight.w800, color: p == page ? Colors.white : s.fg2)),
            ),
          ),
        ),
      GLIconButton(icon: 'chevR', onPressed: page < totalPages ? () => onChanged?.call(page + 1) : null, tooltip: 'Next page'),
    ]);
  }
}

class GLConfirmActionCard extends StatelessWidget {
  final bool danger;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;
  const GLConfirmActionCard({super.key, this.danger = false, this.onConfirm, this.onCancel});

  @override
  Widget build(BuildContext context) => GLDialogCard(
        title: danger ? 'Delete journal entry?' : 'Post this entry?',
        body: danger ? 'JV-2024-0226 and its 3 lines will be permanently removed. Logged to the audit trail.' : 'Once posted, the entry can only be reversed, not edited.',
        confirmLabel: danger ? 'Delete' : 'Post',
        danger: danger,
        onConfirm: onConfirm,
        onCancel: onCancel,
      );
}

class GLPermissionRequestCard extends StatelessWidget {
  final String title;
  final String body;
  final VoidCallback? onApprove;
  final VoidCallback? onDeny;
  const GLPermissionRequestCard({super.key, this.title = 'Allow camera access?', this.body = 'Camera access is used to scan invoice attachments and warehouse barcodes.', this.onApprove, this.onDeny});

  @override
  Widget build(BuildContext context) => GLDialogCard(title: title, body: body, confirmLabel: 'Allow', cancelLabel: 'Not Now', onConfirm: onApprove, onCancel: onDeny);
}

class GLUploadPattern extends StatelessWidget {
  final double progress;
  const GLUploadPattern({super.key, this.progress = .64});

  @override
  Widget build(BuildContext context) {
    final s = GeniusThemeData.of(context);
    return Column(children: [
      Container(
        height: 92,
        decoration: BoxDecoration(border: Border.all(color: s.borderStrong, style: BorderStyle.solid), borderRadius: BorderRadius.circular(GeniusThemeData.radiusMd)),
        child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [const GLIcon('image', size: 24), const SizedBox(height: 6), Text('Drag & drop or browse', style: TextStyle(fontFamily: GeniusThemeData.bodyFont, fontSize: 12.5, color: s.fg3))])),
      ),
      const SizedBox(height: 10),
      GLFileCard(progress: progress),
    ]);
  }
}

class GLMessageStatusList extends StatelessWidget {
  final List<String> rows;
  const GLMessageStatusList({super.key, this.rows = const ['Posted to ledger', 'Awaiting approval', 'Sync failed — retry']});

  @override
  Widget build(BuildContext context) => Column(children: [
        _statusRow(context, rows[0], 'sent'),
        const SizedBox(height: 8),
        _statusRow(context, rows[1], 'pending'),
        const SizedBox(height: 8),
        _statusRow(context, rows[2], 'failed'),
      ]);

  Widget _statusRow(BuildContext context, String text, String status) {
    final s = GeniusThemeData.of(context);
    final tone = status == 'sent' ? GLStateTone.success : status == 'pending' ? GLStateTone.warning : GLStateTone.danger;
    return GLCard(
      padding: 10,
      child: Row(children: [
        GLBadge(dot: true, tone: tone),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: TextStyle(fontFamily: GeniusThemeData.bodyFont, fontSize: 13, fontWeight: FontWeight.w700, color: s.fg1))),
        GLPill(label: status, tone: tone),
      ]),
    );
  }
}

class GLOfflineSyncBanner extends StatelessWidget {
  final bool offline;
  final int pending;
  const GLOfflineSyncBanner({super.key, this.offline = true, this.pending = 3});

  @override
  Widget build(BuildContext context) {
    final tone = offline ? GLStateTone.warning : GLStateTone.success;
    final color = glToneColor(context, tone.name);
    final s = GeniusThemeData.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: color.withOpacity(.1), border: Border.all(color: color.withOpacity(.32)), borderRadius: BorderRadius.circular(GeniusThemeData.radiusMd)),
      child: Row(children: [
        GLIcon(offline ? 'ban' : 'check', size: 17, color: color),
        const SizedBox(width: 10),
        Expanded(child: Text(offline ? 'Offline — changes saved locally' : 'Back online — all synced', style: TextStyle(fontFamily: GeniusThemeData.bodyFont, fontSize: 13, fontWeight: FontWeight.w700, color: s.fg1))),
        offline ? GLPill(label: '$pending pending', tone: GLStateTone.warning) : Text('just now', style: TextStyle(fontFamily: GeniusThemeData.monoFont, fontSize: 11, color: s.fg3)),
      ]),
    );
  }
}

class GLNotificationNavigationTile extends StatelessWidget {
  final VoidCallback? onTap;
  const GLNotificationNavigationTile({super.key, this.onTap});
  @override
  Widget build(BuildContext context) => GLNotificationTile(title: 'Wire EXT-2024-0311 approved', subtitle: 'Tap → deep-links to External Transfer · Details', onTap: onTap);
}
