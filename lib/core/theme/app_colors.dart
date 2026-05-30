import 'package:flutter/material.dart';

class AppColors {

  // ── Primary — Acid Lime ───────────────────────────────
  static const Color primary      = Color(0xFF15E6A0);
  static const Color primaryLight = Color(0xFF00CFA4);
  static const Color primaryDark  = Color(0xFF00D0A3);

  // ── Backgrounds / Surfaces ────────────────────────────
  static const Color bg       = Color(0xFF0A0F1C);
  static const Color surface1 = Color(0xFF111827);
  static const Color surface2 = Color(0xFF1A2233);
  static const Color surface3 = Color(0xFF202B3C);

  // ── Borders ───────────────────────────────────────────
  static const Color border  = Color(0xFF2A3120);
  static const Color border2 = Color(0xFF3A4229);

  // ── Text ──────────────────────────────────────────────
  static const Color textPrimary   = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFBBC2D1);
  static const Color textMuted     = Color(0xFF7BB794);
  static const Color textDim       = Color(0xFF4B5563);

  // ── Semantic ──────────────────────────────────────────
  static const Color success = Color(0xFF22E58B);
  static const Color warning = Color(0xFFFFB547);
  static const Color error   = Color(0xFFFF5A6B);
  static const Color info    = Color(0xFF3BA7FF);

  // ── Accent palette ────────────────────────────────────
  static const Color orange = Color(0xFFFF6B35);
  static const Color blue   = Color(0xFF4DAAFF);
  static const Color purple = Color(0xFFB57BFF);
  static const Color gold   = Color(0xFFFFD700);
  static const Color teal   = Color(0xFF2DDAAD);
  static const Color pink   = Color(0xFFFF6B9D);

  // ── Primary opacity helpers ───────────────────────────
  static Color primaryDim    = primary.withOpacity(0.10);
  static Color primaryBorder = primary.withOpacity(0.25);
  static Color primaryGlow   = primary.withOpacity(0.18);

  // ── Gradients ─────────────────────────────────────────
  static const LinearGradient splashGradient = LinearGradient(
    begin: Alignment.topCenter, end: Alignment.bottomCenter,
    colors: [Color(0xFF182800), Color(0xFF080808)],
  );

  static const LinearGradient cardGymGradient = LinearGradient(
    begin: Alignment.topLeft, end: Alignment.bottomRight,
    colors: [Color(0xFF0D2200), Color(0xFF220D00)],
  );

  static const LinearGradient cardRunGradient = LinearGradient(
    begin: Alignment.topLeft, end: Alignment.bottomRight,
    colors: [Color(0xFF001428), Color(0xFF002814)],
  );

  static const LinearGradient compatGradient = LinearGradient(
    colors: [Color(0xFFBAEE0B), Color(0xFF0ABFCE)],
  );

  static const LinearGradient membershipGradient = LinearGradient(
    begin: Alignment.topLeft, end: Alignment.bottomRight,
    colors: [Color(0xFF1A2800), Color(0xFF0D1A00)],
  );

  static const LinearGradient offerGradient = LinearGradient(
    colors: [Color(0xFFFF6B35), Color(0xFFFF4D4D)],
  );
}