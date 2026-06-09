import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:seshlly/features/dashboard/profile/presentation/bloc/profile_event.dart';
import 'package:seshlly/features/dashboard/profile/presentation/bloc/profile_state.dart';

import '../../../../../core/errors/app_error.dart';
import '../../../../../core/services/secure_storage_service.dart';
import '../../domain/usecases/update_profile_usecase.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final UpdateProfileUseCase updateProfileUseCase;
  final UpdateProfileAvatarUseCase updateProfileAvatarUseCase;
  final GetBuddyProfileUseCase getBuddyProfileUseCase;
  final OnloadProfileUseCase _onloadProfileUseCase;


  ProfileBloc(
    this.updateProfileUseCase,
    this.updateProfileAvatarUseCase,
    this.getBuddyProfileUseCase,
    this._onloadProfileUseCase,
  ) : super(const ProfileState()) {
    on<ProfileLoaded>(_onLoaded);
    on<ProfileUpdated>(_onProfileUpdated);
    on<BuddyProfileLoaded>(_onBuddyLoaded);
  }

  Future<void> _onLoaded(
    ProfileLoaded event,
    Emitter<ProfileState> emit,
  ) async {
    emit(state.copyWith(status: ProfileStatus.loading, clearError: true));
    try {
      final user = await _onloadProfileUseCase.getMe();
      emit(state.copyWith(status: ProfileStatus.success, user: user));
    } on AppError catch (e) {
      emit(state.copyWith(status: ProfileStatus.failure, error: e));
    }
  }

  Future<void> _onProfileUpdated(
    ProfileUpdated event,
    Emitter<ProfileState> emit,
  ) async {
    emit(state.copyWith(status: ProfileStatus.updating, clearError: true));
    try {
      String? avatarUrl;
      if (event.avatarPath != null) {
        avatarUrl = await updateProfileAvatarUseCase.uploadAvatar(
          event.avatarPath!,
        );
      }
      final user = await updateProfileUseCase.updateProfile(
        data: {...event.data, if (avatarUrl != null) 'avatarUrl': avatarUrl},
      );
      emit(state.copyWith(status: ProfileStatus.updated, user: user));
    } on AppError catch (e) {
      emit(state.copyWith(status: ProfileStatus.failure, error: e));
    }
  }

  Future<void> _onBuddyLoaded(
    BuddyProfileLoaded event,
    Emitter<ProfileState> emit,
  ) async {
    emit(state.copyWith(status: ProfileStatus.loading, clearError: true));
    try {
      final profile = await getBuddyProfileUseCase.getBuddyProfile(
        event.userId,
      );
      emit(
        state.copyWith(status: ProfileStatus.success, buddyProfile: profile),
      );
    } on AppError catch (e) {
      emit(state.copyWith(status: ProfileStatus.failure, error: e));
    }
  }
}
