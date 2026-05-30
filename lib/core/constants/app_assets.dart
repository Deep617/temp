// ─────────────────────────────────────────────────────────
//  APP ASSETS
//  lib/core/constants/app_assets.dart
//
//  Single source of truth for every asset path in the app.
//  Usage:
//    Image.asset(AppImages.logo)
//    SvgPicture.asset(AppIcons.home)
//    Lottie.asset(AppAnimations.loading)
//
//  Rules:
//  • Never hard-code a path string outside this file.
//  • Add new assets here first, then declare them in pubspec.yaml.
//  • Keep the three classes in sync with the actual files on disk.
// ─────────────────────────────────────────────────────────

// ── Images (assets/images/) ───────────────────────────────
abstract final class AppImages {
  AppImages._();

  static const String _base = 'assets/images';

  // ── Brand ─────────────────────────────────────────────
  /// FitConnect wordmark PNG (full colour, for light + dark)
  static const String logo        = '$_base/logo.png';

  /// Square app icon used in splash & about screens
  static const String appIcon     = '$_base/app_icon.png';

  // ── Onboarding ────────────────────────────────────────
  static const String onboarding1 = '$_base/onboarding_1.png';
  static const String onboarding2 = '$_base/onboarding_2.png';
  static const String onboarding3 = '$_base/onboarding_3.png';

  // ── Placeholders ──────────────────────────────────────
  /// Generic avatar fallback (shown when network image fails)
  static const String avatarPlaceholder = '$_base/avatar_placeholder.png';

  /// Card cover fallback (shown when buddy has no photo)
  static const String coverPlaceholder  = '$_base/cover_placeholder.png';

  // ── Empty States ──────────────────────────────────────
  static const String emptyDiscover     = '$_base/empty_discover.png';
  static const String emptyChats        = '$_base/empty_chats.png';
  static const String emptySessions     = '$_base/empty_sessions.png';
  static const String emptyNotifications= '$_base/empty_notifications.png';

  // ── Match / Social ────────────────────────────────────
  static const String matchConfetti     = '$_base/match_confetti.png';

  // ── Payment ───────────────────────────────────────────
  static const String razorpayLogo      = '$_base/razorpay_logo.png';
  static const String proMedalBg        = '$_base/pro_medal_bg.png';
}

// ── Icons (assets/icons/) ─────────────────────────────────
// Prefer SVG for icons — they scale crisply at every density.
abstract final class AppIcons {
  AppIcons._();

  static const String _base = 'assets/icons';

  // ── Navigation ────────────────────────────────────────
  static const String home        = '$_base/ic_home.svg';
  static const String discover    = '$_base/ic_discover.svg';
  static const String sessions    = '$_base/ic_sessions.svg';
  static const String chats       = '$_base/ic_chats.svg';
  static const String profile     = '$_base/ic_profile.svg';
  static const String notification= '$_base/ic_notification.svg';

  // ── Actions ───────────────────────────────────────────
  static const String like        = '$_base/ic_like.svg';
  static const String dislike     = '$_base/ic_dislike.svg';
  static const String superLike   = '$_base/ic_super_like.svg';
  static const String boost       = '$_base/ic_boost.svg';
  static const String filter      = '$_base/ic_filter.svg';
  static const String search      = '$_base/ic_search.svg';
  static const String settings    = '$_base/ic_settings.svg';
  static const String edit        = '$_base/ic_edit.svg';
  static const String share       = '$_base/ic_share.svg';
  static const String camera      = '$_base/ic_camera.svg';
  static const String gallery     = '$_base/ic_gallery.svg';
  static const String location    = '$_base/ic_location.svg';
  static const String send        = '$_base/ic_send.svg';
  static const String verified    = '$_base/ic_verified.svg';
  static const String pro         = '$_base/ic_pro.svg';
  static const String token       = '$_base/ic_token.svg';

  // ── Activities (per-sport colour SVGs) ────────────────
  static const String gym         = '$_base/ic_act_gym.svg';
  static const String running     = '$_base/ic_act_running.svg';
  static const String yoga        = '$_base/ic_act_yoga.svg';
  static const String cycling     = '$_base/ic_act_cycling.svg';
  static const String swimming    = '$_base/ic_act_swimming.svg';
  static const String basketball  = '$_base/ic_act_basketball.svg';
  static const String football    = '$_base/ic_act_football.svg';
  static const String tennis      = '$_base/ic_act_tennis.svg';
  static const String boxing      = '$_base/ic_act_boxing.svg';
  static const String crossfit    = '$_base/ic_act_crossfit.svg';

  // ── Social / Auth ─────────────────────────────────────
  static const String google      = '$_base/ic_google.svg';
  static const String apple       = '$_base/ic_apple.svg';
  static const String instagram   = '$_base/ic_instagram.svg';
}

// ── Animations (assets/animations/) ──────────────────────
// Lottie JSON files — use with the `lottie` package:
//   Lottie.asset(AppAnimations.loading)
abstract final class AppAnimations {
  AppAnimations._();

  static const String _base = 'assets/animations';

  // ── Loading / Feedback ────────────────────────────────
  /// Lime spinner — general purpose loading
  static const String loading       = '$_base/loading.json';

  /// Full-screen loading overlay
  static const String loadingScreen = '$_base/loading_screen.json';

  /// Green tick — payment / action success
  static const String success       = '$_base/success.json';

  /// Red shake — error or failed action
  static const String error         = '$_base/error.json';

  // ── Match / Social ────────────────────────────────────
  /// Confetti burst — shown on match screen
  static const String matchConfetti = '$_base/match_confetti.json';

  /// Pulse hearts — shown behind match avatars
  static const String matchHearts   = '$_base/match_hearts.json';

  // ── Onboarding ────────────────────────────────────────
  static const String onboarding1   = '$_base/onboarding_1.json';
  static const String onboarding2   = '$_base/onboarding_2.json';
  static const String onboarding3   = '$_base/onboarding_3.json';

  // ── Empty States ──────────────────────────────────────
  static const String emptyDiscover = '$_base/empty_discover.json';
  static const String emptyChats    = '$_base/empty_chats.json';
  static const String emptySessions = '$_base/empty_sessions.json';

  // ── Payment / Pro ─────────────────────────────────────
  /// Coin shower — token purchase success
  static const String tokenCelebration  = '$_base/token_celebration.json';

  /// Gold badge unlock — Pro subscription activated
  static const String proBadgeUnlock    = '$_base/pro_badge_unlock.json';

  // ── Fitness ───────────────────────────────────────────
  /// Dumbbell lift — shown on session screens
  static const String dumbbell     = '$_base/dumbbell.json';

  /// XP level-up burst — shown when XP threshold is crossed
  static const String levelUp      = '$_base/level_up.json';
}
