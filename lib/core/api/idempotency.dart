// ─────────────────────────────────────────────────────────
//  Idempotency-Key policy (server: src/middleware/idempotency.js)
//
//  Every action that must happen ONCE (send message, book session, upload
//  proof, confirm, pay, buy tokens …) gets a random key. If the network
//  drops, the SAME request is sent again with the SAME key, so the server
//  does it once and returns the first answer — no double messages, no
//  double charges, and the user doesn't see "failed" for something that
//  actually worked.
// ─────────────────────────────────────────────────────────
import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

class IdempotencyPolicy {
  IdempotencyPolicy._();

  static const header = 'Idempotency-Key';
  static const maxAutoRetries = 2;
  static const _uuid = Uuid();

  /// Endpoints where doing it twice would hurt.
  static final List<RegExp> _paths = [
    RegExp(r'/auth/register$'),
    RegExp(r'/chat/[^/]+/messages$'),
    RegExp(r'/sessions$'),
    RegExp(r'/sessions/[^/]+/(proof|confirm|respond|on-my-way)$'),
    RegExp(r'/match/(like|swipe|boost)$'),
    RegExp(r'/match/requests/[^/]+/(accept|decline)$'),
    RegExp(r'/subscriptions/(order|verify-payment)$'),
    RegExp(r'/tokens/buy$'),
    RegExp(r'/strikes$'),
    RegExp(r'/flash/send$'),
    RegExp(r'/feed$'),
    RegExp(r'/referral/apply$'),
    RegExp(r'/safety/(report|block)$'),
    RegExp(r'/gyms/checkin$'),
    RegExp(r'/users/me/photos$'),
    RegExp(r'/verification/submit$'),
    RegExp(r'/challenges/[^/]+/(join|proof|collab)$'),
    RegExp(r'/influencer/apply$'),
  ];

  static bool needsKey(String method, String path) {
    final m = method.toUpperCase();
    if (m != 'POST' && m != 'PUT' && m != 'PATCH') return false;
    final p = path.split('?').first;
    return _paths.any((r) => r.hasMatch(p));
  }

  static String newKey() => _uuid.v4();

  /// Add a key once; a retry of the same RequestOptions keeps it.
  static void attach(RequestOptions o) {
    if (o.headers[header] != null) return;
    if (needsKey(o.method, o.path)) o.headers[header] = newKey();
  }

  /// Safe to re-send automatically? Only keyed requests (server dedupes),
  /// never multipart (the stream can't be sent twice), and only for
  /// "didn't get an answer" or "server busy / still working" cases.
  static bool shouldRetry(DioException e, int attempt) {
    final o = e.requestOptions;
    if (attempt >= maxAutoRetries) return false;
    if (o.headers[header] == null || o.data is FormData) return false;
    final code = e.response?.statusCode;
    if (code == null) {
      return e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.unknown;
    }
    if (code == 502 || code == 503 || code == 504) return true;
    if (code == 409) {
      final data = e.response?.data;
      final errs = data is Map ? data['errors'] : null;
      return errs is Map && errs['code'] == 'IDEMPOTENCY_IN_PROGRESS';
    }
    return false;
  }

  static Duration backoff(int attempt) => Duration(milliseconds: 800 * (attempt + 1));
}
