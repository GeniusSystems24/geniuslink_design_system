// ============================================================
// GeniusLink Design System — Combo box.
// Source parity: components-combobox.html.
// Architecture: MVVM wrapper around smart_auto_suggest_box.
//
// The view model owns the domain selection/options state, while
// smart_auto_suggest_box owns the optimized overlay, keyboard navigation,
// async search scheduling, and multi-select chip rendering.
// ============================================================

import 'package:flutter/material.dart';
import 'package:smart_auto_suggest_box/smart_auto_suggest_box.dart';

import '../../tokens.dart';
import '../core/core_components.dart';

class GLComboOption<T> {
  final T value;
  final String label;
  final String? subtitle;
  final String? icon;

  const GLComboOption({
    required this.value,
    required this.label,
    this.subtitle,
    this.icon,
  });
}

class GLComboBoxViewModel<T> extends ChangeNotifier {
  GLComboBoxViewModel({
    List<GLComboOption<T>> options = const [],
    T? selectedValue,
    Iterable<T> selectedValues = const [],
    this.multi = false,
  })  : _options = [...options],
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
    return _options
        .where((o) =>
            o.label.toLowerCase().contains(q) ||
            (o.subtitle ?? '').toLowerCase().contains(q))
        .toList();
  }

  GLComboOption<T>? get selectedOption => optionForValue(_selectedValue);

  GLComboOption<T>? optionForValue(T? value) {
    if (value == null) return null;
    for (final option in _options) {
      if (option.value == value) return option;
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

  void setSelectedValue(T? value) {
    if (_selectedValue == value) return;
    _selectedValue = value;
    notifyListeners();
  }

  void setSelectedValues(Iterable<T> values) {
    final next = values.toSet();
    if (_selectedValues.length == next.length &&
        _selectedValues.containsAll(next)) {
      return;
    }
    _selectedValues
      ..clear()
      ..addAll(next);
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
  final int maxVisibleChips;
  final int? maxSelections;
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
    this.maxVisibleChips = 3,
    this.maxSelections,
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
  late SmartAutoSuggestDataSource<T> _dataSource;
  late SmartAutoSuggestController<T> _singleController;
  late SmartAutoSuggestMultiSelectController<T> _multiController;
  int _dataSourceVersion = 0;

  @override
  void initState() {
    super.initState();
    _vm = widget.viewModel ??
        GLComboBoxViewModel<T>(options: widget.options, multi: widget.multi);
    _owns = widget.viewModel == null;
    _vm.addListener(_onVm);
    _singleController = SmartAutoSuggestController<T>();
    _multiController = SmartAutoSuggestMultiSelectController<T>();
    _dataSource = _createDataSource();
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncControllersFromVm());
  }

  @override
  void didUpdateWidget(covariant GLComboBox<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    var needsDataSourceRebuild = false;

    if (widget.viewModel != oldWidget.viewModel) {
      _vm.removeListener(_onVm);
      if (_owns) _vm.dispose();
      _vm = widget.viewModel ??
          GLComboBoxViewModel<T>(options: widget.options, multi: widget.multi);
      _owns = widget.viewModel == null;
      _vm.addListener(_onVm);
      needsDataSourceRebuild = true;
    } else if (_owns && widget.options != oldWidget.options) {
      _vm.setOptions(widget.options);
      needsDataSourceRebuild = true;
    }

    if (widget.asyncLoader != oldWidget.asyncLoader ||
        widget.multi != oldWidget.multi) {
      needsDataSourceRebuild = true;
    }

    if (needsDataSourceRebuild) {
      _rebuildDataSource();
      WidgetsBinding.instance.addPostFrameCallback((_) => _syncControllersFromVm());
    }
  }

  void _onVm() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _vm.removeListener(_onVm);
    if (_owns) _vm.dispose();
    _dataSource.dispose();
    _singleController.dispose();
    _multiController.dispose();
    super.dispose();
  }

  SmartAutoSuggestDataSource<T> _createDataSource() {
    return SmartAutoSuggestDataSource<T>(
      itemBuilder: (_, value) => _toSuggestItem(value),
      initialList: (_) => _vm.options.map((o) => o.value).toList(),
      onSearch: widget.asyncLoader == null
          ? null
          : (context, currentItems, searchText) async {
              final query = searchText ?? '';
              _vm.setQuery(query);
              _vm.setLoading(true);
              _vm.setError(null);
              try {
                final options = await widget.asyncLoader!(query);
                if (mounted) _vm.setOptions(options);
                return options.map((o) => o.value).toList();
              } catch (_) {
                if (mounted) _vm.setError('Could not load options.');
                rethrow;
              } finally {
                if (mounted) _vm.setLoading(false);
              }
            },
      searchMode: widget.asyncLoader == null
          ? SmartAutoSuggestSearchMode.onNoLocalResults
          : SmartAutoSuggestSearchMode.always,
      debounce: const Duration(milliseconds: 350),
    );
  }

  void _rebuildDataSource() {
    final old = _dataSource;
    _dataSource = _createDataSource();
    _dataSourceVersion++;
    old.dispose();
  }

  void _syncControllersFromVm() {
    if (!mounted) return;
    if (widget.multi) {
      _multiController.clearAll();
      for (final value in _vm.selectedValues) {
        final option = _vm.optionForValue(value);
        if (option != null) _multiController.select(_toSuggestItem(option.value));
      }
    } else {
      final option = _vm.selectedOption;
      if (option == null) {
        _singleController.clearSelection();
      } else {
        _singleController.select(_toSuggestItem(option.value));
      }
    }
  }

  SmartAutoSuggestItem<T> _toSuggestItem(T value) {
    final option = _vm.optionForValue(value) ??
        GLComboOption<T>(value: value, label: value.toString());
    return SmartAutoSuggestItem<T>(
      key: option.value.hashCode.toString(),
      value: option.value,
      label: option.label,
      semanticLabel: option.subtitle == null
          ? option.label
          : '${option.label}, ${option.subtitle}',
      subtitle: option.subtitle == null ? null : Text(option.subtitle!),
    );
  }

  InputDecoration _decoration(BuildContext context) {
    final s = GeniusThemeData.of(context);
    final radius = BorderRadius.circular(GeniusThemeData.radiusSm);
    final border = OutlineInputBorder(
      borderRadius: radius,
      borderSide: BorderSide(color: s.border),
    );
    return InputDecoration(
      labelText: widget.label,
      hintText: widget.placeholder,
      filled: true,
      fillColor: widget.enabled ? s.inputBg : s.inputBg.withOpacity(.45),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      prefixIcon: widget.icon == null
          ? null
          : SizedBox(
              width: 42,
              child: Center(child: GLIcon(widget.icon!, size: 17, color: s.fg3)),
            ),
      border: border,
      enabledBorder: border,
      disabledBorder: border.copyWith(
        borderSide: BorderSide(color: s.border.withOpacity(.55)),
      ),
      focusedBorder: border.copyWith(
        borderSide: const BorderSide(color: GeniusThemeData.blue500, width: 1.4),
      ),
      errorBorder: border.copyWith(
        borderSide: const BorderSide(color: GeniusThemeData.danger500),
      ),
      labelStyle: TextStyle(
        fontFamily: GeniusThemeData.bodyFont,
        fontSize: 12,
        fontWeight: FontWeight.w800,
        color: s.fg2,
      ),
      hintStyle: TextStyle(
        fontFamily: GeniusThemeData.bodyFont,
        fontSize: 13.5,
        color: s.fg3,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  SmartAutoSuggestTheme _suggestTheme(BuildContext context) {
    final s = GeniusThemeData.of(context);
    return SmartAutoSuggestTheme(
      overlayColor: s.surface,
      overlayCardColor: s.surface,
      overlayBorderRadius: BorderRadius.circular(GeniusThemeData.radiusMd),
      overlayShadows: GeniusThemeData.popShadow,
      overlayMargin: 6,
      tileColor: Colors.transparent,
      selectedTileColor: GeniusThemeData.blue500.withOpacity(.12),
      selectedTileTextColor: GeniusThemeData.blue500,
      tilePadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      tileSubtitleStyle: TextStyle(
        fontFamily: GeniusThemeData.bodyFont,
        fontSize: 11.5,
        color: s.fg3,
      ),
      noResultsSubtitleStyle: TextStyle(
        fontFamily: GeniusThemeData.bodyFont,
        fontSize: 12,
        color: s.fg3,
      ),
      loadingSubtitleStyle: TextStyle(
        fontFamily: GeniusThemeData.bodyFont,
        fontSize: 12,
        color: s.fg3,
      ),
      errorSubtitleStyle: const TextStyle(
        fontFamily: GeniusThemeData.bodyFont,
        fontSize: 12,
        color: GeniusThemeData.danger500,
      ),
      progressIndicatorColor: GeniusThemeData.blue500,
    );
  }

  Widget _suggestionTile(
    BuildContext context,
    SmartAutoSuggestItem<T> item,
    String? searchText,
    bool isFocused,
  ) {
    final s = GeniusThemeData.of(context);
    final option = _vm.optionForValue(item.value) ??
        GLComboOption<T>(value: item.value, label: item.label);
    return AnimatedContainer(
      duration: GeniusThemeData.durFast,
      minHeight: option.subtitle == null ? 42 : 54,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: isFocused ? GeniusThemeData.blue500.withOpacity(.10) : Colors.transparent,
        borderRadius: BorderRadius.circular(GeniusThemeData.radiusSm),
      ),
      child: Row(children: [
        if (option.icon != null) ...[
          GLIcon(
            option.icon!,
            size: 17,
            color: isFocused ? GeniusThemeData.blue500 : s.fg3,
          ),
          const SizedBox(width: 9),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SmartAutoSuggestHighlightText(
                text: option.label,
                query: searchText ?? '',
                baseStyle: TextStyle(
                  fontFamily: GeniusThemeData.bodyFont,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: isFocused ? GeniusThemeData.blue500 : s.fg1,
                ),
                matchStyle: const TextStyle(
                  fontFamily: GeniusThemeData.bodyFont,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: GeniusThemeData.blue500,
                ),
              ),
              if (option.subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  option.subtitle!,
                  style: TextStyle(
                    fontFamily: GeniusThemeData.bodyFont,
                    fontSize: 11.5,
                    color: s.fg3,
                  ),
                ),
              ],
            ],
          ),
        ),
      ]),
    );
  }

  Widget _noResults(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GLStateView(
        icon: 'search',
        title: 'No matching options',
        body: 'Refine the search term or create a new option.',
        tone: GLStateTone.neutral,
      ),
    );
  }

  Widget _loading(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(18),
      child: Center(child: GLSpinner()),
    );
  }

  Widget _chip(BuildContext context, SmartAutoSuggestItem<T> item, VoidCallback onRemove) {
    final s = GeniusThemeData.of(context);
    return InputChip(
      label: Text(
        item.label,
        style: TextStyle(
          fontFamily: GeniusThemeData.bodyFont,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: s.fg1,
        ),
      ),
      onDeleted: onRemove,
      backgroundColor: GeniusThemeData.blue500.withOpacity(.10),
      deleteIconColor: GeniusThemeData.blue500,
      side: BorderSide(color: GeniusThemeData.blue500.withOpacity(.20)),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(GeniusThemeData.radiusSm),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textStyle = TextStyle(
      fontFamily: GeniusThemeData.bodyFont,
      fontSize: 13.5,
      fontWeight: FontWeight.w600,
      color: GeniusThemeData.of(context).fg1,
    );

    final childKey = ValueKey('gl-combo-${widget.multi}-$_dataSourceVersion');

    if (widget.multi) {
      return SmartAutoSuggestMultiSelectBox<T>(
        key: childKey,
        smartController: _multiController,
        dataSource: _dataSource,
        decoration: _decoration(context),
        theme: _suggestTheme(context),
        enabled: widget.enabled,
        style: textStyle,
        tileHeight: 54,
        maxPopupHeight: 260,
        maxVisibleChips: widget.maxVisibleChips,
        maxSelections: widget.maxSelections,
        itemBuilder: _suggestionTile,
        chipBuilder: _chip,
        noResultsFoundBuilder: (context) => _noResults(context),
        waitingBuilder: _loading,
        clearButtonEnabled: true,
        direction: SmartAutoSuggestBoxDirection.bottom,
        overlayCardConstraints: const BoxConstraints(minWidth: 280, maxHeight: 320),
        onChanged: (text, _) => _vm.setQuery(text),
        onSelectionChanged: (items) {
          final values = items.map((item) => item.value).toSet();
          _vm.setSelectedValues(values);
          widget.onMultiChanged?.call(values);
        },
      );
    }

    return SmartAutoSuggestBox<T>(
      key: childKey,
      smartController: _singleController,
      dataSource: _dataSource,
      decoration: _decoration(context),
      theme: _suggestTheme(context),
      enabled: widget.enabled,
      style: textStyle,
      tileHeight: 54,
      maxPopupHeight: 260,
      itemBuilder: _suggestionTile,
      noResultsFoundBuilder: (context) => _noResults(context),
      waitingBuilder: _loading,
      clearButtonEnabled: true,
      direction: SmartAutoSuggestBoxDirection.bottom,
      overlayCardConstraints: const BoxConstraints(minWidth: 280, maxHeight: 320),
      trailingIcon: _vm.loading ? const GLSpinner(size: 16) : null,
      onChanged: (text, _) => _vm.setQuery(text),
      onSelected: (item) {
        _vm.setSelectedValue(item?.value);
        widget.onChanged?.call(item?.value);
      },
    );
  }
}
