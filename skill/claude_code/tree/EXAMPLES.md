# Tree — professional examples

Realistic, varied recipes. Each assumes the import + `TreeThemeData`
registration from the skill.

---

## 1 · Typed chart of accounts (`Tree<Account>`) with a trailing nature badge

```dart
@immutable
class Account { final String code, type, nature; const Account({required this.code, required this.type, required this.nature}); }

final roots = <TreeNode<Account>>[
  TreeNode(id: '1000', label: 'Assets', folder: true,
    value: const Account(code: '1000', type: 'Asset', nature: 'DR'),
    children: [
      TreeNode(id: '1100', label: 'Current Assets', folder: true,
        value: const Account(code: '1100', type: 'Asset', nature: 'DR'),
        children: [
          TreeNode(id: '1101', label: 'Cash on hand',
            value: const Account(code: '1101', type: 'Asset', nature: 'DR'), badge: '12'),
          TreeNode(id: '1102', label: 'Bank — Al Rajhi',
            value: const Account(code: '1102', type: 'Asset', nature: 'DR')),
        ]),
    ]),
  TreeNode(id: '4000', label: 'Revenue', folder: true,
    value: const Account(code: '4000', type: 'Income', nature: 'CR')),
];

Tree<Account>(
  roots: roots,
  initiallyExpanded: const {'1000', '1100'},
  showToolbar: true, showSearch: true,
  trailingBuilder: (ctx, row) {
    final n = row.node.value?.nature;
    if (n == null) return const SizedBox.shrink();
    final cr = n == 'CR';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: (cr ? const Color(0xFF1DB88A) : const Color(0xFF4A7CFF)).withOpacity(0.14),
        borderRadius: BorderRadius.circular(6)),
      child: Text(n, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
        color: cr ? const Color(0xFF1DB88A) : const Color(0xFF4A7CFF))));
  },
  onActivated: (n) => openLedger(n.value!),   // double-click / Enter on a leaf
);
```

---

## 2 · File explorer with tri-state checkboxes (export selection)

```dart
class FilePicker extends StatefulWidget {
  const FilePicker({super.key, required this.roots});
  final List<TreeNode> roots;
  @override State<FilePicker> createState() => _FilePickerState();
}

class _FilePickerState extends State<FilePicker> {
  late final TreeController t = TreeController(roots: widget.roots, expanded: {'src'});
  Set<TreeNodeId> _checked = {};

  @override
  Widget build(BuildContext context) => Column(children: [
    Expanded(child: Tree(
      controller: t,
      showCheckboxes: true,                 // checking a folder checks all descendant leaves
      showSearch: true, showGuides: true,
      iconBuilder: (row) => row.node.isFolder ? Icons.folder_outlined : Icons.insert_drive_file_outlined,
      onCheckedChanged: (ids) => setState(() => _checked = ids),   // checked LEAF ids
    )),
    Padding(
      padding: const EdgeInsets.all(8),
      child: Row(children: [
        Text('${_checked.length} files selected'),
        const Spacer(),
        FilledButton(
          onPressed: _checked.isEmpty ? null : () => export(t.checkedLeafIds),
          child: const Text('Export')),
      ]),
    ),
  ]);

  @override void dispose() { t.dispose(); super.dispose(); }
}
```

---

## 3 · Editable category manager — multi-select + structural ops + undo

Multi-select requires a `controller:` (the mode lives on it). All structural
edits are undoable.

```dart
class CategoryManager extends StatefulWidget {
  const CategoryManager({super.key, required this.roots});
  final List<TreeNode> roots;
  @override State<CategoryManager> createState() => _CategoryManagerState();
}

class _CategoryManagerState extends State<CategoryManager> {
  late final TreeController t = TreeController(
    roots: widget.roots,
    selectionMode: TreeSelectionMode.multi,    // ⌘/⇧-click, ⌘A
  );

  @override
  Widget build(BuildContext context) => Column(children: [
    Row(children: [
      TextButton.icon(
        onPressed: () { final sel = t.selectedNodes; if (sel.isNotEmpty) t.addChild(sel.first.id, label: 'New'); },
        icon: const Icon(Icons.add), label: const Text('Add child')),
      TextButton.icon(onPressed: t.selectionCount > 0 ? t.removeSelected : null,
        icon: const Icon(Icons.delete_outline), label: Text('Delete (${t.selectionCount})')),
      const Spacer(),
      IconButton(onPressed: t.canUndo ? t.undo : null, icon: const Icon(Icons.undo)),
      IconButton(onPressed: t.canRedo ? t.redo : null, icon: const Icon(Icons.redo)),
    ]),
    Expanded(child: Tree(
      controller: t,
      editable: true,                          // F2 / double-click renames
      showToolbar: true, showSearch: true,
      contextActions: (node) => [
        TreeAction(label: 'Duplicate', icon: Icons.copy, onSelected: (c, n) => c.duplicate(n.id)),
        TreeAction(label: 'Add sibling', icon: Icons.add, onSelected: (c, n) => c.addSibling(n.id, label: 'New')),
      ],
      onChanged: (roots) => persist(roots),    // structural change → save
    )),
  ]);

  @override void dispose() { t.dispose(); super.dispose(); }
}
```

---

## 4 · Drive the tree from a custom row widget (`TreeController.of`)

Any widget inside a `trailingBuilder` / `labelBuilder` can reach the controller.

```dart
Tree<Account>(
  roots: roots,
  trailingBuilder: (context, row) => IconButton(
    icon: const Icon(Icons.add, size: 16),
    tooltip: 'Add sub-account',
    onPressed: () => TreeController.of<Account>(context)?.addChild(row.node.id, label: 'New account'),
  ),
);
```
