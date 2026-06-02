// ══════════════════════════════════════════════════════════
//  session_event.dart
// ══════════════════════════════════════════════════════════

import 'package:equatable/equatable.dart';

abstract class SessionEvent extends Equatable {
  const SessionEvent();

  @override
  List<Object?> get props => [];
}

class SessionsLoaded extends SessionEvent {
  const SessionsLoaded({this.status});

  final String? status; // null = all, 'scheduled', 'completed', 'missed'
  @override
  List<Object?> get props => [status];
}

class SessionScheduled extends SessionEvent {
  const SessionScheduled({
    required this.buddyId,
    required this.activity,
    required this.scheduledAt,
    this.gymName,
  });

  final String buddyId;
  final String activity;
  final DateTime scheduledAt;
  final String? gymName;

  @override
  List<Object?> get props => [buddyId, activity, scheduledAt, gymName];
}

class SessionProofUploaded extends SessionEvent {
  const SessionProofUploaded({
    required this.sessionId,
    required this.imagePath,
  });

  final String sessionId;
  final String imagePath;

  @override
  List<Object?> get props => [sessionId, imagePath];
}
