// ═══════════════════════════════════════════════════════════════
//  BuddyMapBloc — Buddy Map (swipe left from Discover)
//  Buddies at a gym ("training now") or in a ~3 km area, a "Training now"
//  filter, and Ghost Mode (hide me from the map).
// ═══════════════════════════════════════════════════════════════
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/app_error.dart';
import '../../data/models/gym_models.dart';
import '../../data/repositories/gym_map_repository.dart';

// ── Events ──
abstract class BuddyMapEvent extends Equatable {
  const BuddyMapEvent();
  @override
  List<Object?> get props => [];
}

class BuddyMapLoaded extends BuddyMapEvent {
  const BuddyMapLoaded();
}

class BuddyMapFilterChanged extends BuddyMapEvent {
  const BuddyMapFilterChanged({required this.trainingOnly});
  final bool trainingOnly;
  @override
  List<Object?> get props => [trainingOnly];
}

/// 'off', '3h', '24h' or 'on' (until turned off)
class BuddyMapGhostChanged extends BuddyMapEvent {
  const BuddyMapGhostChanged(this.mode);
  final String mode;
  @override
  List<Object?> get props => [mode];
}

// ── State ──
enum BuddyMapStatus { initial, loading, ready, failure }

class BuddyMapState extends Equatable {
  const BuddyMapState({
    this.status = BuddyMapStatus.initial,
    this.buddies = const [],
    this.trainingOnly = false,
    this.ghostMode = false,
    this.ghostUntil,
    this.savingGhost = false,
    this.error,
  });

  final BuddyMapStatus status;
  final List<BuddyOnMap> buddies;
  final bool trainingOnly;
  final bool ghostMode;
  final DateTime? ghostUntil;
  final bool savingGhost;
  final String? error;

  List<BuddyOnMap> get visible =>
      trainingOnly ? buddies.where((b) => b.trainingNow).toList() : buddies;
  int get trainingCount => buddies.where((b) => b.trainingNow).length;

  BuddyMapState copyWith({
    BuddyMapStatus? status,
    List<BuddyOnMap>? buddies,
    bool? trainingOnly,
    bool? ghostMode,
    DateTime? ghostUntil,
    bool clearGhostUntil = false,
    bool? savingGhost,
    String? error,
    bool clearError = false,
  }) =>
      BuddyMapState(
        status: status ?? this.status,
        buddies: buddies ?? this.buddies,
        trainingOnly: trainingOnly ?? this.trainingOnly,
        ghostMode: ghostMode ?? this.ghostMode,
        ghostUntil: clearGhostUntil ? null : ghostUntil ?? this.ghostUntil,
        savingGhost: savingGhost ?? this.savingGhost,
        error: clearError ? null : error ?? this.error,
      );

  @override
  List<Object?> get props =>
      [status, buddies, trainingOnly, ghostMode, ghostUntil, savingGhost, error];
}

// ── Bloc ──
class BuddyMapBloc extends Bloc<BuddyMapEvent, BuddyMapState> {
  BuddyMapBloc(this._repo) : super(const BuddyMapState()) {
    on<BuddyMapLoaded>(_onLoaded);
    on<BuddyMapFilterChanged>(
        (e, emit) => emit(state.copyWith(trainingOnly: e.trainingOnly)));
    on<BuddyMapGhostChanged>(_onGhost);
  }

  final GymMapRepository _repo;

  Future<void> _onLoaded(BuddyMapLoaded e, Emitter<BuddyMapState> emit) async {
    emit(state.copyWith(status: BuddyMapStatus.loading, clearError: true));
    try {
      final d = await _repo.buddyMap();
      emit(state.copyWith(
        status: BuddyMapStatus.ready,
        buddies: d.buddies,
        ghostMode: d.ghostMode,
        ghostUntil: d.ghostUntil,
        clearGhostUntil: d.ghostUntil == null,
      ));
    } on AppError catch (err) {
      emit(state.copyWith(status: BuddyMapStatus.failure, error: err.message));
    }
  }

  Future<void> _onGhost(BuddyMapGhostChanged e, Emitter<BuddyMapState> emit) async {
    final before = state.ghostMode;
    emit(state.copyWith(ghostMode: e.mode != 'off', savingGhost: true, clearError: true));
    try {
      await _repo.setGhostMode(e.mode);
      final d = await _repo.buddyMap();
      emit(state.copyWith(
        savingGhost: false,
        buddies: d.buddies,
        ghostMode: d.ghostMode,
        ghostUntil: d.ghostUntil,
        clearGhostUntil: d.ghostUntil == null,
      ));
    } on AppError catch (err) {
      emit(state.copyWith(ghostMode: before, savingGhost: false, error: err.message));
    }
  }
}
