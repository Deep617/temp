// ═════════════════════════════════════════════════════════
//  WorkoutSession
// ═════════════════════════════════════════════════════════
class WorkoutSession {
  const WorkoutSession({
    required this.id,
    required this.userId,
    this.buddyId,
    this.buddyName,
    required this.activity,
    this.gymName,
    required this.scheduledAt,
    this.status = 'scheduled',
    this.proofImageUrl,
    this.proofVideoUrl,
    this.proofUploadedAt,
    this.xpEarned,
    this.tokensDeducted,
    this.notes,
    this.challengeId,
    this.challengeTitle,
    this.challengeStationNum,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String? buddyId;
  final String? buddyName;
  final String activity;
  final String? gymName;
  final DateTime scheduledAt;
  final String status; // scheduled | completed | missed | cancelled
  final String? proofImageUrl;
  final String? proofVideoUrl;
  final DateTime? proofUploadedAt;
  final int? xpEarned;
  final int? tokensDeducted;
  final String? notes;
  final String? challengeId; // if linked to challenge
  final String? challengeTitle; // challenge name
  final int? challengeStationNum; // which station was completed
  final DateTime  createdAt;

  bool get isCompleted => status == 'completed';

  bool get isMissed => status == 'missed';

  bool get needsProof =>
      status == 'scheduled' &&
      scheduledAt.isBefore(DateTime.now()) &&
      proofImageUrl == null;

  bool get proofUploaded => proofImageUrl != null || proofVideoUrl != null;

  factory WorkoutSession.fromJson(Map<String, dynamic> j) => WorkoutSession(
    id: j['id'] as String,
    userId: j['userId'] as String,
    buddyId: j['buddyId'] as String?,
    buddyName: j['buddyName'] as String?,
    activity: j['activity'] as String,
    gymName: j['gymName'] as String?,
    scheduledAt: DateTime.parse(j['scheduledAt'] as String),
    status: j['status'] as String? ?? 'scheduled',
    proofImageUrl: j['proofImageUrl'] as String?,
    proofVideoUrl: j['proofVideoUrl'] as String?,
    proofUploadedAt: j['proofUploadedAt'] != null
        ? DateTime.parse(j['proofUploadedAt'] as String)
        : null,
    xpEarned: j['xpEarned'] as int?,
    tokensDeducted: j['tokensDeducted'] as int?,
    notes: j['notes'] as String?,
    challengeId: j['challengeId'] as String?,
    challengeTitle: j['challengeTitle'] as String?,
    challengeStationNum: j['challengeStationNum'] as int?,
    createdAt: DateTime.parse(j['createdAt'] as String),
  );
}
