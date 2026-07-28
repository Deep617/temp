import 'package:flutter/material.dart';

class AppColors {





  /// Electric Pulse Blue #0A84FF — Primary CTAs, active buttons
  static const Color primary      = Color(0xFF0A84FF);

  /// Sync Cyan #00B2FF — Secondary highlights, neon accents
  static const Color cyan         = Color(0xFF00B2FF);

  /// Pulse Teal #00D0A3 — Active tabs, success states
  static const Color teal         = Color(0xFF00D0A3);

  /// Energy Mint #15E6A0 — Notification dots, live indicators
  static const Color mint         = Color(0xFF15E6A0);

  /// Global Accent #00CFA4 — CTAs, graphs, key interactions
  static const Color accent       = Color(0xFF00CFA4);

  // Aliases kept for backward-compat with existing screens
  static const Color primaryLight = Color(0xFF00B2FF);
  static const Color primaryDark  = Color(0xFF0072E5); // Button Hover

  // ══════════════════════════════════════════════════════
  //  DARK UI BACKGROUNDS
  // ══════════════════════════════════════════════════════
  /// Midnight Black #0A0F1C — Main Background
  static const Color bg       = Color(0xFF0A0F1C);

  /// Deep Navy #111827 — Secondary Background
  static const Color surface1 = Color(0xFF111827);

  /// Soft Dark Slate #1A2233 — Card Background
  static const Color surface2 = Color(0xFF1A2233);

  /// Graphite Blue #202B3C — Elevated Surface
  static const Color surface3 = Color(0xFF202B3C);

  /// Input border level #2A3448
  static const Color surface4 = Color(0xFF2A3448);

  // ══════════════════════════════════════════════════════
  //  BORDERS
  // ══════════════════════════════════════════════════════
  /// Input Border #2A3448
  static const Color border  = Color(0xFF2A3448);
  /// Subtle border #364058
  static const Color border2 = Color(0xFF364058);

  // ══════════════════════════════════════════════════════
  //  TEXT COLORS
  // ══════════════════════════════════════════════════════
  /// Pure White #FFFFFF — Primary Text
  static const Color textPrimary   = Color(0xFFFFFFFF);

  /// Cool Gray #B8C2D1 — Secondary Text
  static const Color textSecondary = Color(0xFFB8C2D1);

  /// Slate Gray #7B8794 — Muted Text
  static const Color textMuted     = Color(0xFF7B8794);

  /// Soft Charcoal #4B5563 — Disabled Text
  static const Color textDim       = Color(0xFF4B5563);

  // ══════════════════════════════════════════════════════
  //  STATUS COLORS
  // ══════════════════════════════════════════════════════
  /// Pulse Green #22E58B — Success
  static const Color success =  primary;

  /// Active Orange #FFB547 — Warning
  static const Color warning = Color(0xFFFFB547);

  /// Alert Red #FF5A6B — Error
  static const Color error   = Color(0xFFFF5A6B);

  /// Bright Blue #3BA7FF — Info
  static const Color info    = Color(0xFF3BA7FF);

  // ══════════════════════════════════════════════════════
  //  UI COMPONENT COLORS
  // ══════════════════════════════════════════════════════
  static const Color activeButton = Color(0xFF0A84FF);
  static const Color buttonHover  = Color(0xFF0072E5);
  static const Color activeTab    = Color(0xFF00D0A3);
  static const Color inputBorder  = Color(0xFF2A3448);
  /// Glow Effect rgba(0,208,163,0.35)
  static const Color glowEffect   = Color(0x5900D0A3);
  /// Notification Dot #15E6A0
  static const Color notifDot     = Color(0xFF15E6A0);

  // ══════════════════════════════════════════════════════
  //  ACCENT PALETTE (activity / badge colour-coding)
  // ══════════════════════════════════════════════════════
  static const Color orange = Color(0xFFFFB547);
  static const Color blue   = Color(0xFF3BA7FF);
  static const Color purple = Color(0xFFB57BFF);
  static const Color gold   = Color(0xFFFFD700);
  static const Color pink   = Color(0xFFFF6B9D);

  // ══════════════════════════════════════════════════════
  //  OPACITY HELPERS
  // ══════════════════════════════════════════════════════
  static Color primaryDim    = primary.withOpacity(0.10);
  static Color primaryBorder = primary.withOpacity(0.25);
  static Color primaryGlow   = primary.withOpacity(0.20);
  static Color tealDim       = teal.withOpacity(0.10);
  static Color tealBorder    = teal.withOpacity(0.20);
  static Color tealGlow      = teal.withOpacity(0.25);
  static Color mintGlow      = mint.withOpacity(0.30);

  // ══════════════════════════════════════════════════════
  //  GRADIENTS
  // ══════════════════════════════════════════════════════

  /// Primary Brand Gradient — #0A84FF → #00D0A3
  static const LinearGradient primaryGradient = LinearGradient(
    begin:  Alignment.centerLeft,
    end:    Alignment.centerRight,
    colors: [Color(0xFF0A84FF), Color(0xFF00D0A3)],
  );

  /// Primary Brand Gradient (diagonal)
  static const LinearGradient primaryGradientDiag = LinearGradient(
    begin:  Alignment.topLeft,
    end:    Alignment.bottomRight,
    colors: [Color(0xFF0A84FF), Color(0xFF00D0A3)],
  );

  /// Neon Pulse Gradient — #00B2FF → #15E6A0
  static const LinearGradient neonPulseGradient = LinearGradient(
    begin:  Alignment.centerLeft,
    end:    Alignment.centerRight,
    colors: [Color(0xFF00B2FF), Color(0xFF15E6A0)],
  );

  /// App Background Gradient — #0A0F1C → #111827
  static const LinearGradient appBgGradient = LinearGradient(
    begin:  Alignment.topCenter,
    end:    Alignment.bottomCenter,
    colors: [Color(0xFF0A0F1C), Color(0xFF111827)],
  );

  // Legacy aliases — keep every existing screen compiling
  static const LinearGradient splashGradient     = appBgGradient;
  static const LinearGradient compatGradient     = primaryGradient;
  static const LinearGradient membershipGradient = LinearGradient(
    begin: Alignment.topLeft, end: Alignment.bottomRight,
    colors: [Color(0xFF0A1429), Color(0xFF0A1A2E)],
  );
  static const LinearGradient cardGymGradient = LinearGradient(
    begin: Alignment.topLeft, end: Alignment.bottomRight,
    colors: [Color(0xFF0D1829), Color(0xFF0A1F2E)],
  );
  static const LinearGradient cardRunGradient = LinearGradient(
    begin: Alignment.topLeft, end: Alignment.bottomRight,
    colors: [Color(0xFF0A1929), Color(0xFF0A2018)],
  );
  static const LinearGradient offerGradient = LinearGradient(
    colors: [Color(0xFFFF5A6B), Color(0xFFFFB547)],
  );

  // ── Shader helper ─────────────────────────────────────
  // ── Shader helper ─────────────────────────────────────
  static Shader gradientShader(Rect bounds) =>
      primaryGradient.createShader(bounds);
}