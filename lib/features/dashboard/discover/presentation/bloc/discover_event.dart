import 'package:equatable/equatable.dart';

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
    this.radiusKm = 5.0,
  });

  final String? activity;
  final String? level;
  final double? lat;
  final double? lng;
  final double radiusKm;

  @override
  List<Object?> get props => [activity, level, lat, lng, radiusKm];
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
