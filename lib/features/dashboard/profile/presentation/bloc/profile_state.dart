
import '../../../../../core/api/base_state.dart';
import '../../../../../core/errors/failure.dart';
import '../../../../auth/data/response_ml/register_response.dart';

class ProfileState extends BaseState {
  final RegisterResponse? updateProfileResponse;

  const ProfileState({super.status, super.error, this.updateProfileResponse});

  ProfileState copyWith({
    ApiStatus? status,
    ApiFailure? error,
    RegisterResponse? updateProfileResponse,

    bool clearError = false,
    bool clearResponse = false,
  }) {
    return ProfileState(
      status: status ?? this.status,
      error: clearError ? null : error ?? this.error,
      updateProfileResponse: clearResponse
          ? null
          : updateProfileResponse ?? this.updateProfileResponse,
    );
  }

  @override
  List<Object?> get props => [...super.props, updateProfileResponse];
}
