import '../../../auth/data/response_ml/register_response.dart';

abstract class StrikeRepository {
  StrikeRepository();

  // ── Strike 2 — Buddy Strike (Snap style) ─────────────────

  Future<String> uploadFile(String request);

  // Strike bhejo buddy ko (kabhi bhi)
  Future<Map<String, dynamic>> sendStrike({
    required String matchId,
    required String imageUrl,
    String? caption,
  });

  // Strike view karo — one-time, 5 min mein expire
  Future<BuddyStrike> viewStrike(String strikeId);

  // Emoji react karo — 💪🔥😤🏆🤝😮
  Future<void> reactToStrike(String strikeId, String emoji);

  // my  pending strikes hain (not yet viewed)
  Future<List<BuddyStrike>> getPendingStrikes(String? buddyId);

  // Ek match ka current streak nikalo
  Future<Map<String, dynamic>> getStrikeStreak(String matchId);
}
