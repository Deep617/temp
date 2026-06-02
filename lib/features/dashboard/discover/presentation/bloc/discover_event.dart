

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
  const DiscoverFilterChanged({this.activity, this.level});
  final String? activity;
  final String? level;
  @override
  List<Object?> get props => [activity, level];
}
