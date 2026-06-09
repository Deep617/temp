import 'package:equatable/equatable.dart';

import '../../../../../core/errors/app_error.dart';
import '../../../../auth/data/response_ml/register_response.dart';
import '../../../discover/data/response_ml/buddy_profile.dart';

enum ProfileStatus { initial, loading, success, updating, updated, failure }

class ProfileState extends Equatable {
  const ProfileState({
    this.status      = ProfileStatus.initial,
    this.user,
    this.buddyProfile,
    this.error,
  });

  final ProfileStatus  status;
  final User?     user;
  final BuddyProfile?  buddyProfile;
  final AppError?      error;

  bool get isInitial  => status == ProfileStatus.initial;
  bool get isLoading  => status == ProfileStatus.loading;
  bool get isUpdating => status == ProfileStatus.updating;
  bool get isUpdated  => status == ProfileStatus.updated;
  bool get isFailure  => status == ProfileStatus.failure;

  ProfileState copyWith({
    ProfileStatus? status,
    User?     user,
    BuddyProfile?  buddyProfile,
    AppError?      error,
    bool           clearError = false,
  }) =>
      ProfileState(
        status:       status       ?? this.status,
        user:         user         ?? this.user,
        buddyProfile: buddyProfile ?? this.buddyProfile,
        error:        clearError ? null : error ?? this.error,
      );

  @override
  List<Object?> get props => [status, user, buddyProfile, error];
}
