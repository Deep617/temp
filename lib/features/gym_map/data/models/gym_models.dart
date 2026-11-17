// Gym map models — GET /gyms/nearby, /gyms/buddies, /gyms/checkin/me

class BuddyCheckin {
  const BuddyCheckin({
    required this.userId,
    required this.placeId,
    required this.gymName,
    required this.lat,
    required this.lng,
    required this.expiresAt,
    this.name,
    this.firstName,
    this.avatarUrl,
    this.address,
    this.checkedInAt,
  });

  final String userId;
  final String? name;
  final String? firstName;
  final String? avatarUrl;
  final String placeId;
  final String gymName;
  final String? address;
  final double lat;
  final double lng;
  final DateTime? checkedInAt;
  final DateTime expiresAt;

  Duration get timeLeft => expiresAt.difference(DateTime.now());
  bool get isActive => !timeLeft.isNegative;

  factory BuddyCheckin.fromJson(Map<String, dynamic> j) => BuddyCheckin(
        userId: j['userId'] as String,
        name: j['name'] as String?,
        firstName: j['firstName'] as String?,
        avatarUrl: j['avatarUrl'] as String?,
        placeId: j['placeId'] as String,
        gymName: j['gymName'] as String? ?? 'Gym',
        address: j['address'] as String?,
        lat: (j['lat'] as num).toDouble(),
        lng: (j['lng'] as num).toDouble(),
        checkedInAt: j['checkedInAt'] != null
            ? DateTime.tryParse(j['checkedInAt'].toString())?.toLocal()
            : null,
        expiresAt: DateTime.tryParse(j['expiresAt']?.toString() ?? '')?.toLocal() ??
            DateTime.now(),
      );
}

class Gym {
  const Gym({
    required this.placeId,
    required this.name,
    required this.lat,
    required this.lng,
    this.address,
    this.rating,
    this.ratingCount = 0,
    this.openNow,
    this.buddiesHere = const [],
    this.trainingNow = 0,
  });

  final String placeId;
  final String name;
  final String? address;
  final double lat;
  final double lng;
  final double? rating;
  final int ratingCount;
  final bool? openNow;
  final List<BuddyCheckin> buddiesHere;
  /// Everyone checked in here now (a number only — no names)
  final int trainingNow;

  factory Gym.fromJson(Map<String, dynamic> j) => Gym(
        placeId: j['placeId'] as String,
        name: j['name'] as String? ?? 'Gym',
        address: j['address'] as String?,
        lat: (j['lat'] as num).toDouble(),
        lng: (j['lng'] as num).toDouble(),
        rating: (j['rating'] as num?)?.toDouble(),
        ratingCount: (j['ratingCount'] as num?)?.toInt() ?? 0,
        openNow: j['openNow'] as bool?,
        buddiesHere: (j['buddiesHere'] as List<dynamic>? ?? [])
            .map((e) => BuddyCheckin.fromJson(e as Map<String, dynamic>))
            .toList(),
        trainingNow: (j['trainingNow'] as num?)?.toInt() ?? 0,
      );
}

/// A buddy on the Buddy Map (GET /gyms/map). Never an exact position:
/// at a gym (checked in, last 2 h) or the centre of a ~3 km area.
class BuddyOnMap {
  const BuddyOnMap({
    required this.userId,
    required this.firstName,
    required this.trainingNow,
    required this.lat,
    required this.lng,
    this.avatarUrl,
    this.gymName,
    this.placeId,
    this.areaKm,
    this.at,
  });

  final String userId;
  final String firstName;
  final String? avatarUrl;
  final bool trainingNow;
  final String? gymName;
  final String? placeId;
  final double lat;
  final double lng;
  final double? areaKm;
  final DateTime? at;

  bool get atGym => placeId != null;

  factory BuddyOnMap.fromJson(Map<String, dynamic> j) => BuddyOnMap(
        userId: j['userId'] as String,
        firstName: j['firstName'] as String? ?? 'Buddy',
        avatarUrl: j['avatarUrl'] as String?,
        trainingNow: j['trainingNow'] == true,
        gymName: j['gymName'] as String?,
        placeId: j['precision'] == 'gym' ? j['placeId'] as String? : null,
        lat: (j['lat'] as num).toDouble(),
        lng: (j['lng'] as num).toDouble(),
        areaKm: (j['areaKm'] as num?)?.toDouble(),
        at: DateTime.tryParse(j['at']?.toString() ?? '')?.toLocal(),
      );
}

class BuddyMapData {
  const BuddyMapData({this.buddies = const [], this.ghostMode = false, this.ghostUntil});

  final List<BuddyOnMap> buddies;
  final bool ghostMode;
  final DateTime? ghostUntil;

  factory BuddyMapData.fromJson(Map<String, dynamic> j) {
    final me = j['me'] as Map<String, dynamic>? ?? const {};
    return BuddyMapData(
      buddies: (j['buddies'] as List<dynamic>? ?? [])
          .map((e) => BuddyOnMap.fromJson(e as Map<String, dynamic>))
          .toList(),
      ghostMode: me['ghostMode'] == true,
      ghostUntil: DateTime.tryParse(me['ghostUntil']?.toString() ?? '')?.toLocal(),
    );
  }
}
