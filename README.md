# GeniusLink — BrowserStyleTabBar (Flutter)

A 1:1 Flutter port of the design-system component `BrowserTabs.jsx` and its
gallery `components-browsertabs.html`. Same design, theme, logic and
interactions — driven by the same GL* tokens.

## Run

The package is a library (no `lib/main.dart`). Run the example app:

```bash
cd flutter/example
flutter pub get
flutter run -d chrome        # or any device/emulator
```

It opens on a realistic product shell — a left navigation rail + window chrome
hosting the tab strip — with a dark/light toggle and a button to open the
documentation gallery (`example/lib/browser_tabs_demo.dart`). Everything imports
the package through the single barrel:
`package:geniuslink_design_system/geniuslink_design_system.dart`.

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
| `tokens.css` / `colors_and_type.css` / theme aliases | `lib/design_system/components/navigation/browser_style_tab_bar_theme.dart` |
| `components-browsertabs.html`    | `example/lib/browser_tabs_demo.dart` |

The component is **self-contained**: everything it paints with lives in one
`BrowserStyleTabBarThemeData extends ThemeExtension`. Its instance fields are
the surfaces that swap between dark & light (`bg / surface / hover / border /
fg1..fg4` — mirroring the CSS aliases `--gl-bg / --gl-surface / …`, lerped on
theme change); its static consts are the theme-independent brand constants
(`accent` + semantic palette, font families, radii, shadows, motion).

Register it on your app theme and read it anywhere:

```dart
ThemeData(extensions: [BrowserStyleTabBarThemeData.dark]); // or .light

final s = BrowserStyleTabBarThemeData.of(context); // falls back to .dark
```

There are no remaining dependencies on a global design-system token/theme file.

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
