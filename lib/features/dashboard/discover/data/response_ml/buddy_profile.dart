
// ── BuddyProfile ─────────────────────────────────────────
class BuddyProfile {
  final String   id;
  final String   firstName;
  final String   lastName;
  final String?  avatarUrl;
  final String?  bio;
  final String?  city;
  final String?  primaryActivity;
  final List<String> activities;
  final String?  experienceLevel;
  final List<String> goals;
  final String?  primaryGym;
  final int      level;
  final String   levelName;
  final double   trustScore;
  final bool     idVerified;
  final bool     isInfluencer;
  final int      buddyCount;
  final int      sessionCount;
  final double   compatibilityScore;
  final double?  distanceKm;
  final bool     isOnline;
  final String   subscriptionPlan;

  const BuddyProfile({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.avatarUrl,
    this.bio,
    this.city,
    this.primaryActivity,
    this.activities = const [],
    this.experienceLevel,
    this.goals = const [],
    this.primaryGym,
    this.level = 1,
    this.levelName = 'Rookie',
    this.trustScore = 50,
    this.idVerified = false,
    this.isInfluencer = false,
    this.buddyCount = 0,
    this.sessionCount = 0,
    this.compatibilityScore = 0,
    this.distanceKm,
    this.isOnline = false,
    this.subscriptionPlan = 'free',
  });

  String get fullName => '$firstName $lastName';
  bool get isPro => subscriptionPlan != 'free';

  factory BuddyProfile.fromJson(Map<String, dynamic> json) => BuddyProfile(
    id:                 json['id']            as String,
    firstName:          json['firstName']     as String,
    lastName:           json['lastName']      as String,
    avatarUrl:          json['avatarUrl']     as String?,
    bio:                json['bio']           as String?,
    city:               json['city']          as String?,
    primaryActivity:    json['primaryActivity'] as String?,
    activities:         (json['activities']   as List<dynamic>?)?.cast<String>() ?? [],
    experienceLevel:    json['experienceLevel'] as String?,
    goals:              (json['goals']        as List<dynamic>?)?.cast<String>() ?? [],
    primaryGym:         json['primaryGym']    as String?,
    level:              json['level']         as int?    ?? 1,
    levelName:          json['levelName']     as String? ?? 'Rookie',
    trustScore:         (json['trustScore']   as num?)?.toDouble() ?? 50,
    idVerified:         json['idVerified']    as bool?   ?? false,
    isInfluencer:       json['isInfluencer']  as bool?   ?? false,
    buddyCount:         json['buddyCount']    as int?    ?? 0,
    sessionCount:       json['sessionCount']  as int?    ?? 0,
    compatibilityScore: (json['compatibilityScore'] as num?)?.toDouble() ?? 0,
    distanceKm:         (json['distanceKm']   as num?)?.toDouble(),
    isOnline:           json['isOnline']      as bool?   ?? false,
    subscriptionPlan:   json['subscriptionPlan'] as String? ?? 'free',
  );
}