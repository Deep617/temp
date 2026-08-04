// ═════════════════════════════════════════════════════════
class WorkoutSession {
  const WorkoutSession({
    required this.id,
    required this.userId,
    required this.activity,
    required this.scheduledAt,
    required this.durationMins,
    required this.endTime,
    required this.createdAt,
    this.buddyId,
    this.buddyName,
    this.buddyAvatar,
    this.gymName,
    this.status          = 'pending_confirmation',
    this.proofImageUrl,
    this.proofVideoUrl,
    this.proofUploadedAt,
    this.xpEarned,
    this.tokensDeducted,
    this.notes,
    this.incompleteReason,
    this.challengeId,
    this.challengeTitle,
    this.challengeStationNum,
    this.chatId,
    this.participants    = const [],
  });

  final String    id;
  final String    userId;
  final String?   buddyId;
  final String?   buddyName;
  final String?   buddyAvatar;
  final String    activity;
  final String?   gymName;
  final DateTime  scheduledAt;
  final int       durationMins;
  final DateTime  endTime;
  final String    status;
  final String?   proofImageUrl;
  final String?   proofVideoUrl;
  final DateTime? proofUploadedAt;
  final int?      xpEarned;
  final int?      tokensDeducted;
  final String?   notes;
  final String?   incompleteReason;
  final String?   challengeId;
  final String?   challengeTitle;
  final int?      challengeStationNum;
  final String?   chatId;
  final List<SessionParticipant> participants;
  final DateTime  createdAt;

  bool get isCompleted  => status == 'completed';
  bool get isIncomplete => status == 'incomplete';
  bool get isCancelled  => status == 'cancelled';
  bool get isPending    => status == 'pending_confirmation';
  bool get isConfirmed  => status == 'confirmed';
  bool get isGroup      => participants.length > 2;

  // needsProof — session ended, within 3hr window, proof not uploaded yet
  bool get needsProof =>
      canUploadProof && proofImageUrl == null;

  bool get canUploadProof {
    final now      = DateTime.now();
    final deadline = endTime.add(const Duration(hours: 3));
    return now.isAfter(endTime) &&
        now.isBefore(deadline) &&
        proofImageUrl == null &&
        (status == 'confirmed' || status == 'pending_confirmation');
  }

  Duration get proofWindowRemaining =>
      endTime.add(const Duration(hours: 3)).difference(DateTime.now());

  String get durationLabel {
    switch (durationMins) {
      case 45:  return '45 mins';
      case 60:  return '1 hour';
      case 90:  return '1.5 hours';
      case 120: return '2 hours';
      default:  return '$durationMins mins';
    }
  }

  factory WorkoutSession.fromJson(Map<String, dynamic> j) => WorkoutSession(
    id:               j['id']               as String,
    userId:           j['userId']           as String,
    buddyId:          j['buddyId']          as String?,
    buddyName:        j['buddyName']        as String?,
    buddyAvatar:      j['buddyAvatar']      as String?,
    activity:         j['activity']         as String,
    gymName:          j['gymName']          as String?,
    scheduledAt:      DateTime.parse(j['scheduledAt'] as String),
    durationMins:     j['durationMins']     as int?    ?? 60,
    endTime:          j['endTime'] != null
        ? DateTime.parse(j['endTime'] as String)
        : DateTime.parse(j['scheduledAt'] as String)
        .add(const Duration(hours: 1)),
    status:           j['status']           as String? ?? 'pending_confirmation',
    proofImageUrl:    j['proofImageUrl']    as String?,
    proofVideoUrl:    j['proofVideoUrl']    as String?,
    proofUploadedAt:  j['proofUploadedAt'] != null
        ? DateTime.parse(j['proofUploadedAt'] as String) : null,
    xpEarned:         j['xpEarned']         as int?,
    tokensDeducted:   j['tokensDeducted']   as int?,
    notes:            j['notes']            as String?,
    incompleteReason: j['incompleteReason'] as String?,
    challengeId:         j['challengeId']         as String?,
    challengeTitle:      j['challengeTitle']      as String?,
    challengeStationNum: j['challengeStationNum'] as int?,
    chatId:              j['chatId']              as String?,
    participants:     (j['participants'] as List<dynamic>? ?? [])
        .map((e) => SessionParticipant.fromJson(e as Map<String, dynamic>))
        .toList(),
    createdAt:        DateTime.parse(j['createdAt'] as String),
  );
}

class SessionParticipant {
  const SessionParticipant({
    required this.id,
    required this.userId,
    required this.name,
    required this.status,
    this.avatarUrl,
  });
  final String  id;
  final String  userId;
  final String  name;
  final String? avatarUrl;
  final String  status;

  factory SessionParticipant.fromJson(Map<String, dynamic> j) =>
      SessionParticipant(
        id:        j['id']        as String,
        userId:    j['userId']    as String,
        name:      j['name']      as String,
        avatarUrl: j['avatarUrl'] as String?,
        status:    j['status']    as String? ?? 'pending',
      );
}