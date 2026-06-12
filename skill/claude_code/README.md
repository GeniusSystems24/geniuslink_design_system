# GeniusLink Design System — Claude Code skills

Per-component how-to-use skills for the `geniuslink_design_system` Flutter
package. Each subfolder is a self-contained skill (`SKILL.md`) describing one
component's import, theme setup, quick start, model, controller API, options,
keyboard, gotchas, and reference files.

| Skill | Component | Use it for |
|---|---|---|
| [`editable_table/`](editable_table/SKILL.md) | **EditableTable** | Excel-style data entry, typed columns, validation, totals, copy/paste, undo |
| [`readable_table/`](readable_table/SKILL.md) | **ReadableTable** | Read-only typed display grid: selection, sort, filtering (chips / nested / column) |
| [`tree/`](tree/SKILL.md) | **Tree** | Hierarchical outline / explorer: selection, rename, search, checkboxes |
| [`browser_style_tab_bar/`](browser_style_tab_bar/SKILL.md) | **BrowserStyleTabBar** | Workspace tab strip: pin / dirty / reorder / previews, state-preserving pages |
| [`navigation_sidebar/`](navigation_sidebar/SKILL.md) | **NavigationSidebar** | App left-nav: expanded / rail / drawer, badges, shortcuts |
| [`auto_suggestions_box/`](auto_suggestions_box/SKILL.md) | **AutoSuggestionsBox** | Auto-suggest / combo field: static / async / hybrid, multi-select |

## Shared setup (read once)

**Install / import.** One unified barrel re-exports everything; each component
also ships a leaner barrel:

```dart
import 'package:geniuslink_design_system/geniuslink_design_system.dart'; // everything
// …or per component, e.g.:
import 'package:geniuslink_design_system/geniuslink_tree.dart';
```

**Register theme extensions** you use (each falls back to its `.dark` preset if
absent — a missing registration is the #1 "why does it look wrong" cause):

```dart
MaterialApp(
  theme: ThemeData(extensions: const [
    EditableTableThemeData.light,        // also styles ReadableTable
    TreeThemeData.light,
    NavigationSidebarThemeData.light,
    BrowserStyleTabBarThemeData.light,
    AutoSuggestionsBoxThemeData.light,
  ]),
  darkTheme: ThemeData(extensions: const [
    EditableTableThemeData.dark, TreeThemeData.dark,
    NavigationSidebarThemeData.dark, BrowserStyleTabBarThemeData.dark,
    AutoSuggestionsBoxThemeData.dark,
  ]),
);
```

**Architecture (all components).** Model → Controller → View → Theme: immutable
data, a `ChangeNotifier` controller as the single source of truth, a thin view
that forwards gestures/keys, and a `ThemeExtension`. Each controller is published
to descendants via a scope, so any child can drive it:
`<Component>Controller.of<T>(context)`.

**Provide data _or_ a controller.** Every component accepts either inline data
(it owns a controller) **or** an external `controller:` — never both data sources.
Pass a `controller:` whenever you need to drive/observe it, or to opt into modes
that live on the controller (Tree multi-select, table selection modes).

**RTL.** Wrap any component in
`Directionality(textDirection: TextDirection.rtl, child: …)` — strips, guides,
gutters, resize handles, and menus all mirror.

**Brand tokens.** blue `#4A7CFF` · green `#1DB88A` · orange `#F97316` · 4px radii
· 40px controls · fonts Manrope / Inter / JetBrainsMono. Tweak a preset with
`EditableTableThemeData.light.copyWith(surface: …)`.

## ⚠️ EditableTable: two barrels, same names

`geniuslink_editable_table.dart` (map-backed, `EditableRow = Map<String,String>`)
and `geniuslink_editable_table_generic.dart` (typed `EditableTable<T>`) both
declare `EditableTable` / `EditableColumn`. **Import exactly one per file.**

## Reference

- Package README: `../../README.md`
- Runnable demos: `../../example/lib/`
- Interactive galleries: `../../docs/components-*.html`
