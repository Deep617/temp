import 'package:equatable/equatable.dart';
import 'package:seshlly/core/services/location_service.dart';

abstract class DiscoverEvent extends Equatable {
  const DiscoverEvent();

  @override
  List<Object?> get props => [];
}

class DiscoverProfilesLoaded extends DiscoverEvent {
  const DiscoverProfilesLoaded({this.refresh = false});

  final bool refresh;

  @override
  List<Object?> get props => [refresh];
}

class DiscoverSwipedRight extends DiscoverEvent {
  const DiscoverSwipedRight({required this.userId});

  final String userId;

  @override
  List<Object?> get props => [userId];
}

class DiscoverSwipedLeft extends DiscoverEvent {
  const DiscoverSwipedLeft({required this.userId});

  final String userId;

  @override
  List<Object?> get props => [userId];
}

class DiscoverFilterChanged extends DiscoverEvent {
  const DiscoverFilterChanged({
    this.activity,
    this.level,
    this.lat,
    this.lng,
    this.radiusKm = 10.0,
  });

  final String? activity;
  final String? level;
  final double? lat;
  final double? lng;
  final double radiusKm;

  @override
  List<Object?> get props => [activity, level, lat, lng, radiusKm];
}

/// The phone's position is known → search within 10 km of it.
class DiscoverLocationUpdated extends DiscoverEvent {
  const DiscoverLocationUpdated({required this.lat, required this.lng});

  final double lat;
  final double lng;

  @override
  List<Object?> get props => [lat, lng];
}

/// No position (permission denied, location off…) → the screen shows a
/// "Turn on location" banner.
class DiscoverLocationUnavailable extends DiscoverEvent {
  const DiscoverLocationUnavailable(this.access);

  final LocationAccess access;

  @override
  List<Object?> get props => [access];
}

// Referral events — new file ya existing events file mein add karo
class ReferralCodeRequested extends DiscoverEvent {
  const ReferralCodeRequested();
}

class ReferralCodeApplied extends DiscoverEvent {
  const ReferralCodeApplied({required this.code});

  final String code;

  @override
  List<Object?> get props => [code];
}
class DiscoverSuperLiked extends DiscoverEvent {
  const DiscoverSuperLiked({required this.userId});
  final String userId;
  @override
  List<Object?> get props => [userId];
}

class DiscoverBoosted extends DiscoverEvent {
  const DiscoverBoosted();
}

/// Loads current boost state from GET /match/boost/status
/// (so the ⚡ button is correct after app restart).
class DiscoverBoostStatusRequested extends DiscoverEvent {
  const DiscoverBoostStatusRequested();
}