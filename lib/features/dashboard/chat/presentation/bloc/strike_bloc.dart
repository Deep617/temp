// ─────────────────────────────────────────────────────────
//  bloc/strike/strike_bloc.dart
//  Handles Strike 2 — camera flow, send, view, react
// ─────────────────────────────────────────────────────────
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../strike/data/repositories/strike_repository.dart';

part 'strike_event.dart';
part 'strike_state.dart';

class StrikeBloc extends Bloc<StrikeEvent, StrikeState> {
  StrikeBloc({required StrikeRepository api})
    : _api = api,
      super(const StrikeState()) {
    on<StrikeLoadRequested>(_onLoad);
    on<StrikeCameraOpened>(_onCameraOpen);
    on<StrikeCameraClosed>(_onCameraClose);
    on<StrikePhotoCaptured>(_onPhotoCaptured);
    on<StrikePreviewCleared>(_onPreviewCleared);
    on<StrikeCaptionChanged>(_onCaptionChanged);
    on<StrikeSendRequested>(_onSend);
    on<StrikeViewRequested>(_onView);
    on<StrikeReactionSent>(_onReact);
    on<StrikeReset>(_onReset);
  }

  final StrikeRepository _api;

  // ── Load streak + pending count ───────────────────────
  Future<void> _onLoad(
    StrikeLoadRequested event,
    Emitter<StrikeState> emit,
  ) async {
    emit(state.copyWith(status: StrikeStatus.loading));
    try {
      final results = await Future.wait([
        _api.getStrikeStreak(event.matchId!),
        _api.getPendingStrikes(event.buddyId),
      ]);
      final streak =
          (results[0] as Map<String, dynamic>)['streak'] as int? ?? 0;
      final pendingList = results[1] as List;
      emit(
        state.copyWith(
          status: StrikeStatus.initial,
          streak: streak,
          pendingCount: pendingList.length,
        ),
      );
    } catch (_) {
      emit(state.copyWith(status: StrikeStatus.initial));
    }
  }

  // ── Camera opened (⚡ tapped) ─────────────────────────
  void _onCameraOpen(StrikeCameraOpened event, Emitter<StrikeState> emit) {
    emit(
      state.copyWith(
        status: StrikeStatus.cameraOpen,
        clearImage: true,
        caption: '',
        clearError: true,
      ),
    );
  }

  // ── Camera closed (swiped down / X tapped) ───────────
  void _onCameraClose(StrikeCameraClosed event, Emitter<StrikeState> emit) {
    emit(
      state.copyWith(
        status: StrikeStatus.initial,
        clearImage: true,
        caption: '',
      ),
    );
  }

  // ── Photo captured → show preview ────────────────────
  void _onPhotoCaptured(StrikePhotoCaptured event, Emitter<StrikeState> emit) {
    emit(
      state.copyWith(
        status: StrikeStatus.photoPreview,
        imagePath: event.imagePath,
      ),
    );
  }

  // ── Preview cleared → back to camera ─────────────────
  void _onPreviewCleared(
    StrikePreviewCleared event,
    Emitter<StrikeState> emit,
  ) {
    emit(
      state.copyWith(
        status: StrikeStatus.cameraOpen,
        clearImage: true,
        caption: '',
      ),
    );
  }

  // ── Caption typed ─────────────────────────────────────
  void _onCaptionChanged(
    StrikeCaptionChanged event,
    Emitter<StrikeState> emit,
  ) {
    emit(state.copyWith(caption: event.caption));
  }

  // ── Send Strike ───────────────────────────────────────

  // ── Send Strike ───────────────────────────────────────
  Future<void> _onSend(
    StrikeSendRequested event,
    Emitter<StrikeState> emit,
  ) async {
    emit(state.copyWith(status: StrikeStatus.sending, clearError: true));
    try {
      await _api.sendStrike(
        matchId: event.matchId,
        imageUrl: event.imageFile,
        caption: event.caption,
      );
      // After send, reload streak so banner updates
      final streakData = await _api.getStrikeStreak(event.matchId);
      final newStreak = (streakData)['streak'] as int? ?? state.streak;
      emit(
        state.copyWith(
          status: StrikeStatus.sent,
          streak: newStreak,
          clearImage: true,
          caption: '',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: StrikeStatus.photoPreview,
          errorMessage: 'Failed to send Strike. Try again.',
        ),
      );
    }
  }

  // ── View Strike ───────────────────────────────────────
  Future<void> _onView(
    StrikeViewRequested event,
    Emitter<StrikeState> emit,
  ) async {
    try {
      final strike = await _api.viewStrike(event.strikeId);
      emit(
        state.copyWith(
          status: StrikeStatus.viewing,
          viewingStrike: strike,
          pendingCount: (state.pendingCount - 1).clamp(0, 999),
        ),
      );
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Could not load Strike'));
    }
  }

  // ── React to Strike ───────────────────────────────────
  Future<void> _onReact(
    StrikeReactionSent event,
    Emitter<StrikeState> emit,
  ) async {
    try {
      await _api.reactToStrike(event.strikeId, event.emoji);
      emit(state.copyWith(status: StrikeStatus.initial));
    } catch (_) {}
  }

  // ── Reset (go back to chat) ───────────────────────────
  void _onReset(StrikeReset event, Emitter<StrikeState> emit) {
    emit(
      state.copyWith(
        status: StrikeStatus.initial,
        clearImage: true,
        caption: '',
        clearError: true,
      ),
    );
  }
}
