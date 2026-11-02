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
      );
}
