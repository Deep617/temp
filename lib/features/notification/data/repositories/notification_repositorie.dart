// ── NotificationRepository ────────────────────────────────
import '../response_ml/app_notification.dart';

abstract class NotificationRepository {
  NotificationRepository( ) ;

  Future<List<AppNotification>> getNotifications({int page = 1});

  Future<void> markRead(String id);

  Future<void> markAllRead();
}