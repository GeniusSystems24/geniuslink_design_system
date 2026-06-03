// ============================================================
// GeniusLink — ReadableTable — public barrel export.
//   import 'package:geniuslink_design_system/geniuslink_readable_table.dart';
//
// A read-only, generic display grid built MVC (the display sibling of
// EditableTable, with which it shares a theme):
//   • Model      — readable_table_models.dart      (ReadableColumn<T>, cell, enums)
//   • Controller — readable_table_controller.dart  (ChangeNotifier + scope;
//                  select/add/delete/replace by index · value · where · firstWhere)
//   • View       — readable_table.dart             (ReadableTable<T> widget)
//   • Theme      — editable_table_theme.dart        (shared with EditableTable)
// ============================================================

export 'design_system/components/data/editable_table_theme.dart';
export 'design_system/components/data/readable_table_models.dart';
export 'design_system/components/data/readable_table_controller.dart';
export 'design_system/components/data/readable_table.dart';
