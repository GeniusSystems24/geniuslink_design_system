// ============================================================
// GeniusLink — ReadableTable — public barrel export.
//   import 'package:geniuslink_design_system/geniuslink_readable_table.dart';
//
// A read-only, generic display grid built MVC (the display sibling of
// EditableTable, with which it shares a theme):
//   • Model      — readable_table_models.dart      (ReadableColumn<T>, cell, enums)
//   • Filter     — readable_table_filter.dart      (ReadableFilter, ops, catalog)
//   • Controller — readable_table_controller.dart  (ChangeNotifier + scope;
//                  select/add/delete/replace by index · value · where · firstWhere;
//                  advanced filtering: per-column predicates AND/OR + search)
//   • View       — readable_table.dart             (ReadableTable<T> widget)
//   • FilterBar  — readable_table_filter_bar.dart  (ReadableFilterBar UI)
//   • Theme      — editable_table_theme.dart        (shared with EditableTable)
// ============================================================

export 'design_system/components/data/editable_table_theme.dart';
export 'design_system/components/data/readable_table_models.dart';
export 'design_system/components/data/readable_table_filter.dart';
export 'design_system/components/data/readable_table_controller.dart';
export 'design_system/components/data/readable_table.dart';
export 'design_system/components/data/readable_table_filter_bar.dart';
