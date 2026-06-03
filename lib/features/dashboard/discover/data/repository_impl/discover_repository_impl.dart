import 'package:seshlly/core/errors/app_error.dart';
import 'package:seshlly/features/dashboard/discover/data/datasource/discover_remote_datasource.dart';
import 'package:seshlly/features/dashboard/discover/data/response_ml/buddy_profile.dart';

import '../../../../../core/api/base_repository.dart';
import '../../../../../core/services/secure_storage_service.dart';
import '../repositories/discover_repository.dart';

class DiscoverRepositoryImpl extends BaseRepository
    implements DiscoverRepository {
  final DiscoverRemoteDatasource remote;
  final SecureStorageService secureStorageService;

  DiscoverRepositoryImpl(
    this.secureStorageService,
    this.remote,
    super.connectivity,
  );

  @override
  Future<List<BuddyProfile>> getProfiles({
    String? activity,
    String? level,
    int page = 1,
  }) {
    return remote
        .getDiscoverProfiles(activity: activity, level: level, page: page)
        .catchError((e) {
          throw AppError.fromException(e);
        });
  }

  @override
  Future<void> swipeLeft(String userId) {
    return remote.swipeLeft(userId).catchError((e) {
      throw AppError.fromException(e);
    });
  }

  @override
  Future<bool> swipeRight(String userId) async {
    try {
      final res = await remote.swipeRight(userId);
      final data = res['data'] as Map<String, dynamic>?;
      return data?['matched'] == true;
    } catch (e) {
      throw AppError.fromException(e);
    }
  }

  @override
  Future<List<BuddyProfile>> getBuddies({int page = 1}) {
    return remote.getMyBuddies(page: page).catchError((e) {
      throw AppError.fromException(e);
    });
  }

  @override
  Future<BuddyProfile> getBuddyProfile(String userId) {
    return remote.getBuddyProfile(userId).catchError((e) {
      throw AppError.fromException(e);
    });
  }

  @override
  Future<void> removeBuddy(String buddyId) {
    return remote.removeBuddy(buddyId).catchError((e) {
      throw AppError.fromException(e);
    });
  }
}
