// ============================================================
// GeniusLink Design System — unified public barrel.
//   import 'package:geniuslink_design_system/geniuslink_design_system.dart';
//
// Re-exports the whole kit. For a leaner import you can still pull a single
// component group from its own barrel:
//   • geniuslink_browser_tabs.dart       — BrowserStyleTabBar
//   • geniuslink_editable_table.dart     — EditableTable + typed columns
//   • geniuslink_readable_table.dart     — ReadableTable (read-only display grid)
//   • geniuslink_tree.dart               — Tree
//   • geniuslink_navigation_sidebar.dart — NavigationSidebar (rail · drawer · tree nav)
//
// v2.3.0
// ============================================================

export 'geniuslink_browser_tabs.dart';
export 'geniuslink_editable_table.dart';
export 'geniuslink_readable_table.dart' hide EditableTableThemeData;
export 'geniuslink_tree.dart';
export 'geniuslink_navigation_sidebar.dart';
