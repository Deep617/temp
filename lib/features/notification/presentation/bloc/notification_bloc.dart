import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/errors/app_error.dart';
import '../../data/repositories/notification_repositorie.dart';
import '../../data/response_ml/app_notification.dart';

part 'notification_event.dart';
part 'notification_state.dart';

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  NotificationBloc({required NotificationRepository notificationRepository})
      : _repo = notificationRepository,
        super(const NotificationState()) {
    on<NotificationsLoaded>    (_onLoaded);
    on<NotificationMarkedRead> (_onMarkedRead);
    on<NotificationAllMarkedRead>(_onAllMarkedRead);
  }

  final NotificationRepository _repo;

  Future<void> _onLoaded(
    NotificationsLoaded event,
    Emitter<NotificationState> emit,
  ) async {
    emit(state.copyWith(status: NotificationStatus.loading, clearError: true));
    try {
      final notifications = await _repo.getNotifications();
      emit(state.copyWith(
        status:        NotificationStatus.success,
        notifications: notifications,
      ));
    } on AppError catch (e) {
      emit(state.copyWith(status: NotificationStatus.failure, error: e));
    }
  }

  Future<void> _onMarkedRead(
    NotificationMarkedRead event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      await _repo.markRead(event.id);
      final updated = state.notifications
          .map((n) => n.id == event.id
              ? AppNotification(
                  id:        n.id,
                  type:      n.type,
                  title:     n.title,
                  message:   n.message,
                  isRead:    true,
                  actionUrl: n.actionUrl,
                  data:      n.data,
                  createdAt: n.createdAt,
                )
              : n)
          .toList();
      emit(state.copyWith(notifications: updated));
    } on AppError catch (e) {
      emit(state.copyWith(error: e));
    }
  }

  Future<void> _onAllMarkedRead(
    NotificationAllMarkedRead event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      await _repo.markAllRead();
      final updated = state.notifications
          .map((n) => AppNotification(
                id:        n.id,
                type:      n.type,
                title:     n.title,
                message:   n.message,
                isRead:    true,
                actionUrl: n.actionUrl,
                data:      n.data,
                createdAt: n.createdAt,
              ))
          .toList();
      emit(state.copyWith(notifications: updated));
    } on AppError catch (e) {
      emit(state.copyWith(error: e));
    }
  }
}
