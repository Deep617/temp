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
