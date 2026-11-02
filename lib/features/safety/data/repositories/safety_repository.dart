import '../datasource/safety_remote_datasource.dart';

abstract class SafetyRepository {
  Future<void> block(String userId);
  Future<void> unblock(String userId);
  Future<List<BlockedUser>> getBlocked();
  Future<void> report({
    required String userId,
    required String reason,
    String? details,
    String? context,
    bool alsoBlock = true,
  });
}
