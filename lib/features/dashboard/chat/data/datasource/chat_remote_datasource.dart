import 'package:dio/dio.dart';

import '../../../../../core/api/dio_client.dart';
import '../response_ml/flash_streakmodel.dart';
import '../response_ml/message.dart';

class ChatRemoteDatasource {
  final DioClient _dio;

  ChatRemoteDatasource(this._dio);

  // CHAT
  Future<List<Map<String, dynamic>>> getChats({int page = 1}) async {
    final res = await _dio.get('/chat', queryParameters: {'page': page});
    return (_body(res)['data'] as List).cast<Map<String, dynamic>>();
  }

  Future<List<Message>> getMessages(String chatId, {int page = 1}) async {
    final res = await _dio.get(
      '/chat/$chatId/messages',
      queryParameters: {'page': page},
    );
    return (_body(res)['data'] as List)
        .map((e) => Message.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Message> sendMessage(
    String chatId,
    String content, {
    String type = 'text',
  }) async {
    final res = await _dio.post(
      '/chat/$chatId/messages',
      data: {'content': content, 'type': type},
    );
    return Message.fromJson(_body(res)['data'] as Map<String, dynamic>);
  }

  Future<void> markChatRead(String chatId) async {
    await _dio.patch('/chat/$chatId/read');
  }

  /// POST /flash/send — record Flash sent (streak logic)
  Future<Map<String, dynamic>> recordFlashSent(String buddyId) async {
    final res = await _dio.post('/flash/send', data: {'buddyId': buddyId});
    return _data(res);
  }

  /// GET /flash/streaks — all streaks for current user
  Future<List<FlashStreakModel>> getMyFlashStreaks() async {
    final res = await _dio.get('/flash/streaks');
    final data = _data(res);
    return (data['streaks'] as List<dynamic>)
        .map((e) => FlashStreakModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// GET /flash/streak/:buddyId — single pair streak
  Future<FlashStreakModel> getPairStreak(String buddyId) async {
    final res = await _dio.get('/flash/streak/$buddyId');
    final data = _data(res);
    return FlashStreakModel.fromJson(data as Map<String, dynamic>);
  }

  dynamic _data(Response res) {
    final body = res.data;
    if (body is Map && body['success'] == true) {
      return body['data'];
    }
    throw DioException(
      requestOptions: res.requestOptions,
      response: res,
      type: DioExceptionType.badResponse,
      message:
          (body is Map ? body['message'] as String? : null) ??
          'Unexpected response',
    );
  }

  Map<String, dynamic> _body(Response res) {
    if (res.statusCode != null &&
        res.statusCode! >= 200 &&
        res.statusCode! < 300) {
      return res.data as Map<String, dynamic>;
    }
    throw Exception(
      (res.data as Map<String, dynamic>?)?['message'] ?? 'Request failed',
    );
  }
}
