// ─────────────────────────────────────────────────────────
//  OfflineCache — last good copy of a few lists (chat list, recent
//  messages, Discover deck) so the app still shows something on a bad
//  network instead of an empty error screen.
//
//  • Only used when the request fails with NO response (offline / timeout).
//    Real server errors (401, 403, 500 …) are never hidden.
//  • Cleared on logout (StorageService.clearStorage wipes prefs) and on
//    session expiry, so one account never sees another account's data.
// ─────────────────────────────────────────────────────────
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OfflineCache {
  OfflineCache._();

  static const _prefix = 'offline_cache_';
  static const maxAge = Duration(days: 7);

  static Future<void> save(String key, Object json) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        '$_prefix$key',
        jsonEncode({'at': DateTime.now().millisecondsSinceEpoch, 'data': json}),
      );
    } catch (_) {/* cache is best effort */}
  }

  static Future<dynamic> read(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('$_prefix$key');
      if (raw == null) return null;
      final m = jsonDecode(raw) as Map<String, dynamic>;
      final at = DateTime.fromMillisecondsSinceEpoch(m['at'] as int);
      if (DateTime.now().difference(at) > maxAge) return null;
      return m['data'];
    } catch (_) {
      return null;
    }
  }

  static Future<void> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      for (final k in prefs.getKeys().where((k) => k.startsWith(_prefix)).toList()) {
        await prefs.remove(k);
      }
    } catch (_) {}
  }

  /// True when the request never got an answer (no internet, timeout).
  static bool isOffline(Object e) =>
      e is DioException &&
      e.response == null &&
      (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.unknown);

  /// Run [fetch]; save its JSON on success; on an offline error return the
  /// cached JSON instead (or rethrow if there is none).
  static Future<T> fetch<T>(
    String key,
    Future<T> Function() fetch, {
    required Object Function(T value) toJson,
    required T Function(dynamic json) fromJson,
  }) async {
    try {
      final v = await fetch();
      await save(key, toJson(v));
      return v;
    } catch (e) {
      if (isOffline(e)) {
        final cached = await read(key);
        if (cached != null) return fromJson(cached);
      }
      rethrow;
    }
  }
}
