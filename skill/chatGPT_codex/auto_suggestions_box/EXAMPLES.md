# AutoSuggestionsBox — professional examples

Realistic, varied recipes. Each assumes the import + `AutoSuggestionsBoxThemeData`
registration from the skill.

---

## 1 · Async city search backed by an API (debounced, race-safe)

```dart
AutoSuggestionsBox<City>(
  source: AutoSuggestionsSource.async((q) async {
    final results = await api.searchCities(q);          // network
    return [for (final c in results) AutoSuggestion(value: c, label: c.name, description: c.country)];
  }),
  hintText: 'Search a city…',
  onSelected: (s) => selectCity(s.value),
);
```

---

## 2 · Hybrid account-code combo (local-first, load-more) with grouped rows

The frequent accounts show instantly; the long tail loads only on a local miss.

```dart
AutoSuggestionsBox<String>(
  source: AutoSuggestionsSource.hybrid(
    initialItems: const [
      AutoSuggestion(value: '1101', label: 'Cash on hand', description: '1101 · Asset',
        icon: Icons.payments_outlined, group: 'Assets'),
      AutoSuggestion(value: '4000', label: 'Sales revenue', description: '4000 · Income',
        icon: Icons.trending_up_rounded, group: 'Income', keywords: ['turnover']),
    ],
    fetch: (q) async {
      final rows = await api.searchAccounts(q);
      return [for (final a in rows) AutoSuggestion(value: a.code, label: a.name,
        description: '${a.code} · ${a.type}', group: a.type)];
    },
    remoteMinChars: 2,
  ),
  hintText: 'Account…',
  onSelected: (s) => postTo(s.value),
);
```

---

## 3 · Multi-select tag picker with chips below the field

Multi-select keeps the overlay open and exposes the set on the controller.

```dart
class TagPicker extends StatefulWidget {
  const TagPicker({super.key});
  @override State<TagPicker> createState() => _TagPickerState();
}

class _TagPickerState extends State<TagPicker> {
  late final AutoSuggestionsBoxController<String> c = AutoSuggestionsBoxController<String>(
    source: StringSuggestions.source(const [
      'Design', 'Engineering', 'Research', 'Marketing', 'Sales', 'Finance', 'Legal', 'Support']),
    multiSelect: true,
  );
  List<String> _tags = const [];

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    AutoSuggestionsBox<String>(
      controller: c,
      multiSelect: true,
      hintText: 'Add teams…',
      onSelectionChanged: (items) => setState(() => _tags = [for (final i in items) i.value]),
    ),
    if (_tags.isNotEmpty) Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Wrap(spacing: 8, runSpacing: 8, children: [
        for (final tag in _tags)
          Chip(
            label: Text(tag),
            onDeleted: () { c.removeSelectedValue(tag); setState(() => _tags = c.selectedValues); },
          ),
      ]),
    ),
  ]);

  @override void dispose() { c.dispose(); super.dispose(); }
}
```

---

## 4 · Custom overlay states (`itemBuilder` / `emptyBuilder` / `loadingBuilder`)

```dart
AutoSuggestionsBox<Person>(
  source: AutoSuggestionsSource.async(fetchPeople),
  hintText: 'Assign to…',
  loadingBuilder: (ctx, query) => const ListTile(
    leading: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
    title: Text('Searching…')),
  emptyBuilder: (ctx, query) => ListTile(title: Text('No teammate matches "$query"')),
  itemBuilder: (ctx, s, highlighted) => ListTile(
    selected: highlighted,
    leading: CircleAvatar(child: Text(s.label[0])),
    title: Text(s.label),
    subtitle: Text(s.description ?? ''),
  ),
  onSelected: (s) => assign(s.value),
);
```

---

## 5 · Embed it flush inside a host surface (`bare` mode)

How EditableTable's combo cells use it: share **one** `FocusNode` with the host
(don't let two focus nodes race), then `openOnFocus` shows suggestions the instant
the field is focused.

```dart
AutoSuggestionsBox<String>(
  controller: box,
  focusNode: sharedFocusNode,       // host requests focus on THIS node
  bare: true,                       // drop border/fill — sits flush in a cell
  autofocus: true,
  openOnFocus: true,                // suggestions appear on focus
  scrollOnFocus: false,             // host (the grid) owns scrolling
  onSelected: (s) { commit(s.value); moveDown(); },
  onSubmitted: (_) => moveDown(),   // free-text Enter
  onEscape: cancel,
  onTabNext: nextCell, onTabPrev: prevCell,
);
```
