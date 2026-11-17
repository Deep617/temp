import 'package:equatable/equatable.dart';
import 'package:seshlly/core/errors/app_error.dart';
import 'package:seshlly/core/services/location_service.dart';

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
    this.matchedChatId,
    this.matchedMatchId,
    this.swipeError,
    this.lat,
    this.lng,
    this.radiusKm = 10.0,
    this.locationAccess = LocationAccess.unknown,
    // Constructor mein add karo:
    this.isBoostActive    = false,
    this.boostExpiresAt,
    this.superLikeSuccess = false,
    this.boostError,
    this.superLikeError,
    this.boostActivated   = false,
    this.tokensRemaining,
  });

  final DiscoverStatus status;
  final List<BuddyProfile> profiles;
  final int currentIndex;
  final bool hasMore;
  final String? selectedActivity;
  final String? selectedLevel;
  final AppError? error;

  final double?  lat;
  final double?  lng;
  final double   radiusKm;
  /// Whether Discover has the phone's position (banner when it doesn't).
  final LocationAccess locationAccess;

  /// Non-null when the most recent right-swipe resulted in a match.
  final String? matchedUserId;
  final String? matchedChatId;   // open the chat right after a match
  final String? matchedMatchId;
  final String? swipeError;      // e.g. "Daily swipe limit reached" (one-shot)

  final bool   isBoostActive;
  final DateTime? boostExpiresAt;
  final bool   superLikeSuccess;    // show animation
  final String? boostError;         // "No boosts left" etc
  final String? superLikeError;     // "Daily limit reached"
  final bool   boostActivated;      // one-shot: boost just turned on (snackbar)
  final int?   tokensRemaining;     // tokens left after boost (badge sync)

  /// Boost is active AND not yet expired.
  bool get isBoostLive =>
      isBoostActive &&
      boostExpiresAt != null &&
      boostExpiresAt!.isAfter(DateTime.now());

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
    bool clearFilters = false,
    AppError? error,
    bool clearError = false,
    bool clearMatch = false,
    String? matchedUserId,
    String? matchedChatId,
    String? matchedMatchId,
    String? swipeError,
    double? lat,
    double? lng,
    double? radiusKm,
    LocationAccess? locationAccess,
    // copyWith mein add karo:
    bool? isBoostActive,
    DateTime? boostExpiresAt,
    bool? superLikeSuccess,
    String? boostError,
    String? superLikeError,
    bool clearBoostError      = false,
    bool clearSuperLikeError  = false,
    bool clearSuperLikeSuccess = false,
    bool? boostActivated,
    int? tokensRemaining,
  }) => DiscoverState(
    status: status ?? this.status,
    profiles: profiles ?? this.profiles,
    currentIndex: currentIndex ?? this.currentIndex,
    hasMore: hasMore ?? this.hasMore,
    selectedActivity: clearFilters ? selectedActivity : selectedActivity ?? this.selectedActivity,
    selectedLevel: clearFilters ? selectedLevel : selectedLevel ?? this.selectedLevel,
    error: clearError ? null : error ?? this.error,
    matchedUserId: clearMatch ? null : matchedUserId ?? this.matchedUserId,
    matchedChatId: clearMatch ? null : matchedChatId ?? this.matchedChatId,
    matchedMatchId: clearMatch ? null : matchedMatchId ?? this.matchedMatchId,
    swipeError:    swipeError, // one-shot
    lat:      lat      ?? this.lat,
    lng:      lng      ?? this.lng,
    radiusKm: radiusKm ?? this.radiusKm,
    locationAccess: locationAccess ?? this.locationAccess,
    // copyWith body mein:
    isBoostActive:     isBoostActive     ?? this.isBoostActive,
    boostExpiresAt:    boostExpiresAt    ?? this.boostExpiresAt,
    superLikeSuccess:  clearSuperLikeSuccess ? false : superLikeSuccess ?? this.superLikeSuccess,
    boostError:        clearBoostError   ? null : boostError    ?? this.boostError,
    superLikeError:    clearSuperLikeError ? null : superLikeError ?? this.superLikeError,
    // one-shot flag: resets to false unless explicitly set
    boostActivated:    boostActivated ?? false,
    tokensRemaining:   tokensRemaining ?? this.tokensRemaining,
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
    matchedUserId, matchedChatId, matchedMatchId, swipeError,
    // props mein add karo:
    isBoostActive, boostExpiresAt, superLikeSuccess, boostError, superLikeError,
    boostActivated, tokensRemaining, lat, lng, radiusKm, locationAccess,
  ];
}
