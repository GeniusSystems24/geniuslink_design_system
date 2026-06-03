# Changelog

All notable changes to **geniuslink_design_system** (Flutter) are documented here.
This project adheres to [Semantic Versioning](https://semver.org).

---

## [2.1.0]

### ✨ Added

- **`ReadableTable`** — a read-only display grid that is the visual sibling of
  `EditableTable` (it reuses `EditableTableThemeData`, so header / hairline grid /
  surfaces / type ramp match exactly). It renders arbitrary **widget** cells
  (status pills, two-line bilingual text, progress bars, links…) with flexible or
  fixed column widths, optional header / zebra / hover / row-tap. New barrel
  `geniuslink_readable_table.dart`; re-exported from the unified barrel.
- **`BrowserStyleTabBar` shell options** (all optional, defaults unchanged):
  `showChrome`, `fillContent`, `contentPadding`, `scrollContent`,
  `contentBackground`, `onAddTab` — let the bar be embedded edge-to-edge as a
  full-window workspace shell that hosts full screens (vs. the standalone card).

---

## [2.0.1]

### 🔄 Changed — example

- **Tree demo rebuilt as “Account Tree.”** `example/lib/tree_demo.dart` now
  mirrors the GeniusLink web *Account Tree* tool: a five-level chart of accounts
  with KPI summary cards (Assets / Liabilities / Equity / Net Income), a recursive
  search that matches **code + English + Arabic** with live in-row highlighting and
  a match counter, colour-coded account-type filter chips, “Try” query chips,
  roll-up group balances with proportional share bars, DR / CR nature pills,
  leaf-count badges, an accounting-equation balance check (A = L + E) and a
  leaf-opens-ledger strip. State (expansion · selection · query) is still driven by
  the library's `TreeController`; rows are painted in an account-specific
  4-column layout via `TreeThemeData` (dark / light). The generic `Tree` widget and
  its MVC core are unchanged — only the demo was re-skinned.

---

## [2.0.0]

> 2026-06-02

A major release that grows the kit from a single component into a themeable,
MVC, three-component design system — and renames the package accordingly.

### ⚠️ Breaking changes

- **Package renamed** `geniuslink_browser_tabs` → **`geniuslink_design_system`**
  (version **1.0.0 → 2.0.0**). Update your imports:
  ```dart
  // before
  import 'package:geniuslink_browser_tabs/geniuslink_browser_tabs.dart';
  // after — unified barrel (everything)
  import 'package:geniuslink_design_system/geniuslink_design_system.dart';
  ```
- The project folder was renamed `flutter/` → **`geniuslink_design_system_flutter/`**.
- The example package is now `geniuslink_design_system_example` and depends on
  `geniuslink_design_system` by path.

### ✨ Added — new components

- **Tree** — a customisable hierarchical tree / outline view (MVC), with:
  - Indent guide-lines (│ ├ └), disclosure twisties, folder/leaf icons.
  - Inline rename (F2 / double-click), search-with-highlight that auto-reveals matches.
  - Tri-state checkboxes (`onCheckedChanged` returns leaf ids).
  - Full keyboard navigation (↑↓ move, → ← expand/step-in & collapse/step-out,
    Enter toggle/activate, Space check, Delete remove, ⌘Z undo).
  - Right-click context menu (add child / folder / sibling, rename, duplicate, delete).
  - Customisation hooks: `iconBuilder`, `trailingBuilder`, `labelBuilder`, `contextActions`.
  - `TreeController` + `TreeScope` (InheritedNotifier) + undo/redo history.
  - `TreeThemeData` ThemeExtension with `.light` / `.dark` presets.
  - Files: `tree_models.dart`, `tree_controller.dart`, `tree_theme.dart`, `tree.dart`,
    barrel `geniuslink_tree.dart`; demo `example/lib/tree_demo.dart`.

- **ERP Console** (example) — one realistic admin shell hosting all three
  components together: an icon module rail, a **Tree** navigator, a
  **BrowserStyleTabBar** workspace, and **EditableTable** data grids, with live
  Light/Dark and **EN ⇄ AR (LTR ⇄ RTL)** toggles. Tree selection ↔ open tabs stay
  in sync. Files: `erp_console.dart`, `erp_console_data.dart`, `erp_console_pages.dart`.

- **Unified barrel** `geniuslink_design_system.dart` re-exporting all three
  component groups (each still importable on its own).

### ✨ Added — EditableTable

- **Nine typed column kinds** (ergonomic `EditableColumn` subclasses in the new
  `editable_table_columns.dart`):
  | Column | Editor | Stores |
  |---|---|---|
  | `EditableColumn` | inline text | free text |
  | `NumericColumn` | inline numeric · `min` / `max` / `decimals` | grouped number `1,234.00` |
  | `DateColumn` | masked `YYYY-MM-DD` + 📅 calendar picker button | ISO date |
  | `TimeColumn` | masked `HH:mm` + 🕑 clock picker button | 24-hour time |
  | `ComboBoxColumn` | free text **+** suggestions dropdown | any string |
  | `DropdownColumn` | strict popup menu | one of `options` |
  | `ColorPickerColumn` | swatch menu | `#RRGGBB` hex |
  | `ReadonlyColumn` | — never editable | display only |
  | `ComputedColumn` | — derived from the whole row | `compute(row)` |
  - Web-style masked keyboard entry for date/time via `DateInputFormatter` /
    `TimeInputFormatter`, plus suffix picker buttons (Material date/time pickers).
  - Date/time parse + format helpers (`EditableTemporal`).

- **`cellBuilder`** per column — replace a cell's read-only content with any
  widget (chip, badge, progress bar…), receiving value, full row, selection &
  invalid state, and a `requestEdit` callback (`EditableCellData`).

- **`cellValidator`** per column — row-aware (cross-column) validation
  `(value, row) => String?`; feeds the red cell border and the toolbar badge.
  (`validate` value-only callback still supported.)

- **Keyboard shortcuts** — expanded set + an in-widget reference dialog
  (toolbar ⌨ button / `⌘/Ctrl + /`):
  - `⌘D` duplicate row, `⌘Enter` add row, `⌘⌫` delete row.
  - `Home`/`End` first/last column, `⌘Home`/`⌘End` first/last cell, `F2` edit.
  - Existing: arrows, Tab/⇧Tab, Enter↓, ⌘C/X/V, ⌘Z/⇧Z.

- **`confirmDelete`** option — show a confirmation popup before deleting a row
  (delete button, context menu, `⌘⌫`); set `false` to delete instantly.

- **`growOnTab`** option — Tab on the very last cell appends a new row and jumps
  into it (continuous data entry without the mouse).

- **`showShortcutsHelp`** option — toggles the toolbar shortcuts button.

- **Auto-scroll into view** — navigating with Tab / arrow keys to an off-screen
  cell now scrolls it fully into view (both axes) via `Scrollable.ensureVisible`.

### 🔧 Changed

- `EditableColumn` gained polymorphic behaviour: `normalize`, `displayValue`,
  `editableInline`, `isReadOnly` (overridden by the typed subclasses).
- Controller resolves `ComputedColumn` values in cell display, totals, and sort;
  numeric/date/time commit through each column's `normalize`.
- `EditableTableFormat.group` / `formatNumber` now take a `decimals` argument.
- Read-only / computed columns are protected from clipboard paste, cut, and the
  clear-cell key.

### 📚 Docs

- **README** rewritten in pub.dev style — badges, install, run, and a full guide
  to every component, every column type, validation, custom cells, keyboard
  shortcuts, theming, RTL, and architecture, with runnable examples.
- **`doc/showcase.html`** — a designed web page (replacing screenshots) that
  walks through every part and feature of the kit in the GeniusLink visual language.

---

## [1.0.0]

> 2026-05-30

### Added

- Initial release: **BrowserStyleTabBar** — a browser-style workspace tab strip
  (pinned / closable / dirty tabs, drag-to-reorder, context menu, overflow
  dropdown, dirty-close confirm, live mini-page previews), with
  `BrowserStyleTabBarController` (MVC) and `BrowserStyleTabBarThemeData`
  (light/dark). Flutter port of the design-system `BrowserTabs.jsx`.
- Initial **EditableTable** — Excel-style data-entry grid: cell selection,
  type-to-overwrite, inline editing, click-header sort, per-row insert/delete,
  totals footer, single-cell clipboard, undo/redo, and mobile stacked-card
  fallback. Column kinds: text, number, select.
