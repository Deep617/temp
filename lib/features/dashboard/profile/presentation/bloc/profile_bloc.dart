import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:seshlly/features/dashboard/profile/presentation/bloc/profile_event.dart';
import 'package:seshlly/features/dashboard/profile/presentation/bloc/profile_state.dart';

import '../../../../../core/api/base_state.dart';
import '../../../../../core/errors/app_error.dart';
import '../../../../../core/errors/failure.dart';
import '../../../../../core/services/secure_storage_service.dart';
import '../../../../auth/data/response_ml/register_response.dart';
import '../../domain/usecases/update_profile_usecase.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final UpdateProfileUseCase updateProfileUseCase;
  final OnloadProfileUseCase _onloadProfileUseCase;
  final SecureStorageService _storageService;

  ProfileBloc(
    this._storageService,
    this.updateProfileUseCase,
    this._onloadProfileUseCase,
  ) : super(const ProfileState()) {
    on<ProfileLoaded>(_onLoaded);
    on<ProfileUpdated>(_onProfileUpdated);
  }

  Future<void> _onLoaded(
    ProfileLoaded event,
    Emitter<ProfileState> emit,
  ) async {
    emit(state.copyWith(status: ApiStatus.loading, clearError: true));
    try {
      final User updateProfileResponse = await _onloadProfileUseCase
          .getMe();

     /* if (kDebugMode) {
        print("Token on login: ${(updateProfileResponse.accessToken)}");
      }*/

      emit(
        state.copyWith(
          status: ApiStatus.success,
          updateProfileResponse: updateProfileResponse,
        ),
      );
    } on AppError catch (e) {
      final apiFailure = ApiFailure(
        code: e.statusCode,
        message: e.message,
        data: e.toString(),
      );
      emit(state.copyWith(status: ApiStatus.failure, error: apiFailure));
    }
  }

  Future<void> _onProfileUpdated(
    ProfileUpdated event,
    Emitter<ProfileState> emit,
  ) async {
    emit(state.copyWith(status: ApiStatus.loading, clearError: true));
    try {
      final RegisterResponse updateProfileResponse = await updateProfileUseCase
          .updateProfilePerform(lgnRequest: event.uploadProfileRequest);

      if (kDebugMode) {
        print("Token on login: ${(updateProfileResponse.accessToken)}");
      }

      emit(
        state.copyWith(
          status: ApiStatus.success,
          updateProfileResponse: updateProfileResponse.user,
        ),
      );
    } on AppError catch (e) {
      final apiFailure = ApiFailure(
        code: e.statusCode,
        message: e.message,
        data: e.toString(),
      );
      emit(state.copyWith(status: ApiStatus.failure, error: apiFailure));
    }
  }
}
