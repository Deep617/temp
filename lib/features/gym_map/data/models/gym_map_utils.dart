// Pure helpers for the Gym Map (unit-tested in test/features/gym_map/)
import 'dart:math' as math;

import 'gym_models.dart';

/// Metres between two points (haversine).
double distanceMeters(double lat1, double lng1, double lat2, double lng2) {
  const r = 6371000.0;
  double rad(double d) => d * math.pi / 180;
  final dLat = rad(lat2 - lat1), dLng = rad(lng2 - lng1);
  final a = math.pow(math.sin(dLat / 2), 2) +
      math.cos(rad(lat1)) * math.cos(rad(lat2)) * math.pow(math.sin(dLng / 2), 2);
  return 2 * r * math.asin(math.sqrt(a));
}

/// "350 m" / "2.4 km"
String formatDistance(double meters) =>
    meters < 1000 ? '${(meters / 10).round() * 10} m' : '${(meters / 1000).toStringAsFixed(1)} km';

/// Nearest first. Gyms without a reference point keep their order.
List<Gym> sortByDistance(List<Gym> gyms, {double? fromLat, double? fromLng}) {
  if (fromLat == null || fromLng == null) return [...gyms];
  final list = [...gyms];
  list.sort((a, b) => distanceMeters(fromLat, fromLng, a.lat, a.lng)
      .compareTo(distanceMeters(fromLat, fromLng, b.lat, b.lng)));
  return list;
}

/// Turn-by-turn directions in Google Maps (app if installed, else browser).
/// Google place ids are passed through; OpenStreetMap ids ("osm:…") are not.
Uri directionsUri(Gym gym) => Uri.https('www.google.com', '/maps/dir/', {
      'api': '1',
      'destination': '${gym.lat},${gym.lng}',
      if (!gym.placeId.startsWith('osm:')) 'destination_place_id': gym.placeId,
      'travelmode': 'driving',
    });

/// OpenStreetMap data must be credited on screen (ODbL licence).
bool needsOsmCredit(List<Gym> gyms) => gyms.any((g) => g.placeId.startsWith('osm:'));
