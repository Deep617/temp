import 'package:seshlly/features/dashboard/chat/data/datasource/chat_remote_datasource.dart';

import '../../../../../core/api/base_repository.dart';
import '../../../../../core/errors/app_error.dart';
import '../response_ml/flash_streakmodel.dart';
import '../response_ml/message.dart';
import 'chat_repository.dart';

class ChatRepositoryImpl extends BaseRepository implements ChatRepository {
  final ChatRemoteDatasource remote;

  ChatRepositoryImpl(this.remote, super.connectivity);

  @override
  Future<List<Map<String, dynamic>>> getChats({int page = 1}) {
    return remote.getChats(page: page).catchError((e) {
      throw AppError.fromException(e);
    });
  }

  @override
  Future<List<Message>> getMessages(String chatId, {int page = 1}) {
    return remote.getMessages(chatId, page: page).catchError((e) {
      throw AppError.fromException(e);
    });
  }

  @override
  Future<void> markRead(String chatId) {
    return remote.markChatRead(chatId).catchError((e) {
      throw AppError.fromException(e);
    });
  }

  @override
  Future<Message> sendMessage(String chatId, String content) {
    return remote.sendMessage(chatId, content).catchError((e) {
      throw AppError.fromException(e);
    });
  }

  /// POST /flash/send — record Flash sent (streak logic)
  Future<Map<String, dynamic>> recordFlashSent(String buddyId) async {
    return remote.recordFlashSent(buddyId).catchError((e) {
      throw AppError.fromException(e);
    });
  }

  /// GET /flash/streaks — all streaks for current user
  Future<List<FlashStreakModel>> getMyFlashStreaks() async {
    return remote.getMyFlashStreaks().catchError((e) {
      throw AppError.fromException(e);
    });
  }

  /// GET /flash/streak/:buddyId — single pair streak
  Future<FlashStreakModel> getPairStreak(String buddyId) async {
    return remote.getPairStreak(buddyId).catchError((e) {
      throw AppError.fromException(e);
    });
  }
}
