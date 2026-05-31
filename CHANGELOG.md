# Changelog

## 1.2.2

> 2026-05-31

- Migrated `GLEditableTable` to use `trina_grid: ^2.2.2` for data-grid rendering, inline editing, keyboard navigation, row checking, filtering, sorting, and column resizing.
- Preserved the design-system MVVM API with `GLTableColumn`, `GLTableRowModel`, `GLTableController`, and added `GLTableCellChange` for edit callbacks.
- Added typed table column semantics for text, number, currency, percentage, select, boolean, date, and time editors, mapped to TrinaGrid column types.
- Updated the table example with add/delete-selected actions, filters, selection, typed currency/select columns, and edit-change feedback.
- Re-exported selected TrinaGrid configuration classes for advanced consumers while keeping GeniusLink wrappers as the default public API.

## 1.2.1

> 2026-05-31

- Migrated `GLComboBox` to use `smart_auto_suggest_box: ^0.15.3` for single-select overlays, multi-select chips, async search debounce, keyboard navigation, and highlighted matches.
- Preserved the design-system wrapper API (`GLComboOption`, `GLComboBoxViewModel`, `GLComboBox`) while delegating suggestion mechanics to `SmartAutoSuggestBox` and `SmartAutoSuggestMultiSelectBox`.
- Added `SmartAutoSuggestBoxLocalizations` / `SmartAutoSuggestTheme` re-exports for app setup and updated the example app localization delegates.
- Raised the Dart SDK constraint to `>=3.10.0` to match the selected `smart_auto_suggest_box` 0.15.x release line.

## 1.2.0

> 2026-05-31

- Completed the Flutter parity stage for `genius_design_system_web/design_system`.
- Added `index.md` as the public component and tool index for the Flutter package.
- Added `progress.md` with the stage plan, source inventory, completion checklist, and release checkpoints.
- Added the full example gallery under `example/lib/components` and linked it from the example launcher.
- Updated public barrel exports so all new components are importable from `package:geniuslink_design_system/geniuslink_design_system.dart`.
- Kept HTML snippets limited to Markdown documentation; no HTML was embedded into Flutter source code.

## 1.1.9

> 2026-05-31

- Added motion components from `motion.html`: `GLPressable`, `GLMotionTokenRow`, `GLMotionTokensView`, `GLStaggeredList`, and `GLShimmerDemo`.
- Centralized motion behavior around `GeniusThemeData` duration and easing tokens.

## 1.1.8

> 2026-05-31

- Added reusable patterns from `patterns.html`: search/filter, pagination, confirmation, permission request, upload, message status, offline sync, and notification navigation.

## 1.1.7

> 2026-05-31

- Added editable table models and MVVM controller: `GLTableColumn`, `GLTableRowModel`, and `GLTableController`.
- Added `GLEditableTable`, responsive mobile data cards, table states, sorting, selection, and inline editing.

## 1.1.6

> 2026-05-31

- Added `GLComboOption`, `GLComboBoxViewModel`, and `GLComboBox`.
- Added single-select, multi-select, searchable, async, loading, empty, and error-ready ComboBox behavior.

## 1.1.5

> 2026-05-31

- Added skeleton components: base bone, text, avatar, card, list, table, chat, dashboard card, and chart skeletons.
- Added shimmer, pulse, and still skeleton modes.

## 1.1.4

> 2026-05-31

- Added chart components: chart frame, legend, line/area chart, bar chart, donut chart, progress ring, KPI sparkline, and chart states.
- Implemented chart drawings with Flutter `CustomPainter` rather than HTML/SVG snippets.

## 1.1.3

> 2026-05-31

- Added domain components: message status ticks, message bubbles, composer, attachment menu, audio/video/poll/media surfaces, pinned bar, notification tile, file card, club card, member tile, task card, and room card.

## 1.1.2

> 2026-05-31

- Added core components based on `ds-kit.jsx` and `components-core.html`: icons, buttons, icon buttons, spinner, fields, search, pills, badges, chips, avatars, cards, list tiles, dividers, state views, snackbar, dialog, mini app bar, mini nav, menu list, shell, section, and spec cards.

## 1.1.1

> 2026-05-31

- Added Flutter foundation tokens and app theme helpers: `GeniusThemeData` and `GeniusAppTheme`.
- Added a bridge from `GeniusThemeData` to the existing `BrowserStyleTabBarThemeData` so browser tabs and new components can share themes.

## 1.1.0

> 2026-05-30

- Added `BrowserStyleTabBarController` as the public `ChangeNotifier` state API for externally controlled tab selection, creation, closing, pinning, reordering, dirty flags, renaming, and arbitrary tab mutations.
- Added `pageBuilder` support so hosts can render custom per-tab content in the active surface and hover previews while keeping the built-in `GLTabPage` fallback.
- Added live page thumbnail support backed by captured page frames, so hover previews can reflect current page state instead of static placeholder content.
- Expanded the example app into a launcher with ERP, Figma-style editor, Chrome-style browser, and documentation demos that all host the same tab component.
- Updated the public barrel exports and README documentation for the controller, custom page builders, live thumbnails, feature parity, and implementation map.

## 1.0.1

> 2026-05-30

- Updated README snapshot links to use absolute GitHub raw URLs so they render on pub.dev.
- Added pub.dev `screenshots` metadata for the package gallery.
- Expanded README documentation for the example launcher, controller-driven state, custom page builders, live thumbnails, implementation map, and public API.
- Removed direct references to source web files from the public README.

## 1.0.0

> 2026-05-30

- Initial release of the GeniusLink browser-style tab strip package.
- Added `BrowserStyleTabBar` with pinned tabs, dirty-state guards, context menus, tab-list dropdowns, hover previews, drag-to-reorder, keyboard navigation, light and dark themes, and RTL support.
- Added `BrowserStyleTabBarThemeData` as the self-contained theme extension for tab surfaces, text colors, semantic colors, radii, shadows, fonts, and motion.
- Added an example app that embeds the component in a realistic workspace shell and includes a documentation gallery.
