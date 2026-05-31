// ============================================================
// GeniusLink Design System — Core components.
// Source parity: ds-kit.jsx + components-core.html.
// Architecture: MVVM-friendly stateless/stateful views; form fields expose
// controllers externally, while transient hover/press state remains in view.
// ============================================================

import 'package:flutter/material.dart';
import '../../tokens.dart';

enum GLButtonVariant { primary, secondary, danger, ghost }
enum GLButtonSize { sm, md }
enum GLFieldState { normal, error, disabled }
enum GLStateTone { neutral, info, success, warning, danger }

String _toneName(GLStateTone tone) => tone.name;

IconData glIconData(String name) {
  switch (name) {
    case 'plus':
      return Icons.add_rounded;
    case 'search':
      return Icons.search_rounded;
    case 'check':
      return Icons.check_rounded;
    case 'trash':
      return Icons.delete_outline_rounded;
    case 'more':
      return Icons.more_horiz_rounded;
    case 'close':
      return Icons.close_rounded;
    case 'alert':
      return Icons.warning_amber_rounded;
    case 'image':
      return Icons.image_outlined;
    case 'doc':
      return Icons.description_outlined;
    case 'bell':
      return Icons.notifications_none_rounded;
    case 'chevR':
      return Icons.chevron_right_rounded;
    case 'chevL':
      return Icons.chevron_left_rounded;
    case 'ban':
      return Icons.cloud_off_outlined;
    case 'poll':
      return Icons.poll_outlined;
    case 'menu':
      return Icons.menu_rounded;
    case 'home':
      return Icons.home_outlined;
    case 'settings':
      return Icons.settings_outlined;
    case 'chart':
      return Icons.bar_chart_rounded;
    case 'user':
      return Icons.person_outline_rounded;
    case 'users':
      return Icons.people_outline_rounded;
    case 'mic':
      return Icons.mic_none_rounded;
    case 'video':
      return Icons.videocam_outlined;
    case 'file':
      return Icons.attach_file_rounded;
    case 'pin':
      return Icons.push_pin_outlined;
    case 'lock':
      return Icons.lock_outline_rounded;
    case 'refresh':
      return Icons.refresh_rounded;
    case 'upload':
      return Icons.cloud_upload_outlined;
    case 'download':
      return Icons.download_rounded;
    case 'filter':
      return Icons.tune_rounded;
    case 'calendar':
      return Icons.calendar_month_outlined;
    case 'table':
      return Icons.table_chart_outlined;
    case 'book':
      return Icons.menu_book_outlined;
    case 'store':
      return Icons.storefront_outlined;
    case 'globe':
      return Icons.public_rounded;
    case 'send':
      return Icons.send_rounded;
    case 'paperclip':
      return Icons.attach_file_rounded;
    case 'star':
      return Icons.star_border_rounded;
    case 'edit':
      return Icons.edit_outlined;
    case 'copy':
      return Icons.content_copy_rounded;
    default:
      return Icons.circle_outlined;
  }
}

class GLIcon extends StatelessWidget {
  final String name;
  final double size;
  final Color? color;
  final String? semanticLabel;
  const GLIcon(this.name, {super.key, this.size = 18, this.color, this.semanticLabel});

  @override
  Widget build(BuildContext context) {
    final s = GeniusThemeData.of(context);
    return Icon(glIconData(name), size: size, color: color ?? s.fg2, semanticLabel: semanticLabel);
  }
}

class GLSpinner extends StatelessWidget {
  final double size;
  final Color? color;
  const GLSpinner({super.key, this.size = 18, this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(color ?? GeniusThemeData.blue500)),
    );
  }
}

class GLButton extends StatefulWidget {
  final Widget? child;
  final String? label;
  final String? icon;
  final GLButtonVariant variant;
  final GLButtonSize size;
  final bool loading;
  final bool disabled;
  final VoidCallback? onPressed;
  final String? semanticLabel;

  const GLButton({
    super.key,
    this.child,
    this.label,
    this.icon,
    this.variant = GLButtonVariant.primary,
    this.size = GLButtonSize.md,
    this.loading = false,
    this.disabled = false,
    this.onPressed,
    this.semanticLabel,
  });

  @override
  State<GLButton> createState() => _GLButtonState();
}

class _GLButtonState extends State<GLButton> {
  bool _hover = false;
  bool _pressed = false;

  bool get _enabled => !widget.disabled && !widget.loading && widget.onPressed != null;

  @override
  Widget build(BuildContext context) {
    final s = GeniusThemeData.of(context);
    final minHeight = widget.size == GLButtonSize.sm ? 32.0 : 40.0;
    final fg = _foreground(s);
    final bg = _background(s);
    final border = _border(s);
    final content = widget.loading
        ? GLSpinner(size: 15, color: fg)
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null) ...[
                GLIcon(widget.icon!, size: 16, color: fg),
                const SizedBox(width: 8),
              ],
              DefaultTextStyle.merge(
                style: TextStyle(fontFamily: GeniusThemeData.bodyFont, fontSize: widget.size == GLButtonSize.sm ? 12.5 : 13.5, fontWeight: FontWeight.w700, color: fg),
                child: widget.child ?? Text(widget.label ?? ''),
              ),
            ],
          );

    return Semantics(
      button: true,
      enabled: _enabled,
      label: widget.semanticLabel ?? widget.label,
      child: MouseRegion(
        cursor: _enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() {
          _hover = false;
          _pressed = false;
        }),
        child: GestureDetector(
          onTapDown: _enabled ? (_) => setState(() => _pressed = true) : null,
          onTapCancel: _enabled ? () => setState(() => _pressed = false) : null,
          onTapUp: _enabled ? (_) => setState(() => _pressed = false) : null,
          onTap: _enabled ? widget.onPressed : null,
          child: AnimatedContainer(
            duration: GeniusThemeData.durBase,
            curve: GeniusThemeData.easeStandard,
            constraints: BoxConstraints(minHeight: minHeight, minWidth: 44),
            padding: EdgeInsets.symmetric(horizontal: widget.size == GLButtonSize.sm ? 12 : 16),
            transform: _pressed ? (Matrix4.identity()..scale(0.985)) : Matrix4.identity(),
            decoration: BoxDecoration(
              color: bg,
              border: Border.all(color: border),
              borderRadius: BorderRadius.circular(GeniusThemeData.radiusSm),
            ),
            alignment: Alignment.center,
            child: Opacity(opacity: _enabled ? 1 : 0.45, child: content),
          ),
        ),
      ),
    );
  }

  Color _background(GeniusThemeData s) {
    final hover = _hover || _pressed;
    switch (widget.variant) {
      case GLButtonVariant.primary:
        return hover ? GeniusThemeData.blue500.withOpacity(0.92) : GeniusThemeData.blue500;
      case GLButtonVariant.danger:
        return hover ? GeniusThemeData.danger500.withOpacity(0.92) : GeniusThemeData.danger500;
      case GLButtonVariant.secondary:
        return hover ? s.hover : Colors.transparent;
      case GLButtonVariant.ghost:
        return hover ? s.hover : Colors.transparent;
    }
  }

  Color _foreground(GeniusThemeData s) {
    switch (widget.variant) {
      case GLButtonVariant.primary:
      case GLButtonVariant.danger:
        return Colors.white;
      case GLButtonVariant.secondary:
      case GLButtonVariant.ghost:
        return s.fg1;
    }
  }

  Color _border(GeniusThemeData s) {
    switch (widget.variant) {
      case GLButtonVariant.primary:
      case GLButtonVariant.danger:
      case GLButtonVariant.ghost:
        return Colors.transparent;
      case GLButtonVariant.secondary:
        return _hover ? s.borderStrong : s.border;
    }
  }
}

class GLIconButton extends StatefulWidget {
  final String icon;
  final VoidCallback? onPressed;
  final GLButtonVariant variant;
  final double size;
  final double iconSize;
  final String? tooltip;
  final bool disabled;
  const GLIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.variant = GLButtonVariant.ghost,
    this.size = 36,
    this.iconSize = 18,
    this.tooltip,
    this.disabled = false,
  });

  @override
  State<GLIconButton> createState() => _GLIconButtonState();
}

class _GLIconButtonState extends State<GLIconButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final s = GeniusThemeData.of(context);
    final enabled = !widget.disabled && widget.onPressed != null;
    Color bg = Colors.transparent;
    Color fg = s.fg2;
    if (widget.variant == GLButtonVariant.primary) {
      bg = GeniusThemeData.blue500;
      fg = Colors.white;
    } else if (widget.variant == GLButtonVariant.danger) {
      bg = _hover ? GeniusThemeData.danger500.withOpacity(0.15) : Colors.transparent;
      fg = GeniusThemeData.danger500;
    } else if (_hover) {
      bg = s.hover;
      fg = s.fg1;
    }
    final button = MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: enabled ? widget.onPressed : null,
        child: AnimatedContainer(
          duration: GeniusThemeData.durBase,
          width: widget.size < 44 ? 44 : widget.size,
          height: widget.size < 44 ? 44 : widget.size,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(GeniusThemeData.radiusMd)),
          child: Opacity(opacity: enabled ? 1 : 0.4, child: GLIcon(widget.icon, size: widget.iconSize, color: fg, semanticLabel: widget.tooltip)),
        ),
      ),
    );
    return widget.tooltip == null ? button : Tooltip(message: widget.tooltip!, child: button);
  }
}

class GLTextField extends StatelessWidget {
  final String? label;
  final String? placeholder;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final String? value;
  final String? errorText;
  final bool mono;
  final bool enabled;
  final bool isRequired;
  final TextDirection? textDirection;
  final String? leadingIcon;
  final int maxLines;

  const GLTextField({
    super.key,
    this.label,
    this.placeholder,
    this.controller,
    this.onChanged,
    this.value,
    this.errorText,
    this.mono = false,
    this.enabled = true,
    this.isRequired = false,
    this.textDirection,
    this.leadingIcon,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    final s = GeniusThemeData.of(context);
    final ctl = controller ?? (value != null ? TextEditingController(text: value) : null);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          RichText(
            text: TextSpan(
              style: TextStyle(fontFamily: GeniusThemeData.bodyFont, fontSize: 12, fontWeight: FontWeight.w700, color: s.fg2),
              children: [
                TextSpan(text: label!),
                if (isRequired) const TextSpan(text: ' *', style: TextStyle(color: GeniusThemeData.danger500)),
              ],
            ),
          ),
          const SizedBox(height: 6),
        ],
        TextField(
          controller: ctl,
          enabled: enabled,
          onChanged: onChanged,
          maxLines: maxLines,
          textDirection: textDirection,
          style: TextStyle(fontFamily: mono ? GeniusThemeData.monoFont : GeniusThemeData.bodyFont, fontSize: 13.5, color: s.fg1),
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle: TextStyle(color: s.fg3),
            prefixIcon: leadingIcon == null ? null : Padding(padding: const EdgeInsetsDirectional.only(start: 12, end: 8), child: GLIcon(leadingIcon!, size: 17, color: s.fg3)),
            prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
            isDense: true,
            filled: true,
            fillColor: enabled ? s.inputBg : s.inputBg.withOpacity(0.45),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(GeniusThemeData.radiusSm), borderSide: BorderSide(color: errorText == null ? s.border : GeniusThemeData.danger500)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(GeniusThemeData.radiusSm), borderSide: BorderSide(color: errorText == null ? GeniusThemeData.blue500 : GeniusThemeData.danger500, width: 2)),
            disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(GeniusThemeData.radiusSm), borderSide: BorderSide(color: s.border)),
            errorText: errorText,
            errorStyle: const TextStyle(fontFamily: GeniusThemeData.bodyFont, color: GeniusThemeData.danger500),
          ),
        ),
      ],
    );
  }
}

class GLSearchField extends StatelessWidget {
  final String placeholder;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  const GLSearchField({super.key, this.placeholder = 'Search…', this.controller, this.onChanged});

  @override
  Widget build(BuildContext context) => GLTextField(placeholder: placeholder, controller: controller, onChanged: onChanged, leadingIcon: 'search');
}

class GLPill extends StatelessWidget {
  final Widget? child;
  final String? label;
  final GLStateTone tone;
  final bool subtle;
  const GLPill({super.key, this.child, this.label, this.tone = GLStateTone.neutral, this.subtle = true});

  @override
  Widget build(BuildContext context) {
    final s = GeniusThemeData.of(context);
    final c = glToneColor(context, _toneName(tone));
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(color: subtle ? c.withOpacity(0.15) : c, borderRadius: BorderRadius.circular(GeniusThemeData.radiusPill)),
      child: DefaultTextStyle.merge(
        style: TextStyle(fontFamily: GeniusThemeData.bodyFont, fontSize: 11, fontWeight: FontWeight.w800, color: subtle ? c : Colors.white, letterSpacing: 0.25),
        child: child ?? Text(label ?? ''),
      ),
    );
  }
}

class GLBadge extends StatelessWidget {
  final int? count;
  final bool dot;
  final GLStateTone tone;
  const GLBadge({super.key, this.count, this.dot = false, this.tone = GLStateTone.danger});

  @override
  Widget build(BuildContext context) {
    final c = glToneColor(context, _toneName(tone));
    if (dot) return Container(width: 9, height: 9, decoration: BoxDecoration(color: c, shape: BoxShape.circle));
    return Container(
      constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
      padding: const EdgeInsets.symmetric(horizontal: 6),
      alignment: Alignment.center,
      decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(GeniusThemeData.radiusPill)),
      child: Text('${count ?? 0}', style: const TextStyle(fontFamily: GeniusThemeData.monoFont, fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white)),
    );
  }
}

class GLChip extends StatelessWidget {
  final String label;
  final bool selected;
  final bool removable;
  final String? icon;
  final VoidCallback? onDeleted;
  final VoidCallback? onTap;
  const GLChip({super.key, required this.label, this.selected = false, this.removable = false, this.icon, this.onDeleted, this.onTap});

  @override
  Widget build(BuildContext context) {
    final s = GeniusThemeData.of(context);
    final bg = selected ? GeniusThemeData.blue500.withOpacity(0.16) : s.inputBg;
    final fg = selected ? GeniusThemeData.blue500 : s.fg2;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(GeniusThemeData.radiusPill),
      child: Container(
        constraints: const BoxConstraints(minHeight: 32),
        padding: EdgeInsetsDirectional.only(start: 10, end: removable ? 6 : 10),
        decoration: BoxDecoration(color: bg, border: Border.all(color: selected ? GeniusThemeData.blue500.withOpacity(0.35) : s.border), borderRadius: BorderRadius.circular(GeniusThemeData.radiusPill)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) ...[GLIcon(icon!, size: 14, color: fg), const SizedBox(width: 6)],
          Text(label, style: TextStyle(fontFamily: GeniusThemeData.bodyFont, fontSize: 12.5, fontWeight: FontWeight.w700, color: fg)),
          if (removable) ...[const SizedBox(width: 4), GLIconButton(icon: 'close', size: 28, iconSize: 14, onPressed: onDeleted, tooltip: 'Remove')],
        ]),
      ),
    );
  }
}

class GLAvatar extends StatelessWidget {
  final String name;
  final double size;
  final Color? color;
  const GLAvatar({super.key, this.name = 'GL', this.size = 36, this.color});

  @override
  Widget build(BuildContext context) {
    final initials = name.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).take(2).map((e) => e[0].toUpperCase()).join();
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: color ?? GeniusThemeData.blue500, shape: BoxShape.circle),
      child: Text(initials.isEmpty ? 'GL' : initials, style: TextStyle(fontFamily: GeniusThemeData.displayFont, fontSize: size * 0.36, fontWeight: FontWeight.w800, color: Colors.white)),
    );
  }
}

class GLCard extends StatelessWidget {
  final Widget child;
  final double padding;
  final bool elevated;
  final Color? color;
  final EdgeInsetsGeometry? margin;
  const GLCard({super.key, required this.child, this.padding = 16, this.elevated = false, this.color, this.margin});

  @override
  Widget build(BuildContext context) {
    final s = GeniusThemeData.of(context);
    return Container(
      margin: margin,
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: color ?? s.surface,
        border: Border.all(color: s.border),
        borderRadius: BorderRadius.circular(GeniusThemeData.radiusLg),
        boxShadow: elevated ? GeniusThemeData.cardShadow : null,
      ),
      child: child,
    );
  }
}

class GLListTile extends StatelessWidget {
  final String? icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Widget? avatar;
  final VoidCallback? onTap;
  const GLListTile({super.key, this.icon, required this.title, this.subtitle, this.trailing, this.avatar, this.onTap});

  @override
  Widget build(BuildContext context) {
    final s = GeniusThemeData.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(GeniusThemeData.radiusMd),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(children: [
          avatar ?? (icon == null ? const SizedBox.shrink() : GLIcon(icon!, size: 18, color: GeniusThemeData.blue500)),
          if (icon != null || avatar != null) const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: TextStyle(fontFamily: GeniusThemeData.bodyFont, fontSize: 13.5, fontWeight: FontWeight.w700, color: s.fg1)),
              if (subtitle != null) ...[
                const SizedBox(height: 3),
                Text(subtitle!, style: TextStyle(fontFamily: GeniusThemeData.bodyFont, fontSize: 12, height: 1.35, color: s.fg3)),
              ],
            ]),
          ),
          if (trailing != null) ...[const SizedBox(width: 10), trailing!],
        ]),
      ),
    );
  }
}

class GLDivider extends StatelessWidget {
  final double height;
  const GLDivider({super.key, this.height = 1});
  @override
  Widget build(BuildContext context) => Container(height: height, color: GeniusThemeData.of(context).border);
}

class GLStateView extends StatelessWidget {
  final String icon;
  final String title;
  final String body;
  final String? actionLabel;
  final VoidCallback? onAction;
  final GLStateTone tone;
  const GLStateView({super.key, required this.icon, required this.title, required this.body, this.actionLabel, this.onAction, this.tone = GLStateTone.neutral});

  @override
  Widget build(BuildContext context) {
    final s = GeniusThemeData.of(context);
    final c = glToneColor(context, _toneName(tone));
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 54, height: 54, alignment: Alignment.center, decoration: BoxDecoration(color: c.withOpacity(0.12), shape: BoxShape.circle), child: GLIcon(icon, size: 26, color: c)),
          const SizedBox(height: 14),
          Text(title, textAlign: TextAlign.center, style: TextStyle(fontFamily: GeniusThemeData.displayFont, fontSize: 18, fontWeight: FontWeight.w800, color: s.fg1)),
          const SizedBox(height: 8),
          Text(body, textAlign: TextAlign.center, style: TextStyle(fontFamily: GeniusThemeData.bodyFont, fontSize: 13.5, height: 1.5, color: s.fg3)),
          if (actionLabel != null) ...[
            const SizedBox(height: 16),
            GLButton(label: actionLabel, icon: 'plus', onPressed: onAction),
          ],
        ]),
      ),
    );
  }
}

class GLSnackbar extends StatelessWidget {
  final GLStateTone tone;
  final String icon;
  final String text;
  final Widget? action;
  const GLSnackbar({super.key, this.tone = GLStateTone.info, required this.icon, required this.text, this.action});

  @override
  Widget build(BuildContext context) {
    final s = GeniusThemeData.of(context);
    final c = glToneColor(context, _toneName(tone));
    return GLCard(
      padding: 12,
      child: Row(children: [
        GLIcon(icon, color: c, size: 18),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: TextStyle(fontFamily: GeniusThemeData.bodyFont, fontSize: 13, fontWeight: FontWeight.w600, color: s.fg1))),
        if (action != null) action!,
      ]),
    );
  }
}

class GLDialogCard extends StatelessWidget {
  final String title;
  final String body;
  final String confirmLabel;
  final String cancelLabel;
  final bool danger;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;
  const GLDialogCard({super.key, required this.title, required this.body, this.confirmLabel = 'Confirm', this.cancelLabel = 'Cancel', this.danger = false, this.onConfirm, this.onCancel});

  @override
  Widget build(BuildContext context) {
    final s = GeniusThemeData.of(context);
    return GLCard(
      padding: 0,
      elevated: true,
      child: SizedBox(
        width: 360,
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: TextStyle(fontFamily: GeniusThemeData.displayFont, fontSize: 16, fontWeight: FontWeight.w800, color: s.fg1)),
              const SizedBox(height: 8),
              Text(body, style: TextStyle(fontFamily: GeniusThemeData.bodyFont, fontSize: 13, height: 1.5, color: s.fg3)),
            ]),
          ),
          const GLDivider(),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              GLButton(label: cancelLabel, variant: GLButtonVariant.secondary, size: GLButtonSize.sm, onPressed: onCancel),
              const SizedBox(width: 8),
              GLButton(label: confirmLabel, icon: danger ? 'trash' : 'check', variant: danger ? GLButtonVariant.danger : GLButtonVariant.primary, size: GLButtonSize.sm, onPressed: onConfirm),
            ]),
          ),
        ]),
      ),
    );
  }
}

class GLMiniAppBar extends StatelessWidget {
  final String title;
  final List<Widget> actions;
  const GLMiniAppBar({super.key, required this.title, this.actions = const []});

  @override
  Widget build(BuildContext context) {
    final s = GeniusThemeData.of(context);
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(color: s.surface, border: Border(bottom: BorderSide(color: s.border))),
      child: Row(children: [
        const GLIcon('menu', size: 18),
        const SizedBox(width: 12),
        Expanded(child: Text(title, style: TextStyle(fontFamily: GeniusThemeData.displayFont, fontSize: 15, fontWeight: FontWeight.w800, color: s.fg1))),
        ...actions,
      ]),
    );
  }
}

class GLMiniNav extends StatelessWidget {
  final List<String> items;
  final int selectedIndex;
  final ValueChanged<int>? onSelected;
  const GLMiniNav({super.key, this.items = const ['Dashboard', 'Ledger', 'Reports'], this.selectedIndex = 0, this.onSelected});

  @override
  Widget build(BuildContext context) {
    final s = GeniusThemeData.of(context);
    return GLCard(
      padding: 8,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < items.length; i++)
            InkWell(
              onTap: () => onSelected?.call(i),
              borderRadius: BorderRadius.circular(GeniusThemeData.radiusMd),
              child: Container(
                height: 38,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(color: i == selectedIndex ? GeniusThemeData.blue500.withOpacity(0.13) : Colors.transparent, borderRadius: BorderRadius.circular(GeniusThemeData.radiusMd)),
                child: Row(children: [
                  GLIcon(i == 0 ? 'home' : i == 1 ? 'book' : 'chart', size: 16, color: i == selectedIndex ? GeniusThemeData.blue500 : s.fg3),
                  const SizedBox(width: 9),
                  Text(items[i], style: TextStyle(fontFamily: GeniusThemeData.bodyFont, fontSize: 13, fontWeight: FontWeight.w700, color: i == selectedIndex ? GeniusThemeData.blue500 : s.fg2)),
                ]),
              ),
            ),
        ],
      ),
    );
  }
}

class GLMenuList extends StatelessWidget {
  final List<GLMenuItem> items;
  const GLMenuList({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    final s = GeniusThemeData.of(context);
    return GLCard(
      padding: 6,
      elevated: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final item in items)
            InkWell(
              onTap: item.onTap,
              borderRadius: BorderRadius.circular(GeniusThemeData.radiusSm),
              child: Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(children: [
                  GLIcon(item.icon, size: 16, color: item.danger ? GeniusThemeData.danger500 : s.fg2),
                  const SizedBox(width: 9),
                  Expanded(child: Text(item.label, style: TextStyle(fontFamily: GeniusThemeData.bodyFont, fontSize: 13, fontWeight: FontWeight.w600, color: item.danger ? GeniusThemeData.danger500 : s.fg1))),
                ]),
              ),
            ),
        ],
      ),
    );
  }
}

class GLMenuItem {
  final String icon;
  final String label;
  final bool danger;
  final VoidCallback? onTap;
  const GLMenuItem({required this.icon, required this.label, this.danger = false, this.onTap});
}

class GLShell extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Widget> children;
  final double maxWidth;
  final Widget? trailing;
  const GLShell({super.key, required this.title, required this.subtitle, required this.children, this.maxWidth = GeniusThemeData.contentWide, this.trailing});

  @override
  Widget build(BuildContext context) {
    final s = GeniusThemeData.of(context);
    return Scaffold(
      backgroundColor: s.bg,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
              children: [
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('GENIUSLINK DESIGN SYSTEM', style: TextStyle(fontFamily: GeniusThemeData.bodyFont, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.65, color: GeniusThemeData.blue500)),
                      const SizedBox(height: 10),
                      Text(title, style: TextStyle(fontFamily: GeniusThemeData.displayFont, fontSize: 30, fontWeight: FontWeight.w800, letterSpacing: -0.7, color: s.fg1)),
                      const SizedBox(height: 6),
                      Text(subtitle, style: TextStyle(fontFamily: GeniusThemeData.bodyFont, fontSize: 14, color: s.fg3)),
                    ]),
                  ),
                  if (trailing != null) trailing!,
                ]),
                const SizedBox(height: 32),
                for (final c in children) ...[c, const SizedBox(height: 40)],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class GLSection extends StatelessWidget {
  final String title;
  final String? description;
  final List<Widget>? children;
  final Widget? child;
  final int minTileWidth;
  const GLSection({super.key, required this.title, this.description, this.children, this.child, this.minTileWidth = 240});

  @override
  Widget build(BuildContext context) {
    final s = GeniusThemeData.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(width: 4, height: 22, decoration: BoxDecoration(color: GeniusThemeData.blue500, borderRadius: BorderRadius.circular(GeniusThemeData.radiusPill))),
        const SizedBox(width: 12),
        Text(title, style: TextStyle(fontFamily: GeniusThemeData.bodyFont, fontSize: 16, fontWeight: FontWeight.w800, color: s.fg1)),
      ]),
      if (description != null) ...[
        const SizedBox(height: 8),
        Text(description!, style: TextStyle(fontFamily: GeniusThemeData.bodyFont, fontSize: 13, height: 1.55, color: s.fg3)),
      ],
      const SizedBox(height: 18),
      if (child != null)
        child!
      else
        LayoutBuilder(builder: (context, c) {
          final columns = (c.maxWidth / minTileWidth).floor().clamp(1, 4).toInt();
          return GridView.count(
            crossAxisCount: columns,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.35,
            children: children ?? const [],
          );
        }),
    ]);
  }
}

class GLSpec extends StatelessWidget {
  final String label;
  final Widget child;
  const GLSpec({super.key, required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    final s = GeniusThemeData.of(context);
    return GLCard(
      padding: 18,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label.toUpperCase(), style: const TextStyle(fontFamily: GeniusThemeData.monoFont, fontSize: 10.5, fontWeight: FontWeight.w800, letterSpacing: 0.8, color: GeniusThemeData.blue500)),
        const SizedBox(height: 12),
        Expanded(child: DefaultTextStyle.merge(style: TextStyle(color: s.fg1), child: child)),
      ]),
    );
  }
}
