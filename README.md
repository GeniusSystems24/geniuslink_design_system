# GeniusLink Design System

A Flutter design-system package for browser-style workspace tabs, themed
previews, contextual menus, dirty-state guards, and RTL-ready navigation.

It is a Flutter implementation of the GeniusLink browser-style workspace tab
experience, preserving the same visual structure, interaction model, and GL
design tokens.

It is prepared in the same layout and documentation style expected by pub.dev
packages, including package metadata, example documentation, changelog, license,
and public API comments.

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
- Optional `BrowserStyleTabBarController` for externally driven tab state.
- Optional `pageBuilder` for custom per-tab pages in both the active content
  surface and hover previews.

## Feature Snapshots

### Browser-Style Workspace Tabs

The tab strip mirrors a modern browser workspace: active tabs merge into the
content surface, inactive tabs stay compact, and the add-tab and tab-list
buttons stay anchored at the trailing edge.

![Browser-style workspace tabs](https://raw.githubusercontent.com/GeniusSystems24/geniuslink_design_system/main/snapshots/2.png)

### Pinned, Closable, and Dirty Tabs

Pinned tabs stay at the leading edge, closable tabs expose close affordances on
hover or active state, and dirty tabs show an unsaved indicator before the user
attempts to close them.

![Pinned, closable, and dirty tabs](https://raw.githubusercontent.com/GeniusSystems24/geniuslink_design_system/main/snapshots/2.png)

### Context Menu Actions

Right-click and long-press open a tab context menu with close, close others,
close to the right, duplicate, and pin or unpin actions, including disabled and
danger states.

![Context menu actions](https://raw.githubusercontent.com/GeniusSystems24/geniuslink_design_system/main/snapshots/3.png)

### Overflow and Tab-List Dropdown

Overflow chevrons appear only when the strip scrolls horizontally. The tab-list
dropdown lists every open tab, highlights the active tab, and marks pinned or
dirty tabs so users can jump directly to the right workspace.

![Overflow and tab-list dropdown](https://raw.githubusercontent.com/GeniusSystems24/geniuslink_design_system/main/snapshots/2.png)

### Hover-Intent Mini-Page Preview

Hovering over a tab opens a mini-page preview after a short delay. The preview
renders a scaled version of the real page instead of a placeholder skeleton.

![Hover-intent mini-page preview](https://raw.githubusercontent.com/GeniusSystems24/geniuslink_design_system/main/snapshots/2.png)

### Drag, Keyboard, Theme, and RTL Support

The component supports drag-to-reorder, Left/Right/Home/End keyboard navigation,
dark and light themes, and mirrored RTL layout for tab placement, separators,
overflow controls, and menus.

![RTL tab layout](https://raw.githubusercontent.com/GeniusSystems24/geniuslink_design_system/main/snapshots/1.png)

### Interactive Preview

The included GIF shows the same interactions in motion, including tab
selection, menus, previews, and overflow behavior.

![Interactive preview](https://raw.githubusercontent.com/GeniusSystems24/geniuslink_design_system/main/snapshots/preview.gif)

### Self-Contained Theme Tokens

`BrowserStyleTabBarThemeData` carries all component tokens, including surfaces,
foreground colors, semantic colors, radii, shadows, font family names, and
motion values, so the tab strip and its overlays can be themed without a global
design-system dependency.

![Self-contained theme tokens](https://raw.githubusercontent.com/GeniusSystems24/geniuslink_design_system/main/snapshots/2.png)

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

## Example Launcher

The package is a library, so it has no `lib/main.dart`. Run the example app:

```bash
cd example
flutter pub get
flutter run -d chrome
```

The example opens a launcher with four demos that host the same component:

| Demo | Shell | Content |
|------|-------|---------|
| ERP System | Light SaaS shell with module sidebar and app bar | Built-in accounting pages, pinned reference tab, unsaved journal tab, close guard, and dark/light toggle |
| Figma-Style Editor | Dark design-tool shell with tools rail, layers, and inspector | Custom canvas pages. The "Add frame" action mutates page state and marks the tab dirty, so its live thumbnail updates |
| Chrome-Style Browser | Browser-like shell with omnibox toolbar | Custom document pages where in-page links open new tabs through the controller |
| Documentation | Component documentation shell | Anatomy, states, props, and LTR/RTL specimens from `example/lib/browser_tabs_demo.dart` |

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

Use an external controller when the host app needs to own tab state:

```dart
final controller = BrowserStyleTabBarController(
  tabs: [
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
  ],
  activeId: 2,
);

BrowserStyleTabBar(
  controller: controller,
  pageBuilder: (context, tab) => MyWorkspacePage(tab: tab),
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

## State Controller

`BrowserStyleTabBarController` is a `ChangeNotifier` that stores the open tabs,
active tab, pin and dirty flags, ordering, and live page snapshots.

Pass a controller to drive the strip from outside, or omit it and
`BrowserStyleTabBar` creates a private controller seeded from `tabsState`.
Descendant pages can access the hosting controller:

```dart
final tabs = BrowserStyleTabBarController.of(context);

tabs?.add(title: 'New report', kind: GLTabKind.chart);
tabs?.setDirty(myTabId, true);
tabs?.select(otherTabId);
```

`BrowserStyleTabBarController.of(context)` returns `null` when the widget is not
hosted inside a `BrowserStyleTabBar`, so custom pages can still be rendered
stand-alone. Use `BrowserStyleTabBarController.read(context)` in callbacks when
you do not need to subscribe to controller changes.

Controller operations include `select`, `add`, `close`, `closeOthers`,
`closeToRight`, `duplicate`, `togglePin`, `setPinned`, `reorder`, `setDirty`,
`rename`, and `mutate`.

## Live Page Thumbnails

Hover previews are live page thumbnails, not static placeholders. The component
captures the active page through a `RepaintBoundary` and stores the rendered
frame in the controller. The active tab is recaptured on hover, while inactive
tabs show their last captured frame. If a tab has not been rendered yet, the
preview falls back to building the page at thumbnail scale.

This model keeps previews accurate for custom pages, including controller-driven
state changes, dirty-page mutations, and pages that open additional tabs.

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

## Implementation Map

| Source or concept | Flutter implementation |
|-------------------|------------------------|
| Browser-style tab component | `lib/design_system/components/navigation/browser_style_tab_bar.dart` |
| State controller | `lib/design_system/components/navigation/browser_style_tab_bar_controller.dart` |
| Context menu, tab list, dirty dialog, and preview overlays | `lib/design_system/components/navigation/tab_overlays.dart` |
| Tab content pages | `lib/design_system/components/navigation/tab_pages.dart` |
| Tab model and icon maps | `lib/design_system/components/navigation/tab_models.dart` |
| GL color, type, radius, shadow, and motion tokens | `lib/design_system/components/navigation/browser_style_tab_bar_theme.dart` |
| Documentation gallery | `example/lib/browser_tabs_demo.dart` |

## Feature Parity

The Flutter component covers active, inactive, hover, pressed, and focused
states; closable tabs; add and select actions; pinned icon-only tabs; overflow
scrolling with animated chevrons; right-click and long-press context menus;
unsaved indicators; dirty-close confirmation; tab-list dropdowns; live
mini-page previews; long-title truncation and tooltips; drag-to-reorder;
keyboard navigation with Left, Right, Home, End, and Escape; external
`ChangeNotifier` state; custom `pageBuilder` content; dark and light themes;
and RTL mirroring through `Directionality` and directional padding.

## Public API

The primary import is:

```dart
import 'package:geniuslink_design_system/geniuslink_design_system.dart';
```

It exports:

- `BrowserStyleTabBar`
- `BrowserStyleTabBarController`
- `BrowserStyleTabBarScope`
- `BrowserStyleTabBarThemeData`
- `BrowserTab`
- `GLTabKind`
- `GLTabPage`
- `TabPageBuilder`
- `glTabIcon`
- `glPreviewMeta`
- `kNewTabCycle`

When no controller is supplied, the tab strip owns its internal tab list and
active-tab state after creation. To lift state into an application controller,
create and pass a `BrowserStyleTabBarController`.

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

Before publishing this package publicly, verify the final release metadata:

- Replace the private `LICENSE` file if the package should be distributed under
  an open-source license.
- Run `flutter analyze` and `dart pub publish --dry-run` from the package root.

## License

See `LICENSE` for the current redistribution terms.
