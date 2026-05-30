# GeniusLink — BrowserStyleTabBar (Flutter)

A 1:1 Flutter port of the design-system component `BrowserTabs.jsx` and its
gallery `components-browsertabs.html`. Same design, theme, logic and
interactions — driven by the same GL* tokens.

## Run

```bash
cd flutter
flutter pub get
flutter run -d chrome        # or any device/emulator  — opens the gallery
```

### Example app (realistic embed)

```bash
cd flutter/example
flutter pub get
flutter run -d chrome
```

`example/lib/main.dart` shows the component inside a real product shell — a
left navigation rail + window chrome hosting the tab strip — with a
dark/light toggle and a button to open the documentation gallery. It imports
the package through the single barrel: `package:browser_style_tabs/browser_style_tabs.dart`.

Top-right toggle switches dark/light. The second specimen is forced RTL.
(Optional: drop the brand fonts into `assets/fonts/` and uncomment the
`fonts:` block in `pubspec.yaml` — see comments there. Without them the
component falls back to the platform UI font; metrics/layout are unaffected.)

## What maps to what

| Source (web)                     | Flutter |
|----------------------------------|---------|
| `BrowserTabs.jsx` → component    | `lib/design_system/components/navigation/browser_style_tab_bar.dart` |
| `BrowserTabs.jsx` → overlays     | `lib/design_system/components/navigation/tab_overlays.dart` |
| `TabPages.jsx`                   | `lib/design_system/components/navigation/tab_pages.dart` |
| tab data / icon set              | `lib/design_system/components/navigation/tab_models.dart` |
| `components-browsertabs.html`    | `lib/design_system/documentation_examples/browser_tabs_demo.dart` |
| `tokens.css` / `colors_and_type.css` | `lib/design_system/tokens/tokens.dart` + `tokens/gl_surfaces.dart` |
| theme aliases (`[data-theme]`)   | `lib/design_system/themes/app_theme.dart` (registers `GLSurfaces`) |

`GLSurfaces` is a `ThemeExtension` that carries the semantic roles the CSS
aliases (`--gl-bg / --gl-surface / --gl-hover / --gl-input-bg / --gl-border /
--gl-border-strong / --gl-fg-1..4`) and swaps wholesale between dark & light —
read it with `GLSurfaces.of(context)`.

## Feature parity

Active / inactive / hover / pressed · closable (×) · add (+) · select ·
overflow scroll **+ animated chevrons** · **pinned** tabs (icon-only, anchored,
corner dirty-dot) · **right-click / long-press context menu** (close · close
others · close to the right · duplicate · pin·unpin, with disabled states) ·
**unsaved (dirty) indicator** · **dirty-close confirm dialog** (Discard / Save /
Cancel · Esc · backdrop) · **tab-list dropdown** (▾ — jump to any open tab) ·
**hover-intent mini-page preview** (~480 ms, a real scaled-down render of the
page, caret + flip-above) · long-title **truncation + tooltip** ·
**drag-to-reorder** with drop indicator · **keyboard** ←/→/Home/End + Esc ·
dark/light · **RTL** (everything mirrors via `Directionality` +
`EdgeInsetsDirectional`).

## Usage

```dart
// self-contained demo state (matches the JSX default set):
const BrowserStyleTabBar();

// or seed your own:
BrowserStyleTabBar(tabsState: [
  BrowserTab(id: 1, title: 'Chart of Accounts', kind: GLTabKind.ledger, pinned: true),
  BrowserTab(id: 2, title: 'Opening Journal Entry', kind: GLTabKind.doc, dirty: true),
  BrowserTab(id: 3, title: 'Dashboard', kind: GLTabKind.chart),
]);
```

`BrowserStyleTabBar` is self-contained (owns its tab list / active id, like the
JSX). To lift state out, move the ops in `_BrowserStyleTabBarState` up and pass
`tabs` + callbacks down — the chip/overlay widgets are already stateless on
that axis.
