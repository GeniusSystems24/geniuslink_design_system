import 'package:flutter/material.dart';
import 'package:geniuslink_design_system/geniuslink_design_system.dart';

class DomainComponentsDemo extends StatelessWidget {
  const DomainComponentsDemo({super.key});
  @override
  Widget build(BuildContext context) => GLShell(
        title: 'Domain Components',
        subtitle: 'Chat · media · notifications · files · rooms · tasks',
        children: const [
          GLSection(title: 'Messaging', children: [
            GLSpec(label: 'Message Bubble', child: Column(children: [GLMessageBubble(text: 'Opening journal entry is ready for review.'), SizedBox(height: 8), GLMessageBubble(me: true, text: 'Posted to ledger.', status: GLMessageStatus.read)])),
            GLSpec(label: 'Composer', child: GLComposer()),
            GLSpec(label: 'Audio Bubble', child: GLAudioBubble()),
            GLSpec(label: 'Poll', child: GLPollBubble()),
          ]),
          GLSection(title: 'Records and collaboration', children: [
            GLSpec(label: 'Notification', child: GLNotificationTile()),
            GLSpec(label: 'File', child: GLFileCard()),
            GLSpec(label: 'Club', child: GLClubCard()),
            GLSpec(label: 'Member', child: GLMemberTile()),
            GLSpec(label: 'Task', child: GLTaskCard()),
            GLSpec(label: 'Room', child: GLRoomCard()),
          ]),
        ],
      );
}
