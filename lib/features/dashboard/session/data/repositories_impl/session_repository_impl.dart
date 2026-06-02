import 'package:seshlly/core/errors/app_error.dart';
import 'package:seshlly/features/dashboard/session/data/datasource/session_remote_datasource.dart';
import 'package:seshlly/features/dashboard/session/data/repositories/session_repository.dart';
import 'package:seshlly/features/dashboard/session/data/response_ml/workout_session.dart';

import '../../../../../core/api/base_repository.dart';
import '../../../../../core/services/secure_storage_service.dart';

class SessionRepositoryImpl extends BaseRepository
    implements SessionRepository {
  final SessionRemoteDatasource remote;
  final SecureStorageService secureStorageService;

  SessionRepositoryImpl(
    this.secureStorageService,
    this.remote,
    super.connectivity,
  );

  @override
  Future<List<WorkoutSession>> getSessions({String? status, int page = 1}) {
    try {
      return remote.getMySessions(status: status, page: page);
    } catch (e) {
      throw AppError.fromException(e);
    }
  }

  @override
  Future<WorkoutSession> scheduleSession({
    required String buddyId,
    required String activity,
    required DateTime scheduledAt,
    String? gymName,
  }) {
    try {
      return remote.scheduleSession(
        buddyId: buddyId,
        activity: activity,
        scheduledAt: scheduledAt,
        gymName: gymName,
      );
    } catch (e) {
      throw AppError.fromException(e);
    }
  }

  @override
  Future<WorkoutSession> uploadProof({
    required String sessionId,
    required String imagePath,
  }) {
    try {
      return remote.uploadProof(sessionId: sessionId, imagePath: imagePath);
    } catch (e) {
      throw AppError.fromException(e);
    }
  }
}
