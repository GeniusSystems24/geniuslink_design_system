import 'package:flutter/material.dart';

/// The semantic page type represented by a browser tab.
///
/// The value drives the tab icon, preview metadata, and demo page selected by
/// [GLTabPage].
enum GLTabKind {
  /// Accounting ledger or account-list content.
  ledger,

  /// Document-like content such as a journal entry.
  doc,

  /// Branch, store, or location content.
  store,

  /// Analytics dashboard content.
  chart,

  /// People, team, or directory content.
  user,

  /// Generic workspace page content.
  globe,
}

/// Mutable tab state consumed by [BrowserStyleTabBar].
///
/// The model is intentionally generic so applications can map domain entities
/// to tabs without coupling the design-system package to business models.
class BrowserTab {
  /// Stable identifier used for selection, close, duplicate, and reorder logic.
  final int id;

  /// Human-readable tab label shown in the strip, dropdown, and previews.
  String title;

  /// Semantic content type used for icons and demo page rendering.
  final GLTabKind kind;

  /// Whether the tab has unsaved changes.
  ///
  /// Dirty tabs show an indicator and ask for confirmation before closing.
  bool dirty;

  /// Whether the tab is pinned to the leading edge of the strip.
  ///
  /// Pinned tabs render as compact icon-only tabs and do not scroll with the
  /// unpinned region.
  bool pinned;

  /// Creates a browser tab model.
  BrowserTab({
    required this.id,
    required this.title,
    required this.kind,
    this.dirty = false,
    this.pinned = false,
  });

  /// Returns a copy of this tab with selected fields replaced.
  BrowserTab copyWith({
    int? id,
    String? title,
    GLTabKind? kind,
    bool? dirty,
    bool? pinned,
  }) =>
      BrowserTab(
        id: id ?? this.id,
        title: title ?? this.title,
        kind: kind ?? this.kind,
        dirty: dirty ?? this.dirty,
        pinned: pinned ?? this.pinned,
      );
}

/// Returns the Material icon that represents [kind] in tabs and previews.
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

/// Returns the short type label shown in the hover-preview header.
String glPreviewMeta(GLTabKind kind) {
  switch (kind) {
    case GLTabKind.ledger:
      return 'Accounting / Ledger';
    case GLTabKind.doc:
      return 'Journal / Document';
    case GLTabKind.store:
      return 'Branch / Storefront';
    case GLTabKind.chart:
      return 'Analytics / Dashboard';
    case GLTabKind.user:
      return 'Directory / People';
    case GLTabKind.globe:
      return 'Workspace / Page';
  }
}

/// Rotation used by the new-tab button to assign demo page kinds.
const List<GLTabKind> kNewTabCycle = [
  GLTabKind.globe,
  GLTabKind.user,
  GLTabKind.store,
  GLTabKind.chart,
  GLTabKind.doc,
];
