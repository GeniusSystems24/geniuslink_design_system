# GeniusLink Flutter Design System Index

This index covers the Flutter implementation of all component groups found in `genius_design_system_web/design_system`.

## Implementation architecture

| Area | Chosen pattern | Reason |
|---|---|---|
| Foundations | Token / ThemeExtension | Shared immutable values consumed by every widget. |
| Core widgets | MVVM-ready views | Stateless/stateful views can be driven by external controllers where needed. |
| Domain widgets | MVVM-ready views | Domain status enums separate presentation from application state. |
| Charts | MVC | Model data is passed to CustomPainter view classes. |
| Skeletons | View-only | Animation state is local and token-driven. |
| ComboBox | MVVM | `GLComboBoxViewModel` owns query, loading, open state, and selection. |
| Editable table | MVVM | `GLTableController` owns rows, selected IDs, sorting, and cell edits. |
| Browser tabs | MVVM-C | `BrowserStyleTabBarController` coordinates state and view interactions. |
| Patterns | Composition | Patterns are assembled from the canonical components. |
| Motion | Token-driven views | Motion is centralized through Flutter tokens. |

## Source-to-Flutter mapping

| Web file | Flutter implementation | Example |
|---|---|---|
| `FOUNDATIONS.md`, `tokens.css` | `lib/design_system/tokens.dart`, `lib/design_system/app_theme.dart` | `example/lib/components/foundations_demo.dart` |
| `ds-kit.jsx`, `components-core.html` | `lib/design_system/components/core/core_components.dart` | `example/lib/components/core_components_demo.dart` |
| `components-domain.html` | `lib/design_system/components/domain/domain_components.dart` | `example/lib/components/domain_components_demo.dart` |
| `components-charts.html` | `lib/design_system/components/charts/chart_components.dart` | `example/lib/components/charts_demo.dart` |
| `components-skeletons.html` | `lib/design_system/components/skeletons/skeleton_components.dart` | `example/lib/components/skeletons_demo.dart` |
| `components-combobox.html` | `lib/design_system/components/forms/combo_box.dart` | `example/lib/components/combo_box_demo.dart` |
| `components-table.html` | `lib/design_system/components/data/editable_table.dart` | `example/lib/components/table_demo.dart` |
| `patterns.html` | `lib/design_system/components/patterns/design_patterns.dart` | `example/lib/components/patterns_demo.dart` |
| `motion.html` | `lib/design_system/components/motion/motion_components.dart` | `example/lib/components/motion_demo.dart` |
| `BrowserTabs.jsx`, `TabPages.jsx`, `components-browsertabs*.html` | `lib/design_system/components/navigation/*` | `example/lib/browser_tabs_demo.dart` |

## Public import

```dart
import 'package:geniuslink_design_system/geniuslink_design_system.dart';
```

## Theme setup

```dart
MaterialApp(
  theme: GeniusAppTheme.light(),
  darkTheme: GeniusAppTheme.dark(),
  home: const AllComponentsDemo(),
);
```

`GeniusAppTheme` registers both `GeniusThemeData` and the existing `BrowserStyleTabBarThemeData` adapter so older tab examples continue to work.

## Foundations

| API | Purpose |
|---|---|
| `GeniusThemeData` | Dark/light semantic surfaces, foreground ramp, semantic colors, typography, spacing, radius, motion, and breakpoints. |
| `GeniusAppTheme` | Ready-to-use `ThemeData` builders. |
| `glToneColor` | Converts semantic tone names to theme colors. |
| `glTextStyle` | Convenience text style using design-system typography. |

Documentation-only HTML source reference:

```html
<!-- from design_system/tokens.css; documentation reference only -->
--gl-dur-base: 150ms;
--gl-z-dropdown: 1000;
--gl-content-wide: 1120px;
```

## Core components

| API | Purpose |
|---|---|
| `GLIcon` | Token-aligned outlined icon adapter. |
| `GLButton` | Primary, secondary, danger, and ghost buttons. |
| `GLIconButton` | Icon-only action button with tooltip and minimum target support. |
| `GLSpinner` | Loading spinner. |
| `GLTextField` | Labelled field with required/error/disabled support. |
| `GLSearchField` | Search input using the core text field. |
| `GLPill` | Semantic status pill. |
| `GLBadge` | Count or dot badge. |
| `GLChip` | Filter/removable chip. |
| `GLAvatar` | Initials avatar. |
| `GLCard` | Tokenized surface card. |
| `GLListTile` | List row with icon/avatar/trailing slot. |
| `GLDivider` | Border-token divider. |
| `GLStateView` | Loading/empty/error style state content. |
| `GLSnackbar` | Inline snackbar/toast specimen. |
| `GLDialogCard` | Confirmation dialog card. |
| `GLMiniAppBar`, `GLMiniNav`, `GLMenuList` | App-bar, navigation, and menu specimens. |
| `GLShell`, `GLSection`, `GLSpec` | Documentation/demo layout components. |

Documentation-only HTML source reference:

```html
<!-- from components-core.html; documentation reference only -->
<StateView icon="poll" title="No entries yet" body="Posted journal entries will appear here." />
```

## Domain components

| API | Purpose |
|---|---|
| `GLStatusTicks` | Message status indicator. |
| `GLMessageBubble` | Chat bubble with direction/status support. |
| `GLComposer` | Message composer row. |
| `GLAttachmentMenu` | Attachment action menu. |
| `GLAudioBubble`, `GLVideoBubble`, `GLPollBubble` | Media and poll surfaces. |
| `GLMediaPreview` | File/media preview row. |
| `GLPinnedBar` | Pinned message/notice bar. |
| `GLNotificationTile` | Notification deep-link row. |
| `GLFileCard` | Upload/file status card. |
| `GLClubCard`, `GLMemberTile`, `GLTaskCard`, `GLRoomCard` | Collaboration/domain cards. |

## Chart components

| API | Purpose |
|---|---|
| `GLChartFrame` | Standard title/legend/chart container. |
| `GLChartLegendItem` | Legend token. |
| `GLLineAreaChart` | Line or area chart using `CustomPainter`. |
| `GLBarChart` | Token-aligned bar chart. |
| `GLDonutChart` | Donut chart with center label and legend. |
| `GLProgressRing` | Circular progress chart. |
| `GLKpiSparkline` | KPI number plus sparkline. |
| `GLChartState` | Chart loading/empty/error states. |

## Skeleton components

| API | Purpose |
|---|---|
| `GLSkeletonBone` | Base shimmer/pulse/still placeholder. |
| `GLTextSkeleton` | Multi-line text placeholder. |
| `GLAvatarSkeleton` | Avatar placeholder. |
| `GLCardSkeleton` | Card placeholder. |
| `GLListSkeleton` | List placeholder. |
| `GLTableSkeleton` | Table placeholder. |
| `GLChatSkeleton` | Chat placeholder. |
| `GLDashboardCardSkeleton` | Dashboard KPI placeholder. |
| `GLChartSkeleton` | Chart placeholder. |

## ComboBox components

| API | Purpose |
|---|---|
| `GLComboOption<T>` | Option model. |
| `GLComboBoxViewModel<T>` | Query/open/loading/error/selection view model. |
| `GLComboBox<T>` | Single, multi, searchable, async-ready combo box view. |

Documentation-only HTML source reference:

```html
<!-- from components-combobox.html; documentation reference only -->
<Trigger open={open} error={error} disabled={disabled}>Select account…</Trigger>
```

## Editable table components

| API | Purpose |
|---|---|
| `GLTableColumn` | Column model. |
| `GLTableRowModel` | Row model. |
| `GLTableController` | Rows, selected IDs, sorting, and edits. |
| `GLEditableTable` | Desktop table + responsive mobile cards. |
| `GLResponsiveDataCards` | Mobile data-card fallback. |
| `GLTableStateBox` | Loading/empty/error table states. |
| `glSampleColumns`, `glSampleRows` | Example data helpers. |

## Patterns

| API | Purpose |
|---|---|
| `GLSearchFilterPattern` | Search plus chips and filter button. |
| `GLPagination` | Compact numbered pagination. |
| `GLConfirmActionCard` | Post/delete confirmation pattern. |
| `GLPermissionRequestCard` | Permission prompt pattern. |
| `GLUploadPattern` | Dropzone plus upload file card. |
| `GLMessageStatusList` | Posting/message status list. |
| `GLOfflineSyncBanner` | Offline/online sync status banner. |
| `GLNotificationNavigationTile` | Notification-to-deep-link pattern. |

## Motion

| API | Purpose |
|---|---|
| `GLPressable` | Press/hover feedback wrapper. |
| `GLMotionTokenRow` | Motion token documentation row. |
| `GLMotionTokensView` | Motion token reference card. |
| `GLStaggeredList` | List entrance stagger demo. |
| `GLShimmerDemo` | Shimmer example. |

## Browser-style tabs

| API | Purpose |
|---|---|
| `BrowserStyleTabBar` | Browser-style workspace tab strip. |
| `BrowserStyleTabBarController` | Tab state controller. |
| `BrowserTab`, `GLTabKind` | Tab models. |
| `GLTabPage` | Built-in tab page content. |
| `BrowserStyleTabBarThemeData` | Existing tab theme extension. |

## Example launcher

The example launcher now contains a **Full Component Gallery** card that opens `AllComponentsDemo`. Individual demos are also available under `example/lib/components`.

## Release checkpoints

| Version | Component group |
|---|---|
| 1.1.0 | Existing browser tabs. |
| 1.1.1 | Foundations. |
| 1.1.2 | Core components. |
| 1.1.3 | Domain components. |
| 1.1.4 | Charts. |
| 1.1.5 | Skeletons. |
| 1.1.6 | ComboBox. |
| 1.1.7 | Editable table. |
| 1.1.8 | Patterns. |
| 1.1.9 | Motion. |
| 1.2.0 | Full stage documentation, exports, and example gallery. |
