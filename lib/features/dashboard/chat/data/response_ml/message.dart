// ── Message ───────────────────────────────────────────────
class Message {
  final String   id;
  final String   chatId;
  final String   senderId;
  final String   senderName;
  final String?  senderAvatar;
  final String   content;
  final String   type; // text, image, session_invite, proof
  final bool     isRead;
  final DateTime createdAt;
  final Map<String,dynamic>? metadata;

  const Message({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.senderName,
    this.senderAvatar,
    required this.content,
    this.type = 'text',
    this.isRead = false,
    required this.createdAt,
    this.metadata,
  });

  factory Message.fromJson(Map<String, dynamic> j) => Message(
    id: j['id'], chatId: j['chatId'], senderId: j['senderId'],
    senderName: j['senderName'], senderAvatar: j['senderAvatar'],
    content: j['content'], type: j['type'] ?? 'text',
    isRead: j['isRead'] ?? false,
    createdAt: DateTime.parse(j['createdAt']),
    metadata: j['metadata'],
  );

  Map<String,dynamic> toJson() => {
    'id':id, 'chatId':chatId, 'senderId':senderId,
    'content':content, 'type':type, 'isRead':isRead,
    'createdAt':createdAt.toIso8601String(),
  };
}