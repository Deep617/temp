// ─────────────────────────────────────────────────────────
//  MonitoringService — Firebase Crashlytics + Analytics
//
//  • Crashlytics: every Flutter / async crash is reported (release only).
//  • Analytics : screen views (GoRouter observer) + key events, so you
//    can see Day-1 / Day-7 / Day-30 retention and where users drop off.
//
//  Requires the same Firebase config files as push. Without them
//  everything here is a silent no-op.
// ─────────────────────────────────────────────────────────
import 'dart:ui';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'push_service.dart';

class MonitoringService {
  MonitoringService._();
  static final MonitoringService instance = MonitoringService._();

  bool _ready = false;
  FirebaseAnalytics? _analytics;

  /// Add to GoRouter(observers: ...) for automatic screen_view events.
  List<NavigatorObserver> get navigatorObservers => _analytics == null
      ? const []
      : [FirebaseAnalyticsObserver(analytics: _analytics!)];

  /// Call after PushService.init() (which initialises Firebase).
  Future<void> init() async {
    if (_ready || !PushService.instance.isReady) return;
    try {
      _analytics = FirebaseAnalytics.instance;
      final crash = FirebaseCrashlytics.instance;
      // Don't pollute crash reports with debug sessions
      await crash.setCrashlyticsCollectionEnabled(!kDebugMode);

      final previous = FlutterError.onError;
      FlutterError.onError = (details) {
        previous?.call(details);
        crash.recordFlutterFatalError(details);
      };
      PlatformDispatcher.instance.onError = (error, stack) {
        crash.recordError(error, stack, fatal: true);
        return true;
      };
      _ready = true;
    } catch (e) {
      debugPrint('Monitoring disabled: $e');
    }
  }

  /// Tie crashes + analytics to the logged-in user (ID only, no PII)
  Future<void> setUser(String? userId) async {
    if (!_ready) return;
    try {
      await _analytics?.setUserId(id: userId);
      if (userId != null) {
        await FirebaseCrashlytics.instance.setUserIdentifier(userId);
      }
    } catch (_) {}
  }

  /// Key product events, e.g. log('proof_uploaded', {'type': 'buddy'})
  void log(String name, [Map<String, Object>? params]) {
    if (!_ready) return;
    _analytics?.logEvent(name: name, parameters: params).catchError((_) {});
  }

  /// Non-fatal error (caught exceptions worth knowing about)
  void recordError(Object error, StackTrace? stack, {String? reason}) {
    if (!_ready) return;
    FirebaseCrashlytics.instance
        .recordError(error, stack, reason: reason)
        .catchError((_) {});
  }
}
