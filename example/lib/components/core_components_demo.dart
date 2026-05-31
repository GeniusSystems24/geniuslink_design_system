import 'package:flutter/material.dart';
import 'package:geniuslink_design_system/geniuslink_design_system.dart';

class CoreComponentsDemo extends StatelessWidget {
  const CoreComponentsDemo({super.key});
  @override
  Widget build(BuildContext context) => GLShell(
        title: 'Core Components',
        subtitle: 'Buttons · fields · chips · cards · state views · overlays',
        children: [
          GLSection(title: 'Actions', children: [
            GLSpec(label: 'Buttons', child: Wrap(spacing: 8, runSpacing: 8, children: const [
              GLButton(label: 'Create Store', icon: 'plus'),
              GLButton(label: 'Back to List', variant: GLButtonVariant.secondary),
              GLButton(label: 'Delete', icon: 'trash', variant: GLButtonVariant.danger),
            ])),
            const GLSpec(label: 'Icon Buttons', child: Wrap(spacing: 8, children: [GLIconButton(icon: 'search'), GLIconButton(icon: 'more'), GLIconButton(icon: 'trash', variant: GLButtonVariant.danger)])),
            const GLSpec(label: 'Spinner', child: Center(child: GLSpinner(size: 30))),
          ]),
          GLSection(title: 'Inputs and display', children: [
            const GLSpec(label: 'Field', child: GLTextField(label: 'Account Name', placeholder: 'Cash on hand', isRequired: true)),
            const GLSpec(label: 'Search', child: GLSearchField()),
            const GLSpec(label: 'Pills & Badges', child: Wrap(spacing: 8, runSpacing: 8, children: [GLPill(label: 'posted', tone: GLStateTone.success), GLPill(label: 'draft', tone: GLStateTone.warning), GLBadge(count: 8), GLBadge(dot: true)])),
            const GLSpec(label: 'Chip', child: Wrap(spacing: 8, children: [GLChip(label: 'Selected', selected: true), GLChip(label: 'Removable', removable: true)])),
          ]),
          const GLSection(title: 'State and overlays', children: [
            GLSpec(label: 'StateView', child: GLStateView(icon: 'poll', title: 'No entries yet', body: 'Posted journal entries will appear here.', actionLabel: 'Create Entry')),
            GLSpec(label: 'Dialog', child: GLDialogCard(title: 'Post this entry?', body: 'Once posted, the entry can only be reversed, not edited.', confirmLabel: 'Post')),
            GLSpec(label: 'Snackbar', child: GLSnackbar(icon: 'check', text: 'Controller approved wire EXT-2024-0311.', tone: GLStateTone.success)),
          ]),
        ],
      );
}
