
import '../response_ml/flash_streakmodel.dart';
import '../response_ml/message.dart';

abstract class ChatRepository {
  ChatRepository();

  Future<List<Map<String, dynamic>>> getChats({int page = 1});

  Future<List<Message>> getMessages(String chatId, {int page = 1});

  Future<Message> sendMessage(String chatId, String content);

  Future<void> markRead(String chatId);

  /// Messages + whether the chat is in 24h (disappearing) mode
  Future<({List<Message> messages, bool disappearing})> getMessagesWithMode(
    String chatId, {
    int page = 1,
  });

  /// Switch chat between 24h and Normal mode. Returns the system message.
  Future<Message?> setChatMode(String chatId, bool disappearing);

  //  SESH FLASH STREAK  /api/v1/flash

  /// POST /flash/send — record Flash sent (streak logic)
  Future<Map<String, dynamic>> recordFlashSent(String buddyId) ;

  /// GET /flash/streaks — all streaks for current user
  Future<List<FlashStreakModel>> getMyFlashStreaks();

  /// GET /flash/streak/:buddyId — single pair streak
  Future<FlashStreakModel> getPairStreak(String buddyId) ;

}