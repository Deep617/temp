import 'package:equatable/equatable.dart';
import 'package:seshlly/core/errors/app_error.dart';

import '../../data/response_ml/buddy_profile.dart';

enum DiscoverStatus { initial, loading, success, failure }

class DiscoverState extends Equatable {
  const DiscoverState({
    this.status = DiscoverStatus.initial,
    this.profiles = const [],
    this.currentIndex = 0,
    this.hasMore = true,
    this.selectedActivity,
    this.selectedLevel,
    this.error,
    this.matchedUserId,
  });

  final DiscoverStatus status;
  final List<BuddyProfile> profiles;
  final int currentIndex;
  final bool hasMore;
  final String? selectedActivity;
  final String? selectedLevel;
  final AppError? error;

  /// Non-null when the most recent right-swipe resulted in a match.
  final String? matchedUserId;

  bool get isLoading => status == DiscoverStatus.loading;

  bool get isEmpty => status == DiscoverStatus.success && profiles.isEmpty;

  bool get isExhausted => currentIndex >= profiles.length;

  BuddyProfile? get currentProfile =>
      currentIndex < profiles.length ? profiles[currentIndex] : null;

  DiscoverState copyWith({
    DiscoverStatus? status,
    List<BuddyProfile>? profiles,
    int? currentIndex,
    bool? hasMore,
    String? selectedActivity,
    String? selectedLevel,
    AppError? error,
    bool clearError = false,
    bool clearMatch = false,
    String? matchedUserId,
  }) => DiscoverState(
    status: status ?? this.status,
    profiles: profiles ?? this.profiles,
    currentIndex: currentIndex ?? this.currentIndex,
    hasMore: hasMore ?? this.hasMore,
    selectedActivity: selectedActivity ?? this.selectedActivity,
    selectedLevel: selectedLevel ?? this.selectedLevel,
    error: clearError ? null : error ?? this.error,
    matchedUserId: clearMatch ? null : matchedUserId ?? this.matchedUserId,
  );

  @override
  List<Object?> get props => [
    status,
    profiles,
    currentIndex,
    hasMore,
    selectedActivity,
    selectedLevel,
    error,
    matchedUserId,
  ];
}
