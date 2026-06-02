import 'package:equatable/equatable.dart';

import '../../../../../core/errors/app_error.dart';
import '../../data/response_ml/workout_session.dart';

enum SessionStatus {
  initial,
  loading,
  success,
  scheduling,
  scheduled,
  uploading,
  uploaded,
  failure,
}

class SessionState extends Equatable {
  const SessionState({
    this.status = SessionStatus.initial,
    this.sessions = const [],
    this.error,
  });

  final SessionStatus status;
  final List<WorkoutSession> sessions;
  final AppError? error;

  bool get isLoading => status == SessionStatus.loading;

  bool get isScheduling => status == SessionStatus.scheduling;

  bool get isUploading => status == SessionStatus.uploading;

  bool get isEmpty => status == SessionStatus.success && sessions.isEmpty;

  SessionState copyWith({
    SessionStatus? status,
    List<WorkoutSession>? sessions,
    AppError? error,
    bool clearError = false,
  }) => SessionState(
    status: status ?? this.status,
    sessions: sessions ?? this.sessions,
    error: clearError ? null : error ?? this.error,
  );

  @override
  List<Object?> get props => [status, sessions, error];
}
