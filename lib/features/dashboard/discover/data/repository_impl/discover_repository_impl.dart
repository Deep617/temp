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
    try {
      return remote.getDiscoverProfiles(
        activity: activity,
        level: level,
        page: page,
      );
    } catch (e) {
      throw AppError.fromException(e);
    }
  }

  @override
  Future<void> swipeLeft(String userId) {
    try {
      return remote.swipeLeft(userId);
    } catch (e) {
      throw AppError.fromException(e);
    }
  }

  @override
  Future<bool> swipeRight(String userId) async {
    try {
      final res = remote.swipeRight(userId);
      // accoure error here
      //return res['data']?['matched'] == true;
      return false;
    } catch (e) {
      throw AppError.fromException(e);
    }
  }

  @override
  Future<List<BuddyProfile>> getBuddies({int page = 1}) {
    try {
      return remote.getMyBuddies(page: page);
    } catch (e) {
      throw AppError.fromException(e);
    }
  }

  @override
  Future<BuddyProfile> getBuddyProfile(String userId) {
    try {
      return remote.getBuddyProfile(userId);
    } catch (e) {
      throw AppError.fromException(e);
    }
  }

  @override
  Future<void> removeBuddy(String buddyId) {
    try {
      return remote.removeBuddy(buddyId);
    } catch (e) {
      throw AppError.fromException(e);
    }
  }
}
