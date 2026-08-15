import 'package:seshlly/core/api/base_repository.dart';
import 'package:seshlly/features/strike/data/datasource/strike_remote_datasource.dart';
import 'package:seshlly/features/strike/data/repositories/strike_repository.dart';

import '../../../../core/errors/app_error.dart';
import '../../../auth/data/response_ml/register_response.dart';

class StrikeRepositoryImpl extends BaseRepository implements StrikeRepository {
  final StrikeRemoteDatasource remote;

  StrikeRepositoryImpl(this.remote, super.connectivity);

  @override
  Future<String> uploadFile(String request) async {
    return await safeApiCall(() async {
      final response = await remote.uploadFile(request);
      String responseUrl = response.data['data']['url'] as String;
      return responseUrl;
    });
  }

  @override
  Future<Map<String, dynamic>> sendStrike({
    required String matchId,
    required String imageUrl,
    String? caption,
  }) {
    return remote
        .sendStrike(matchId: matchId, imageUrl: imageUrl, caption: caption)
        .catchError((e) {
          throw AppError.fromException(e);
        });
  }

  @override
  Future<BuddyStrike> viewStrike(String strikeId) {
    return remote.viewStrike(strikeId).catchError((e) {
      throw AppError.fromException(e);
    });
  }

  // Emoji react karo — 💪🔥😤🏆🤝😮
  @override
  Future<void> reactToStrike(String strikeId, String emoji) {
    return remote.reactToStrike(strikeId, emoji).catchError((e) {
      throw AppError.fromException(e);
    });
  }

  @override
  Future<List<BuddyStrike>> getPendingStrikes() {
    return remote.getPendingStrikes().catchError((e) {
      throw AppError.fromException(e);
    });
  }

  @override
  Future<Map<String, dynamic>> getStrikeStreak(String matchId) {
    return remote.getStrikeStreak(matchId).catchError((e) {
      throw AppError.fromException(e);
    });
  }
}
