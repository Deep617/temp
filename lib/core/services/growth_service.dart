// ─────────────────────────────────────────────────────────
//  GrowthService — funnel analytics + Play Store rating prompt
//
//  • logFirst('first_match') logs an analytics event only the FIRST time
//    on this install, so the funnel (sign up → first match → first session
//    scheduled → first proof → first completed session) shows where new
//    people drop off.
//  • maybeAskForRating() — once, after the first completed session (the
//    moment people are happiest). "Not really" goes to support email
//    instead of the store, so unhappy users talk to us, not to 1-star.
// ─────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/app_colors.dart';
import 'monitoring_service.dart';
import 'navigation_service.dart';

class GrowthService {
  GrowthService._();
  static final GrowthService instance = GrowthService._();

  static const String playStoreUrl =
      'https://play.google.com/store/apps/details?id=com.seshlly.app';
  static const String _ratingKey = 'growth_rating_prompt_shown';

  /// Funnel steps (first time only on this device).
  static const String signUp = 'funnel_sign_up';
  static const String firstMatch = 'funnel_first_match';
  static const String firstSessionScheduled = 'funnel_first_session';
  static const String firstProof = 'funnel_first_proof';
  static const String firstSessionCompleted = 'funnel_first_completed';

  Future<void> logFirst(String event, [Map<String, Object>? params]) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'growth_$event';
      if (prefs.getBool(key) == true) return;
      await prefs.setBool(key, true);
      MonitoringService.instance.log(event, params);
    } catch (_) {
      // analytics must never break the app
    }
  }

  /// Call when a session is completed (proof confirmed / solo proof).
  /// Uses the app's root navigator, so it works even after a sheet closed.
  Future<void> onSessionCompleted() async {
    await logFirst(firstSessionCompleted);
    final ctx = NavigationService.navigatorKey.currentContext;
    if (ctx == null || !ctx.mounted) return;
    await maybeAskForRating(ctx);
  }

  Future<void> maybeAskForRating(BuildContext context) async {
    SharedPreferences prefs;
    try {
      prefs = await SharedPreferences.getInstance();
    } catch (_) {
      return;
    }
    if (prefs.getBool(_ratingKey) == true || !context.mounted) return;
    await prefs.setBool(_ratingKey, true);
    // Let the success snack bar show first
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    if (!context.mounted) return;

    final choice = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Enjoying Seshlly? 💪'),
        content: const Text(
          'You just finished your first session! A quick rating helps more '
          'people find a gym buddy.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop('feedback'),
            child: const Text('Not really'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop('later'),
            child: const Text('Later'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () => Navigator.of(ctx).pop('rate'),
            child: const Text('Rate us'),
          ),
        ],
      ),
    );
    MonitoringService.instance.log('rating_prompt', {'choice': choice ?? 'dismissed'});
    try {
      if (choice == 'rate') {
        await launchUrl(Uri.parse(playStoreUrl), mode: LaunchMode.externalApplication);
      } else if (choice == 'feedback') {
        await launchUrl(Uri.parse(
          'mailto:support@seshlly.com?subject=Seshlly%20feedback'
          '&body=What%20can%20we%20do%20better%3F',
        ));
      }
    } catch (_) {}
  }
}
