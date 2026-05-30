// ============================================================
// GeniusLink Design System — Flutter Tokens  (V2, documentation)
// ------------------------------------------------------------
// Mirrors design_system/tokens.css 1:1 so HTML specimens and the
// Flutter app stay in sync. NEVER hardcode these values inside a
// widget — read them from GL* classes or the active Theme.
//
// File placement:  lib/design_system/tokens/tokens.dart
// ============================================================

import 'package:flutter/material.dart';

/// ---- COLORS ------------------------------------------------
/// Single bright primary against a quiet neutral spine. Semantic
/// colors are state-only (never decoration).
class GLColors {
  // Brand / primary
  static const blue50  = Color(0xFFF0F2FF);
  static const blue100 = Color(0xFFDDE2F1);
  static const blue200 = Color(0xFFADC6FF);
  static const blue500 = Color(0xFF4A7CFF); // PRIMARY
  static const blue700 = Color(0xFF005AC2);

  // Section-marker accents
  static const markerBlue   = Color(0xFF4A7CFF);
  static const markerGreen  = Color(0xFF1DB88A);
  static const markerOrange = Color(0xFFF97316);

  // Semantic
  static const success = Color(0xFF1DB88A);
  static const warning = Color(0xFFF97316);
  static const danger  = Color(0xFFEF4444);

  // Dark surfaces
  static const darkBg      = Color(0xFF111318);
  static const darkSurface = Color(0xFF1A1B21);
  static const darkCard    = Color(0xFF1E2025);
  static const darkCard2   = Color(0xFF292D38);
  static const darkInput   = Color(0xFF33353A);
  static const darkHover   = Color(0xFF2F3540);
  static const darkBorder  = Color(0x6643464F); // rgba(67,70,84,.4)

  static const darkFg1 = Color(0xFFE2E2E9);
  static const darkFg2 = Color(0xFFC3C6D7);
  static const darkFg3 = Color(0xFF8D90A0);
  static const darkFg4 = Color(0xFF44474E);

  // Light surfaces
  static const lightBg      = Color(0xFFF7F8FA);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightInput   = Color(0xFFF1F3F8);
  static const lightHover   = Color(0xFFEEF1F7);
  static const lightBorder  = Color(0xFFE2E8F0);

  static const lightFg1 = Color(0xFF0F172A);
  static const lightFg2 = Color(0xFF424754);
  static const lightFg3 = Color(0xFF64748B);
  static const lightFg4 = Color(0xFFC2C6D6);
}

/// ---- TYPOGRAPHY -------------------------------------------
class GLFonts {
  static const display = 'Manrope';
  static const body    = 'Inter';
  static const mono    = 'JetBrainsMono';
  static const arabic  = 'NotoNaskhArabic';
}

/// Type scale (px == logical pixels).
class GLType {
  static const eyebrow = TextStyle(fontFamily: GLFonts.body, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.65, height: 1.5);
  static const label   = TextStyle(fontFamily: GLFonts.body, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.55);
  static const h1      = TextStyle(fontFamily: GLFonts.display, fontSize: 26, fontWeight: FontWeight.w700, letterSpacing: -0.65, height: 1.25);
  static const h2      = TextStyle(fontFamily: GLFonts.body, fontSize: 16, fontWeight: FontWeight.w700, height: 1.25);
  static const body14  = TextStyle(fontFamily: GLFonts.body, fontSize: 14, fontWeight: FontWeight.w400, height: 1.5);
  static const caption = TextStyle(fontFamily: GLFonts.body, fontSize: 12, fontWeight: FontWeight.w400, height: 1.5);
  static const mono14  = TextStyle(fontFamily: GLFonts.mono, fontSize: 14, fontFeatures: [FontFeature.tabularFigures()]);
}

/// ---- SPACING (4px base) -----------------------------------
class GLSpace {
  static const s1 = 4.0;  static const s2 = 8.0;  static const s3 = 12.0;
  static const s4 = 16.0; static const s5 = 24.0; static const s6 = 32.0;
  static const s7 = 40.0; static const s8 = 64.0; static const s9 = 80.0;
}

/// ---- RADIUS -----------------------------------------------
class GLRadius {
  static const xs = 2.0; static const sm = 4.0; static const md = 6.0;
  static const lg = 8.0; static const xl = 12.0; static const pill = 999.0;
}

/// ---- ELEVATION / SHADOWS ----------------------------------
class GLShadows {
  static const card = [
    BoxShadow(color: Color(0x40000000), blurRadius: 50, spreadRadius: -12, offset: Offset(0, 25)),
  ];
  static const cardLight = [
    BoxShadow(color: Color(0x0A0F172A), blurRadius: 2, offset: Offset(0, 1)),
    BoxShadow(color: Color(0x1F0F172A), blurRadius: 24, spreadRadius: -12, offset: Offset(0, 8)),
  ];
  static const pop = [
    BoxShadow(color: Color(0x73000000), blurRadius: 32, spreadRadius: -8, offset: Offset(0, 12)),
  ];
}

/// ---- MOTION -----------------------------------------------
class GLDur {
  static const instant  = Duration.zero;
  static const fast     = Duration(milliseconds: 100);
  static const base     = Duration(milliseconds: 150);
  static const moderate = Duration(milliseconds: 200);
  static const slow     = Duration(milliseconds: 300);
  static const slower   = Duration(milliseconds: 500);
  static const stagger  = Duration(milliseconds: 40);
}

class GLCurves {
  static const standard   = Cubic(0.4, 0, 0.2, 1);
  static const decelerate = Cubic(0, 0, 0.2, 1);   // enter
  static const accelerate = Cubic(0.4, 0, 1, 1);   // exit
  static const emphasized = Cubic(0.2, 0, 0, 1);   // sheets / dialogs
}

/// ---- Z-INDEX / OVERLAY LAYERS -----------------------------
/// In Flutter these map to Overlay/route priorities, not a CSS
/// stack — kept for parity & documentation.
class GLZ {
  static const base = 0, raised = 10, sticky = 100, dropdown = 1000;
  static const overlay = 2000, modal = 3000, toast = 4000, tooltip = 5000;
}

/// ---- BREAKPOINTS ------------------------------------------
class GLBreak {
  static const sm = 480.0, md = 768.0, lg = 1024.0, xl = 1280.0;
  static const contentMax = 720.0, contentWide = 1120.0, gutter = 24.0;

  /// Tables collapse to stacked cards below [md].
  static bool isCompact(BuildContext c) => MediaQuery.of(c).size.width < md;
}
