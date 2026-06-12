---
name: geniuslink-auto-suggestions-box
description: >
  How to use the GeniusLink AutoSuggestionsBox — a typed, themeable auto-suggest /
  combo text field for Flutter with static / async / hybrid sources, match
  highlighting, multi-select, custom item/empty/loading builders, scroll-on-focus,
  and an embeddable bare mode. Use when adding a search/autocomplete/combo field
  with the `geniuslink_design_system` package, or wiring an
  `AutoSuggestionsBoxController`.
---

# GeniusLink · AutoSuggestionsBox

A typed, themeable **auto-suggest / combo field** — type to filter, `↑ ↓` to
move, `Enter` / click to pick, `Esc` to dismiss; free text commits as-is when
allowed. The matched substring of every row is highlighted. Built MVC, no
third-party dependency. It also powers `EditableTable`'s combo cells.

## Import & theme

```dart
import 'package:geniuslink_design_system/geniuslink_auto_suggestions_box.dart';

ThemeData(extensions: const [AutoSuggestionsBoxThemeData.light]); // + .dark
```

## Quick start

```dart
// 1 · static list of plain strings
AutoSuggestionsBox<String>(
  source: StringSuggestions.source(['Apple', 'Banana', 'Cherry']),
  hintText: 'Search a fruit…',
  onSelected: (s) => print(s.value),
)

// 2 · rich, grouped suggestions (icon + description + section headers)
AutoSuggestionsBox<String>(
  items: [
    AutoSuggestion(value: '1000', label: 'Cash on hand',
        description: '1000 · Asset', icon: Icons.payments_outlined, group: 'Assets'),
    AutoSuggestion(value: '4000', label: 'Sales revenue',
        description: '4000 · Income', icon: Icons.trending_up_rounded, group: 'Income',
        keywords: ['turnover']),
  ],
  onSelected: (s) => print(s.value),
)
```

Pass either `items:` (a `List<AutoSuggestion<T>>`) **or** `source:` (below), and a
`controller:` when you need to read state externally.

## Sources

- `AutoSuggestionsSource.list(items, match: …)` — static, local.
- `AutoSuggestionsSource.async(fetch)` — debounced, race-safe remote.
- `AutoSuggestionsSource.hybrid(initialItems:, fetch:)` — **local-first with an
  async load-more fallback**: the local set shows instantly; the network is
  consulted only when local matches fall below `remoteThreshold`.
- `StringSuggestions.source([...])` — convenience for plain strings.

```dart
AutoSuggestionsBox<City>(
  source: AutoSuggestionsSource.hybrid(
    initialItems: recentCities,           // instant
    fetch: (q) => api.searchCities(q),     // loaded on demand, merged in
    remoteMinChars: 2,
  ),
  hintText: 'Search a city…',
  onSelected: (s) => select(s.value),
)
```

## Key capabilities

- **Match strategies**: `contains` · `prefix` · `words` · `fuzzy` — each with
  matching highlight spans (`highlightMatch:`).
- **Multi-select**: `multiSelect: true` keeps a set of chosen rows — tap / Enter
  toggles, the overlay stays open, rows show a checkbox, the field shows a count.
  Read via `controller.selectedItems` / `selectedValues`, or `onSelectionChanged`;
  seed with `initialSelected:`. Controller helpers: `toggleSelected`,
  `removeSelectedValue`, `setSelectedItems`, `clearSelection`.
- **Custom overlay**: `itemBuilder`, `emptyBuilder`, `loadingBuilder` override the
  row, no-match and async-loading states.
- **Scroll-on-focus**: focusing the field brings it into view inside the nearest
  scrollable ancestor (toggle with `scrollOnFocus`). Arrowing keeps the
  highlighted row scrolled into view.
- **Embedding (`bare: true`)**: drops the border/fill so the box sits flush in a
  host surface (this is how `EditableTable` cells use it). Pair with a shared
  `focusNode:`, `openOnFocus: true`, and `onEscape` / `onTabNext` / `onTabPrev`
  so the host can wire keyboard commits.

## Driving it — `AutoSuggestionsBoxController<T>`

```dart
final c = AutoSuggestionsBoxController<String>(
  source: src,
  textController: myTextController,  // optional: share an existing TextEditingController
  allowFreeText: true,
  multiSelect: false,
);
c.open(); c.close(); c.refresh();      // refresh = re-run the current query
c.query; c.results; c.isLoading; c.highlighted;
c.selectedItems; c.selectedValues;     // multi-select
AutoSuggestionsBox<String>(controller: c);
```

## Embedding recipe (e.g. inside a custom table cell)

```dart
AutoSuggestionsBox<String>(
  controller: box,
  focusNode: sharedEditFocusNode,   // host requests focus on THIS node → field gets it
  bare: true, autofocus: true, openOnFocus: true, scrollOnFocus: false,
  onSelected: (s) { /* commit + move */ },
  onSubmitted: (_) { /* free-text Enter */ },
  onEscape: cancel, onTabNext: nextCell, onTabPrev: prevCell,
);
```

Key insight from the EditableTable integration: **share one `FocusNode`** between
the host and the box (don't let two competing focus nodes race), then
`openOnFocus: true` makes suggestions appear the instant the field is focused.

## Gotchas

- Provide `items:` **or** `source:`, not both.
- Multi-select state lives on the controller — read `selectedItems` /
  `onSelectionChanged`, not a single `onSelected`.
- For embedding, pass a shared `focusNode` and request focus on it from the host;
  relying on `autofocus` alone is flaky inside grids.
- Register `AutoSuggestionsBoxThemeData` or you get the dark preset.

## Reference

- **Examples (read first):** `EXAMPLES.md` in this folder — professional, varied, copy-ready scenarios.
- Demo: `example/lib/auto_suggestions_box_demo.dart`
- Interactive: `docs/components-auto-suggestions-box.html`
- Source: `lib/design_system/components/forms/auto_suggestions_box*.dart`
