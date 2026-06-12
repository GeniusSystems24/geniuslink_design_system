<!--
  ChatGPT Codex skills · GeniusLink Design System (Flutter)
  Read the matching component AGENTS.md before writing or editing code that uses
  that component. This file is the shared setup that applies to all of them.
-->

# GeniusLink Design System — ChatGPT Codex skills

Per-component how-to-use guides for the `geniuslink_design_system` Flutter
package. Each subfolder holds one component's `AGENTS.md` — the authoritative
guide to its import, theme setup, quick start, model, controller API, options,
keyboard, and gotchas. Open the relevant one before generating Flutter code that
touches that component, and follow its patterns exactly.

| Folder | Component | Use it for |
|---|---|---|
| `editable_table/` | **EditableTable** | Excel-style data entry, typed columns, validation, totals, copy/paste, undo |
| `readable_table/` | **ReadableTable** | Read-only typed display grid: selection, sort, filtering (chips / nested / column) |
| `tree/` | **Tree** | Hierarchical outline / explorer: selection, rename, search, checkboxes |
| `browser_style_tab_bar/` | **BrowserStyleTabBar** | Workspace tab strip: pin / dirty / reorder / previews, state-preserving pages |
| `navigation_sidebar/` | **NavigationSidebar** | App left-nav: expanded / rail / drawer, badges, shortcuts |
| `auto_suggestions_box/` | **AutoSuggestionsBox** | Auto-suggest / combo field: static / async / hybrid, multi-select |

## Shared setup (applies to every component)

**Import.** One unified barrel re-exports everything; each component also ships a
leaner barrel:

```dart
import 'package:geniuslink_design_system/geniuslink_design_system.dart'; // everything
// …or per component, e.g. geniuslink_tree.dart / geniuslink_readable_table.dart
```

**Always register the theme extensions you use.** Each falls back to its `.dark`
preset if missing — a forgotten registration is the most common rendering bug:

```dart
MaterialApp(
  theme: ThemeData(extensions: const [
    EditableTableThemeData.light,        // also styles ReadableTable
    TreeThemeData.light, NavigationSidebarThemeData.light,
    BrowserStyleTabBarThemeData.light, AutoSuggestionsBoxThemeData.light,
  ]),
  darkTheme: ThemeData(extensions: const [
    EditableTableThemeData.dark, TreeThemeData.dark, NavigationSidebarThemeData.dark,
    BrowserStyleTabBarThemeData.dark, AutoSuggestionsBoxThemeData.dark,
  ]),
);
```

**Architecture contract.** Model → Controller → View → Theme: immutable data, a
`ChangeNotifier` controller as the single source of truth, a thin view that
forwards every gesture/keystroke, and a `ThemeExtension`. Controllers are exposed
to descendant widgets via a scope — `<Component>Controller.of<T>(context)` — so
page/cell code can drive the component without prop-drilling.

**Data or controller, never both.** Each widget accepts inline data (it owns a
controller) or an external `controller:`. Use a `controller:` whenever you need
to drive/observe it or to enable controller-resident modes (Tree multi-select,
table selection modes).

**RTL.** Wrap any component in
`Directionality(textDirection: TextDirection.rtl, child: …)`; all chrome mirrors.

**Brand tokens.** blue `#4A7CFF` · green `#1DB88A` · orange `#F97316` · 4px radii
· 40px controls · fonts Manrope / Inter / JetBrainsMono.

## ⚠️ EditableTable: two barrels, same names

`geniuslink_editable_table.dart` (map-backed, `EditableRow = Map<String,String>`)
and `geniuslink_editable_table_generic.dart` (typed `EditableTable<T>`) both
declare `EditableTable` / `EditableColumn`. Import **exactly one per file**.

## Reference

- Package README: `../../README.md`
- Runnable demos: `../../example/lib/`
- Interactive galleries: `../../docs/components-*.html`
