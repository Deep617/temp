import 'package:bloc/bloc.dart';
import 'package:seshlly/features/dashboard/session/presentation/bloc/session_event.dart';
import 'package:seshlly/features/dashboard/session/presentation/bloc/session_state.dart';

import '../../../../../core/errors/app_error.dart';
import '../../data/repositories/session_repository.dart';

class SessionBloc extends Bloc<SessionEvent, SessionState> {
  SessionBloc({required SessionRepository sessionRepository})
    : _repo = sessionRepository,
      super(const SessionState()) {
    on<SessionsLoaded>(_onSessionsLoaded);
    on<SessionScheduled>(_onSessionScheduled);
    on<SessionProofUploaded>(_onProofUploaded);
  }

  final SessionRepository _repo;

  Future<void> _onSessionsLoaded(
    SessionsLoaded event,
    Emitter<SessionState> emit,
  ) async {
    emit(state.copyWith(status: SessionStatus.loading, clearError: true));
    try {
      final sessions = await _repo.getSessions(status: event.status);
      emit(state.copyWith(status: SessionStatus.success, sessions: sessions));
    } on AppError catch (e) {
      emit(state.copyWith(status: SessionStatus.failure, error: e));
    }
  }

  Future<void> _onSessionScheduled(
    SessionScheduled event,
    Emitter<SessionState> emit,
  ) async {
    emit(state.copyWith(status: SessionStatus.scheduling, clearError: true));
    try {
      final session = await _repo.scheduleSession(
        buddyId: event.buddyId,
        activity: event.activity,
        scheduledAt: event.scheduledAt,
        gymName: event.gymName,
      );
      emit(
        state.copyWith(
          status: SessionStatus.scheduled,
          sessions: [session, ...state.sessions],
        ),
      );
    } on AppError catch (e) {
      emit(state.copyWith(status: SessionStatus.failure, error: e));
    }
  }

  Future<void> _onProofUploaded(
    SessionProofUploaded event,
    Emitter<SessionState> emit,
  ) async {
    emit(state.copyWith(status: SessionStatus.uploading, clearError: true));
    try {
      final updated = await _repo.uploadProof(
        sessionId: event.sessionId,
        imagePath: event.imagePath,
      );
      final sessions = state.sessions
          .map((s) => s.id == updated.id ? updated : s)
          .toList();
      emit(state.copyWith(status: SessionStatus.uploaded, sessions: sessions));
    } on AppError catch (e) {
      emit(state.copyWith(status: SessionStatus.failure, error: e));
    }
  }
}
