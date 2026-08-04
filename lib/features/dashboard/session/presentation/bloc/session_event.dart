// ══════════════════════════════════════════════════════════
//  session_event.dart
// ══════════════════════════════════════════════════════════

import 'dart:core';

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
    required this.buddyIds,
    required this.activity,
    required this.scheduledAt,
    required this.durationMins,
    this.gymName,
    this.challengeId,
  });

  final List<String> buddyIds; // [] = solo, [id] = buddy, [id,id] = group
  final String activity;
  final DateTime scheduledAt;
  final int durationMins; // 45 | 60 | 90 | 120
  final String? gymName;
  final String? challengeId;

  @override
  List<Object?> get props => [
    buddyIds,
    activity,
    scheduledAt,
    durationMins,
    gymName,
    challengeId,
  ];
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
