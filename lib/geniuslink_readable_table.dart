// ============================================================
// GeniusLink — ReadableTable — public barrel export.
//   import 'package:geniuslink_design_system/geniuslink_readable_table.dart';
//
// A read-only, generic display grid built MVC (the display sibling of
// EditableTable, with which it shares a theme):
//   • Model      — readable_table_models.dart      (ReadableColumn<T>, cell, enums)
//   • Filter     — readable_table_filter.dart      (ReadableFilter + ReadableFilterGroup tree)
//   • Controller — readable_table_controller.dart  (ChangeNotifier + scope;
//                  select/add/delete/replace by index · value · where · firstWhere;
//                  advanced filtering: flat predicates AND/OR + nested tree + search)
//   • View       — readable_table.dart             (ReadableTable<T> widget)
//   • FilterBar  — readable_table_filter_bar.dart  (ReadableFilterBar — flat chip UI)
//   • FilterView — readable_table_filter_view.dart (ReadableFilterEditingView — nested builder)
//   • Theme      — editable_table_theme.dart        (shared with EditableTable)
// ============================================================

export 'design_system/components/data/editable_table_theme.dart';
export 'design_system/components/data/readable_table_models.dart';
export 'design_system/components/data/readable_table_filter.dart';
export 'design_system/components/data/readable_table_controller.dart';
export 'design_system/components/data/readable_table.dart';
export 'design_system/components/data/readable_table_filter_bar.dart';
export 'design_system/components/data/readable_table_filter_view.dart';
