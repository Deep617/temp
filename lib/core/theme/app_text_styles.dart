// ─────────────────────────────────────────────────────────
//  APP TEXT STYLES
//  lib/theme/app_text_styles.dart
//
//  All typography uses the locally-bundled Syne font family.
//  No network dependency — works fully offline.
//
//  Scale (desktop-adapted to mobile):
//    display  48 / w800  — hero numbers, splash
//    h1       32 / w800  — page titles
//    h2       24 / w700  — section titles, card names
//    h3       18 / w700  — sub-section titles, AppBar
//    subtitle 16 / w600  — list items, form labels
//    body     14 / w400  — general paragraph text
//    bodySM   12 / w400  — secondary info, captions
//    label    11 / w700  — ALL-CAPS chip labels, tags
//    caption  10 / w500  — timestamps, metadata
//    btn      14 / w800  — button copy
//    metric   28 / w800  — XP / stat numbers
//
//  Usage:
//    Text('Hello', style: AppTextStyles.h1())
//    Text('Hello', style: AppTextStyles.body(color: AppColors.primary))
// ─────────────────────────────────────────────────────────

import 'package:flutter/material.dart';

import 'app_colors.dart';


// ── Font family constant ──────────────────────────────────
// Using a const so a typo is a compile error, not a silent fallback.
const String _syne = 'Syne';

// ── Font weight aliases ───────────────────────────────────
// Mirrors the five weights declared in pubspec.yaml.
abstract final class AppFontWeights {
  static const FontWeight regular   = FontWeight.w400;
  static const FontWeight medium    = FontWeight.w500;
  static const FontWeight semiBold  = FontWeight.w600;
  static const FontWeight bold      = FontWeight.w700;
  static const FontWeight extraBold = FontWeight.w800;
}

// ── Text styles ───────────────────────────────────────────
abstract final class AppTextStyles {
  AppTextStyles._();

  // ── Display ───────────────────────────────────────────
  /// 48 / ExtraBold  — hero numbers, match screen title
  static TextStyle display({Color color = AppColors.textPrimary}) => TextStyle(
    fontFamily:    _syne,
    fontSize:      48,
    fontWeight:    AppFontWeights.extraBold,
    color:         color,
    letterSpacing: -2.0,
    height:        1.0,
  );

  // ── Headings ──────────────────────────────────────────
  /// 32 / ExtraBold  — page hero titles
  static TextStyle h1({Color color = AppColors.textPrimary}) => TextStyle(
    fontFamily:    _syne,
    fontSize:      32,
    fontWeight:    AppFontWeights.extraBold,
    color:         color,
    letterSpacing: -1.0,
    height:        1.1,
  );

  /// 24 / Bold  — section titles, buddy card name
  static TextStyle h2({Color color = AppColors.textPrimary}) => TextStyle(
    fontFamily:    _syne,
    fontSize:      24,
    fontWeight:    AppFontWeights.bold,
    color:         color,
    letterSpacing: -0.5,
    height:        1.2,
  );

  /// 18 / Bold  — AppBar title, modal headers
  static TextStyle h3({Color color = AppColors.textPrimary}) => TextStyle(
    fontFamily:    _syne,
    fontSize:      18,
    fontWeight:    AppFontWeights.bold,
    color:         color,
    letterSpacing: -0.3,
    height:        1.3,
  );

  // ── Body family ───────────────────────────────────────
  /// 16 / SemiBold  — list tile titles, form field labels
  static TextStyle subtitle({Color color = AppColors.textSecondary}) => TextStyle(
    fontFamily:    _syne,
    fontSize:      16,
    fontWeight:    AppFontWeights.semiBold,
    color:         color,
    height:        1.4,
  );

  /// 14 / Regular  — paragraph text, form hints, descriptions
  static TextStyle body({Color color = AppColors.textSecondary}) => TextStyle(
    fontFamily:    _syne,
    fontSize:      14,
    fontWeight:    AppFontWeights.regular,
    color:         color,
    height:        1.6,
  );

  /// 12 / Regular  — secondary descriptions, helper text
  static TextStyle bodySM({Color color = AppColors.textMuted}) => TextStyle(
    fontFamily:    _syne,
    fontSize:      12,
    fontWeight:    AppFontWeights.regular,
    color:         color,
    height:        1.5,
  );

  // ── Utility ───────────────────────────────────────────
  /// 11 / ExtraBold / tracked  — ALL-CAPS chip labels, section headers
  static TextStyle label({Color color = AppColors.textMuted}) => TextStyle(
    fontFamily:    _syne,
    fontSize:      11,
    fontWeight:    AppFontWeights.extraBold,
    color:         color,
    letterSpacing: 1.2,
    height:        1.3,
  );

  /// 10 / Medium / tracked  — timestamps, distance badges
  static TextStyle caption({Color color = AppColors.textMuted}) => TextStyle(
    fontFamily:    _syne,
    fontSize:      10,
    fontWeight:    AppFontWeights.medium,
    color:         color,
    letterSpacing: 0.6,
    height:        1.4,
  );

  /// 14 / ExtraBold  — button copy
  static TextStyle btn({Color color = Colors.black}) => TextStyle(
    fontFamily:    _syne,
    fontSize:      14,
    fontWeight:    AppFontWeights.extraBold,
    color:         color,
    letterSpacing: 0.3,
    height:        1.2,
  );

  /// 28 / ExtraBold  — XP counters, stat numbers
  static TextStyle metric({Color color = AppColors.primary}) => TextStyle(
    fontFamily:    _syne,
    fontSize:      28,
    fontWeight:    AppFontWeights.extraBold,
    color:         color,
    letterSpacing: -1.0,
    height:        1.1,
  );

  // ── Global Text Theme ─────────────────────────────────
  // Used inside ThemeData to set Syne as the default for
  // every Text widget that doesn't specify a style.
  static TextTheme get textTheme => TextTheme(
    // Material 3 role → our scale mapping
    displayLarge:  display(),
    displayMedium: h1(),
    displaySmall:  h2(),
    headlineLarge: h2(),
    headlineMedium:h3(),
    headlineSmall: subtitle(),
    titleLarge:    h3(),
    titleMedium:   subtitle(),
    titleSmall:    body(),
    bodyLarge:     body(),
    bodyMedium:    bodySM(),
    bodySmall:     caption(),
    labelLarge:    btn(),
    labelMedium:   label(),
    labelSmall:    caption(),
  );
}
