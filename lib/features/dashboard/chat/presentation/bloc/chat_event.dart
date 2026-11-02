// ── chat_event.dart ───────────────────────────────────────
part of 'chat_bloc.dart';

abstract class ChatEvent extends Equatable {
  const ChatEvent();
  @override
  List<Object?> get props => [];
}

class ChatListLoaded extends ChatEvent {
  const ChatListLoaded();
}

class ChatMessagesLoaded extends ChatEvent {
  const ChatMessagesLoaded({required this.chatId});
  final String chatId;
  @override
  List<Object?> get props => [chatId];
}

class ChatMessageSent extends ChatEvent {
  const ChatMessageSent({required this.chatId, required this.content});
  final String chatId;
  final String content;
  @override
  List<Object?> get props => [chatId, content];
}

class ChatMessageReceived extends ChatEvent {
  const ChatMessageReceived({required this.message});
  final Message message;
  @override
  List<Object?> get props => [message];
}

class ChatMarkedRead extends ChatEvent {
  const ChatMarkedRead({required this.chatId});
  final String chatId;
  @override
  List<Object?> get props => [chatId];
}

/// User picked 24h / Normal from the ⏱ sheet
class ChatModeChanged extends ChatEvent {
  const ChatModeChanged({required this.chatId, required this.disappearing});
  final String chatId;
  final bool disappearing;
  @override
  List<Object?> get props => [chatId, disappearing];
}

/// Scrolled to the top → load the previous page of history
class ChatOlderMessagesLoaded extends ChatEvent {
  const ChatOlderMessagesLoaded({required this.chatId});
  final String chatId;
  @override
  List<Object?> get props => [chatId];
}

/// A message card changed on the server (socket 'message:updated'),
/// e.g. session invite confirmed / declined / expired.
class ChatMessageUpdated extends ChatEvent {
  const ChatMessageUpdated({required this.messageId, this.metadata});
  final String messageId;
  final Map<String, dynamic>? metadata;
  @override
  List<Object?> get props => [messageId, metadata];
}

/// Other user switched the mode (socket 'chat:mode')
class ChatModeReceived extends ChatEvent {
  const ChatModeReceived({required this.chatId, required this.disappearing});
  final String chatId;
  final bool disappearing;
  @override
  List<Object?> get props => [chatId, disappearing];
}
