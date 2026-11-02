import '../../../../auth/data/request_ml/upload_profile_request.dart';
import '../../../../auth/data/response_ml/register_response.dart';
import '../../data/response_ml/buddy_profile.dart';

abstract class DiscoverRepository {
  DiscoverRepository();


  Future<List<BuddyProfile>> getProfiles({
    String? activity,
    String? level,
    int page = 1,
    double? lat,
    double? lng,
    double? maxDistance,
  });

  Future<bool> swipeRight(String userId);

  /// Like → { matched, matchId?, chatId? }
  Future<Map<String, dynamic>> likeUser(String userId);

  Future<void> swipeLeft(String userId);

  Future<List<BuddyProfile>> getBuddies({int page = 1});

  Future<BuddyProfile> getBuddyProfile(String userId);

  Future<void> removeBuddy(String buddyId);

  /// Returns true when the super like resulted in a mutual match.
  Future<bool> superLike(String userId);

  Future<Map<String, dynamic>> boost();

  Future<Map<String, dynamic>> boostStatus();

}
