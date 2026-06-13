import 'package:seshlly/features/dashboard/chat/data/datasource/chat_remote_datasource.dart';

import '../../../../../core/api/base_repository.dart';
import '../../../../../core/errors/app_error.dart';
import '../../../../../core/services/secure_storage_service.dart';
import '../response_ml/message.dart';
import 'chat_repository.dart';

class ChatRepositoryImpl extends BaseRepository implements ChatRepository {
  final ChatRemoteDatasource remote;


  ChatRepositoryImpl(
    this.remote,
    super.connectivity,
  );

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
}
