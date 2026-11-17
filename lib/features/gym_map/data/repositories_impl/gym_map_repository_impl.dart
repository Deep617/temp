import '../../../../core/api/base_repository.dart';
import '../../../../core/errors/app_error.dart';
import '../datasource/gym_map_remote_datasource.dart';
import '../models/gym_models.dart';
import '../repositories/gym_map_repository.dart';

class GymMapRepositoryImpl extends BaseRepository implements GymMapRepository {
  GymMapRepositoryImpl(this.remote, super.connectivity);
  final GymMapRemoteDatasource remote;

  @override
  Future<List<Gym>> nearby({
    required double lat,
    required double lng,
    int radiusM = 3000,
    String? query,
  }) =>
      remote
          .nearby(lat: lat, lng: lng, radiusM: radiusM, query: query)
          .catchError((e) => throw AppError.fromException(e));

  @override
  Future<List<BuddyCheckin>> buddies() =>
      remote.buddies().catchError((e) => throw AppError.fromException(e));

  @override
  Future<BuddyCheckin?> myCheckin() =>
      remote.myCheckin().catchError((e) => throw AppError.fromException(e));

  @override
  Future<BuddyCheckin> checkIn(Gym gym, {required double myLat, required double myLng}) =>
      remote.checkIn(gym, myLat: myLat, myLng: myLng)
          .catchError((e) => throw AppError.fromException(e));

  @override
  Future<void> checkOut() =>
      remote.checkOut().catchError((e) => throw AppError.fromException(e));

  @override
  Future<BuddyMapData> buddyMap() =>
      remote.buddyMap().catchError((e) => throw AppError.fromException(e));

  @override
  Future<void> setGhostMode(String mode) =>
      remote.setGhostMode(mode).catchError((e) => throw AppError.fromException(e));
}
