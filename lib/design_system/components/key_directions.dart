/// Direction-aware keyboard helpers shared by every component that navigates a
/// horizontal axis with the arrow keys (`BrowserStyleTabBar`, `EditableTable`,
/// `ReadableTable`, `Tree`).
///
/// Navigation state is stored as a logical index, but in an RTL layout that
/// index axis is mirrored on screen. A naive handler that always maps
/// `arrowRight → index + 1` therefore moves the highlight to the *left* in
/// Arabic. These helpers keep the **visual** meaning of the key intact in both
/// directions: the right arrow always moves toward the right of the screen.
///
/// Usage — replace a hardcoded `±1` with [horizontalStep]:
/// ```dart
/// final step = horizontalStep(key, Directionality.of(context));
/// if (step != 0) controller.moveSelection(0, step);
/// ```
library;

import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';

/// Resolves a horizontal arrow [key] to a logical index *step* for the given
/// text [dir]. Returns `+1` (next index) or `-1` (previous index) for the
/// right/left arrows, mirrored under RTL, and `0` for any other key.
int horizontalStep(LogicalKeyboardKey key, TextDirection dir) {
  final rtl = dir == TextDirection.rtl;
  if (key == LogicalKeyboardKey.arrowRight) return rtl ? -1 : 1;
  if (key == LogicalKeyboardKey.arrowLeft) return rtl ? 1 : -1;
  return 0;
}

/// True when a horizontal arrow [key] points *toward deeper nesting* for the
/// given text [dir] — the arrow a `Tree` should treat as expand / step-in.
/// In LTR that is the right arrow; in RTL the indent mirrors, so it is the
/// left arrow. The opposite arrow collapses / steps out.
bool arrowGoesInto(LogicalKeyboardKey key, TextDirection dir) =>
    horizontalStep(key, dir) > 0;
