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
  /// Buddy Map: buddies at gyms / in ~3 km areas, and my Ghost Mode
  Future<BuddyMapData> buddyMap();
  /// Ghost Mode: 'off', '3h', '24h' or 'on' (until turned off)
  Future<void> setGhostMode(String mode);
}
