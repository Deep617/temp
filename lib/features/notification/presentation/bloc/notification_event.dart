// ── notification_event.dart ───────────────────────────────
part of 'notification_bloc.dart';

abstract class NotificationEvent extends Equatable {
  const NotificationEvent();
  @override
  List<Object?> get props => [];
}

class NotificationsLoaded extends NotificationEvent {
  const NotificationsLoaded();
}

class NotificationMarkedRead extends NotificationEvent {
  const NotificationMarkedRead({required this.id});
  final String id;
  @override
  List<Object?> get props => [id];
}

class NotificationAllMarkedRead extends NotificationEvent {
  const NotificationAllMarkedRead();
}
