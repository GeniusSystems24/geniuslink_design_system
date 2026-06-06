// ============================================================
// GeniusLink Design System — unified public barrel.
//   import 'package:geniuslink_design_system/geniuslink_design_system.dart';
//
// Re-exports the whole kit. For a leaner import you can still pull a single
// component group from its own barrel:
//   • geniuslink_browser_tabs.dart       — BrowserStyleTabBar
//   • geniuslink_editable_table.dart     — EditableTable + typed columns (map rows)
//   • geniuslink_editable_table_generic.dart — EditableTable<T> (typed rows) — import INSTEAD of the map table
//   • geniuslink_readable_table.dart     — ReadableTable (read-only display grid)
//   • geniuslink_tree.dart               — Tree
//   • geniuslink_navigation_sidebar.dart — NavigationSidebar (rail · drawer · tree nav)
//
// v2.5.0
// ============================================================
//
// NOTE: the generic `EditableTable<T>` lives in its own barrel
// (geniuslink_editable_table_generic.dart) — it declares the same names as the
// map-backed table, so it is NOT re-exported here. Import it directly instead.

export 'geniuslink_browser_tabs.dart';
export 'geniuslink_editable_table.dart';
export 'geniuslink_readable_table.dart' hide EditableTableThemeData;
export 'geniuslink_tree.dart';
export 'geniuslink_navigation_sidebar.dart';
