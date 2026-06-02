// ── WorkoutSession ────────────────────────────────────────
class WorkoutSession {
  final String   id;
  final String   userId;
  final String?  buddyId;
  final String?  buddyName;
  final String   activity;
  final String?  gymName;
  final DateTime scheduledAt;
  final String   status; // scheduled, completed, missed, cancelled
  final String?  proofImageUrl;
  final String?  proofVideoUrl;
  final DateTime? proofUploadedAt;
  final int?     xpEarned;
  final int?     tokensDeducted;
  final DateTime createdAt;

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
    required this.createdAt,
  });

  bool get isCompleted    => status == 'completed';
  bool get isMissed       => status == 'missed';
  bool get needsProof     => status == 'scheduled' && scheduledAt.isBefore(DateTime.now()) && proofImageUrl == null;
  bool get proofUploaded  => proofImageUrl != null || proofVideoUrl != null;
  Duration get timeUntil  => scheduledAt.difference(DateTime.now());

  factory WorkoutSession.fromJson(Map<String,dynamic> j) => WorkoutSession(
    id: j['id'], userId: j['userId'], buddyId: j['buddyId'],
    buddyName: j['buddyName'], activity: j['activity'],
    gymName: j['gymName'], scheduledAt: DateTime.parse(j['scheduledAt']),
    status: j['status'] ?? 'scheduled',
    proofImageUrl: j['proofImageUrl'], proofVideoUrl: j['proofVideoUrl'],
    proofUploadedAt: j['proofUploadedAt'] != null ? DateTime.parse(j['proofUploadedAt']) : null,
    xpEarned: j['xpEarned'], tokensDeducted: j['tokensDeducted'],
    createdAt: DateTime.parse(j['createdAt']),
  );
}