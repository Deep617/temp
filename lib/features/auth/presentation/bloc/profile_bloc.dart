import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:seshlly/core/services/secure_storage_service.dart';
import 'package:seshlly/features/auth/domain/entities/register_response.dart';
import 'package:seshlly/features/auth/domain/usecases/update_profile_usecase.dart';
import 'package:seshlly/features/auth/presentation/bloc/profile_event.dart';
import 'package:seshlly/features/auth/presentation/bloc/profile_state.dart';

import '../../../../core/api/base_state.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/failure.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final UpdateProfileUseCase updateProfileUseCase;

  final SecureStorageService _storageService;


  ProfileBloc(this._storageService, this.updateProfileUseCase)
    : super(const ProfileState()) {
    on<ProfileUpdated>(_onProfileUpdated);
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
          updateProfileResponse: updateProfileResponse,
        ),
      );
    } on AppException catch (e) {
      final apiFailure = ApiFailure(
        code: e.statusCode,
        message: e.message,
        data: e.toString(),
      );
      emit(state.copyWith(status: ApiStatus.failure, error: apiFailure));
    }
  }
}
