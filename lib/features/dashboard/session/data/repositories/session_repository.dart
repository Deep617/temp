import '../response_ml/workout_session.dart';

abstract class SessionRepository {
  SessionRepository();

  Future<List<WorkoutSession>> getSessions({String? status, int page = 1});

  Future<WorkoutSession> scheduleSession({
    required String buddyId,
    required String activity,
    required DateTime scheduledAt,
    String? gymName,
  });

  Future<WorkoutSession> uploadProof({
    required String sessionId,
    required String imagePath,
  });
}
