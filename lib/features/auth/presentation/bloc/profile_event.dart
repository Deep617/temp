import 'package:equatable/equatable.dart';

import '../../data/request_ml/upload_profile_request.dart';

abstract class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  List<Object?> get props => [];
}
class ProfileLoaded extends ProfileEvent {
  const ProfileLoaded();
}

class ProfileUpdated extends ProfileEvent {
  final UploadProfileRequest uploadProfileRequest;

  const ProfileUpdated({required this.uploadProfileRequest});

  @override
  List<Object?> get props => [uploadProfileRequest];
}
