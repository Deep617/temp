// ─────────────────────────────────────────────────────────
//  PendingProofConfirm — a buddy's proof waiting for MY confirm
//  GET /sessions/pending-confirm  → data.sessions[]
// ─────────────────────────────────────────────────────────
class PendingProofConfirm {
  const PendingProofConfirm({
    required this.sessionId,
    required this.activity,
    required this.deadline,
    this.imageUrl,
    this.uploaderName,
    this.potentialXp = 0,
  });

  final String   sessionId;
  final String   activity;
  final String?  imageUrl;
  final String?  uploaderName;
  final DateTime deadline;     // proofUploadedAt + 2h
  final int      potentialXp;  // XP I get if I confirm

  Duration get timeLeft => deadline.difference(DateTime.now());
  bool     get isExpired => timeLeft.isNegative;

  factory PendingProofConfirm.fromJson(Map<String, dynamic> j) {
    final uploadedAt = j['proofUploadedAt'] != null
        ? DateTime.tryParse(j['proofUploadedAt'].toString())?.toLocal()
        : null;
    final deadline = j['confirmDeadline'] != null
        ? DateTime.tryParse(j['confirmDeadline'].toString())?.toLocal()
        : uploadedAt?.add(const Duration(hours: 2));
    return PendingProofConfirm(
      sessionId:    j['id'] as String,
      activity:     j['activity'] as String? ?? 'Workout',
      imageUrl:     j['proofImageUrl'] as String?,
      uploaderName: j['uploaderName'] as String?,
      deadline:     (deadline ?? DateTime.now()).toLocal(),
      potentialXp:  (j['potentialXp'] as num?)?.toInt() ?? 0,
    );
  }
}
