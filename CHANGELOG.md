# Changelog

All notable changes to **geniuslink_design_system** (Flutter) are documented here.
This project adheres to [Semantic Versioning](https://semver.org).

---

## [2.3.0]

### ✨ Added — `NavigationSidebar` (the GeniusLink web nav, ported MVC)

- **A fifth component: a themeable, responsive app navigation sidebar.** A
  faithful Flutter port of the web `components-navigation-sidebar.html`, built to
  the same Model → Controller → View → Theme split as the rest of the kit. One
  data model renders in **three modes** the host picks from the available width:
  - **expanded** — a full-width labelled tree with `│ ├ └` connector guides,
    badges, two-key shortcut hints and disclosure chevrons; the active leaf fills
    with the accent and its ancestor modules auto-expand.
  - **rail** — an icon-only column; hovering a module opens a grouped **flyout**
    (an `Overlay` + `CompositedTransformFollower`, RTL-aware) listing its
    sub-destinations.
  - **drawer** — an off-canvas panel that slides over the content with a scrim
    for small screens; a destination tap navigates **and** dismisses.
- **Model** (`navigation_sidebar_models.dart`) — immutable `NavSection<T>` bands
  of a `NavNode<T>` tree, generic over a typed `value`. A node's visual **role**
  (`direct` · `module` · `group` · `item`) is *derived* from its depth + whether
  it has children (`NavNodeRole.of`), so the same recursion paints any depth.
  `NavBadge` (count / status, four tones), `NavSidebarBreakpoints.modeFor(width)`
  and `NavOps` (walk · find · ancestorsOf · subtreeHasBadge · leafIds) round it
  out.
- **Controller** (`navigation_sidebar_controller.dart`) — a `ChangeNotifier`
  single source of truth holding the active id, the expanded-module set
  (auto-opening the active node's ancestors), the collapsed (rail) flag and the
  drawer-open flag. Ops: `navigate` (sets active + reveals + closes the drawer),
  `toggleNode` / `expandAll` / `collapseAll`, `toggleCollapsed`, `open/close/
  toggleDrawer`, plus an optional search filter (`setQuery` / `matchSet`) and
  `replaceSections`. Published to descendants via
  `NavigationSidebarController.of<T>(context)`.
- **View** (`navigation_sidebar.dart`) — a thin render of the controller with
  `header` / `footer` slot builders, `showGuides`, `railFlyouts`, `drawerTitle`
  and an `onNavigate` host hook. RTL-mirrored throughout
  (`EdgeInsetsDirectional` / `PositionedDirectional` / `BorderDirectional`).
- **Theme** (`navigation_sidebar_theme.dart`) — `NavigationSidebarThemeData`
  `ThemeExtension` with `.light` / `.dark` presets (lerped), the brand + semantic
  palette, role metrics, connector geometry, motion and `badgeColors(tone)`.
- New barrel `geniuslink_navigation_sidebar.dart`, re-exported from the unified
  barrel. New example `example/lib/navigation_sidebar_demo.dart` — a faithful
  reproduction of the web workbench: an app bar (cube logo · optically-centered
  command-search · workspace dropdown · user menu), the sidebar with a footer
  **ThemeToggle** (segmented Dark/Light) + a **"Need help?"** card, a working
  **command palette** (`/` search over every tab, grouped by module), and a
  workbench strip that flips LTR/RTL and simulates Fill/Desktop/Tablet/Mobile
  widths — plus a launcher card. Colours, radii, row metrics and connector
  geometry are matched 1:1 to `colors_and_type.css` / the web `NavigationSidebar.jsx`.

---

## [2.2.0]

### ♻️ Changed — `ReadableTable` is now generic + MVC

- **Generic over the row value type — `ReadableTable<T>`.** Each row is one
  strongly-typed `T`; every `ReadableColumn<T>` renders itself from that value
  via `cell: (context, value) => Widget` and sorts via `sortKey: (value) =>
  Comparable`. Row code reads `value.field` with no casting. (For a plain grid
  of pre-built widgets use `ReadableTable<List<Widget>>` and index into it —
  which is how the desktop `GLTable` wrapper keeps its `List<List<Widget>>` API.)
- **Rebuilt MVC**, mirroring `EditableTable`: split into
  `readable_table_models.dart` (Model), `readable_table_controller.dart`
  (Controller + `ReadableTableScope`) and `readable_table.dart` (View). The
  view is a thin render of a `ReadableTableController<T>`; pass `columns + rows`
  (widget owns a controller) or a `controller:` to drive/observe externally.
- **`ReadableTableController<T>`** is the single source of truth, published to
  descendants via `ReadableTableController.of<T>(context)`, with intention-
  revealing operations:
  - **Select rows** by index · value · where — `selectRowAt`,
    `selectRowByValue`, `selectRowsWhere`, `selectAllRows`, `clearSelection`.
  - **Add rows** by index · where · end — `insertRowAt`, `addRowWhere`
    (`after` / `firstOnly`), `addRow`.
  - **Delete rows** by index · where · value — `deleteRowAt`,
    `deleteRowsWhere`, `deleteRowByValue`, `deleteSelectedRows`.
  - **Replace row** by index · value · where · firstWhere — `replaceRowAt`,
    `replaceRowByValue`, `replaceRowsWhere`, `replaceFirstWhere`.
  - plus `selectCellAt` / `selectAllCells`, `sortByColumn` / `clearSort`,
    `setRows`. Structural edits remap selection by value identity; sort remaps
    it by position so it follows the rows.

### ⚠️ Migration from 2.1.0

- `ReadableColumn` now requires `cell:` (and takes `sortKey:` instead of the
  table-level `sortKeyOf`). `ReadableTable.rows` is now `List<T>` (was
  `List<List<Widget>>`) — pass `ReadableTable<List<Widget>>` with
  `cell: (ctx, row) => row[i]` to keep the old shape.
- `onRowSelectionChanged` now yields `List<T>` (selected values) rather than
  `Set<int>`; `onRowTap` is `(value, index)`. Seed selection/sort on the
  controller (or via `initialSelected*` / `initialSort*` on the controller-less
  form).

---

## [2.1.0]

### ✨ Added

- **`ReadableTable`** — a read-only display grid that is the visual sibling of
  `EditableTable` (it reuses `EditableTableThemeData`, so header / hairline grid /
  surfaces / type ramp match exactly). It renders arbitrary **widget** cells
  (status pills, two-line bilingual text, progress bars, links…) with flexible or
  fixed column widths, and adds the read-only interaction layer a display grid
  needs:
  - **Selection** — five modes via `ReadableSelectionMode`:
    `none · singleRow · multiRow · singleCell · multiCell`. Pointer: click
    selects, Ctrl/⌘-click toggles, Shift-click extends a range (linear for rows,
    rectangular for cells). `onRowSelectionChanged` / `onCellSelectionChanged`
    report **original** (pre-sort) indices; `initialSelectedRows` /
    `initialSelectedCells` seed it.
  - **Keyboard** — arrows move the active row/cell, Shift+arrows extend a
    multi-selection, Space toggles, Enter activates (`onRowTap`), ⌘/Ctrl+A selects
    all, Esc clears, Home/End + ⌘/Ctrl+Home/End jump to row edges / grid corners,
    and `?` (or ⌘/Ctrl+/) opens an in-widget shortcut cheatsheet.
  - **Column sort** — mark a column `sortable: true`; click its header to cycle
    asc → desc (numeric-looking text sorts numerically, else case-insensitive
    string). `sortKeyOf` provides keys for non-text cells; `initialSortColumn` /
    `initialSortAscending` / `onSortChanged` round it out.
  - Defaults reproduce a plain, non-interactive ledger — adopting it for
    display-only tables is a no-op until a mode is opted into.
  - New barrel `geniuslink_readable_table.dart`; re-exported from the unified
    barrel. New example `example/lib/readable_table_demo.dart` + launcher card.
- **`BrowserStyleTabBar` shell options** (all optional, defaults unchanged):
  `showChrome`, `fillContent`, `contentPadding`, `scrollContent`,
  `contentBackground`, `onAddTab` — let the bar be embedded edge-to-edge as a
  full-window workspace shell that hosts full screens (vs. the standalone card).

---

## [2.4.0]

### 🧩 Added — `EditableTable<T>` (generic typed rows) is a real component

- **The generic editable table is now a shipping widget, not a reference
  sketch.** `EditableTable<T>` + `EditableTableController<T>` render a
  `List<T>` of an immutable model (each `EditableColumn<T>` carries
  `value: (T) => String` / `setValue: (T, raw) => T`), with inline editing
  (text · number · date · dropdown · checkbox), click-to-sort, drag-to-resize +
  long-press-to-reorder columns, TSV copy, RTL-aware keyboard nav and
  scroll-on-focus. Typed column constructors — `NumericColumn`,
  `DropdownColumn`, `DateColumn`, `CheckboxColumn`, `ComputedColumn` — plus
  `mapColumn(...)` for the legacy `T = EditableRow` map rows.
- Ships as its own barrel, `geniuslink_editable_table_generic.dart` (imported
  **instead of** the map-backed table, since both declare the same names). New
  files: `editable_table_generic.dart` (model + controller) and
  `editable_table_generic_view.dart` (the widget).
- **A full selection layer** lives on `EditableTableController<T>`, independent
  of the editing cursor — the same five modes as `ReadableTable`
  (`EditableSelectionMode.{none, singleRow, multiRow, singleCell, multiCell}`),
  with Shift-range / ⌘-toggle / ⌘A-all pointer + keyboard selection and a
  selection-aware ⌘C (rows or a cell rectangle → TSV). The
  `EditableTable<InvoiceRow>` example exposes all five modes via a segmented
  control with a live selection readout, Select-all / Clear / Delete-selected /
  Copy-selection buttons and a TSV preview.

### 📘 Changed — example screens exercise every new capability

- **All four component example screens were rebuilt to demonstrate and test the
  new requirements with realistic, scrollable data and feature toggles:**
  - **EditableTable** → now an `EditableTable<InvoiceRow>` (typed model, not a
    map): 26 rows, every column kind, inline editing, resize / reorder, ⌘C +
    copy-all-rows TSV, an RTL toggle and a live typed-row inspector.
  - **ReadableTable** → 24 rows built from the typed `ReadableColumn`
    factories (text · enum-badge · boolean · date · progress · number), five
    selection modes, a Copy-selection (TSV) button with a clipboard preview,
    and an RTL toggle.
  - **BrowserStyleTabBar** → a live state-preservation test: each tab hosts a
    stateful counter + text field + scroll list, with a Keep-alive ↔ Rebuild
    toggle (`lazyPages`) that visibly preserves vs. resets state, plus an RTL
    toggle.
  - **Tree** → rebuilt on the real `Tree<Account>` widget: Single / Multi
    selection segmented control, a checkbox-column toggle, Add child / Add
    sibling / Delete-selected actions, a live **Selected nodes** panel
    (`controller.selectedNodes`), and an RTL toggle.

### 📘 Changed — example app: one screen per component + one all-in-one

- **The example launcher is consolidated to five screens.** Previously it
  carried three BrowserStyleTabBar product skins (ERP / Figma / Chrome) plus a
  separate docs card. It now shows exactly one example per component —
  **BrowserStyleTabBar**, **EditableTable**, **ReadableTable**, **Tree** — plus
  an **All Components** screen (the ERP Console running Tree + tab bar +
  EditableTable together). The orphaned `erp_app.dart`, `figma_app.dart` and
  `chrome_app.dart` screens were removed. Subtitles now surface the new
  capabilities (generic rows, column resize/reorder, typed ReadableTable
  columns, TSV copy, tree multi-select & add/remove, state-preserving tabs).

### ⚡ Changed — `BrowserStyleTabBar` preserves page state across switches

- **Switching tabs no longer rebuilds pages.** Previously only the active tab's
  page was built, so changing tabs disposed it and rebuilt the next from
  scratch — losing scroll offset, form input and controllers, and re-running all
  build work on every visit. Now every tab's page is built once and kept mounted
  in an `IndexedStack`; switching only changes the visible index. Each page is
  wrapped in `_KeepAliveTabPage` (an `AutomaticKeepAliveClientMixin`) so it
  survives offstage even inside a lazy list. Opt back into the cheap,
  single-page build with `BrowserStyleTabBar(lazyPages: true)`. The hover
  thumbnail `RepaintBoundary` now wraps the stack — only the visible page
  paints, so the captured frame is always the current tab.

### ✨ Added — `removeSelected()` for group delete in `Tree`

- **The `Tree`'s structural ops now cover multi-selection delete.** `addChild`,
  `addSibling`, `remove` and `duplicate` already existed; new `removeSelected()`
  deletes every node in the current multi-selection (and their subtrees) as a
  single undoable step, dropping any node whose ancestor is also selected so a
  parent + child don't double-remove. Like every structural op it routes through
  `_apply`, so add / remove / removeSelected are all ⌘Z-undoable. `remove` also
  now prunes the deleted id from the new selection set.

### ✨ Added — single & multi-select in `Tree`

- **`Tree` now supports a configurable click/keyboard selection model.** A
  `TreeSelectionMode` (none / single / multi) plus a selection set and a Shift
  anchor on `TreeController`. `selectWith(id, toggle, range)` handles
  modifier-aware selection — plain click resets to one, Ctrl/⌘-click toggles,
  Shift-click (and Shift+↑/↓) selects the contiguous visible range — with
  `selectAllVisible` (⌘A) and `clearSelection`. `selectedNodes` exposes the
  selection in visible order for group actions (delete / move / export). The
  existing tri-state checkbox layer (`_checked`) composes alongside in multi
  mode.

### ✨ Added — copy rows & cells to the clipboard as TSV

- **Selection-based copy in `ReadableTable` & `EditableTable`.** A single row,
  multiple rows, a single cell or a cell rectangle now serialize to
  tab-separated values (tabs between columns, newlines between rows) and go to
  the real system clipboard via `Clipboard.setData`, so the result pastes
  straight into Sheets / Excel / Numbers. Cell copies emit the bounding
  rectangle with un-selected interior cells left blank so the block keeps its
  shape; tabs/newlines inside a value are flattened so one cell can't spill into
  neighbouring fields. New `rowsAsTsv` / `cellsAsTsv` serializers +
  `copyRowsToClipboard` / `copyCellsToClipboard` on each controller, wired to
  ⌘/Ctrl + C in both tables' key handlers.

### ✨ Added — typed column kinds in `ReadableTable`

- **`ReadableTable` now supports the same diversity of column types as
  `EditableTable`.** A `ReadableColumnType` enum plus `ReadableColumn.<kind>`
  factories — `text` (optionally bilingual / two-line), `number` (grouped,
  signed-colour, fixed decimals), `enumBadge` (coloured pill), `date`, `time`,
  `color` (swatch + hex), `progress` (labelled bar) and `link` — let a call
  site declare a column's intent and get consistent formatting, alignment and a
  typed sort key, instead of hand-writing a `cell` builder each time. The
  renderers live in new `readable_table_cells.dart` (`ReadableCells.*`),
  theme-driven and intl-free. The original unnamed `ReadableColumn` constructor
  with a custom `cell` keeps working unchanged.

### ✨ Added — column reordering in `ReadableTable` & `EditableTable`

- **Columns can be reordered by dragging their headers.** Visual order is an
  `order` index list on the controller; `moveColumn(fromVisual, toVisual)`
  rearranges it and the header + every body row (and the footer) read
  `columnAt(visualIndex)`, so a drop rearranges the whole grid at once — while
  sort, selection and cell addresses stay keyed by each column's stable
  **logical** index. Each header cell is a `Draggable<int>`/`DragTarget<int>`
  pair (a `LongPressDraggable` on `ReadableTable` so a tap still sorts); the drop
  paints a `PositionedDirectional` accent indicator, RTL-correct for free.
  `columnOrder` exposes the current logical order.

### ✨ Added — column resizing in `ReadableTable` & `EditableTable`

- **Columns can be resized by dragging a header handle.** Each header cell
  carries a `PositionedDirectional` resize handle on its inline-end edge;
  dragging drives `resizeColumn(visualIndex, delta)` on the controller and the
  header + every body row size from `widthOf(visualIndex)`, so the grid reflows in a
  single frame. Width is clamped (`columnMinWidth` 64 / `columnMaxWidth` 520) and a
  double-tap on the handle (`resetColumnWidth`) restores the column's declared
  width (or flex, on `ReadableTable`). RTL-correct: the handle sits on the visual
  left and the drag delta is mirrored. `hasWidthOverride(visual)` reports whether
  a column has been hand-sized.

### ♻️ Changed — `EditableTable` is becoming generic (`EditableTable<T>`)

- **Rows can now be a strongly-typed value `T` instead of `Map<String,String>`.**
  Each `EditableColumn<T>` carries typed accessors — `value: (T row) => String`
  to read a cell and `setValue: (T row, String raw) => T` to write one (a null
  `setValue` marks a read-only / computed column). Because `setValue` returns a
  fresh immutable row, undo/redo snapshots are plain `List<T>` copies. This
  mirrors the already-shipped `ReadableTable<T>` MVC. The legacy string-map
  table is simply `T = EditableRow`, reproduced by the `mapColumn(...)` helper,
  so existing call sites keep working. Reference design shipped as
  `lib/design_system/components/data/editable_table_generic.dart`; the live
  `editable_table_*.dart` files fold these signatures in as the migration lands.

### 🐛 Fixed — keyboard arrow directions in RTL (all four components)

- **Arrow keys now resolve to the *visual* direction in both LTR and RTL** for
  `BrowserStyleTabBar`, `EditableTable`, `ReadableTable` and `Tree`. Previously
  every handler hardcoded `arrowRight → index + 1`, so in an Arabic (RTL)
  layout the right arrow moved the highlight *left*, and the Tree's right arrow
  *collapsed* the node a user was trying to open. A new shared helper
  `horizontalStep(key, dir)` (and `arrowGoesInto` for the Tree) mirrors the
  index step under `TextDirection.rtl`; each component threads
  `Directionality.of(context)` into its existing key handler — no other logic
  changed. `Home`/`End` stay logical first/last (direction-agnostic by name).
  File: `lib/design_system/components/key_directions.dart`.

### 🐛 Fixed — scroll-on-focus in `ReadableTable` & `Tree`

- **`ReadableTable` now reveals the focused cell/row.** It previously had no
  scroll-on-focus, so keyboard navigation could move the active cell completely
  outside the viewport. A `GlobalKey` parked on the active row/cell drives
  `Scrollable.ensureVisible` whenever the active position changes — which walks
  up through *every* enclosing `Scrollable`, so one call reveals it on both the
  vertical (rows) and horizontal (columns) axes, and is RTL-correct. The two
  `keepVisibleAtStart` / `keepVisibleAtEnd` policies scroll only as far as
  needed rather than re-centring.
- **`Tree` reveals focus on expand / step too.** `_scrollToFocused()` is now
  also called from the ← / → (focus-into / focus-out) branch, not just
  ↑ / ↓ / Home / End — so expanding into a deep child or stepping out to a
  far-up parent keeps the cursor on screen.

### ⚠️ Changed — Tree is now generic (`Tree<T>` / `TreeNode<T>`)

- **`TreeNode<T>` carries a strongly-typed `value`.** The node schema is now
  generic over a value type `T`, so a host can attach a typed payload (an
  `Account`, a `FileMeta`, a `Person`, …) and read `node.value` with **no
  casting**. `TreeController<T>`, `Tree<T>`, `TreeScope<T>`, `TreeOps` helpers,
  and the builder/callback typedefs all thread `<T>` through. A new
  `controller.valueOf(id)` returns the typed value for an id.
  - **Backwards compatible:** existing call sites that write `TreeNode(...)`,
    `Tree(...)` or `TreeController(...)` infer `T = dynamic` and keep working.
    The loose `data` map is retained for incidental metadata.

### ✨ Added — Tree keyboard control

- **Full keyboard navigation** in the `Tree` view: `↑ ↓` move the focus cursor,
  `← →` collapse / step out and expand / step in, `Home`/`End` jump, `Enter`
  opens a leaf (fires `onActivated`) or toggles a group, `Space` toggles a
  checkbox, `F2` renames, `Delete` removes, `/` (or `⌘/Ctrl+F`) focuses search,
  `Esc` clears it, `*` / `\` expand / collapse all, `⌘/Ctrl+Z` undo (`⇧` redo),
  and `?` opens a **shortcuts cheatsheet** dialog (also reachable from a new
  toolbar button). The focused row shows an accent ring and auto-scrolls into
  view. New `TreeController` cursor API: `focused`, `focus`, `moveFocus`,
  `focusFirst/Last`, `focusInto/Out`, `activateFocused`, `revealNode`.

### 📝 Added — Tree documentation page

- **`docs/components-tree.html`** — an interactive documentation gallery for the
  tree (cloned from the design-system web tool, with `tree-component.jsx`,
  `tree-examples.jsx`, `ds-kit.jsx`). Documents every feature, the row anatomy,
  the search behaviour and the keyboard map, and ships **three live examples**
  that demonstrate the generic value type: `TreeNode<Account>` (chart of
  accounts), `TreeNode<FileMeta>` (file explorer) and `TreeNode<Person>` (org
  chart) — one tree engine, three value types.

### 🔄 Changed — example

- **Tree demo rebuilt as “Account Tree” (typed + keyboard-driven).**
  `example/lib/tree_demo.dart` mirrors the GeniusLink web *Account Tree* tool and
  is now built on `TreeController<Account>` with `TreeNode<Account>` nodes (typed
  `Account` value: code · nameEn · nameAr · type · balance). It adds KPI summary
  cards (Assets / Liabilities / Equity / Net Income), a recursive search matching
  **code + English + Arabic** with live in-row highlighting and a match counter,
  colour-coded type filter chips, “Try” query chips, roll-up group balances with
  share bars, DR / CR nature pills, leaf-count badges, an accounting-equation
  balance check (A = L + E), a leaf-opens-ledger strip, full keyboard navigation
  and a `?` shortcuts dialog. Sample data moved to
  `example/lib/account_tree_data.dart`. Rows are painted in an account-specific
  4-column layout via `TreeThemeData` (dark / light).

---

## [2.0.0]

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
