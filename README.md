# GeniusLink Design System

A Flutter design-system package for browser-style workspace tabs, themed
previews, contextual menus, dirty-state guards, and RTL-ready navigation.

This package currently publishes to no public registry (`publish_to: none`).
It is prepared in the same layout and documentation style expected by
pub.dev packages so it can be reviewed, documented, and promoted later with
minimal churn.

## Features

- Browser-style tab strip with active, inactive, hover, pressed, and focused
  states.
- Pinned tabs, closable tabs, dirty-state indicators, and guarded dirty-close
  confirmation.
- Right-click and long-press context menu with close, close others, close to
  the right, duplicate, and pin or unpin actions.
- Overflow chevrons plus a tab-list dropdown for jumping to any open tab.
- Hover-intent mini-page previews that render a scaled version of the real tab
  page.
- Drag-to-reorder, keyboard navigation, dark and light themes, and RTL layout.
- Self-contained theme tokens through `BrowserStyleTabBarThemeData`.

## Getting Started

Add the package to a Flutter app. For the current local checkout, use a path
dependency:

```yaml
dependencies:
  geniuslink_design_system:
    path: ../flutter
```

Then import the public barrel:

```dart
import 'package:geniuslink_design_system/geniuslink_design_system.dart';
```

Register the theme extension on your app theme:

```dart
ThemeData(
  useMaterial3: true,
  extensions: const [
    BrowserStyleTabBarThemeData.dark,
  ],
);
```

Use `BrowserStyleTabBarThemeData.light` for light mode, or switch between both
with `ThemeMode`.

## Usage

Create a tab strip with the built-in sample state:

```dart
const BrowserStyleTabBar();
```

Seed it with your own tabs:

```dart
BrowserStyleTabBar(
  tabsState: [
    BrowserTab(
      id: 1,
      title: 'Chart of Accounts',
      kind: GLTabKind.ledger,
      pinned: true,
    ),
    BrowserTab(
      id: 2,
      title: 'Opening Journal Entry',
      kind: GLTabKind.doc,
      dirty: true,
    ),
    BrowserTab(
      id: 3,
      title: 'Dashboard',
      kind: GLTabKind.chart,
    ),
  ],
);
```

Render a content page for a single tab when you need the same demo surface
outside the tab strip:

```dart
GLTabPage(
  tab: BrowserTab(
    id: 4,
    title: 'Downtown Central Store',
    kind: GLTabKind.store,
  ),
);
```

## Theming

`BrowserStyleTabBarThemeData` is a `ThemeExtension` that contains the colors,
font family names, radii, elevation shadows, and motion tokens used by the tab
strip and its overlays.

```dart
final tabsTheme = BrowserStyleTabBarThemeData.of(context);
```

If no extension is registered, `BrowserStyleTabBarThemeData.of(context)` falls
back to the dark preset so the widget can still paint.

The package references these optional font families:

- `Manrope` for display text.
- `Inter` for body text.
- `JetBrainsMono` for tab metadata and numeric text.

If your app does not register those fonts, Flutter falls back to the platform
font. The example keeps the font declarations commented in `pubspec.yaml` so
you can add the `.ttf` files when available.

## Example

Run the included example app:

```bash
cd example
flutter pub get
flutter run -d chrome
```

The example opens a product-like workspace shell with a left navigation rail,
window chrome, the browser tab strip, a dark and light toggle, an RTL specimen,
and a documentation gallery.

## Public API

The primary import is:

```dart
import 'package:geniuslink_design_system/geniuslink_design_system.dart';
```

It exports:

- `BrowserStyleTabBar`
- `BrowserStyleTabBarThemeData`
- `BrowserTab`
- `GLTabKind`
- `GLTabPage`
- `glTabIcon`
- `glPreviewMeta`
- `kNewTabCycle`

The tab strip owns its internal tab list and active-tab state after creation.
To lift state into an application controller, keep the public model shape and
move the operations from the widget state into your own controller layer.

## Accessibility and Interaction

- Mouse: hover, close, context menu, drag-to-reorder, and preview-on-hover.
- Touch: tap, long-press context menu, and scrollable overflow.
- Keyboard: Left, Right, Home, End, and Escape for overlay dismissal.
- Directionality: all tab edges, paddings, menus, and dropdown placement honor
  `Directionality`.

## Platform Support

The package uses Flutter framework widgets only and has no native plugin code.
It is suitable for Android, iOS, Linux, macOS, web, and Windows, with the most
complete browser-tab interaction model on desktop and web.

## Publishing Checklist

Before publishing this package publicly, decide and apply the final publication
metadata:

- Replace `publish_to: none` when the package is ready for pub.dev.
- Add a real `repository`, `homepage`, or `issue_tracker` URL to `pubspec.yaml`.
- Replace the private `LICENSE` file if the package should be distributed under
  an open-source license.
- Run `flutter analyze` and `dart pub publish --dry-run` from the package root.

## License

This checkout is private by default. See `LICENSE` for the current redistribution
terms.
