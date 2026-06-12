# BrowserStyleTabBar — professional examples

Realistic, varied recipes. Each assumes the import + `BrowserStyleTabBarThemeData`
registration from the skill.

---

## 1 · ERP workspace shell — external controller + custom `pageBuilder`

State-preserving pages mean a half-filled journal entry survives tab switches.

```dart
class Workspace extends StatefulWidget {
  const Workspace({super.key});
  @override State<Workspace> createState() => _WorkspaceState();
}

class _WorkspaceState extends State<Workspace> {
  final tabs = BrowserStyleTabBarController(tabs: [
    BrowserTab(id: 1, title: 'Chart of Accounts', kind: GLTabKind.ledger, pinned: true),
    BrowserTab(id: 2, title: 'Journal Entry', kind: GLTabKind.doc, dirty: true),
    BrowserTab(id: 3, title: 'Dashboard', kind: GLTabKind.chart),
  ], activeId: 2);

  Widget _page(BuildContext ctx, BrowserTab tab) {
    switch (tab.kind) {
      case GLTabKind.ledger: return const ChartOfAccountsPage();
      case GLTabKind.doc:    return JournalEntryPage(onDirty: (d) => tabs.setDirty(tab.id, d));
      case GLTabKind.chart:  return const DashboardPage();
      default:               return Center(child: Text(tab.title));
    }
  }

  @override
  Widget build(BuildContext context) => BrowserStyleTabBar(
    controller: tabs,
    pageBuilder: _page,
    showChrome: false,        // edge-to-edge inside the app shell
    fillContent: true,        // page fills all available height
    onAddTab: () => tabs.add(title: 'New report', kind: GLTabKind.chart),
  );

  @override void dispose() { tabs.dispose(); super.dispose(); }
}
```

---

## 2 · Open a detail tab from page content (`BrowserStyleTabBarController.of`)

A row in one page opens (or focuses) a document tab — pages stay reusable because
`of(context)` returns null outside a tab bar.

```dart
class AccountRow extends StatelessWidget {
  const AccountRow({super.key, required this.account});
  final Account account;
  @override
  Widget build(BuildContext context) => ListTile(
    title: Text(account.name),
    onTap: () {
      final tabs = BrowserStyleTabBarController.of(context);
      tabs?.add(title: account.name, kind: GLTabKind.doc);   // → new id; activates
    },
  );
}
```

For callbacks / `initState` use the non-listening variant:
`BrowserStyleTabBarController.read(context)`.

---

## 3 · Dirty-aware save flow

```dart
// mark dirty as the form changes:
JournalEntryPage(onChanged: () => tabs.setDirty(tabId, true));

// on save, clear the flag (closing a dirty tab triggers the built-in confirm dialog):
Future<void> save() async {
  await api.post(entry);
  tabs.setDirty(tabId, false);
}

// programmatic tab management:
tabs.rename(tabId, 'JE-2025-0042');
tabs.togglePin(tabId);
tabs.duplicate(tabId);
tabs.closeOthers(tabId);          // guard with tabs.canCloseOthers(tabId)
```

---

## 4 · Minimal, self-seeding strip (prototyping)

```dart
// zero config — owns a controller with a default tab set + built-in pages:
const BrowserStyleTabBar();

// or seed tabs but keep the built-in GLTabPage per kind:
BrowserStyleTabBar(tabsState: [
  BrowserTab(id: 1, title: 'Customers', kind: GLTabKind.user),
  BrowserTab(id: 2, title: 'Catalog', kind: GLTabKind.store),
  BrowserTab(id: 3, title: 'Globe', kind: GLTabKind.globe),
]);

// rebuild-on-revisit instead of keeping state alive:
BrowserStyleTabBar(controller: c, pageBuilder: buildPage, lazyPages: true);
```
