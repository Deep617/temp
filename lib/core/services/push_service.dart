// ─────────────────────────────────────────────────────────
//  PushService — Firebase Cloud Messaging (FCM)
//
//  Developer setup (one time):
//   Android → put google-services.json in android/app/
//   iOS     → add GoogleService-Info.plist to Runner (Xcode),
//             enable Push Notifications + Background Modes › Remote
//             notifications, upload APNs key in Firebase Console.
//
//  Without those files Firebase.initializeApp() throws → we catch it,
//  push stays disabled and the rest of the app works normally.
// ─────────────────────────────────────────────────────────
import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../../di_injection/dependency_injection.dart';
import '../api/dio_client.dart';

class PushService {
  PushService._();
  static final PushService instance = PushService._();

  bool _ready = false;
  bool get isReady => _ready;

  Map<String, dynamic>? _initialTap;
  StreamSubscription<String>? _tokenRefreshSub;

  final _tapCtrl = StreamController<Map<String, dynamic>>.broadcast();
  final _foregroundCtrl = StreamController<RemoteMessage>.broadcast();

  /// User tapped a notification (app was in background)
  Stream<Map<String, dynamic>> get onTap => _tapCtrl.stream;

  /// Notification arrived while the app is open
  Stream<RemoteMessage> get onForeground => _foregroundCtrl.stream;

  /// Call once from main() — safe even when Firebase isn't configured.
  Future<void> init() async {
    if (_ready) return;
    try {
      await Firebase.initializeApp();
      _ready = true;
    } catch (e) {
      debugPrint('🔕 Push disabled (Firebase not configured): $e');
      return;
    }

    try {
      FirebaseMessaging.onMessage.listen(_foregroundCtrl.add);
      FirebaseMessaging.onMessageOpenedApp
          .listen((m) => _tapCtrl.add(Map<String, dynamic>.from(m.data)));

      // App launched from a terminated state by tapping a notification
      final initial = await FirebaseMessaging.instance.getInitialMessage();
      if (initial != null) _initialTap = Map<String, dynamic>.from(initial.data);

      // iOS: show banner/sound while app is in foreground too
      await FirebaseMessaging.instance
          .setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    } catch (e) {
      debugPrint('Push listeners failed: $e');
    }
  }

  /// One-shot: the notification that launched the app (if any)
  Map<String, dynamic>? takeInitialTap() {
    final t = _initialTap;
    _initialTap = null;
    return t;
  }

  /// Ask permission + send FCM token to backend (POST /users/fcm-token).
  /// Call after login (HomeScreen does this).
  Future<void> registerToken() async {
    if (!_ready) return;
    try {
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      if (settings.authorizationStatus == AuthorizationStatus.denied) return;

      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) await _sendToken(token);

      _tokenRefreshSub ??=
          FirebaseMessaging.instance.onTokenRefresh.listen(_sendToken);
    } catch (e) {
      // iOS without APNs setup throws here — just skip
      debugPrint('FCM token registration skipped: $e');
    }
  }

  Future<void> _sendToken(String token) async {
    try {
      await getIt<DioClient>().post(
        '/users/fcm-token',
        data: {'fcmToken': token},
      );
    } catch (e) {
      debugPrint('FCM token upload failed: $e');
    }
  }
}
