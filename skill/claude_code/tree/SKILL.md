---
name: geniuslink-tree
description: >
  How to use the GeniusLink Tree — a generic, hierarchical tree/outline view for
  Flutter (file explorers, category outlines, charts of accounts) with selection,
  inline rename, search, tri-state checkboxes, context menus, undo/redo, RTL. Use
  when building or modifying Flutter UI that needs a tree/outline from the
  `geniuslink_design_system` package, or when wiring a `TreeController`.
---

# GeniusLink · Tree

A customisable **generic** hierarchical tree / outline. Every node is
`TreeNode<T>` carrying a typed `value`, so row code reads `node.value` with no
casting. Indent guide-lines, disclosure twisties, click/keyboard selection
(single or multi), inline rename, search-with-highlight, tri-state checkboxes,
a context menu, and undo/redo.

## Import & theme

```dart
import 'package:geniuslink_design_system/geniuslink_tree.dart';

ThemeData(extensions: const [TreeThemeData.light]); // + TreeThemeData.dark in darkTheme
```

## Quick start

```dart
Tree(
  roots: const [
    TreeNode(id: 'src', label: 'src', folder: true, children: [
      TreeNode(id: 'main', label: 'main.dart'),
      TreeNode(id: 'ui', label: 'ui', folder: true, children: [
        TreeNode(id: 'button', label: 'button.dart', badge: 'edited'),
      ]),
    ]),
    TreeNode(id: 'readme', label: 'README.md'),
  ],
  initiallyExpanded: const {'src', 'ui'},
  onSelected: (node) => debugPrint('opened ${node.id}'),
);
```

Provide `roots` + `initiallyExpanded` (widget owns a controller) **or** pass a
`controller:` (required to opt into multi-select).

## The node — `TreeNode<T>`

| Field | Type | Meaning |
|---|---|---|
| `id` | `String` | **Required** stable unique id (path / uuid / db id). |
| `label` | `String` | **Required** display text — also what rename & search match. |
| `children` | `List<TreeNode<T>>` | Child nodes; empty for a leaf. |
| `value` | `T?` | Typed host payload (`node.value` is a `T`, no cast). |
| `icon` | `IconData?` | Leading-icon override (else inferred folder/leaf). |
| `badge` | `String?` | Trailing badge text. |
| `folder` | `bool?` | Force folder/leaf; `null` ⇒ folder iff it has children. |
| `selectable` | `bool` | `false` ⇒ row can't be selected (still shown/expandable). |
| `data` | `Map<String,Object?>` | Incidental metadata; prefer `value` for the payload. |

## Typed nodes — `Tree<T>`

```dart
final roots = <TreeNode<Account>>[
  TreeNode(id: '1000', label: 'Assets', value: Account(code: '1000', type: 'Asset'),
    children: [ /* … */ ]),
];

Tree<Account>(
  roots: roots,
  trailingBuilder: (ctx, row) => Text(row.node.value!.nature),  // DR / CR
  onActivated: (n) => openLedger(n.value!),
);
```

## Selection — single or multi

A click/keyboard selection layer, independent of checkboxes. Set
`TreeController.selectionMode` to `TreeSelectionMode.{none, single, multi}`
(default `single`). **Multi-select means passing a `controller:`** (the mode
lives on it):

```dart
final t = TreeController<Account>(roots: roots, selectionMode: TreeSelectionMode.multi);
Tree<Account>(controller: t, onSelected: (n) {});

t.selection;        // Set<TreeNodeId>
t.selectedNodes;    // List<TreeNode<T>> in visible order
t.selectionCount;
t.selectWith(id, toggle: true);   // or range: true
t.selectAllVisible();             // multi only
t.removeSelected();               // delete selected subtrees (one undo step)
t.clearSelection();
```

Plain click resets to one; **Ctrl/⌘-click toggles**; **Shift-click** /
`Shift+↑↓` range-selects; `⌘/Ctrl+A` selects all visible.

## Checkboxes (independent of selection)

`showCheckboxes: true` ⇒ tri-state column: checking a folder checks all
descendant leaves; partial shows a dash. `onCheckedChanged` reports checked
**leaf** ids; read `controller.checkedLeafIds` any time.

## Search

`showSearch: true` (+ toolbar): typing filters to matching labels **plus their
ancestors** and highlights hits. `controller.setQuery('cash')`;
`controller.filtering` / `matchCount`. `/` or `⌘/Ctrl+F` focuses, `Esc` clears.

## Options & hooks

```dart
Tree(
  roots: roots,
  showToolbar: true, showSearch: true, showCheckboxes: false, showFooter: true,
  showGuides: true,   // │ ├ └ indent guides
  dense: false,
  editable: true,     // inline rename (F2 / double-click) + structural edits
  iconBuilder: (row) => row.node.isFolder ? Icons.folder : Icons.description,
  trailingBuilder: (context, row) => null,   // inject host widgets per row
  labelBuilder: (context, row) => null,      // fully replace the label cell
  contextActions: (node) => [TreeAction(label: 'Open', icon: Icons.open_in_new, onSelected: (c, n) {})],
  onSelected: (n) {}, onActivated: (n) {},   // activated = double-click / Enter on a leaf
  onCheckedChanged: (ids) {}, onChanged: (roots) {},  // structural change
);
```

## Driving it — `TreeController`

All structural edits are undoable and route through `onChanged`:

```dart
final t = TreeController(roots: roots, expanded: {'src'}, selected: 'main');
t.addChild('src', label: 'new.dart');   // → new id; expands, selects, renames
t.addChild('src', folder: true);
t.addSibling('main', label: 'next.dart');
t.duplicate('main');                      // fresh-id subtree as next sibling
t.remove('button'); t.removeSelected();
t.expandAll(); t.collapseAll(); t.toggle('ui');
t.beginEdit('main');                      // inline rename
t.undo(); t.redo();                       // t.canUndo / t.canRedo

TreeController.of<Account>(context)?.addChild(parentId);  // from row content / a page
```

## Keyboard (press ? for the cheatsheet)

`↑↓` move · `→←` expand/collapse (RTL-mirrored) · `Home/End` first/last visible ·
`Enter` toggle folder / activate leaf · `Space` check · `⇧+↑↓`/`⌘-click`/`⇧-click`
multi · `⌘/Ctrl+A` select all · `F2`/`Delete` rename/remove (`editable`) ·
`/` or `⌘/Ctrl+F` search, `Esc` clear · `*`/`\` expand/collapse all ·
`⌘/Ctrl+Z`/`⇧Z` undo/redo. Off-screen targets auto-scroll into view.

## Gotchas

- `id` must be **stable and unique** across the whole tree — selection,
  expansion, search and undo all key on it.
- Multi-select + `selectAllVisible` need a `controller:` (mode is on the
  controller, not the widget).
- Checkbox state (`checkedLeafIds`) is separate from selection (`selectedNodes`).
- Register `TreeThemeData` or you get the dark preset.

## Reference

- **Examples (read first):** `EXAMPLES.md` in this folder — professional, varied, copy-ready scenarios.
- Demo: `example/lib/tree_demo.dart` + `account_tree_data.dart`
- Interactive: `docs/components-tree.html` (Account / FileMeta / Person value types)
- Source: `lib/design_system/components/data/tree_*.dart`
