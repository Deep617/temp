// ═══════════════════════════════════════════════════════════════
//  LocationService — asks for location and reads the phone's position.
//  Discover needs it for the 10 km radius; the profile keeps the last
//  position so other people can find you by distance (the server only
//  shows others a rounded position, never the exact one).
// ═══════════════════════════════════════════════════════════════
import 'dart:math' as math;

import 'package:geolocator/geolocator.dart';

enum LocationAccess { unknown, granted, denied, deniedForever, serviceOff }

class LocationResult {
  const LocationResult(this.access, {this.lat, this.lng});

  final LocationAccess access;
  final double? lat;
  final double? lng;

  bool get hasPosition => lat != null && lng != null;
}

/// Save the position to the profile only when there is none yet or the
/// phone moved at least [minMoveMeters] (no profile write on every open).
bool shouldSaveLocation({
  required double? savedLat,
  required double? savedLng,
  required double lat,
  required double lng,
  double minMoveMeters = 500,
}) {
  if (savedLat == null || savedLng == null) return true;
  return _meters(savedLat, savedLng, lat, lng) >= minMoveMeters;
}

double _meters(double lat1, double lng1, double lat2, double lng2) {
  const r = 6371000.0;
  double rad(double d) => d * math.pi / 180;
  final dLat = rad(lat2 - lat1);
  final dLng = rad(lng2 - lng1);
  final a =
      math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(rad(lat1)) *
          math.cos(rad(lat2)) *
          math.sin(dLng / 2) *
          math.sin(dLng / 2);
  return 2 * r * math.asin(math.min(1.0, math.sqrt(a)));
}

class LocationService {
  const LocationService();

  /// Current permission state, without asking.
  Future<LocationAccess> access() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled())
        return LocationAccess.serviceOff;
      return _map(await Geolocator.checkPermission());
    } catch (_) {
      return LocationAccess.unknown;
    }
  }

  /// Asks for permission when allowed ([ask]) and reads the position.
  Future<LocationResult> current({bool ask = true}) async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return const LocationResult(LocationAccess.serviceOff);
      }
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied && ask) {
        perm = await Geolocator.requestPermission();
      }
      final access = _map(perm);
      if (access != LocationAccess.granted) return LocationResult(access);

      Position? pos;
      try {
        pos = await Geolocator.getCurrentPosition(
          timeLimit: Duration(seconds: 10),
        );
      } catch (_) {
        pos = await Geolocator.getLastKnownPosition();
      }
      if (pos == null) return const LocationResult(LocationAccess.granted);
      return LocationResult(
        LocationAccess.granted,
        lat: pos.latitude,
        lng: pos.longitude,
      );
    } catch (_) {
      return const LocationResult(LocationAccess.unknown);
    }
  }

  /// Opens the right settings page: phone location for [serviceOff],
  /// the app's permission page otherwise.
  Future<bool> openSettings(LocationAccess access) async {
    try {
      return access == LocationAccess.serviceOff
          ? await Geolocator.openLocationSettings()
          : await Geolocator.openAppSettings();
    } catch (_) {
      return false;
    }
  }

  LocationAccess _map(LocationPermission p) {
    switch (p) {
      case LocationPermission.always:
      case LocationPermission.whileInUse:
        return LocationAccess.granted;
      case LocationPermission.deniedForever:
        return LocationAccess.deniedForever;
      case LocationPermission.denied:
        return LocationAccess.denied;
      default:
        return LocationAccess.unknown;
    }
  }
}
