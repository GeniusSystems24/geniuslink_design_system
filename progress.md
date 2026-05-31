# genius_design_system_flutter — Stage: `genius_design_system_web/design_system`

## Stage plan before implementation

**Architecture decision:** This stage uses a practical mix of MVVM, MVC, and view-only composition.

1. **Inventory and parity map** — list all files in `genius_design_system_web/design_system` and map each web component group to Flutter folders, public exports, examples, and documentation.
2. **Foundations** — create shared Flutter tokens and app theme helpers so components consume semantic roles instead of hard-coded CSS/HTML values.
3. **Core components** — implement DS kit primitives: icons, buttons, icon buttons, spinner, fields, search, pills, badges, chips, avatars, cards, tiles, dividers, state views, mini navigation, menu, dialog, snackbar, shell, section, and spec cards.
4. **Domain components** — implement chat/media/collaboration components: ticks, bubbles, composer, attachment menu, audio/video/poll/media, pinned bar, notification tile, file card, club card, member tile, task card, and room card.
5. **Data visualization** — implement chart frame, line/area, bars, donut, progress ring, KPI sparkline, legends, and loading/empty/error chart states.
6. **Loading skeletons** — implement shimmer, pulse, and still skeleton variants for text, avatar, card, list, table, chat, dashboard cards, and charts.
7. **Forms** — implement ComboBox with MVVM view model for single, multi, async, searchable, empty, loading, and error states; update ComboBox to use `smart_auto_suggest_box` for overlay/search/chip behavior.
8. **Editable data table** — implement table models and MVVM controller with selection, sorting, inline editing, responsive mobile cards, and table state boxes.
9. **Patterns and motion** — implement composed reusable patterns and token-driven motion helpers.
10. **Examples and documentation** — add example screens under `example/lib/components`, update public barrel exports, create `index.md`, update README/CHANGELOG, and bump package version.

## Source inventory and completion status

| Web source | Flutter destination | Pattern | Status | Release checkpoint |
|---|---|---:|---|---:|
| `FOUNDATIONS.md`, `tokens.css` | `lib/design_system/tokens.dart`, `app_theme.dart` | Tokens / ThemeExtension | Complete | 1.1.1 |
| `ds-kit.jsx`, `components-core.html` | `lib/design_system/components/core/core_components.dart` | MVVM-ready views | Complete | 1.1.2 |
| `components-domain.html` | `lib/design_system/components/domain/domain_components.dart` | MVVM-ready views | Complete | 1.1.3 |
| `components-charts.html` | `lib/design_system/components/charts/chart_components.dart` | MVC / CustomPainter | Complete | 1.1.4 |
| `components-skeletons.html` | `lib/design_system/components/skeletons/skeleton_components.dart` | View-only token animation | Complete | 1.1.5 |
| `components-combobox.html` | `lib/design_system/components/forms/combo_box.dart` | MVVM + `smart_auto_suggest_box` adapter | Complete | 1.2.1 |
| `components-table.html` | `lib/design_system/components/data/editable_table.dart` | MVVM | Complete | 1.1.7 |
| `patterns.html` | `lib/design_system/components/patterns/design_patterns.dart` | Composition / MVVM-friendly | Complete | 1.1.8 |
| `motion.html` | `lib/design_system/components/motion/motion_components.dart` | Token-driven view animation | Complete | 1.1.9 |
| `BrowserTabs.jsx`, `TabPages.jsx`, `components-browsertabs*.html` | Existing navigation implementation | MVVM-C style controller + views | Complete / retained | 1.1.0 |
| `DESIGN_SYSTEM.md`, `flutter-structure.md` | `index.md`, README, examples | Documentation | Complete | 1.2.0 |

## Component checklist

### Foundations

| Component / token area | Status |
|---|---|
| Dark/light surfaces | Complete |
| Semantic colors | Complete |
| Typography families | Complete |
| Spacing scale | Complete |
| Radius scale | Complete |
| Motion durations/easing | Complete |
| Breakpoints/content widths | Complete |
| App theme helpers | Complete |

### Core

| Component | Status |
|---|---|
| `GLIcon` | Complete |
| `GLButton` | Complete |
| `GLIconButton` | Complete |
| `GLSpinner` | Complete |
| `GLTextField` | Complete |
| `GLSearchField` | Complete |
| `GLPill` | Complete |
| `GLBadge` | Complete |
| `GLChip` | Complete |
| `GLAvatar` | Complete |
| `GLCard` | Complete |
| `GLListTile` | Complete |
| `GLDivider` | Complete |
| `GLStateView` | Complete |
| `GLSnackbar` | Complete |
| `GLDialogCard` | Complete |
| `GLMiniAppBar` | Complete |
| `GLMiniNav` | Complete |
| `GLMenuList` | Complete |
| `GLShell`, `GLSection`, `GLSpec` | Complete |

### Domain

| Component | Status |
|---|---|
| `GLStatusTicks` | Complete |
| `GLMessageBubble` | Complete |
| `GLComposer` | Complete |
| `GLAttachmentMenu` | Complete |
| `GLAudioBubble` | Complete |
| `GLVideoBubble` | Complete |
| `GLPollBubble` | Complete |
| `GLMediaPreview` | Complete |
| `GLPinnedBar` | Complete |
| `GLNotificationTile` | Complete |
| `GLFileCard` | Complete |
| `GLClubCard` | Complete |
| `GLMemberTile` | Complete |
| `GLTaskCard` | Complete |
| `GLRoomCard` | Complete |

### Charts, skeletons, forms, table, patterns, motion

| Component | Status |
|---|---|
| `GLChartFrame`, `GLChartLegendItem` | Complete |
| `GLLineAreaChart`, `GLBarChart`, `GLDonutChart` | Complete |
| `GLProgressRing`, `GLKpiSparkline`, `GLChartState` | Complete |
| `GLSkeletonBone`, `GLTextSkeleton`, `GLAvatarSkeleton` | Complete |
| `GLCardSkeleton`, `GLListSkeleton`, `GLTableSkeleton`, `GLChatSkeleton` | Complete |
| `GLDashboardCardSkeleton`, `GLChartSkeleton` | Complete |
| `GLComboOption`, `GLComboBoxViewModel`, `GLComboBox` | Complete — migrated to `SmartAutoSuggestBox` / `SmartAutoSuggestMultiSelectBox` in 1.2.1 |
| `GLTableColumn`, `GLTableRowModel`, `GLTableController`, `GLEditableTable` | Complete |
| `GLResponsiveDataCards`, `GLTableStateBox` | Complete |
| `GLSearchFilterPattern`, `GLPagination`, `GLConfirmActionCard` | Complete |
| `GLPermissionRequestCard`, `GLUploadPattern`, `GLMessageStatusList` | Complete |
| `GLOfflineSyncBanner`, `GLNotificationNavigationTile` | Complete |
| `GLPressable`, `GLMotionTokenRow`, `GLMotionTokensView` | Complete |
| `GLStaggeredList`, `GLShimmerDemo` | Complete |

## Examples added

| Example file | Status |
|---|---|
| `example/lib/components/foundations_demo.dart` | Complete |
| `example/lib/components/core_components_demo.dart` | Complete |
| `example/lib/components/domain_components_demo.dart` | Complete |
| `example/lib/components/charts_demo.dart` | Complete |
| `example/lib/components/skeletons_demo.dart` | Complete |
| `example/lib/components/combo_box_demo.dart` | Complete |
| `example/lib/components/table_demo.dart` | Complete |
| `example/lib/components/patterns_demo.dart` | Complete |
| `example/lib/components/motion_demo.dart` | Complete |
| `example/lib/components/all_components_demo.dart` | Complete |

## Notes

- HTML snippets from the web project are used only inside `index.md` documentation. No HTML was embedded into Flutter source code.
- The current package version is `1.2.1`. The changelog records release checkpoints for each completed component group.
- `smart_auto_suggest_box: ^0.15.3` was added for ComboBox. Pub.dev lists 0.15.x with minimum Dart SDK `3.10`, so `pubspec.yaml` now requires Dart `>=3.10.0`.
- I could not run `flutter pub get`, `flutter analyze`, or `flutter test` in this sandbox because Flutter/Dart tooling is not installed here; the code is organized and checked manually against Dart syntax and public exports.
