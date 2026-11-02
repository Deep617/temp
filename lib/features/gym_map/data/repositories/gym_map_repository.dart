import '../models/gym_models.dart';

abstract class GymMapRepository {
  Future<List<Gym>> nearby({
    required double lat,
    required double lng,
    int radiusM = 3000,
    String? query,
  });
  Future<List<BuddyCheckin>> buddies();
  Future<BuddyCheckin?> myCheckin();
  Future<BuddyCheckin> checkIn(Gym gym, {required double myLat, required double myLng});
  Future<void> checkOut();
}
