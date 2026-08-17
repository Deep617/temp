// To parse this JSON data, do
//
//     final registerResponse = registerResponseFromJson(jsonString);

import 'dart:convert';

RegisterResponse registerResponseFromJson(String str) =>
    RegisterResponse.fromJson(json.decode(str));

String registerResponseToJson(RegisterResponse data) =>
    json.encode(data.toJson());

class RegisterResponse {
  UserModel? user;
  String? accessToken;
  String? refreshToken;

  RegisterResponse({this.user, this.accessToken, this.refreshToken});

  factory RegisterResponse.fromJson(Map<String, dynamic> json) =>
      RegisterResponse(
        user: json["user"] == null ? null : UserModel.fromJson(json["user"]),
        accessToken: json["accessToken"],
        refreshToken: json["refreshToken"],
      );

  Map<String, dynamic> toJson() => {
    "user": user?.toJson(),
    "accessToken": accessToken,
    "refreshToken": refreshToken,
  };
}

// ═════════════════════════════════════════════════════════
class UserModel {
  const UserModel({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.createdAt,
    this.avatarUrl,
    this.phone,
    this.username,
    this.bio,
    this.country,
    this.city,
    this.gender,
    this.walkthroughSeen = false,
    this.status = 'ACTIVE',
    this.emailVerified = false,
    this.isBanned = false,
    this.loginCount = 0,
    this.lastLoginAt,
    this.primaryActivity,
    this.activities = const [],
    this.experienceLevel,
    this.goals = const [],
    this.primaryGym,
    this.latitude,
    this.longitude,
    this.searchRadius = 10,
    this.xpTotal = 0,
    this.weeklyXp = 0,
    this.monthlyXp = 0,
    this.level = 1,
    this.chatTokens = 20,
    this.isInfluencer = false,
    this.instagramHandle,
    this.instagramFollowers,
    this.trustScore = 30.0,
    this.idVerified = false,
    this.buddyCount = 0,
    this.sessionCount = 0,
    this.challengeCount = 0,
    this.subscriptionPlan = 'free',
    this.subscriptionExpiry,
    this.influencerBio,
    this.influencerAppliedAt,
    this.influencerSessionLimit = 3,
    this.lastActiveAt,
    this.age,
    this.matchScore,
  });

  final String    id;
  final String    email;
  final String    firstName;
  final String    lastName;
  final String?   avatarUrl;
  final String?   phone;
  final String?   username;
  final String?   bio;
  final String?   country;
  final String?   city;
  final String?   gender;
  final bool      walkthroughSeen;
  final String    status;
  final bool      emailVerified;
  final bool      isBanned;
  final int       loginCount;
  final DateTime? lastLoginAt;
  final DateTime  createdAt;
  final String?   primaryActivity;
  final List<String> activities;
  final String?   experienceLevel;
  final List<String> goals;
  final String?   primaryGym;
  final double?   latitude;
  final double?   longitude;
  final int       searchRadius;
  final int       xpTotal;
  final int       weeklyXp;
  final int       monthlyXp;
  final int       level;
  final int       chatTokens;
  final bool      isInfluencer;
  final String?   instagramHandle;
  final int?      instagramFollowers;
  final double    trustScore;
  final bool      idVerified;
  final int       buddyCount;
  final int       sessionCount;
  final int       challengeCount;
  final String    subscriptionPlan;
  final DateTime? subscriptionExpiry;
  final String?   influencerBio;           // Fitness niche bio
  final DateTime? influencerAppliedAt;     // When applied as influencer
  final int       influencerSessionLimit;  // Max sessions/month for fans
  final DateTime? lastActiveAt;            // Last seen timestamp
  final int?      age;                     // Computed from DOB on backend
  final int?      matchScore;              // 0-100 match % (Requests tab)

  // ── Computed ────────────────────────────────────────
  String get fullName       => '$firstName $lastName';
  String get displayHandle  => username != null ? '@$username' : email;
  bool   get isPro          => subscriptionPlan == 'pro' || subscriptionPlan == 'elite';
  bool   get isElite        => subscriptionPlan == 'elite';
  bool   get isActive       => subscriptionExpiry == null || subscriptionExpiry!.isAfter(DateTime.now());
  bool   get hasTokens      => chatTokens > 0;
  int    get tokenWarning   => chatTokens <= 5 ? chatTokens : -1; // -1 = no warning
  String get levelName {
    const names = ['Rookie','Grinder','Regular','Dedicated','Warrior','Champion','Elite','Legend','Icon','GOATified'];
    return level >= 1 && level <= names.length ? names[level - 1] : 'GOATified';
  }
  String get trustLevel {
    if (trustScore >= 91) return 'Legend';
    if (trustScore >= 76) return 'Elite';
    if (trustScore >= 51) return 'Trusted';
    if (trustScore >= 26) return 'Regular';
    return 'New';
  }

  // ── Deserialise ─────────────────────────────────────
  // Backend formatUser returns these exact keys.
  factory UserModel.fromJson(Map<String, dynamic> j) => UserModel(
    id:                 j['id']            as String,
    email:              j['email']          as String,
    firstName:          j['firstName']      as String,
    lastName:           j['lastName']       as String,
    avatarUrl:          j['avatarUrl']      as String?,
    phone:              j['phone']          as String?,
    username:           j['username']       as String?,
    bio:                j['bio']            as String?,
    country:            j['country']        as String?,
    city:               j['city']           as String?,
    gender:             j['gender']         as String?,
    walkthroughSeen:    j['walkthroughSeen'] as bool?   ?? false,
    status:             j['status']         as String?  ?? 'ACTIVE',
    emailVerified:      j['emailVerified']  as bool?    ?? false,
    isBanned:           j['isBanned']       as bool?    ?? false,
    loginCount:         j['loginCount']     as int?     ?? 0,
    lastLoginAt:        j['lastLoginAt'] != null ? DateTime.parse(j['lastLoginAt'] as String) : null,
    createdAt:          DateTime.parse(j['createdAt']   as String),
    primaryActivity:    j['primaryActivity'] as String?,
    activities:         _strings(j['activities']),
    experienceLevel:    j['experienceLevel'] as String?,
    goals:              _strings(j['goals']),
    primaryGym:         j['primaryGym']     as String?,
    latitude:           (j['latitude']      as num?)?.toDouble(),
    longitude:          (j['longitude']     as num?)?.toDouble(),
    searchRadius:       j['searchRadius']   as int?     ?? 10,
    xpTotal:            j['xpTotal']        as int?     ?? 0,
    weeklyXp:           j['weeklyXp']       as int?     ?? 0,
    monthlyXp:          j['monthlyXp']      as int?     ?? 0,
    level:              j['level']          as int?     ?? 1,
    chatTokens:         j['chatTokens']     as int?     ?? 20,
    isInfluencer:       j['isInfluencer']   as bool?    ?? false,
    instagramHandle:    j['instagramHandle'] as String?,
    instagramFollowers: j['instagramFollowers'] as int?,
    trustScore:         (j['trustScore']    as num?)?.toDouble() ?? 30.0,
    idVerified:         j['idVerified']     as bool?    ?? false,
    buddyCount:         j['buddyCount']      as int? ?? 0,
    sessionCount:       j['sessionCount']    as int? ?? 0,
    challengeCount:     j['challengeCount']  as int? ?? 0,
    subscriptionPlan:   j['subscriptionPlan']   as String? ?? 'free',
    subscriptionExpiry: j['subscriptionExpiry']  != null
        ? DateTime.parse(j['subscriptionExpiry']  as String) : null,
    influencerBio:      j['influencerBio']        as String?,
    influencerAppliedAt: j['influencerAppliedAt'] != null
        ? DateTime.parse(j['influencerAppliedAt'] as String) : null,
    influencerSessionLimit: j['influencerSessionLimit'] as int? ?? 3,
    lastActiveAt:       j['lastActiveAt']         != null
        ? DateTime.parse(j['lastActiveAt']         as String) : null,
    age:                j['age']                  as int?,
    matchScore:         j['matchScore']           as int?,
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'email': email, 'firstName': firstName, 'lastName': lastName,
    'avatarUrl': avatarUrl, 'phone': phone, 'username': username, 'bio': bio,
    'country': country, 'city': city, 'status': status,
    'emailVerified': emailVerified, 'isBanned': isBanned,
    'primaryActivity': primaryActivity, 'activities': activities,
    'experienceLevel': experienceLevel, 'goals': goals,
    'primaryGym': primaryGym, 'xpTotal': xpTotal, 'level': level,
    'chatTokens': chatTokens, 'isInfluencer': isInfluencer,
    'trustScore': trustScore, 'idVerified': idVerified,
    'subscriptionPlan': subscriptionPlan,
  };

  UserModel copyWith({
    String? firstName, String? lastName, String? avatarUrl, String? bio,
    String? username,  String? phone,    String? city,       String? country,
    String? gender,    bool?   walkthroughSeen,
    String? primaryActivity,    List<String>? activities,
    String? experienceLevel,    List<String>? goals,
    String? primaryGym,         int?          xpTotal,
    int?    level,              int?          chatTokens,
    double? latitude,           double?       longitude,
    int?    searchRadius,
    double? trustScore,         bool?         idVerified,
    int?    buddyCount,         int?          sessionCount,
    int?    challengeCount,
    String?   subscriptionPlan,   DateTime?  subscriptionExpiry,
    String?   influencerBio,       DateTime?  influencerAppliedAt,
    int?      influencerSessionLimit,
    DateTime? lastActiveAt,          int?     age,
    int?      matchScore,
  }) => UserModel(
    id: id, email: email, createdAt: createdAt,
    status: status, emailVerified: emailVerified, isBanned: isBanned,
    isInfluencer: isInfluencer, instagramHandle: instagramHandle,
    instagramFollowers: instagramFollowers,
    firstName:          firstName          ?? this.firstName,
    lastName:           lastName           ?? this.lastName,
    avatarUrl:          avatarUrl          ?? this.avatarUrl,
    bio:                bio                ?? this.bio,
    username:           username           ?? this.username,
    phone:              phone              ?? this.phone,
    city:               city               ?? this.city,
    country:            country            ?? this.country,
    gender:             gender             ?? this.gender,
    walkthroughSeen:    walkthroughSeen    ?? this.walkthroughSeen,
    latitude:           latitude           ?? this.latitude,
    longitude:          longitude          ?? this.longitude,
    searchRadius:       searchRadius       ?? this.searchRadius,
    primaryActivity:    primaryActivity    ?? this.primaryActivity,
    activities:         activities         ?? this.activities,
    experienceLevel:    experienceLevel    ?? this.experienceLevel,
    goals:              goals              ?? this.goals,
    primaryGym:         primaryGym         ?? this.primaryGym,
    xpTotal:            xpTotal            ?? this.xpTotal,
    level:              level              ?? this.level,
    chatTokens:         chatTokens         ?? this.chatTokens,
    trustScore:         trustScore         ?? this.trustScore,
    idVerified:         idVerified         ?? this.idVerified,
    buddyCount:         buddyCount         ?? this.buddyCount,
    sessionCount:       sessionCount       ?? this.sessionCount,
    challengeCount:     challengeCount     ?? this.challengeCount,
    subscriptionPlan:        subscriptionPlan        ?? this.subscriptionPlan,
    subscriptionExpiry:      subscriptionExpiry      ?? this.subscriptionExpiry,
    influencerBio:           influencerBio           ?? this.influencerBio,
    influencerAppliedAt:     influencerAppliedAt     ?? this.influencerAppliedAt,
    influencerSessionLimit:  influencerSessionLimit  ?? this.influencerSessionLimit,
    lastActiveAt:            lastActiveAt            ?? this.lastActiveAt,
    age:                     age                     ?? this.age,
    matchScore:              matchScore              ?? this.matchScore,
  );
}

// ── Helpers ───────────────────────────────────────────────
List<String> _strings(dynamic v) =>
    (v as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];

T? _castOr<T>(dynamic v, T? fallback) => v is T ? v : fallback;




class BuddyStrike {
  BuddyStrike({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.matchId,
    required this.expiresAt,
    required this.createdAt,
    this.imageUrl,
    this.caption,
    this.reactEmoji,
    this.viewedAt,
    this.sender,
    this.streak = 0,
  });

  final String    id;
  final String    senderId;
  final String    receiverId;
  final String    matchId;
  final String?   imageUrl;   // null until viewed (one-time view)
  final String?   caption;
  final String?   reactEmoji; // 💪🔥😤🏆🤝😮
  final DateTime? viewedAt;
  final DateTime  expiresAt;
  final DateTime  createdAt;
  final Map<String, dynamic>? sender; // {id, firstName, avatarUrl}
  final int       streak;

  bool get isViewed  => viewedAt != null;
  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get canReact  => isViewed && reactEmoji == null && !isExpired;

  factory BuddyStrike.fromJson(Map<String, dynamic> j) => BuddyStrike(
    id:         j['id']         as String,
    senderId:   j['senderId']   as String,
    receiverId: j['receiverId'] as String,
    matchId:    j['matchId']    as String,
    imageUrl:   j['imageUrl']   as String?,
    caption:    j['caption']    as String?,
    reactEmoji: j['reactEmoji'] as String?,
    viewedAt:   j['viewedAt'] != null
        ? DateTime.parse(j['viewedAt'] as String)
        : null,
    expiresAt:  DateTime.parse(j['expiresAt'] as String),
    createdAt:  DateTime.parse(j['createdAt'] as String),
    sender:     j['sender']  as Map<String, dynamic>?,
    streak:     j['streak']  as int? ?? 0,
  );
}

// ════════════════════════════════════════════════════════
//  NEW CLASS 2 — StrikeStreakEntry (leaderboard ke liye)
//  File ke end mein add karo (BuddyStrike ke baad)
// ════════════════════════════════════════════════════════

class StrikeStreakEntry {
  StrikeStreakEntry({
    required this.matchId,
    required this.userAName,
    required this.userBName,
    required this.streak,
    this.userAAvatarUrl,
    this.userBAvatarUrl,
  });

  final String  matchId;
  final String  userAName;
  final String  userBName;
  final int     streak;
  final String? userAAvatarUrl;
  final String? userBAvatarUrl;

  factory StrikeStreakEntry.fromJson(Map<String, dynamic> j) =>
      StrikeStreakEntry(
        matchId:        j['matchId']        as String,
        userAName:      j['userAName']      as String,
        userBName:      j['userBName']      as String,
        streak:         j['streak']         as int,
        userAAvatarUrl: j['userAAvatarUrl'] as String?,
        userBAvatarUrl: j['userBAvatarUrl'] as String?,
      );
}


// ─────────────────────────────────────────────────────────
//  Influencer Models
// ─────────────────────────────────────────────────────────

class InfluencerProfile {
  InfluencerProfile({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.instagramHandle,
    required this.instagramFollowers,
    required this.isLocked,
    required this.influencerSessionLimit,
    required this.sessionsUsed,
    required this.sessionsRemaining,
    required this.canBook,
    this.avatarUrl,
    this.city,
    this.primaryActivity,
    this.influencerBio,
    this.trustScore = 30.0,
    this.level = 1,
    this.totalSessions = 0,
    this.instagramVerifiedAt,
  });

  final String  id;
  final String  firstName;
  final String  lastName;
  final String? avatarUrl;
  final String? city;
  final String? primaryActivity;
  final String  instagramHandle;
  final int     instagramFollowers;
  final String? influencerBio;
  final double  trustScore;
  final int     level;
  final int     totalSessions;
  final DateTime? instagramVerifiedAt;
  final bool    isLocked;          // Non-elite = true
  final int     influencerSessionLimit;      // This month
  final int     sessionsUsed;      // This month
  final int     sessionsRemaining; // Left this month
  final bool    canBook;           // Elite + sessions remaining

  String get fullName  => '$firstName $lastName'.trim();
  String get igUrl     => 'https://instagram.com/$instagramHandle';
  String get followers => instagramFollowers >= 1000000
      ? '${(instagramFollowers / 1000000).toStringAsFixed(1)}M'
      : instagramFollowers >= 1000
      ? '${(instagramFollowers / 1000).toStringAsFixed(0)}K'
      : '$instagramFollowers';

  factory InfluencerProfile.fromJson(Map<String, dynamic> j) =>
      InfluencerProfile(
        id:                  j['id']                  as String,
        firstName:           j['firstName']            as String,
        lastName:            j['lastName']             as String? ?? '',
        avatarUrl:           j['avatarUrl']            as String?,
        city:                j['city']                 as String?,
        primaryActivity:     j['primaryActivity']      as String?,
        instagramHandle:     j['instagramHandle']      as String,
        instagramFollowers:  j['instagramFollowers']   as int? ?? 0,
        influencerBio:       j['influencerBio']        as String?,
        trustScore:          (j['trustScore'] as num?) ?.toDouble() ?? 30.0,
        level:               j['level']                as int? ?? 1,
        totalSessions:       j['totalSessions']        as int? ?? 0,
        instagramVerifiedAt: j['instagramVerifiedAt'] != null
            ? DateTime.parse(j['instagramVerifiedAt']) : null,
        isLocked:            j['isLocked']             as bool? ?? true,
        influencerSessionLimit:        j['influencerSessionLimit']         as int? ?? 0,
        sessionsUsed:        j['sessionsUsed']         as int? ?? 0,
        sessionsRemaining:   j['sessionsRemaining']    as int? ?? 0,
        canBook:             j['canBook']              as bool? ?? false,
      );
}

class InfluencerApplicationStatus {
  InfluencerApplicationStatus({
    required this.applied,
    this.status,
    this.verificationCode,
    this.instagramHandle,
    this.codeExpiresIn,
    this.codeExpired = false,
    this.canReapplyAt,
    this.rejectedReason,
  });

  final bool     applied;
  final String?  status;           // pending|code_added|approved|rejected
  final String?  verificationCode; // "SESHLLY-X7K9P2"
  final String?  instagramHandle;
  final String?  codeExpiresIn;
  final bool     codeExpired;
  final String?  canReapplyAt;
  final String?  rejectedReason;

  bool get isPending   => status == 'pending';
  bool get isCodeAdded => status == 'code_added';
  bool get isApproved  => status == 'approved';
  bool get isRejected  => status == 'rejected';

  factory InfluencerApplicationStatus.fromJson(Map<String, dynamic> j) =>
      InfluencerApplicationStatus(
        applied:          j['applied']           as bool,
        status:           j['status']            as String?,
        verificationCode: j['verificationCode']  as String?,
        instagramHandle:  j['instagramHandle']   as String?,
        codeExpiresIn:    j['codeExpiresIn']     as String?,
        codeExpired:      j['codeExpired']       as bool? ?? false,
        canReapplyAt:     j['canReapplyAt']      as String?,
        rejectedReason:   j['rejectedReason']    as String?,
      );
}

// Match request from another user
class MatchRequest {
  MatchRequest({
    required this.swipeId,
    required this.user,
    required this.createdAt,
    this.isSuperLike = false,
  });

  final String    swipeId;
  final UserModel user;
  final DateTime  createdAt;
  final bool      isSuperLike;

  factory MatchRequest.fromJson(Map<String, dynamic> j) => MatchRequest(
    swipeId:     j['swipeId']     as String,
    user:        UserModel.fromJson(j['user'] as Map<String, dynamic>),
    createdAt:   DateTime.parse(j['createdAt'] as String),
    isSuperLike: j['isSuperLike'] as bool? ?? false,
  );
}

