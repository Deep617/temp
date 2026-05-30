import 'package:equatable/equatable.dart';
import 'package:new_arch/features/auth/data/models/upload_profile_request.dart';

abstract class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  List<Object?> get props => [];
}

class ProfileUpdated extends ProfileEvent {
  final UploadProfileRequest uploadProfileRequest;

  const ProfileUpdated({required this.uploadProfileRequest});

  @override
  List<Object?> get props => [uploadProfileRequest];
}
