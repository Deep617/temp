// ═════════════════════════════════════════════════════════
//  V2 CHALLENGE MODELS
// ═════════════════════════════════════════════════════════

// ── ChallengeStation ──────────────────────────────────────
class ChallengeStation {
  const ChallengeStation({
    required this.id,
    required this.challengeId,
    required this.stationNum,
    required this.title,
    required this.description,
    this.exerciseName     = '',
    this.setsReps         = '',
    this.proofInstruction = 'Upload a photo or video of your workout',
    required this.verifyType,
    required this.targetValue,
    required this.buddyRequired,
    required this.xpReward,
  });

  final String id;
  final String challengeId;
  final int    stationNum;
  final String title;
  final String description;
  final String exerciseName;      // e.g. "Push-ups"
  final String setsReps;          // e.g. "3 sets × 20 reps"
  final String proofInstruction;  // exact proof guidance shown to user
  final String verifyType;
  final int    targetValue;
  final bool   buddyRequired;
  final int    xpReward;

  factory ChallengeStation.fromJson(Map<String, dynamic> j) =>
      ChallengeStation(
        id:               j['id']               as String,
        challengeId:      j['challengeId']      as String,
        stationNum:       j['stationNum']        as int,
        title:            j['title']             as String,
        description:      j['description']       as String,
        exerciseName:     j['exerciseName']      as String? ?? '',
        setsReps:         j['setsReps']          as String? ?? '',
        proofInstruction: j['proofInstruction']  as String? ?? 'Upload a photo or video of your workout',
        verifyType:       j['verifyType']        as String,
        targetValue:      j['targetValue']       as int,
        buddyRequired:    j['buddyRequired']     as bool? ?? false,
        xpReward:         j['xpReward']          as int,
      );
}

// ── StationCompletion ─────────────────────────────────────
class StationCompletion {
  const StationCompletion({
    required this.id,
    required this.stationId,
    required this.stationNum,
    required this.completedAt,
    required this.xpAwarded,
    required this.progressValue,
    this.isCollab = false,
  });

  final String   id;
  final String   stationId;
  final int      stationNum;
  final DateTime completedAt;
  final int      xpAwarded;
  final int      progressValue;
  final bool     isCollab;

  factory StationCompletion.fromJson(Map<String, dynamic> j) =>
      StationCompletion(
        id:            j['id']            as String,
        stationId:     j['stationId']     as String,
        stationNum:    j['stationNum']    as int,
        completedAt:   DateTime.parse(j['completedAt'] as String),
        xpAwarded:     j['xpAwarded']     as int,
        progressValue: j['progressValue'] as int? ?? 0,
        isCollab:      j['isCollab']      as bool? ?? false,
      );
}

// ── ChallengeEntry ────────────────────────────────────────
// ── ChallengeEntry ────────────────────────────────────────
class ChallengeEntry {
  const ChallengeEntry({
    required this.id,
    required this.challengeId,
    required this.userId,
    required this.status,
    required this.currentStation,
    required this.totalXpEarned,
    required this.joinedAt,
    this.buddyId,
    this.challengeTitle,
    this.rankCity,
    this.rankGlobal,
    this.lastSessionAt,
    this.completedAt,
    this.completions = const [],
  });

  final String   id;
  final String   challengeId;
  final String   userId;
  final String?  buddyId;
  final String?  challengeTitle; // from challenge.title via include
  final String   status; // active/completed/dormant/dropped
  final int      currentStation;
  final int      totalXpEarned;
  final int?     rankCity;
  final int?     rankGlobal;
  final DateTime joinedAt;
  final DateTime? lastSessionAt;
  final DateTime? completedAt;
  final List<StationCompletion> completions;

  factory ChallengeEntry.fromJson(Map<String, dynamic> j) =>
      ChallengeEntry(
        id:             j['id']             as String,
        challengeId:    j['challengeId']    as String,
        userId:         j['userId']         as String,
        buddyId:        j['buddyId']        as String?,
        challengeTitle: j['challengeTitle'] as String?
            ?? (j['challenge'] as Map<String, dynamic>?)?['title'] as String?,
        status:         j['status']         as String,
        currentStation: j['currentStation'] as int? ?? 0,
        totalXpEarned:  j['totalXpEarned']  as int? ?? 0,
        rankCity:       j['rankCity']       as int?,
        rankGlobal:     j['rankGlobal']     as int?,
        joinedAt:       DateTime.parse(j['joinedAt'] as String),
        lastSessionAt:  j['lastSessionAt'] != null
            ? DateTime.parse(j['lastSessionAt'] as String)
            : null,
        completedAt:    j['completedAt'] != null
            ? DateTime.parse(j['completedAt'] as String)
            : null,
        completions:    (j['completions'] as List<dynamic>? ?? [])
            .map((e) => StationCompletion.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

// ── Challenge ─────────────────────────────────────────────
// ── Challenge ─────────────────────────────────────────────
class Challenge {
  const Challenge({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.tier,
    required this.activityType,
    required this.activityTag,
    this.environment = 'any',
    required this.startAt,
    required this.endAt,
    required this.xpPool,
    required this.entryLevelRequired,
    required this.trustRequired,
    required this.isActive,
    this.cityId,
    this.maxParticipants,
    this.stations = const [],
    this.myEntry,
    this.participantCount = 0,
  });

  final String   id;
  final String   title;
  final String   description;
  final String   type;         // solo/duel/pack
  final int      tier;         // 1/2/3/4
  final String   activityType; // gym|outdoor|running|cycling|swimming|boxing|yoga|any
  final String   activityTag;  // e.g. "🏋️ Gym", "🏃 Running", "🏅 Any activity"
  final String   environment;  // gym | outdoor | no_gym | any
  final String?  cityId;
  final DateTime startAt;
  final DateTime endAt;
  final int      xpPool;
  final int      entryLevelRequired;
  final int      trustRequired;
  final bool     isActive;
  final int?     maxParticipants;
  final List<ChallengeStation> stations;
  final ChallengeEntry?        myEntry;
  final int      participantCount;

  bool get isEnrolled => myEntry != null && myEntry!.status == 'active';

  int get daysLeft {
    final diff = endAt.difference(DateTime.now()).inDays;
    return diff < 0 ? 0 : diff;
  }

  double get progressPercent {
    if (myEntry == null || stations.isEmpty) return 0.0;
    return (myEntry!.completions.length / stations.length).clamp(0.0, 1.0);
  }

  factory Challenge.fromJson(Map<String, dynamic> j) =>
      Challenge(
        id:                  j['id']                  as String,
        title:               j['title']               as String,
        description:         j['description']         as String,
        type:                j['type']                as String,
        tier:                j['tier']                as int,
        activityType:        j['activityType']        as String? ?? 'any',
        activityTag:         j['activityTag']         as String? ?? '🏅 Any activity',
        environment:         j['environment']         as String? ?? 'any',
        cityId:              j['cityId']              as String?,
        startAt:             DateTime.parse(j['startAt'] as String),
        endAt:               DateTime.parse(j['endAt']   as String),
        xpPool:              j['xpPool']              as int,
        entryLevelRequired:  j['entryLevelRequired']  as int? ?? 1,
        trustRequired:       j['trustRequired']       as int? ?? 0,
        isActive:            j['isActive']            as bool? ?? true,
        maxParticipants:     j['maxParticipants']     as int?,
        participantCount:    j['participantCount']    as int? ?? 0,
        stations: (j['stations'] as List<dynamic>? ?? [])
            .map((e) => ChallengeStation.fromJson(e as Map<String, dynamic>))
            .toList(),
        myEntry: j['myEntry'] != null
            ? ChallengeEntry.fromJson(j['myEntry'] as Map<String, dynamic>)
            : null,
      );
}

// ── LeaderboardEntry ──────────────────────────────────────
class LeaderboardEntry {
  const LeaderboardEntry({
    required this.rank,
    required this.userId,
    required this.displayName,
    required this.xpEarned,
    required this.stationsCompleted,
    this.avatarUrl,
    this.city,
    this.buddyName,
  });

  final int    rank;
  final String userId;
  final String displayName;
  final String? avatarUrl;
  final String? city;
  final String? buddyName;
  final int    xpEarned;
  final int    stationsCompleted;

  factory LeaderboardEntry.fromJson(Map<String, dynamic> j) =>
      LeaderboardEntry(
        rank:               j['rank']               as int,
        userId:             j['userId']             as String,
        displayName:        j['displayName']        as String,
        avatarUrl:          j['avatarUrl']          as String?,
        city:               j['city']               as String?,
        buddyName:          j['buddyName']          as String?,
        xpEarned:           j['xpEarned']           as int,
        stationsCompleted:  j['stationsCompleted']  as int,
      );
}

// ── ChallengeFeedPost ─────────────────────────────────────
class ChallengeFeedPost {
  const ChallengeFeedPost({
    required this.id,
    required this.userId,
    required this.displayName,
    required this.stationNum,
    required this.stationTitle,
    required this.postedAt,
    required this.expiresAt,
    required this.xpAwarded,
    this.proofImageUrl,
    this.avatarUrl,
    this.city,
    this.challengeId,
    this.challengeTitle,
    this.activityTag,
    this.isCollab = false,
    this.collabUserName,
    this.collabAvatarUrl,
    this.activitySlug,
    this.caption,
    this.groupPhotoUrl,
    this.groupName,
  });

  final String   id;
  final String   userId;
  final String   displayName;
  final String?  avatarUrl;
  final String?  city;
  final String?  challengeId;
  final String?  challengeTitle;
  final String?  activityTag;
  final int      stationNum;
  final String   stationTitle;
  final DateTime postedAt;
  final DateTime expiresAt;
  final int      xpAwarded;
  final String?  proofImageUrl;
  final bool     isCollab;
  final String?  collabUserName;
  final String?  collabAvatarUrl;
  final String?  activitySlug;
  final String?  caption;
  final String?  groupPhotoUrl;
  final String?  groupName;

  // Time left until post expires
  Duration get timeLeft => expiresAt.difference(DateTime.now());
  bool     get isExpired => timeLeft.isNegative;
  String   get timeLeftLabel {
    final h = timeLeft.inHours;
    final m = timeLeft.inMinutes % 60;
    if (h > 0) return '${h}h ${m}m left';
    return '${m}m left';
  }

  factory ChallengeFeedPost.fromJson(Map<String, dynamic> j) =>
      ChallengeFeedPost(
        id:             j['id']             as String,
        userId:         j['userId']         as String,
        displayName:    j['displayName']    as String,
        avatarUrl:      j['avatarUrl']      as String?,
        city:           j['city']           as String?,
        challengeId:    j['challengeId']    as String?,
        challengeTitle: j['challengeTitle'] as String?,
        activityTag:    j['activityTag']    as String?,
        stationNum:     j['stationNum']     as int,
        stationTitle:   j['stationTitle']   as String,
        postedAt:       DateTime.parse(j['postedAt'] as String),
        expiresAt:      j['expiresAt'] != null
            ? DateTime.parse(j['expiresAt'] as String)
            : DateTime.now().add(const Duration(hours: 24)),
        xpAwarded:      j['xpAwarded']      as int,
        proofImageUrl:  j['proofImageUrl']  as String?,
        isCollab:       j['isCollab']       as bool? ?? false,
        collabUserName: j['collabUserName'] as String?,
        collabAvatarUrl:j['collabAvatarUrl']as String?,
        activitySlug:   j['activitySlug']   as String?,
        caption:        j['caption']        as String?,
        groupPhotoUrl:  j['groupPhotoUrl']  as String?,
        groupName:      j['groupName']      as String?,
      );
}

// ── GlobalLeaderboardEntry ────────────────────────────────
class GlobalLeaderboardEntry {
  const GlobalLeaderboardEntry({
    required this.rank,
    required this.userId,
    required this.displayName,
    required this.xpTotal,
    required this.level,
    this.avatarUrl,
    this.city,
    this.primaryActivity,
  });

  final int     rank;
  final String  userId;
  final String  displayName;
  final int     xpTotal;
  final int     level;
  final String? avatarUrl;
  final String? city;
  final String? primaryActivity;

  factory GlobalLeaderboardEntry.fromJson(Map<String, dynamic> j) =>
      GlobalLeaderboardEntry(
        rank:            j['rank']            as int,
        userId:          j['userId']          as String,
        displayName:     j['displayName']     as String,
        xpTotal:         j['xpTotal']         as int,
        level:           j['level']           as int,
        avatarUrl:       j['avatarUrl']       as String?,
        city:            j['city']            as String?,
        primaryActivity: j['primaryActivity'] as String?,
      );
}
