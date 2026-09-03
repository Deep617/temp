// ─────────────────────────────────────────────────────────
//  FlashStreakModel
//  Sesh Flash streak between 2 buddies
// ─────────────────────────────────────────────────────────
class FlashStreakModel {
  const FlashStreakModel({
    required this.buddyId,
    required this.buddyName,
    required this.buddyAvatar,
    required this.currentStreak,
    required this.longestStreak,
    required this.flashStatus,
    this.lastStreakAt,
  });

  final String    buddyId;
  final String    buddyName;
  final String?   buddyAvatar;
  final int       currentStreak;
  final int       longestStreak;

  /// 'send_now' | 'waiting' | 'respond' | 'done'
  /// send_now  = neither sent today
  /// waiting   = I sent, buddy hasn't
  /// respond   = buddy sent, I haven't
  /// done      = both sent today ✅
  final String    flashStatus;
  final DateTime? lastStreakAt;

  bool get hasStreak    => currentStreak > 0;
  bool get needsAction  => flashStatus == 'send_now' || flashStatus == 'respond';
  bool get iDone        => flashStatus == 'waiting'  || flashStatus == 'done';

  factory FlashStreakModel.fromJson(Map<String, dynamic> j) => FlashStreakModel(
    buddyId:       j['buddyId']       as String,
    buddyName:     j['buddyName']     as String,
    buddyAvatar:   j['buddyAvatar']   as String?,
    currentStreak: j['currentStreak'] as int?    ?? 0,
    longestStreak: j['longestStreak'] as int?    ?? 0,
    flashStatus:   j['flashStatus']   as String? ?? 'send_now',
    lastStreakAt:  j['lastStreakAt']  != null
        ? DateTime.parse(j['lastStreakAt'] as String) : null,
  );
}