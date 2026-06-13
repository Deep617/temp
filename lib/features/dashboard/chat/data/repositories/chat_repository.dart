
import '../response_ml/message.dart';

abstract class ChatRepository {
  ChatRepository();

  Future<List<Map<String, dynamic>>> getChats({int page = 1});

  Future<List<Message>> getMessages(String chatId, {int page = 1});

  Future<Message> sendMessage(String chatId, String content);

  Future<void> markRead(String chatId);
}