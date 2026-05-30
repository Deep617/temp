// ─────────────────────────────────────────────────────────
//  APP THEME
//  lib/theme/app_theme.dart
//
//  Re-exports AppColors and AppTextStyles so every screen
//  only needs one import:
//    import '../theme/app_theme.dart';
//
//  Font strategy
//  ─────────────
//  • fontFamily: 'Syne'  sets the global default.
//  • ThemeData.textTheme is populated from AppTextStyles so
//    every Material widget (AppBar, ListTile, Dialog…) uses
//    our type scale automatically.
//  • No google_fonts → works fully offline.
// ─────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';


class AppTheme {
  AppTheme._();

  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness:   Brightness.dark,

      // ── Global font ──────────────────────────────────
      fontFamily:  'Syne',
      textTheme:   AppTextStyles.textTheme,

      // ── Colours ──────────────────────────────────────
      scaffoldBackgroundColor: AppColors.bg,
      colorScheme: const ColorScheme.dark(
        background:    AppColors.bg,
        surface:       AppColors.surface1,
        surfaceVariant:AppColors.surface2,
        primary:       AppColors.primary,
        secondary:     AppColors.teal,
        tertiary:      AppColors.warning,
        error:         AppColors.error,
        onBackground:  AppColors.textPrimary,
        onSurface:     AppColors.textPrimary,
        onPrimary:     Colors.black,
        onSecondary:   Colors.black,
        onError:       Colors.white,
        outline:       AppColors.border,
        outlineVariant:AppColors.border2,
      ),

      // ── AppBar ───────────────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor:     AppColors.surface1,
        elevation:           0,
        centerTitle:         false,
        systemOverlayStyle:  _overlayDark,
        titleTextStyle:      AppTextStyles.h3(),
        iconTheme: const IconThemeData(
            color: AppColors.textPrimary, size: 22),
      ),

      // ── Inputs ───────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled:              true,
        fillColor:           AppColors.surface2,
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 14),
        border:              _border(AppColors.border2),
        enabledBorder:       _border(AppColors.border2),
        focusedBorder:       _border(AppColors.primary, width: 1.5),
        errorBorder:         _border(AppColors.error),
        focusedErrorBorder:  _border(AppColors.error,   width: 1.5),
        hintStyle:           AppTextStyles.body(color: AppColors.textDim),
        labelStyle:          AppTextStyles.bodySM(color: AppColors.textMuted),
        errorStyle:          AppTextStyles.bodySM(color: AppColors.error),
      ),

      // ── Buttons ──────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.black,
          minimumSize:     const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          elevation:  0,
          textStyle:  AppTextStyles.btn(),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          minimumSize:     const Size(double.infinity, 52),
          side:            const BorderSide(color: AppColors.border2),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          textStyle: AppTextStyles.subtitle(),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: AppTextStyles.bodySM(color: AppColors.primary)
              .copyWith(fontWeight: FontWeight.w700),
        ),
      ),

      // ── Bottom Nav ───────────────────────────────────
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor:      AppColors.surface1,
        selectedItemColor:    AppColors.primary,
        unselectedItemColor:  AppColors.textDim,
        type:                 BottomNavigationBarType.fixed,
        elevation:            0,
        selectedLabelStyle:   AppTextStyles.caption(color: AppColors.primary),
        unselectedLabelStyle: AppTextStyles.caption(),
      ),

      // ── Misc ─────────────────────────────────────────
      dividerTheme: const DividerThemeData(
          color: AppColors.border, thickness: 1, space: 0),

      checkboxTheme: CheckboxThemeData(
        fillColor: MaterialStateProperty.resolveWith((s) =>
            s.contains(MaterialState.selected)
                ? AppColors.primary : AppColors.surface3),
        checkColor: MaterialStateProperty.all(Colors.black),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith((s) =>
            s.contains(MaterialState.selected)
                ? Colors.black : AppColors.textDim),
        trackColor: MaterialStateProperty.resolveWith((s) =>
            s.contains(MaterialState.selected)
                ? AppColors.primary : AppColors.surface3),
      ),

      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: AppColors.surface3,
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor:  AppColors.surface2,
        contentTextStyle: AppTextStyles.body(color: AppColors.textPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        behavior: SnackBarBehavior.floating,
      ),

      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surface2,
        labelStyle:      AppTextStyles.bodySM(),
        side:            const BorderSide(color: AppColors.border2),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(100)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),

      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),

      cardTheme: CardThemeData(
        color: AppColors.surface1,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border),
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor:  AppColors.surface1,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        titleTextStyle:   AppTextStyles.h3(),
        contentTextStyle: AppTextStyles.body(),
      ),

      tabBarTheme: TabBarThemeData(
        labelColor:           AppColors.primary,
        unselectedLabelColor: AppColors.textMuted,
        indicatorColor:       AppColors.primary,
        indicatorSize:        TabBarIndicatorSize.tab,
        labelStyle:           AppTextStyles.label(color: AppColors.primary),
        unselectedLabelStyle: AppTextStyles.label(),
      ),

      listTileTheme: ListTileThemeData(
        iconColor:         AppColors.textMuted,
        titleTextStyle:    AppTextStyles.subtitle(),
        subtitleTextStyle: AppTextStyles.bodySM(),
      ),

      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color:        AppColors.surface3,
          borderRadius: BorderRadius.circular(8),
          border:       Border.all(color: AppColors.border2),
        ),
        textStyle: AppTextStyles.bodySM(color: AppColors.textPrimary),
      ),
    );
  }

  // ── System overlay ────────────────────────────────────
  static SystemUiOverlayStyle get overlayStyle => _overlayDark;

  static const SystemUiOverlayStyle _overlayDark = SystemUiOverlayStyle(
    statusBarColor:                   Colors.transparent,
    statusBarIconBrightness:          Brightness.light,
    systemNavigationBarColor:         AppColors.surface1,
    systemNavigationBarIconBrightness:Brightness.light,
  );

  // ── Helper ────────────────────────────────────────────
  static OutlineInputBorder _border(Color color, {double width = 1.0}) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide:   BorderSide(color: color, width: width),
      );
}
