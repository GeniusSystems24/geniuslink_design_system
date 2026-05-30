# Changelog

## 1.1.0

> 2026-05-30

- Added `BrowserStyleTabBarController` as the public `ChangeNotifier` state
  API for externally controlled tab selection, creation, closing, pinning,
  reordering, dirty flags, renaming, and arbitrary tab mutations.
- Added `pageBuilder` support so hosts can render custom per-tab content in the
  active surface and hover previews while keeping the built-in `GLTabPage`
  fallback.
- Added live page thumbnail support backed by captured page frames, so hover
  previews can reflect current page state instead of static placeholder content.
- Expanded the example app into a launcher with ERP, Figma-style editor,
  Chrome-style browser, and documentation demos that all host the same tab
  component.
- Updated the public barrel exports and README documentation for the controller,
  custom page builders, live thumbnails, feature parity, and implementation map.

## 1.0.1

> 2026-05-30

- Updated README snapshot links to use absolute GitHub raw URLs so they render
  on pub.dev.
- Added pub.dev `screenshots` metadata for the package gallery.
- Expanded README documentation for the example launcher, controller-driven
  state, custom page builders, live page thumbnails, implementation map, and
  public API.
- Removed direct references to source web files from the public README.

## 1.0.0

> 2026-05-30

- Initial release of the GeniusLink browser-style tab strip package.
- Added `BrowserStyleTabBar` with pinned tabs, dirty-state guards, context
  menus, tab-list dropdowns, hover previews, drag-to-reorder, keyboard
  navigation, light and dark themes, and RTL support.
- Added `BrowserStyleTabBarThemeData` as the self-contained theme extension for
  tab surfaces, text colors, semantic colors, radii, shadows, fonts, and motion.
- Added an example app that embeds the component in a realistic workspace shell
  and includes a documentation gallery.
