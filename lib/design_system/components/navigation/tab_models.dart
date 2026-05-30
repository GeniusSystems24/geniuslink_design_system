// ============================================================
// BrowserStyleTabBar — models & maps.
// Mirrors the tab data shape and icon set used in BrowserTabs.jsx.
//   File: lib/design_system/components/navigation/tab_models.dart
// ============================================================

import 'package:flutter/material.dart';

/// Builds the content shown for a tab — both in the active content surface
/// and (scaled down) inside the hover preview. Lets a host render
/// style-appropriate pages (ERP doc, design canvas, web page …) while the
/// component falls back to its built-in [GLTabPage] when this is null.
typedef TabPageBuilder = Widget Function(BuildContext context, BrowserTab tab);

/// The page-type of a workspace tab. Drives the leading icon, the
/// mini-page preview layout and the full content surface — exactly like
/// the `icon` string in the JSX (ledger · doc · store · chart · user · globe).
enum GLTabKind { ledger, doc, store, chart, user, globe }

/// A single workspace tab. Generic / no business-model coupling.
class BrowserTab {
  final int id;
  String title;
  final GLTabKind kind;
  bool dirty; // unsaved-changes indicator
  bool pinned; // icon-only, anchored on the start edge

  BrowserTab({
    required this.id,
    required this.title,
    required this.kind,
    this.dirty = false,
    this.pinned = false,
  });

  BrowserTab copyWith({int? id, String? title, GLTabKind? kind, bool? dirty, bool? pinned}) =>
      BrowserTab(
        id: id ?? this.id,
        title: title ?? this.title,
        kind: kind ?? this.kind,
        dirty: dirty ?? this.dirty,
        pinned: pinned ?? this.pinned,
      );
}

/// Material icon for each tab kind (closest match to the JSX line-icons).
IconData glTabIcon(GLTabKind kind) {
  switch (kind) {
    case GLTabKind.ledger:
      return Icons.menu_book_outlined;
    case GLTabKind.doc:
      return Icons.description_outlined;
    case GLTabKind.store:
      return Icons.storefront_outlined;
    case GLTabKind.chart:
      return Icons.bar_chart_rounded;
    case GLTabKind.user:
      return Icons.people_alt_outlined;
    case GLTabKind.globe:
      return Icons.public;
  }
}

/// Type label shown in the hover-preview header (mirrors PREVIEW_META).
String glPreviewMeta(GLTabKind kind) {
  switch (kind) {
    case GLTabKind.ledger:
      return 'Accounting · Ledger';
    case GLTabKind.doc:
      return 'Journal · Document';
    case GLTabKind.store:
      return 'Branch · Storefront';
    case GLTabKind.chart:
      return 'Analytics · Dashboard';
    case GLTabKind.user:
      return 'Directory · People';
    case GLTabKind.globe:
      return 'Workspace · Page';
  }
}

/// Rotating kinds for the "New Tab" (+) button, matching the JSX cycle.
const List<GLTabKind> kNewTabCycle = [
  GLTabKind.globe,
  GLTabKind.user,
  GLTabKind.store,
  GLTabKind.chart,
  GLTabKind.doc,
];
