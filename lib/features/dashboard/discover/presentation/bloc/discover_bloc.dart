import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:seshlly/core/errors/app_error.dart';

import '../../data/repositories/discover_repository.dart';
import 'discover_event.dart';
import 'discover_state.dart';

class DiscoverBloc extends Bloc<DiscoverEvent, DiscoverState> {
  final DiscoverRepository _repo;
  int _page = 1;

  DiscoverBloc({required DiscoverRepository discoverRepository})
    : _repo = discoverRepository,
      super(const DiscoverState()) {
    on<DiscoverProfilesLoaded>(_onProfilesLoaded);
    on<DiscoverSwipedRight>(_onSwipedRight);
    on<DiscoverSwipedLeft>(_onSwipedLeft);
    on<DiscoverFilterChanged>(_onFilterChanged);
    // Constructor mein add karo (on<DiscoverFilterChanged> ke baad):
    on<DiscoverSuperLiked>(_onSuperLiked);
    on<DiscoverBoosted>(_onBoosted);
  }

  Future<void> _onProfilesLoaded(
    DiscoverProfilesLoaded event,
    Emitter<DiscoverState> emit,
  ) async {
    if (state.isLoading) return;
    if (event.refresh) {
      _page = 1;
      emit(
        state.copyWith(
          profiles: [],
          currentIndex: 0,
          hasMore: true,
          clearError: true,
          clearMatch: true,
        ),
      );
    }
    emit(state.copyWith(status: DiscoverStatus.loading, clearError: true));
    try {
      final profiles = await _repo.getProfiles(
        activity: state.selectedActivity,
        level: state.selectedLevel,
        lat:         state.lat,
        lng:         state.lng,
        maxDistance: state.radiusKm.clamp(1.0, 10.0), // hard cap 10km
        page: _page,
      );
      final merged = event.refresh
          ? profiles
          : [...state.profiles, ...profiles];
      emit(
        state.copyWith(
          status: DiscoverStatus.success,
          profiles: merged,
          hasMore: profiles.length >= 20,
        ),
      );
      _page++;
    } on AppError catch (e) {
      emit(state.copyWith(status: DiscoverStatus.failure, error: e));
    }
  }

  Future<void> _onSwipedRight(
    DiscoverSwipedRight event,
    Emitter<DiscoverState> emit,
  ) async {
    // Advance card immediately so UI is responsive
    _advance(emit);
    try {
      final matched = await _repo.swipeRight(event.userId);
      if (matched) {
        emit(state.copyWith(matchedUserId: event.userId));
      }
    } on AppError {
      // Swipe failure is silent — card already advanced
    }
  }

  Future<void> _onSwipedLeft(
    DiscoverSwipedLeft event,
    Emitter<DiscoverState> emit,
  ) async {
    _advance(emit);
    try {
      await _repo.swipeLeft(event.userId);
    } on AppError {
      // Silent
    }
  }

  void _onFilterChanged(
    DiscoverFilterChanged event,
    Emitter<DiscoverState> emit,
  ) {
    emit(
      state.copyWith(
        selectedActivity: event.activity,
        selectedLevel: event.level,
        lat:              event.lat,
        lng:              event.lng,
        radiusKm:         event.radiusKm.clamp(1.0, 10.0),
      ),
    );
    add(const DiscoverProfilesLoaded(refresh: true));
  }

  void _advance(Emitter<DiscoverState> emit) {
    final next = state.currentIndex + 1;
    emit(state.copyWith(currentIndex: next, clearMatch: true));
    // Pre-load when near the end
    if (next >= state.profiles.length - 3 && state.hasMore) {
      add(const DiscoverProfilesLoaded());
    }
  }

  // ── Super Like handler ──────────────────────────────────
  Future<void> _onSuperLiked(
      DiscoverSuperLiked event,
      Emitter<DiscoverState> emit,
      ) async {
    _advance(emit); // Advance card immediately
    try {
      await _repo.superLike(event.userId);
      emit(state.copyWith(superLikeSuccess: true));
      // Clear success after animation
      await Future.delayed(const Duration(seconds: 2));
      emit(state.copyWith(clearSuperLikeSuccess: true));
    } on AppError catch (e) {
      // Show error — daily limit ya insufficient plan
      emit(state.copyWith(superLikeError: e.message));
      await Future.delayed(const Duration(seconds: 3));
      emit(state.copyWith(clearSuperLikeError: true));
    }
  }

  // ── Boost handler ───────────────────────────────────────
  Future<void> _onBoosted(
      DiscoverBoosted event,
      Emitter<DiscoverState> emit,
      ) async {
    try {
      final result = await _repo.boost();
      final expiresAt = DateTime.parse(result['expiresAt'] as String);
      emit(state.copyWith(
        isBoostActive:  true,
        boostExpiresAt: expiresAt,
      ));
    } on AppError catch (e) {
      emit(state.copyWith(boostError: e.message));
      await Future.delayed(const Duration(seconds: 3));
      emit(state.copyWith(clearBoostError: true));
    }
  }
}
