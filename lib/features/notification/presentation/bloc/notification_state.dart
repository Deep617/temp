part of 'notification_bloc.dart';

enum NotificationStatus { initial, loading, success, failure }

class NotificationState extends Equatable {
  const NotificationState({
    this.status        = NotificationStatus.initial,
    this.notifications = const [],
    this.error,
  });

  final NotificationStatus       status;
  final List<AppNotification>    notifications;
  final AppError?                error;

  int get unreadCount => notifications.where((n) => !n.isRead).length;
  bool get hasUnread  => unreadCount > 0;
  bool get isLoading  => status == NotificationStatus.loading;

  NotificationState copyWith({
    NotificationStatus?     status,
    List<AppNotification>?  notifications,
    AppError?               error,
    bool                    clearError = false,
  }) =>
      NotificationState(
        status:        status        ?? this.status,
        notifications: notifications ?? this.notifications,
        error:         clearError ? null : error ?? this.error,
      );

  @override
  List<Object?> get props => [status, notifications, error];
}
