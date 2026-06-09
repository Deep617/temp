import 'package:equatable/equatable.dart';

import '../../../../auth/data/request_ml/upload_profile_request.dart';

abstract class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  List<Object?> get props => [];
}
class ProfileLoaded extends ProfileEvent {
  const ProfileLoaded();
}

class ProfileUpdated extends ProfileEvent {
  const ProfileUpdated({required this.data, this.avatarPath});
  final Map<String, dynamic> data;
  final String?              avatarPath;
  @override
  List<Object?> get props => [data, avatarPath];
}

class BuddyProfileLoaded extends ProfileEvent {
  const BuddyProfileLoaded({required this.userId});
  final String userId;
  @override
  List<Object?> get props => [userId];
}
