import 'package:seshlly/core/api/base_repository.dart';
import 'package:seshlly/features/notification/data/repositories/notification_repositorie.dart';
import 'package:seshlly/features/notification/data/response_ml/app_notification.dart';

import '../../../../core/errors/app_error.dart';
import '../datasource/notification_remote_datasource.dart';

class NotificationRepositoryImpl extends BaseRepository
    implements NotificationRepository {
  final NotificationRemoteDataSource remote;

  NotificationRepositoryImpl(super.connectivity, this.remote);

  @override
  Future<List<AppNotification>> getNotifications({int page = 1}) {
    return remote.getNotifications(page: page).catchError((e) {
      throw AppError.fromException(e);
    });
  }

  @override
  Future<void> markRead(String id) {
    return remote.markNotificationRead(id).catchError((e) {
      throw AppError.fromException(e);
    });
  }


  @override
  Future<void> markAllRead() {
    return remote.markAllNotificationsRead().catchError((e) {
      throw AppError.fromException(e);
    });
  }
}
