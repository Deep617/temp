// ─────────────────────────────────────────────────────────
//  Session invite card — what state should the card show?
//
//  Pure logic (no widgets) so it is unit-tested in
//  test/features/chat/session_invite_status_test.dart
//
//  Sources, strongest first:
//   1. what I just tapped on this device (localAction)
//   2. my own answer recorded by the server (metadata.responses[myId])
//   3. the card status the server keeps up to date (metadata.status)
//   4. time: once the session start time has passed, a still-pending
//      invite is EXPIRED — no Confirm/Decline buttons any more
// ─────────────────────────────────────────────────────────

enum InviteCardStatus { pending, confirmed, declined, expired }

InviteCardStatus? _parse(Object? s) {
  switch (s) {
    case 'confirmed':
    case 'confirm':
      return InviteCardStatus.confirmed;
    case 'declined':
    case 'decline':
      return InviteCardStatus.declined;
    case 'expired':
      return InviteCardStatus.expired;
    case 'pending':
      return InviteCardStatus.pending;
  }
  return null;
}

InviteCardStatus resolveInviteStatus({
  required Map<String, dynamic>? metadata,
  required String myId,
  required bool isScheduler,
  String? localAction,
  DateTime? now,
}) {
  final local = _parse(localAction);
  if (local != null && local != InviteCardStatus.pending) return local;

  final meta = metadata ?? const <String, dynamic>{};

  final responses = meta['responses'];
  if (!isScheduler && responses is Map) {
    final mine = _parse(responses[myId]);
    if (mine != null && mine != InviteCardStatus.pending) return mine;
  }

  final server = _parse(meta['status']);
  if (server != null && server != InviteCardStatus.pending) return server;

  final at = DateTime.tryParse(meta['scheduledAt']?.toString() ?? '');
  if (at != null && !at.isAfter(now ?? DateTime.now())) {
    return InviteCardStatus.expired;
  }
  return InviteCardStatus.pending;
}

/// Map an API error status code from POST /sessions/:id/respond
/// to the card state it means (null = keep the buttons, show the error).
InviteCardStatus? statusFromRespondError(int? statusCode, Object? inviteStatus) {
  if (statusCode == 410) return InviteCardStatus.expired;
  if (statusCode == 409) return _parse(inviteStatus) ?? InviteCardStatus.expired;
  return null;
}
