import '../../../../auth/data/request_ml/upload_profile_request.dart';
import '../../../../auth/data/response_ml/register_response.dart';
import '../../data/response_ml/buddy_profile.dart';

abstract class DiscoverRepository {
  DiscoverRepository();


  Future<List<BuddyProfile>> getProfiles({
    String? activity,
    String? level,
    int page = 1,
  });

  Future<bool> swipeRight(String userId);

  Future<void> swipeLeft(String userId);

  Future<List<BuddyProfile>> getBuddies({int page = 1});

  Future<BuddyProfile> getBuddyProfile(String userId);

  Future<void> removeBuddy(String buddyId);
}
