import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:seshlly/routes/app_router.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/widgets/common/common_widgets.dart';
import '../../../../../core/widgets/error_widget.dart';
import '../../data/response_ml/workout_session.dart';
import '../bloc/session_bloc.dart';
import '../bloc/session_event.dart';
import '../bloc/session_state.dart';

class SessionsScreen extends StatefulWidget {
  const SessionsScreen({super.key});

  @override
  State<SessionsScreen> createState() => _SessionsScreenState();
}

class _SessionsScreenState extends State<SessionsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        title: Text('Sessions', style: AppTextStyles.h3()),
        bottom: TabBar(
          controller: _tabs,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textMuted,
          indicatorColor: AppColors.primary,
          indicatorSize: TabBarIndicatorSize.tab,
          labelStyle: AppTextStyles.label(color: AppColors.primary),
          tabs: const [
            Tab(text: 'UPCOMING'),
            Tab(text: 'COMPLETED'),
            Tab(text: 'MISSED'),
          ],
          onTap: (i) {
            // Reload sessions filtered by tab
            final statuses = ['scheduled', 'completed', 'missed'];
            context.read<SessionBloc>().add(
              SessionsLoaded(status: statuses[i]),
            );
          },
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.add, color: Colors.black, size: 18),
            ),
            onPressed: () => context.push(AppRoutes.scheduleSession),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabs,
        physics: const NeverScrollableScrollPhysics(),
        children: const [
          _SessionList(status: 'scheduled'),
          _SessionList(status: 'completed'),
          _SessionList(status: 'missed'),
        ],
      ),
    );
  }
}

class _SessionList extends StatelessWidget {
  const _SessionList({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SessionBloc, SessionState>(
      listener: (context, state) {
        if (state.status == SessionStatus.scheduled) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Session scheduled! 💪',
                style: AppTextStyles.body(),
              ),
            ),
          );
        }
        if (state.status == SessionStatus.uploaded) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Proof uploaded! +50 XP ✅',
                style: AppTextStyles.body(),
              ),
            ),
          );
        }
        if (state.status == SessionStatus.failure && state.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                state.error!.message,
                style: AppTextStyles.bodySM(color: AppColors.error),
              ),
            ),
          );
        }
      },
      builder: (context, state) {
        if (state.isLoading) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        // Error View with action
        if (state.status == SessionStatus.failure) {
          ErrorView(
            message: state.error!.message,
            apiFailure: state.error!,
            onRetry: () {
              context.read<SessionBloc>().add(const SessionsLoaded());
            },
          );
        }

        final filtered = state.sessions
            .where((s) => s.status == status)
            .toList();

        if (filtered.isEmpty) {
          return EmptyState(
            emoji: status == 'scheduled'
                ? '📅'
                : status == 'completed'
                ? '🏆'
                : '😔',
            title: status == 'scheduled'
                ? 'No upcoming sessions'
                : status == 'completed'
                ? 'No completed sessions'
                : 'No missed sessions',
            action: status == 'scheduled' ? 'Schedule Session' : null,
            onAction: status == 'scheduled'
                ? () => context.push(AppRoutes.scheduleSession)
                : null,
          );
        }

        return RefreshIndicator(
          color: AppColors.primary,
          backgroundColor: AppColors.surface2,
          onRefresh: () async =>
              context.read<SessionBloc>().add(SessionsLoaded(status: status)),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filtered.length,
            itemBuilder: (_, i) => _SessionCard(session: filtered[i])
                .animate(delay: Duration(milliseconds: i * 80))
                .fadeIn()
                .slideY(begin: 0.2),
          ),
        );
      },
    );
  }
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({required this.session});

  final WorkoutSession session;

  Color get _statusColor {
    switch (session.status) {
      case 'completed':
        return AppColors.teal;
      case 'missed':
        return AppColors.error;
      case 'cancelled':
        return AppColors.textMuted;
      default:
        return AppColors.primary;
    }
  }

  String get _statusEmoji {
    switch (session.status) {
      case 'completed':
        return '✅';
      case 'missed':
        return '❌';
      case 'cancelled':
        return '🚫';
      default:
        return '⏰';
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('EEE, dd MMM · hh:mm a');
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface1,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: session.needsProof
              ? AppColors.warning.withOpacity(0.4)
              : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                session.needsProof ? '⚠️' : _statusEmoji,
                style: const TextStyle(fontSize: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.activity.replaceFirst(
                        session.activity[0],
                        session.activity[0].toUpperCase(),
                      ),
                      style: AppTextStyles.subtitle(),
                    ),
                    Text(
                      fmt.format(session.scheduledAt),
                      style: AppTextStyles.bodySM(),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(color: _statusColor.withOpacity(0.3)),
                ),
                child: Text(
                  session.status.toUpperCase(),
                  style: AppTextStyles.label(color: _statusColor),
                ),
              ),
            ],
          ),
          if (session.buddyName != null) ...[
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(
                  Icons.people_outline,
                  size: 15,
                  color: AppColors.textMuted,
                ),
                const SizedBox(width: 6),
                Text(
                  'With ${session.buddyName}',
                  style: AppTextStyles.bodySM(),
                ),
                if (session.gymName != null) ...[
                  const SizedBox(width: 12),
                  const Icon(
                    Icons.location_on_outlined,
                    size: 15,
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(width: 4),
                  Text(session.gymName!, style: AppTextStyles.bodySM()),
                ],
              ],
            ),
          ],
          if (session.xpEarned != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.star, color: AppColors.warning, size: 15),
                const SizedBox(width: 4),
                Text(
                  '+${session.xpEarned} XP earned',
                  style: AppTextStyles.bodySM(
                    color: AppColors.warning,
                  ).copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ],
          if (session.needsProof) ...[
            const SizedBox(height: 14),
            GestureDetector(
              onTap: () => context.push(
                AppRoutes.uploadProof.replaceAll(':sessionId', session.id),
              ),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.warning.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Text('📸', style: TextStyle(fontSize: 20)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Upload Proof',
                            style: AppTextStyles.subtitle(
                              color: AppColors.warning,
                            ),
                          ),
                          Text(
                            'Missing proof will deduct chat tokens!',
                            style: AppTextStyles.bodySM(),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: AppColors.warning),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
