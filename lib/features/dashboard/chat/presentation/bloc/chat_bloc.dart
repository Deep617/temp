import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../../core/errors/app_error.dart';
import '../../data/repositories/chat_repository.dart';
import '../../data/response_ml/flash_streakmodel.dart';
import '../../data/response_ml/message.dart';

part 'chat_event.dart';
part 'chat_state.dart';

/// Oldest → newest (top → bottom), whatever order the server/socket used.
List<Message> sortMessages(List<Message> messages) {
  final list = [...messages];
  list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
  return list;
}

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  ChatBloc({required ChatRepository chatRepository})
    : _repo = chatRepository,
      super(const ChatState()) {
    on<ChatListLoaded>(_onListLoaded);
    on<ChatMessagesLoaded>(_onMessagesLoaded);
    on<ChatMessageSent>(_onMessageSent);
    on<ChatMessageReceived>(_onMessageReceived);
    on<ChatMarkedRead>(_onMarkedRead);
    on<ChatModeChanged>(_onModeChanged);
    on<ChatModeReceived>(_onModeReceived);
    on<ChatMessageUpdated>(_onMessageUpdated);
    on<ChatOlderMessagesLoaded>(_onOlderLoaded);
  }

  static const pageSize = 30; // server default page size
  int _historyPage = 1;

  Future<void> _onOlderLoaded(ChatOlderMessagesLoaded event, Emitter<ChatState> emit) async {
    if (!state.hasOlder || state.loadingOlder || event.chatId != state.activeChatId) return;
    emit(state.copyWith(loadingOlder: true));
    try {
      final result = await _repo.getMessagesWithMode(event.chatId, page: _historyPage + 1);
      _historyPage++;
      final known = state.messages.map((m) => m.id).toSet();
      final older = result.messages.where((m) => !known.contains(m.id)).toList();
      emit(state.copyWith(
        messages: sortMessages([...older, ...state.messages]),
        hasOlder: result.messages.length >= pageSize,
        loadingOlder: false,
      ));
    } on AppError {
      emit(state.copyWith(loadingOlder: false));
    }
  }

  final ChatRepository _repo;

  Future<void> _onListLoaded(
    ChatListLoaded event,
    Emitter<ChatState> emit,
  ) async {
    emit(state.copyWith(status: ChatStatus.loading, clearError: true));
    try {
      // Streaks are a nice-to-have — never block the chat list on them
      final streaks = await _repo.getMyFlashStreaks().catchError((_) => state.flashStreaks);
      final chats = await _repo.getChats();
      emit(state.copyWith(flashStreaks: streaks));
      emit(state.copyWith(status: ChatStatus.success, chats: chats));
    } on AppError catch (e) {
      emit(state.copyWith(status: ChatStatus.failure, error: e));
    }
  }

  Future<void> _onMessagesLoaded(
    ChatMessagesLoaded event,
    Emitter<ChatState> emit,
  ) async {
    emit(
      state.copyWith(
        status: ChatStatus.loading,
        activeChatId: event.chatId,
        clearError: true,
        disappearing: false,
      ),
    );
    try {
      _historyPage = 1;
      final result = await _repo.getMessagesWithMode(event.chatId);
      emit(
        state.copyWith(
          status: ChatStatus.success,
          hasOlder: result.messages.length >= pageSize,
          messages: sortMessages(result.messages),
          disappearing: result.disappearing,
        ),
      );
    } on AppError catch (e) {
      emit(state.copyWith(status: ChatStatus.failure, error: e));
    }
  }

  Future<void> _onMessageSent(
    ChatMessageSent event,
    Emitter<ChatState> emit,
  ) async {
    emit(state.copyWith(status: ChatStatus.sending));
    try {
      final message = await _repo.sendMessage(event.chatId, event.content);
      emit(
        state.copyWith(
          status: ChatStatus.success,
          messages: _withMessage(message),
        ),
      );
    } on AppError catch (e) {
      emit(state.copyWith(status: ChatStatus.failure, error: e));
    }
  }

  void _onMessageReceived(ChatMessageReceived event, Emitter<ChatState> emit) {
    // Called by Socket.io when a new message arrives
    if (event.message.chatId == state.activeChatId) {
      emit(
        state.copyWith(
          status: ChatStatus.success,
          messages: _withMessage(event.message),
        ),
      );
    }
  }

  // Socket also echoes our own messages back → skip duplicates by id
  List<Message> _withMessage(Message m) =>
      state.messages.any((x) => x.id == m.id)
          ? state.messages
          : sortMessages([...state.messages, m]);

  void _onMessageUpdated(ChatMessageUpdated event, Emitter<ChatState> emit) {
    final i = state.messages.indexWhere((m) => m.id == event.messageId);
    if (i < 0 || event.metadata == null) return;
    final list = [...state.messages];
    list[i] = list[i].copyWith(metadata: event.metadata);
    emit(state.copyWith(messages: list));
  }

  // ── 24h / Normal mode ───────────────────────────────────
  Future<void> _onModeChanged(
    ChatModeChanged event,
    Emitter<ChatState> emit,
  ) async {
    final previous = state.disappearing;
    emit(state.copyWith(disappearing: event.disappearing)); // optimistic
    try {
      final sysMsg = await _repo.setChatMode(event.chatId, event.disappearing);
      if (sysMsg != null && sysMsg.chatId == state.activeChatId) {
        emit(state.copyWith(messages: _withMessage(sysMsg)));
      }
    } on AppError catch (e) {
      emit(state.copyWith(
        disappearing: previous,
        status: ChatStatus.failure,
        error: e,
      ));
    }
  }

  void _onModeReceived(ChatModeReceived event, Emitter<ChatState> emit) {
    if (event.chatId == state.activeChatId) {
      emit(state.copyWith(disappearing: event.disappearing));
    }
  }

  Future<void> _onMarkedRead(
    ChatMarkedRead event,
    Emitter<ChatState> emit,
  ) async {
    await _repo.markRead(event.chatId);
  }
}
