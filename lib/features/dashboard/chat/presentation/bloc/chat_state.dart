part of 'chat_bloc.dart';

enum ChatStatus { initial, loading, success, sending, failure }

class ChatState extends Equatable {
  const ChatState({
    this.status   = ChatStatus.initial,
    this.chats    = const [],
    this.messages = const [],
    this.error,
    this.activeChatId,
  });

  final ChatStatus                    status;
  final List<Map<String, dynamic>>    chats;
  final List<Message>                 messages;
  final AppError?                     error;
  final String?                       activeChatId;

  bool get isLoading => status == ChatStatus.loading;
  bool get isSending => status == ChatStatus.sending;

  ChatState copyWith({
    ChatStatus?                  status,
    List<Map<String, dynamic>>?  chats,
    List<Message>?               messages,
    AppError?                    error,
    bool                         clearError = false,
    String?                      activeChatId,
  }) =>
      ChatState(
        status:       status       ?? this.status,
        chats:        chats        ?? this.chats,
        messages:     messages     ?? this.messages,
        error:        clearError ? null : error ?? this.error,
        activeChatId: activeChatId ?? this.activeChatId,
      );

  @override
  List<Object?> get props => [status, chats, messages, error, activeChatId];
}
