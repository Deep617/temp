import '../../../discover/data/response_ml/buddy_profile.dart';
import '../response_ml/workout_session.dart';

abstract class SessionRepository {
  SessionRepository();

  Future<List<WorkoutSession>> getSessions({String? status, int page = 1});

  Future<WorkoutSession> scheduleSession({
    required List<String> buddyIds, // [] = solo, [id] = buddy, [id,id] = group
    required String activity,
    required DateTime scheduledAt,
    required int durationMins, // 45 | 60 | 90 | 120
    String? gymName,
    String? challengeId,
  });

  Future<WorkoutSession> uploadProof({
    required String sessionId,
    required String imagePath,
  });

  @override
  Future<List<BuddyProfile>> getMyBuddies({int page = 1});


  @override
  Future<void>  respondToSessionInvite(String sessionId, String action) ;
}
