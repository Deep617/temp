import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../../core/errors/app_error.dart';
import '../../data/repositories/chat_repository.dart';
import '../../data/response_ml/message.dart';

part 'chat_event.dart';
part 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  ChatBloc({required ChatRepository chatRepository})
    : _repo = chatRepository,
      super(const ChatState()) {
    on<ChatListLoaded>(_onListLoaded);
    on<ChatMessagesLoaded>(_onMessagesLoaded);
    on<ChatMessageSent>(_onMessageSent);
    on<ChatMessageReceived>(_onMessageReceived);
    on<ChatMarkedRead>(_onMarkedRead);
  }

  final ChatRepository _repo;

  Future<void> _onListLoaded(
    ChatListLoaded event,
    Emitter<ChatState> emit,
  ) async {
    emit(state.copyWith(status: ChatStatus.loading, clearError: true));
    try {
      final chats = await _repo.getChats();
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
      ),
    );
    try {
      final messages = await _repo.getMessages(event.chatId);
      emit(
        state.copyWith(
          status: ChatStatus.success,
          messages: messages.reversed.toList(),
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
          messages: [...state.messages, message],
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
          messages: [...state.messages, event.message],
        ),
      );
    }
  }

  Future<void> _onMarkedRead(
    ChatMarkedRead event,
    Emitter<ChatState> emit,
  ) async {
    await _repo.markRead(event.chatId);
  }
}
