// ============================================================
// GeniusLink Design System — Combo box.
// Source parity: components-combobox.html.
// Architecture: MVVM. GLComboBoxViewModel owns query/open/selection/loading.
// ============================================================

import 'package:flutter/material.dart';
import '../../tokens.dart';
import '../core/core_components.dart';

class GLComboOption<T> {
  final T value;
  final String label;
  final String? subtitle;
  final String? icon;
  const GLComboOption({required this.value, required this.label, this.subtitle, this.icon});
}

class GLComboBoxViewModel<T> extends ChangeNotifier {
  GLComboBoxViewModel({List<GLComboOption<T>> options = const [], T? selectedValue, Iterable<T> selectedValues = const [], this.multi = false})
      : _options = [...options],
        _selectedValue = selectedValue,
        _selectedValues = {...selectedValues};

  final bool multi;
  List<GLComboOption<T>> _options;
  T? _selectedValue;
  final Set<T> _selectedValues;
  String _query = '';
  bool _open = false;
  bool _loading = false;
  String? _error;

  List<GLComboOption<T>> get options => List.unmodifiable(_options);
  T? get selectedValue => _selectedValue;
  Set<T> get selectedValues => Set.unmodifiable(_selectedValues);
  String get query => _query;
  bool get open => _open;
  bool get loading => _loading;
  String? get error => _error;

  List<GLComboOption<T>> get filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return options;
    return _options.where((o) => o.label.toLowerCase().contains(q) || (o.subtitle ?? '').toLowerCase().contains(q)).toList();
  }

  GLComboOption<T>? get selectedOption {
    for (final o in _options) {
      if (o.value == _selectedValue) return o;
    }
    return null;
  }

  void setOptions(List<GLComboOption<T>> value) {
    _options = [...value];
    notifyListeners();
  }

  void setOpen(bool value) {
    if (_open == value) return;
    _open = value;
    notifyListeners();
  }

  void toggleOpen() => setOpen(!_open);

  void setQuery(String value) {
    if (_query == value) return;
    _query = value;
    notifyListeners();
  }

  void setLoading(bool value) {
    if (_loading == value) return;
    _loading = value;
    notifyListeners();
  }

  void setError(String? value) {
    if (_error == value) return;
    _error = value;
    notifyListeners();
  }

  void select(GLComboOption<T> option) {
    if (multi) {
      if (_selectedValues.contains(option.value)) {
        _selectedValues.remove(option.value);
      } else {
        _selectedValues.add(option.value);
      }
    } else {
      _selectedValue = option.value;
      _open = false;
    }
    notifyListeners();
  }

  void clear() {
    _selectedValue = null;
    _selectedValues.clear();
    _query = '';
    notifyListeners();
  }
}

class GLComboBox<T> extends StatefulWidget {
  final List<GLComboOption<T>> options;
  final GLComboBoxViewModel<T>? viewModel;
  final bool multi;
  final bool enabled;
  final bool searchable;
  final String placeholder;
  final String? label;
  final String? icon;
  final ValueChanged<T?>? onChanged;
  final ValueChanged<Set<T>>? onMultiChanged;
  final Future<List<GLComboOption<T>>> Function(String query)? asyncLoader;

  const GLComboBox({
    super.key,
    this.options = const [],
    this.viewModel,
    this.multi = false,
    this.enabled = true,
    this.searchable = true,
    this.placeholder = 'Select option…',
    this.label,
    this.icon,
    this.onChanged,
    this.onMultiChanged,
    this.asyncLoader,
  });

  @override
  State<GLComboBox<T>> createState() => _GLComboBoxState<T>();
}

class _GLComboBoxState<T> extends State<GLComboBox<T>> {
  late GLComboBoxViewModel<T> _vm;
  late bool _owns;
  final _queryController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _vm = widget.viewModel ?? GLComboBoxViewModel<T>(options: widget.options, multi: widget.multi);
    _owns = widget.viewModel == null;
    _vm.addListener(_onVm);
  }

  @override
  void didUpdateWidget(covariant GLComboBox<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.viewModel != oldWidget.viewModel) {
      _vm.removeListener(_onVm);
      if (_owns) _vm.dispose();
      _vm = widget.viewModel ?? GLComboBoxViewModel<T>(options: widget.options, multi: widget.multi);
      _owns = widget.viewModel == null;
      _vm.addListener(_onVm);
    } else if (_owns && widget.options != oldWidget.options) {
      _vm.setOptions(widget.options);
    }
  }

  void _onVm() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _vm.removeListener(_onVm);
    if (_owns) _vm.dispose();
    _queryController.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    _vm.setQuery(query);
    if (widget.asyncLoader == null) return;
    _vm.setLoading(true);
    _vm.setError(null);
    try {
      final options = await widget.asyncLoader!(query);
      if (mounted) _vm.setOptions(options);
    } catch (_) {
      if (mounted) _vm.setError('Could not load options.');
    } finally {
      if (mounted) _vm.setLoading(false);
    }
  }

  void _select(GLComboOption<T> option) {
    _vm.select(option);
    if (widget.multi) {
      widget.onMultiChanged?.call(_vm.selectedValues);
    } else {
      widget.onChanged?.call(_vm.selectedValue);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = GeniusThemeData.of(context);
    final selectedText = widget.multi
        ? (_vm.selectedValues.isEmpty ? null : '${_vm.selectedValues.length} selected')
        : _vm.selectedOption?.label;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (widget.label != null) ...[
        Text(widget.label!, style: TextStyle(fontFamily: GeniusThemeData.bodyFont, fontSize: 12, fontWeight: FontWeight.w800, color: s.fg2)),
        const SizedBox(height: 6),
      ],
      Semantics(
        button: true,
        expanded: _vm.open,
        enabled: widget.enabled,
        child: InkWell(
          onTap: widget.enabled ? _vm.toggleOpen : null,
          borderRadius: BorderRadius.circular(GeniusThemeData.radiusSm),
          child: Container(
            constraints: const BoxConstraints(minHeight: 44),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(color: widget.enabled ? s.inputBg : s.inputBg.withOpacity(.45), border: Border.all(color: _vm.error == null ? s.border : GeniusThemeData.danger500), borderRadius: BorderRadius.circular(GeniusThemeData.radiusSm)),
            child: Row(children: [
              if (widget.icon != null) ...[GLIcon(widget.icon!, size: 17, color: s.fg3), const SizedBox(width: 8)],
              Expanded(child: Text(selectedText ?? widget.placeholder, style: TextStyle(fontFamily: GeniusThemeData.bodyFont, fontSize: 13.5, color: selectedText == null ? s.fg3 : s.fg1, fontWeight: FontWeight.w600))),
              if (_vm.loading) const GLSpinner(size: 16) else Icon(_vm.open ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded, color: s.fg3),
            ]),
          ),
        ),
      ),
      if (_vm.error != null) ...[
        const SizedBox(height: 6),
        Text(_vm.error!, style: const TextStyle(fontFamily: GeniusThemeData.bodyFont, fontSize: 12, color: GeniusThemeData.danger500)),
      ],
      AnimatedSwitcher(
        duration: GeniusThemeData.durModerate,
        child: !_vm.open
            ? const SizedBox.shrink()
            : Padding(
                key: const ValueKey('dropdown'),
                padding: const EdgeInsets.only(top: 8),
                child: GLCard(
                  padding: 6,
                  elevated: true,
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    if (widget.searchable) ...[
                      GLSearchField(placeholder: 'Search options…', controller: _queryController, onChanged: _search),
                      const SizedBox(height: 6),
                    ],
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 260),
                      child: SingleChildScrollView(
                        child: Column(children: [
                          if (_vm.loading)
                            const Padding(padding: EdgeInsets.all(18), child: GLSpinner())
                          else if (_vm.filtered.isEmpty)
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: GLStateView(icon: 'search', title: 'No matching options', body: 'Refine the search term or create a new option.', tone: GLStateTone.neutral),
                            )
                          else
                            for (final option in _vm.filtered) _ComboOptionRow<T>(option: option, selected: widget.multi ? _vm.selectedValues.contains(option.value) : _vm.selectedValue == option.value, multi: widget.multi, onTap: () => _select(option)),
                        ]),
                      ),
                    ),
                  ]),
                ),
              ),
      ),
    ]);
  }
}

class _ComboOptionRow<T> extends StatelessWidget {
  final GLComboOption<T> option;
  final bool selected;
  final bool multi;
  final VoidCallback onTap;
  const _ComboOptionRow({required this.option, required this.selected, required this.multi, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final s = GeniusThemeData.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(GeniusThemeData.radiusSm),
      child: Container(
        constraints: BoxConstraints(minHeight: 42),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(color: selected ? GeniusThemeData.blue500.withOpacity(.12) : Colors.transparent, borderRadius: BorderRadius.circular(GeniusThemeData.radiusSm)),
        child: Row(children: [
          if (option.icon != null) ...[GLIcon(option.icon!, size: 17, color: selected ? GeniusThemeData.blue500 : s.fg3), const SizedBox(width: 9)],
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(option.label, style: TextStyle(fontFamily: GeniusThemeData.bodyFont, fontSize: 13, fontWeight: FontWeight.w800, color: selected ? GeniusThemeData.blue500 : s.fg1)),
            if (option.subtitle != null) Text(option.subtitle!, style: TextStyle(fontFamily: GeniusThemeData.bodyFont, fontSize: 11.5, color: s.fg3)),
          ])),
          if (multi)
            Checkbox(value: selected, onChanged: (_) => onTap(), activeColor: GeniusThemeData.blue500)
          else if (selected)
            const GLIcon('check', size: 17, color: GeniusThemeData.blue500),
        ]),
      ),
    );
  }
}
