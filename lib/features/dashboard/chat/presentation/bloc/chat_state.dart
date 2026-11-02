part of 'chat_bloc.dart';

enum ChatStatus { initial, loading, success, sending, failure }

class ChatState extends Equatable {
  const ChatState({
    this.status   = ChatStatus.initial,
    this.chats    = const [],
    this.messages = const [],
    this.flashStreaks = const [],
    this.error,
    this.activeChatId,
    this.disappearing = false,
    this.hasOlder = false,
    this.loadingOlder = false,
  });

  final ChatStatus                    status;
  final List<Map<String, dynamic>>    chats;
  final List<Message>                 messages;
  final List<FlashStreakModel> flashStreaks;
  final AppError?                     error;
  final String?                       activeChatId;
  final bool                          disappearing; // active chat is in 24h mode
  final bool                          hasOlder;     // more history on the server
  final bool                          loadingOlder;

  bool get isLoading => status == ChatStatus.loading;
  bool get isSending => status == ChatStatus.sending;

  ChatState copyWith({
    ChatStatus?                  status,
    List<Map<String, dynamic>>?  chats,
    List<Message>?               messages,
    List<FlashStreakModel>? flashStreaks,
    AppError?                    error,
    bool                         clearError = false,
    String?                      activeChatId,
    bool?                        disappearing,
    bool?                        hasOlder,
    bool?                        loadingOlder,
  }) =>
      ChatState(
        status:       status       ?? this.status,
        chats:        chats        ?? this.chats,
        messages:     messages     ?? this.messages,
        flashStreaks:     flashStreaks     ?? this.flashStreaks,
        error:        clearError ? null : error ?? this.error,
        activeChatId: activeChatId ?? this.activeChatId,
        disappearing: disappearing ?? this.disappearing,
        hasOlder:     hasOlder     ?? this.hasOlder,
        loadingOlder: loadingOlder ?? this.loadingOlder,
      );

  @override
  List<Object?> get props =>
      [status, chats, messages, error, activeChatId, disappearing, flashStreaks, hasOlder, loadingOlder];
}
