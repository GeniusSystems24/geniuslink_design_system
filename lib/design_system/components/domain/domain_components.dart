// ============================================================
// GeniusLink Design System — Domain components.
// Source parity: components-domain.html.
// Architecture: MVVM view widgets; domain status values are explicit enums.
// ============================================================

import 'package:flutter/material.dart';
import '../../tokens.dart';
import '../core/core_components.dart';

enum GLMessageStatus { sending, sent, delivered, read, failed, pending }
enum GLFileStatus { uploading, paused, failed, completed }
enum GLTaskStatus { pending, inProgress, blocked, done }

GLStateTone _statusTone(String s) {
  switch (s) {
    case 'read':
    case 'delivered':
    case 'sent':
    case 'completed':
    case 'done':
      return GLStateTone.success;
    case 'failed':
    case 'blocked':
      return GLStateTone.danger;
    case 'pending':
    case 'paused':
    case 'uploading':
    case 'inProgress':
      return GLStateTone.warning;
    default:
      return GLStateTone.neutral;
  }
}

class GLStatusTicks extends StatelessWidget {
  final GLMessageStatus status;
  const GLStatusTicks({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final color = status == GLMessageStatus.failed
        ? GeniusThemeData.danger500
        : status == GLMessageStatus.read
            ? GeniusThemeData.blue500
            : GeniusThemeData.of(context).fg3;
    final icon = status == GLMessageStatus.failed
        ? Icons.error_outline_rounded
        : status == GLMessageStatus.sending || status == GLMessageStatus.pending
            ? Icons.schedule_rounded
            : status == GLMessageStatus.sent
                ? Icons.check_rounded
                : Icons.done_all_rounded;
    return Icon(icon, size: 15, color: color);
  }
}

class GLMessageBubble extends StatelessWidget {
  final bool me;
  final String text;
  final String time;
  final GLMessageStatus status;
  const GLMessageBubble({super.key, this.me = false, required this.text, this.time = '09:41', this.status = GLMessageStatus.sent});

  @override
  Widget build(BuildContext context) {
    final s = GeniusThemeData.of(context);
    return Align(
      alignment: me ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 320),
        padding: const EdgeInsets.fromLTRB(13, 10, 13, 8),
        decoration: BoxDecoration(
          color: me ? GeniusThemeData.blue500 : s.surface,
          border: Border.all(color: me ? Colors.transparent : s.border),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(14),
            topRight: const Radius.circular(14),
            bottomLeft: Radius.circular(me ? 14 : 4),
            bottomRight: Radius.circular(me ? 4 : 14),
          ),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(text, style: TextStyle(fontFamily: GeniusThemeData.bodyFont, fontSize: 13.5, height: 1.45, color: me ? Colors.white : s.fg1)),
          const SizedBox(height: 6),
          Row(mainAxisSize: MainAxisSize.min, children: [
            Text(time, style: TextStyle(fontFamily: GeniusThemeData.monoFont, fontSize: 10.5, color: me ? Colors.white70 : s.fg3)),
            const SizedBox(width: 5),
            GLStatusTicks(status: status),
          ]),
        ]),
      ),
    );
  }
}

class GLComposer extends StatelessWidget {
  final TextEditingController? controller;
  final VoidCallback? onSend;
  final VoidCallback? onAttach;
  final String placeholder;
  const GLComposer({super.key, this.controller, this.onSend, this.onAttach, this.placeholder = 'Write a message…'});

  @override
  Widget build(BuildContext context) {
    final s = GeniusThemeData.of(context);
    return GLCard(
      padding: 8,
      child: Row(children: [
        GLIconButton(icon: 'paperclip', onPressed: onAttach, tooltip: 'Attach'),
        Expanded(
          child: TextField(
            controller: controller,
            minLines: 1,
            maxLines: 4,
            style: TextStyle(fontFamily: GeniusThemeData.bodyFont, color: s.fg1, fontSize: 13.5),
            decoration: InputDecoration(border: InputBorder.none, hintText: placeholder, hintStyle: TextStyle(color: s.fg3), isDense: true),
          ),
        ),
        GLIconButton(icon: 'send', variant: GLButtonVariant.primary, onPressed: onSend, tooltip: 'Send'),
      ]),
    );
  }
}

class GLAttachmentMenu extends StatelessWidget {
  final VoidCallback? onDocument;
  final VoidCallback? onImage;
  final VoidCallback? onAudio;
  const GLAttachmentMenu({super.key, this.onDocument, this.onImage, this.onAudio});

  @override
  Widget build(BuildContext context) => GLMenuList(items: [
        GLMenuItem(icon: 'doc', label: 'Document', onTap: onDocument),
        GLMenuItem(icon: 'image', label: 'Image', onTap: onImage),
        GLMenuItem(icon: 'mic', label: 'Audio note', onTap: onAudio),
      ]);
}

class GLAudioBubble extends StatelessWidget {
  final bool me;
  final double progress;
  const GLAudioBubble({super.key, this.me = false, this.progress = 0.42});

  @override
  Widget build(BuildContext context) {
    final s = GeniusThemeData.of(context);
    return GLCard(
      padding: 12,
      color: me ? GeniusThemeData.blue500.withOpacity(0.13) : null,
      child: Row(children: [
        Container(width: 34, height: 34, alignment: Alignment.center, decoration: const BoxDecoration(color: GeniusThemeData.blue500, shape: BoxShape.circle), child: const Icon(Icons.play_arrow_rounded, color: Colors.white)),
        const SizedBox(width: 12),
        Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(999), child: LinearProgressIndicator(value: progress, minHeight: 5, backgroundColor: s.inputBg, valueColor: const AlwaysStoppedAnimation<Color>(GeniusThemeData.blue500)))),
        const SizedBox(width: 10),
        Text('0:38', style: TextStyle(fontFamily: GeniusThemeData.monoFont, fontSize: 11, color: s.fg3)),
      ]),
    );
  }
}

class GLVideoBubble extends StatelessWidget {
  final String label;
  const GLVideoBubble({super.key, this.label = 'Branch walkthrough'});

  @override
  Widget build(BuildContext context) {
    final s = GeniusThemeData.of(context);
    return Container(
      height: 150,
      decoration: BoxDecoration(color: s.inputBg, borderRadius: BorderRadius.circular(GeniusThemeData.radiusLg), border: Border.all(color: s.border)),
      child: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 46, height: 46, decoration: const BoxDecoration(color: GeniusThemeData.blue500, shape: BoxShape.circle), child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 32)),
          const SizedBox(height: 10),
          Text(label, style: TextStyle(fontFamily: GeniusThemeData.bodyFont, fontSize: 13, fontWeight: FontWeight.w700, color: s.fg1)),
        ]),
      ),
    );
  }
}

class GLPollBubble extends StatelessWidget {
  final String question;
  final Map<String, double> options;
  const GLPollBubble({super.key, this.question = 'Approve opening balance?', this.options = const {'Approve': .72, 'Needs review': .28}});

  @override
  Widget build(BuildContext context) {
    final s = GeniusThemeData.of(context);
    return GLCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(question, style: TextStyle(fontFamily: GeniusThemeData.displayFont, fontWeight: FontWeight.w800, color: s.fg1)),
        const SizedBox(height: 12),
        for (final e in options.entries) ...[
          Row(children: [
            Expanded(child: Text(e.key, style: TextStyle(fontFamily: GeniusThemeData.bodyFont, fontSize: 12.5, fontWeight: FontWeight.w700, color: s.fg2))),
            Text('${(e.value * 100).round()}%', style: TextStyle(fontFamily: GeniusThemeData.monoFont, fontSize: 11, color: s.fg3)),
          ]),
          const SizedBox(height: 6),
          ClipRRect(borderRadius: BorderRadius.circular(999), child: LinearProgressIndicator(value: e.value, minHeight: 6, backgroundColor: s.inputBg, valueColor: const AlwaysStoppedAnimation<Color>(GeniusThemeData.blue500))),
          const SizedBox(height: 10),
        ],
      ]),
    );
  }
}

class GLMediaPreview extends StatelessWidget {
  final String title;
  final String subtitle;
  const GLMediaPreview({super.key, this.title = 'invoice-Q4.pdf', this.subtitle = 'PDF · 2.4 MB'});

  @override
  Widget build(BuildContext context) {
    final s = GeniusThemeData.of(context);
    return GLCard(
      padding: 12,
      child: Row(children: [
        Container(width: 46, height: 46, decoration: BoxDecoration(color: GeniusThemeData.blue500.withOpacity(0.14), borderRadius: BorderRadius.circular(GeniusThemeData.radiusMd)), child: const GLIcon('doc', color: GeniusThemeData.blue500)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: TextStyle(fontFamily: GeniusThemeData.bodyFont, fontSize: 13.5, fontWeight: FontWeight.w800, color: s.fg1)),
          const SizedBox(height: 3),
          Text(subtitle, style: TextStyle(fontFamily: GeniusThemeData.bodyFont, fontSize: 12, color: s.fg3)),
        ])),
        const GLIcon('download', size: 18),
      ]),
    );
  }
}

class GLPinnedBar extends StatelessWidget {
  final String text;
  const GLPinnedBar({super.key, this.text = 'Pinned: Controller approved wire EXT-2024-0311'});

  @override
  Widget build(BuildContext context) {
    final s = GeniusThemeData.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(color: GeniusThemeData.warning500.withOpacity(0.12), border: Border.all(color: GeniusThemeData.warning500.withOpacity(0.35)), borderRadius: BorderRadius.circular(GeniusThemeData.radiusMd)),
      child: Row(children: [
        const GLIcon('pin', size: 16, color: GeniusThemeData.warning500),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: TextStyle(fontFamily: GeniusThemeData.bodyFont, fontSize: 12.5, color: s.fg1, fontWeight: FontWeight.w700))),
      ]),
    );
  }
}

class GLNotificationTile extends StatelessWidget {
  final bool unread;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  const GLNotificationTile({super.key, this.unread = true, this.title = 'Wire EXT-2024-0311 approved', this.subtitle = 'Tap to open External Transfer · Details', this.onTap});

  @override
  Widget build(BuildContext context) => GLListTile(
        icon: 'bell',
        title: title,
        subtitle: subtitle,
        trailing: unread ? const GLBadge(dot: true) : const GLIcon('chevR', size: 16),
        onTap: onTap,
      );
}

class GLFileCard extends StatelessWidget {
  final String name;
  final GLFileStatus status;
  final double progress;
  const GLFileCard({super.key, this.name = 'invoice-Q4.pdf', this.status = GLFileStatus.uploading, this.progress = .64});

  @override
  Widget build(BuildContext context) {
    final s = GeniusThemeData.of(context);
    final label = status.name;
    return GLCard(
      padding: 12,
      child: Column(children: [
        Row(children: [
          const GLIcon('doc', color: GeniusThemeData.blue500),
          const SizedBox(width: 10),
          Expanded(child: Text(name, style: TextStyle(fontFamily: GeniusThemeData.bodyFont, fontSize: 13.5, fontWeight: FontWeight.w800, color: s.fg1))),
          GLPill(label: label, tone: _statusTone(label)),
        ]),
        if (status == GLFileStatus.uploading || status == GLFileStatus.paused) ...[
          const SizedBox(height: 10),
          ClipRRect(borderRadius: BorderRadius.circular(999), child: LinearProgressIndicator(value: progress, minHeight: 5, backgroundColor: s.inputBg, valueColor: AlwaysStoppedAnimation<Color>(status == GLFileStatus.paused ? GeniusThemeData.warning500 : GeniusThemeData.blue500))),
        ],
      ]),
    );
  }
}

class GLClubCard extends StatelessWidget {
  final String name;
  final String meta;
  const GLClubCard({super.key, this.name = 'Finance Controllers', this.meta = '28 members · private'});

  @override
  Widget build(BuildContext context) {
    final s = GeniusThemeData.of(context);
    return GLCard(
      child: Row(children: [
        const GLAvatar(name: 'FC', size: 44, color: GeniusThemeData.success500),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name, style: TextStyle(fontFamily: GeniusThemeData.displayFont, fontSize: 15, fontWeight: FontWeight.w800, color: s.fg1)),
          const SizedBox(height: 4),
          Text(meta, style: TextStyle(fontFamily: GeniusThemeData.bodyFont, fontSize: 12, color: s.fg3)),
        ])),
        const GLIcon('lock', size: 17),
      ]),
    );
  }
}

class GLMemberTile extends StatelessWidget {
  final String name;
  final String role;
  const GLMemberTile({super.key, this.name = 'Maha Alotaibi', this.role = 'Controller'});

  @override
  Widget build(BuildContext context) => GLListTile(
        avatar: GLAvatar(name: name, size: 34),
        title: name,
        subtitle: role,
        trailing: const GLPill(label: 'active', tone: GLStateTone.success),
      );
}

class GLTaskCard extends StatelessWidget {
  final String title;
  final String assignee;
  final GLTaskStatus status;
  const GLTaskCard({super.key, this.title = 'Review branch inventory issue', this.assignee = 'Maha Alotaibi', this.status = GLTaskStatus.inProgress});

  @override
  Widget build(BuildContext context) {
    final s = GeniusThemeData.of(context);
    return GLCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(title, style: TextStyle(fontFamily: GeniusThemeData.displayFont, fontSize: 14.5, fontWeight: FontWeight.w800, color: s.fg1))),
          GLPill(label: status.name, tone: _statusTone(status.name)),
        ]),
        const SizedBox(height: 12),
        GLListTile(avatar: GLAvatar(name: assignee, size: 28), title: assignee, subtitle: 'Due today'),
      ]),
    );
  }
}

class GLRoomCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool live;
  const GLRoomCard({super.key, this.title = 'Accounting War Room', this.subtitle = '8 online · 3 pending approvals', this.live = true});

  @override
  Widget build(BuildContext context) {
    final s = GeniusThemeData.of(context);
    return GLCard(
      child: Row(children: [
        Container(width: 42, height: 42, alignment: Alignment.center, decoration: BoxDecoration(color: GeniusThemeData.blue500.withOpacity(0.14), borderRadius: BorderRadius.circular(GeniusThemeData.radiusLg)), child: const GLIcon('users', color: GeniusThemeData.blue500)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: TextStyle(fontFamily: GeniusThemeData.displayFont, fontSize: 15, fontWeight: FontWeight.w800, color: s.fg1)),
          const SizedBox(height: 4),
          Text(subtitle, style: TextStyle(fontFamily: GeniusThemeData.bodyFont, fontSize: 12.5, color: s.fg3)),
        ])),
        if (live) const GLBadge(dot: true, tone: GLStateTone.success),
      ]),
    );
  }
}
