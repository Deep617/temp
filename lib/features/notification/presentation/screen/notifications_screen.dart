import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/common/common_widgets.dart';
import '../../data/response_ml/app_notification.dart';
import '../bloc/notification_bloc.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<NotificationBloc>().add(const NotificationsLoaded());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        title: Text('Notifications', style: AppTextStyles.h3()),
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary), onPressed: () => context.pop()),
        actions: [
          BlocBuilder<NotificationBloc, NotificationState>(
            builder: (context, state) {
              if (!state.hasUnread) return const SizedBox.shrink();
              return TextButton(
                onPressed: () => context.read<NotificationBloc>().add(const NotificationAllMarkedRead()),
                child: Text('Mark all read', style: AppTextStyles.bodySM(color: AppColors.primary).copyWith(fontWeight: FontWeight.w700)),
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<NotificationBloc, NotificationState>(
        builder: (context, state) {
          if (state.isLoading) {
            return ListView.builder(
              itemCount: 6,
              itemBuilder: (_, i) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(children: [const SkeletonAvatar(size: 44), const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [SkeletonBox(width: 160, height: 13, radius: 6), SizedBox(height: 6), SizedBox(width: double.infinity, height: 11, child: SkeletonBox(width: double.infinity, height: 11, radius: 4))]))]),
              ),
            );
          }

          if (state.notifications.isEmpty) {
            return const EmptyState(emoji: '🔔', title: 'No notifications yet', subtitle: 'Match alerts, session reminders, and XP updates appear here.');
          }

          final today     = DateTime.now();
          final todayList = state.notifications.where((n) => _isToday(n.createdAt, today)).toList();
          final olderList = state.notifications.where((n) => !_isToday(n.createdAt, today)).toList();

          return RefreshIndicator(
            color: AppColors.primary, backgroundColor: AppColors.surface2,
            onRefresh: () async => context.read<NotificationBloc>().add(const NotificationsLoaded()),
            child: ListView(children: [
              if (todayList.isNotEmpty) ...[
                _GroupHeader(label: 'Today'),
                ...todayList.asMap().entries.map((e) => _NotifTile(notif: e.value,
                    onRead: () => context.read<NotificationBloc>().add(NotificationMarkedRead(id: e.value.id)))
                    .animate(delay: Duration(milliseconds: e.key * 60)).fadeIn().slideX(begin: -0.1)),
              ],
              if (olderList.isNotEmpty) ...[
                _GroupHeader(label: 'Earlier'),
                ...olderList.asMap().entries.map((e) => _NotifTile(notif: e.value,
                    onRead: () => context.read<NotificationBloc>().add(NotificationMarkedRead(id: e.value.id)))
                    .animate(delay: Duration(milliseconds: e.key * 40)).fadeIn()),
              ],
              const SizedBox(height: 40),
            ]),
          );
        },
      ),
    );
  }

  bool _isToday(DateTime dt, DateTime now) => dt.year == now.year && dt.month == now.month && dt.day == now.day;
}

class _GroupHeader extends StatelessWidget {
  const _GroupHeader({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
    child: Text(label.toUpperCase(), style: AppTextStyles.label()),
  );
}

class _NotifTile extends StatelessWidget {
  const _NotifTile({required this.notif, required this.onRead});
  final AppNotification notif;
  final VoidCallback    onRead;

  Color get _accentColor {
    switch (notif.type) {
      case 'match': return AppColors.primary; case 'session': return AppColors.teal;
      case 'proof': return AppColors.warning;  case 'token':   return AppColors.orange;
      case 'xp':    return AppColors.gold;     case 'payment': return AppColors.blue;
      case 'subscription': return AppColors.purple;
      default: return AppColors.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) => Dismissible(
    key: Key(notif.id),
    direction: DismissDirection.endToStart,
    background: Container(alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20), color: AppColors.error.withOpacity(0.15), child: const Icon(Icons.delete_outline, color: AppColors.error)),
    onDismissed: (_) => onRead(),
    child: GestureDetector(
      onTap: notif.isRead ? null : onRead,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        color: notif.isRead ? Colors.transparent : _accentColor.withOpacity(0.04),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(width: 44, height: 44,
              decoration: BoxDecoration(color: _accentColor.withOpacity(0.12), borderRadius: BorderRadius.circular(12), border: Border.all(color: _accentColor.withOpacity(0.25))),
              child: Center(child: Text(notif.icon, style: const TextStyle(fontSize: 20)))),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: Text(notif.title, style: AppTextStyles.subtitle(color: notif.isRead ? AppColors.textSecondary : AppColors.textPrimary))),
                const SizedBox(width: 8),
                Text(timeago.format(notif.createdAt, locale: 'en_short'), style: AppTextStyles.caption(color: notif.isRead ? AppColors.textDim : _accentColor)),
              ]),
              const SizedBox(height: 3),
              Text(notif.message, style: AppTextStyles.bodySM(color: notif.isRead ? AppColors.textMuted : AppColors.textSecondary), maxLines: 2, overflow: TextOverflow.ellipsis),
            ])),
            if (!notif.isRead) Padding(padding: const EdgeInsets.only(left: 8, top: 4),
                child: Container(width: 7, height: 7, decoration: BoxDecoration(color: _accentColor, shape: BoxShape.circle, boxShadow: [BoxShadow(color: _accentColor.withOpacity(0.4), blurRadius: 6)]))),
          ]),
        ),
      ),
    ),
  );
}
