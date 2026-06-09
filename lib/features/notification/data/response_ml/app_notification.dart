// ── Notification ──────────────────────────────────────────
class AppNotification {
  final String   id;
  final String   type;
  final String   title;
  final String   message;
  final bool     isRead;
  final String?  actionUrl;
  final Map<String,dynamic>? data;
  final DateTime createdAt;

  const AppNotification({
    required this.id, required this.type, required this.title,
    required this.message, this.isRead = false, this.actionUrl,
    this.data, required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String,dynamic> j) => AppNotification(
    id: j['id'], type: j['type'], title: j['title'], message: j['message'],
    isRead: j['isRead'] ?? false, actionUrl: j['actionUrl'],
    data: j['data'], createdAt: DateTime.parse(j['createdAt']),
  );

  String get icon {
    switch (type) {
      case 'match':        return '🤝';
      case 'session':      return '💪';
      case 'proof':        return '📸';
      case 'chat':         return '💬';
      case 'token':        return '🎫';
      case 'xp':           return '⭐';
      case 'payment':      return '💳';
      case 'subscription': return '◈';
      default:             return '🔔';
    }
  }
}