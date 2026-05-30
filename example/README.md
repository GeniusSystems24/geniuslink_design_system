# GeniusLink Design System Example

Demonstrates `BrowserStyleTabBar` inside a realistic GeniusLink workspace shell.

The example shows:

- A product-like shell with a navigation rail and window chrome.
- Dark and light theme switching through `BrowserStyleTabBarThemeData`.
- The default browser-style tab strip.
- A documentation gallery with LTR and RTL specimens.
- Context menus, dirty-close confirmation, tab overflow, previews, and keyboard
  navigation.

## Running

```bash
flutter pub get
flutter run -d chrome
```

Use any Flutter device target if Chrome is not available.

## Important Files

- `lib/main.dart` embeds the component in an app shell.
- `lib/browser_tabs_demo.dart` contains the gallery and documentation specimens.
- `pubspec.yaml` depends on the package through `path: ../`.

## Theme Setup

The example registers the package theme extension in `_appTheme`:

```dart
ThemeData(
  brightness: brightness,
  useMaterial3: true,
  extensions: [
    brightness == Brightness.dark
        ? BrowserStyleTabBarThemeData.dark
        : BrowserStyleTabBarThemeData.light,
  ],
);
```

This is the minimum setup needed by apps that consume the package.
