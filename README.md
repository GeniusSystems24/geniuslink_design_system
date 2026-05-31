# GeniusLink Design System Flutter

A Flutter design-system package for the GeniusLink foundations, core UI primitives, domain widgets, charts, skeletons, ComboBox, TrinaGrid-backed editable tables, reusable patterns, token-driven motion, and browser-style workspace tabs.

This package now covers the component groups in `genius_design_system_web/design_system` while keeping Flutter source code native. HTML snippets from the web project are documented only in `index.md`; they are not embedded in Flutter widgets.

## Current version

`1.2.2`

## What is included

| Group | Main Flutter file |
|---|---|
| Foundations and theme | `lib/design_system/tokens.dart`, `lib/design_system/app_theme.dart` |
| Core components | `lib/design_system/components/core/core_components.dart` |
| Domain components | `lib/design_system/components/domain/domain_components.dart` |
| Charts | `lib/design_system/components/charts/chart_components.dart` |
| Skeleton loaders | `lib/design_system/components/skeletons/skeleton_components.dart` |
| ComboBox | `lib/design_system/components/forms/combo_box.dart` (`smart_auto_suggest_box`) |
| Editable table | `lib/design_system/components/data/editable_table.dart` (`trina_grid`) |
| Patterns | `lib/design_system/components/patterns/design_patterns.dart` |
| Motion | `lib/design_system/components/motion/motion_components.dart` |
| Browser tabs | `lib/design_system/components/navigation/*` |

The full public index is in [`index.md`](index.md). The stage plan and completion checklist are in [`progress.md`](progress.md).

## Import

```dart
import 'package:geniuslink_design_system/geniuslink_design_system.dart';
```

## Theme setup

```dart
MaterialApp(
  theme: GeniusAppTheme.light(),
  darkTheme: GeniusAppTheme.dark(),
  localizationsDelegates: const [
    SmartAutoSuggestBoxLocalizations.delegate,
    // GlobalMaterialLocalizations.delegate,
    // GlobalWidgetsLocalizations.delegate,
    // GlobalCupertinoLocalizations.delegate,
  ],
  supportedLocales: SmartAutoSuggestBoxLocalizations.delegate.supportedLocales,
  home: const AllComponentsDemo(),
);
```

`GeniusAppTheme` registers both the new `GeniusThemeData` extension and an adapter for the existing `BrowserStyleTabBarThemeData`. ComboBox uses `smart_auto_suggest_box`, so apps that want its built-in localized strings should register `SmartAutoSuggestBoxLocalizations.delegate` in `MaterialApp`.

## Quick examples

### Core button

```dart
GLButton(
  label: 'Create Store',
  icon: 'plus',
  onPressed: () {},
)
```

### State view

```dart
const GLStateView(
  icon: 'poll',
  title: 'No entries yet',
  body: 'Posted journal entries will appear here.',
  actionLabel: 'Create Entry',
)
```

### ComboBox with MVVM view model backed by smart_auto_suggest_box

```dart
final accounts = GLComboBoxViewModel<String>(options: const [
  GLComboOption(value: '1010', label: 'Cash on hand', subtitle: 'Current assets'),
  GLComboOption(value: '4100', label: 'Sales revenue', subtitle: 'Revenue'),
]);

GLComboBox<String>(
  label: 'Account',
  viewModel: accounts,
  icon: 'book',
  asyncLoader: (query) async => accounts.options
      .where((option) => option.label.toLowerCase().contains(query.toLowerCase()))
      .toList(),
)
```

The public `GLComboBox` API remains design-system friendly, while the overlay, keyboard navigation, async debounce, highlighting, and multi-select chips are delegated to `smart_auto_suggest_box`.

### Editable table

`GLEditableTable` is a GeniusLink MVVM wrapper over `trina_grid`. Keep your app state in `GLTableController`, define columns with `GLTableColumn`, and let TrinaGrid handle keyboard navigation, inline editing, row checks, filters, sorting, resizing, and typed editors.

```dart
final controller = GLTableController(rows: glSampleRows());

GLEditableTable(
  controller: controller,
  columns: glSampleColumns(),
  showFilters: true,
  onCellChanged: (change) {
    debugPrint('Updated ${change.rowId}.${change.columnKey}: ${change.value}');
  },
)
```

### Chart

```dart
const GLChartFrame(
  title: 'Revenue trend',
  legend: [GLChartLegendItem(label: 'Revenue', color: GeniusThemeData.blue500)],
  child: GLLineAreaChart(),
)
```

### Browser-style tabs

```dart
BrowserStyleTabBar(
  tabsState: [
    BrowserTab(id: 1, title: 'Chart of Accounts', kind: GLTabKind.ledger, pinned: true),
    BrowserTab(id: 2, title: 'Opening Journal Entry', kind: GLTabKind.doc, dirty: true),
    BrowserTab(id: 3, title: 'Dashboard', kind: GLTabKind.chart),
  ],
)
```

## Example app

Run the example launcher:

```bash
cd example
flutter pub get
flutter run -d chrome
```

The launcher includes the existing ERP, Figma-style, Chrome-style, and browser-tab documentation demos, plus a **Full Component Gallery** for all component groups added in version `1.2.0`.

Individual example files are under:

```text
example/lib/components/
```

## Architecture

- **MVVM**: ComboBox, TrinaGrid-backed editable table, browser tab controller, and externally driven state surfaces.
- **MVC**: Chart models passed to Flutter `CustomPainter` views.
- **MVVM-C**: Browser tab strip uses a controller to coordinate tab state, overlays, selection, and previews.
- **Composition**: Patterns are assembled from canonical core/domain components.

## Notes

- No HTML is used inside Flutter source files.
- Theme values should come from `GeniusThemeData`, `GeniusAppTheme`, or the existing `BrowserStyleTabBarThemeData` adapter.
- `smart_auto_suggest_box` 0.15.x requires Dart `>=3.10.0`, so the package SDK constraint was raised accordingly.
- `trina_grid: ^2.2.2` powers `GLEditableTable`; use the GeniusLink wrapper for token styling and state synchronization, and pass `TrinaGridConfiguration` only for advanced overrides.
- The sandbox used for this update does not include Flutter/Dart tooling, so `flutter pub get`, `flutter analyze`, and `flutter test` could not be executed here. Run them locally before publishing.
