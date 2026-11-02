import '../../../../core/api/base_repository.dart';
import '../../../../core/errors/app_error.dart';
import '../datasource/safety_remote_datasource.dart';
import '../repositories/safety_repository.dart';

class SafetyRepositoryImpl extends BaseRepository implements SafetyRepository {
  SafetyRepositoryImpl(this.remote, super.connectivity);
  final SafetyRemoteDatasource remote;

  @override
  Future<void> block(String userId) =>
      remote.block(userId).catchError((e) => throw AppError.fromException(e));

  @override
  Future<void> unblock(String userId) =>
      remote.unblock(userId).catchError((e) => throw AppError.fromException(e));

  @override
  Future<List<BlockedUser>> getBlocked() =>
      remote.getBlocked().catchError((e) => throw AppError.fromException(e));

  @override
  Future<void> report({
    required String userId,
    required String reason,
    String? details,
    String? context,
    bool alsoBlock = true,
  }) =>
      remote
          .report(
            userId: userId,
            reason: reason,
            details: details,
            context: context,
            alsoBlock: alsoBlock,
          )
          .catchError((e) => throw AppError.fromException(e));
}
