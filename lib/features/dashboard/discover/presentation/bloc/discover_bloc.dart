import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:seshlly/core/errors/app_error.dart';
import 'package:seshlly/core/services/location_service.dart';

import '../../data/repositories/discover_repository.dart';
import 'discover_event.dart';
import 'discover_state.dart';

class DiscoverBloc extends Bloc<DiscoverEvent, DiscoverState> {
  final DiscoverRepository _repo;
  int _page = 1;
  // A refresh asked for while a load runs (e.g. the position arrived during
  // the first load) runs right after it instead of being dropped.
  bool _refreshPending = false;

  DiscoverBloc({required DiscoverRepository discoverRepository})
    : _repo = discoverRepository,
      super(const DiscoverState()) {
    on<DiscoverProfilesLoaded>(_onProfilesLoaded);
    on<DiscoverSwipedRight>(_onSwipedRight);
    on<DiscoverSwipedLeft>(_onSwipedLeft);
    on<DiscoverFilterChanged>(_onFilterChanged);
    on<DiscoverLocationUpdated>(_onLocationUpdated);
    on<DiscoverLocationUnavailable>(_onLocationUnavailable);
    // Constructor mein add karo (on<DiscoverFilterChanged> ke baad):
    on<DiscoverSuperLiked>(_onSuperLiked);
    on<DiscoverBoosted>(_onBoosted);
    on<DiscoverBoostStatusRequested>(_onBoostStatusRequested);
  }

  Future<void> _onProfilesLoaded(
    DiscoverProfilesLoaded event,
    Emitter<DiscoverState> emit,
  ) async {
    if (state.isLoading) {
      if (event.refresh) _refreshPending = true;
      return;
    }
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
        // The server already leaves out everyone I swiped on, so page 1 is
        // always "the next unseen people". Asking for page 2, 3… skipped
        // real profiles and showed "You've seen everyone" too early.
        page: 1,
      );
      final seen = event.refresh ? <String>{} : state.profiles.map((p) => p.id).toSet();
      final fresh = profiles.where((p) => seen.add(p.id)).toList();
      final merged = event.refresh ? fresh : [...state.profiles, ...fresh];
      emit(
        state.copyWith(
          status: DiscoverStatus.success,
          profiles: merged,
          hasMore: fresh.isNotEmpty && profiles.length >= 20,
        ),
      );
      _page++;
    } on AppError catch (e) {
      emit(state.copyWith(status: DiscoverStatus.failure, error: e));
    }
    if (_refreshPending) {
      _refreshPending = false;
      add(const DiscoverProfilesLoaded(refresh: true));
    }
  }

  Future<void> _onSwipedRight(
    DiscoverSwipedRight event,
    Emitter<DiscoverState> emit,
  ) async {
    // Advance card immediately so UI is responsive
    _advance(emit);
    try {
      final res = await _repo.likeUser(event.userId);
      if (res['matched'] == true) {
        emit(state.copyWith(
          matchedUserId:  event.userId,
          matchedChatId:  res['chatId'] as String?,
          matchedMatchId: res['matchId'] as String?,
        ));
      }
    } on AppError catch (e) {
      // Tell the user (e.g. daily limit) instead of silently losing the like
      emit(state.copyWith(swipeError: e.message));
    }
  }

  Future<void> _onSwipedLeft(
    DiscoverSwipedLeft event,
    Emitter<DiscoverState> emit,
  ) async {
    _advance(emit);
    try {
      await _repo.swipeLeft(event.userId);
    } on AppError catch (e) {
      if (e.statusCode == 429) emit(state.copyWith(swipeError: e.message));
    }
  }

  void _onFilterChanged(
    DiscoverFilterChanged event,
    Emitter<DiscoverState> emit,
  ) {
    emit(
      state.copyWith(
        // null = "Clear All" → really clear (copyWith used to keep the old one)
        clearFilters:     true,
        selectedActivity: event.activity,
        selectedLevel:    event.level,
        lat:              event.lat,   // null keeps the phone's position
        lng:              event.lng,
        radiusKm:         event.radiusKm.clamp(1.0, 10.0),
      ),
    );
    add(const DiscoverProfilesLoaded(refresh: true));
  }

  void _onLocationUpdated(
    DiscoverLocationUpdated event,
    Emitter<DiscoverState> emit,
  ) {
    emit(state.copyWith(
      lat: event.lat,
      lng: event.lng,
      locationAccess: LocationAccess.granted,
    ));
    add(const DiscoverProfilesLoaded(refresh: true));
  }

  void _onLocationUnavailable(
    DiscoverLocationUnavailable event,
    Emitter<DiscoverState> emit,
  ) {
    emit(state.copyWith(locationAccess: event.access));
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
  // POST /match/swipe { targetId, action: 'super_like' }
  Future<void> _onSuperLiked(
      DiscoverSuperLiked event,
      Emitter<DiscoverState> emit,
      ) async {
    _advance(emit); // Advance card immediately
    try {
      final matched = await _repo.superLike(event.userId);
      emit(state.copyWith(
        superLikeSuccess: true,
        matchedUserId: matched ? event.userId : null,
      ));
      // Clear success after animation
      await Future.delayed(const Duration(seconds: 2));
      emit(state.copyWith(clearSuperLikeSuccess: true));
    } on AppError catch (e) {
      // Show error — daily limit / plan / tokens
      emit(state.copyWith(superLikeError: e.message));
      await Future.delayed(const Duration(seconds: 3));
      emit(state.copyWith(clearSuperLikeError: true));
    }
  }

  // ── Boost handler ───────────────────────────────────────
  // POST /match/boost → { boostExpiresAt, tokensRemaining, durationMinutes }
  Future<void> _onBoosted(
      DiscoverBoosted event,
      Emitter<DiscoverState> emit,
      ) async {
    try {
      final result = await _repo.boost();
      final expiresAt = DateTime.tryParse(
        result['boostExpiresAt']?.toString() ?? '',
      )?.toLocal();
      emit(state.copyWith(
        isBoostActive:   expiresAt != null,
        boostExpiresAt:  expiresAt,
        boostActivated:  expiresAt != null,
        tokensRemaining: (result['tokensRemaining'] as num?)?.toInt(),
      ));
    } on AppError catch (e) {
      emit(state.copyWith(boostError: e.message));
      await Future.delayed(const Duration(seconds: 3));
      emit(state.copyWith(clearBoostError: true));
    }
  }

  // ── Boost status (on screen open) ───────────────────────
  // GET /match/boost/status → { isActive, boostExpiresAt, remainingMinutes, tokens }
  Future<void> _onBoostStatusRequested(
      DiscoverBoostStatusRequested event,
      Emitter<DiscoverState> emit,
      ) async {
    try {
      final result = await _repo.boostStatus();
      final isActive = result['isActive'] == true;
      final expiresAt = DateTime.tryParse(
        result['boostExpiresAt']?.toString() ?? '',
      )?.toLocal();
      emit(state.copyWith(
        isBoostActive:  isActive && expiresAt != null,
        boostExpiresAt: expiresAt,
      ));
    } on AppError {
      // Silent — button just stays in default state
    }
  }
}
