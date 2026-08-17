// ─────────────────────────────────────────────────────────
//  sessions_screen.dart
//
//  Fixes:
//  1. + button only visible if buddyCount > 0
//  2. Session card shows duration + start-end time range
//  3. incomplete/missed status handled properly
//  4. incompleteReason shown on card
//  5. inviteStatus shown (pending/confirmed/declined)
//  6. Group session label
//  7. Upload Proof button (within 3hr window)
// ─────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/widgets/common/common_widgets.dart';
import '../../../../../routes/app_router.dart';
import '../../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../session/data/response_ml/workout_session.dart';
import '../../../session/presentation/bloc/session_bloc.dart';
import '../../../session/presentation/bloc/session_event.dart';
import '../../../session/presentation/bloc/session_state.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SessionBloc>().add(
          const SessionsLoaded(status: 'scheduled'));
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Read buddyCount from AuthBloc to control + button visibility
    final user = context.select((AuthBloc b) => b.state.user);
    final hasBuddies = (user?.buddyCount ?? 0) > 0;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        title: Text('Sessions', style: AppTextStyles.h3()),
        bottom: TabBar(
          controller: _tabs,
          labelColor:            AppColors.primary,
          unselectedLabelColor:  AppColors.textMuted,
          indicatorColor:        AppColors.primary,
          indicatorSize:         TabBarIndicatorSize.tab,
          labelStyle: AppTextStyles.label(color: AppColors.primary),
          tabs: const [
            Tab(text: 'UPCOMING'),
            Tab(text: 'COMPLETED'),
            Tab(text: 'MISSED'),
          ],
          onTap: (i) {
            final statuses = ['scheduled', 'completed', 'missed'];
            context.read<SessionBloc>()
                .add(SessionsLoaded(status: statuses[i]));
          },
        ),
        actions: [
          // ── + button: only if user has buddies ────────
          if (hasBuddies)
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color:        AppColors.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.add,
                    color: Colors.white, size: 18),
              ),
              onPressed: () =>
                  context.push(AppRoutes.scheduleSession),
            )
          else
          // No buddies — tap to go to Discover
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color:        AppColors.surface2,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border2),
                ),
                child: const Icon(Icons.add,
                    color: AppColors.textMuted, size: 18),
              ),
              tooltip: 'Find a buddy first',
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text(
                        'Match with a buddy first to schedule sessions 🤝'),
                    backgroundColor: AppColors.warning,
                    behavior: SnackBarBehavior.floating,
                    action: SnackBarAction(
                      label:   'Discover',
                      textColor: Colors.white,
                      onPressed: () =>
                          context.go(AppRoutes.discover),
                    ),
                  ),
                );
              },
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

// ══════════════════════════════════════════════════════════
//  SESSION LIST
// ══════════════════════════════════════════════════════════
class _SessionList extends StatelessWidget {
  const _SessionList({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SessionBloc, SessionState>(
      listener: (context, state) {
        if (state.status == SessionStatus.uploaded) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Proof uploaded! +50 XP ✅',
                style: AppTextStyles.body()),
            backgroundColor: AppColors.teal,
            behavior: SnackBarBehavior.floating,
          ));
        }
        if (state.status == SessionStatus.failure &&
            state.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(state.error!.message,
                style: AppTextStyles.bodySM(
                    color: AppColors.error)),
            behavior: SnackBarBehavior.floating,
          ));
        }
      },
      builder: (context, state) {
        if (state.isLoading) {
          return const Center(
              child: CircularProgressIndicator(
                  color: AppColors.primary));
        }

        // Filter sessions by status
        // Also show 'scheduled' sessions that need proof in UPCOMING
        final filtered = state.sessions.where((s) {
          if (status == 'scheduled') {
            return s.status == 'scheduled';
          }
          return s.status == status;
        }).toList();

        // Sort: upcoming by scheduledAt asc, rest by desc
        filtered.sort((a, b) => status == 'scheduled'
            ? a.scheduledAt.compareTo(b.scheduledAt)
            : b.scheduledAt.compareTo(a.scheduledAt));

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
            subtitle: status == 'scheduled'
                ? 'Schedule a session with your buddy'
                : null,
            action:   status == 'scheduled' ? 'Schedule Session' : null,
            onAction: status == 'scheduled'
                ? () => context.push(AppRoutes.scheduleSession)
                : null,
          );
        }

        return RefreshIndicator(
          color:           AppColors.primary,
          backgroundColor: AppColors.surface2,
          onRefresh: () async => context.read<SessionBloc>()
              .add(SessionsLoaded(status: status)),
          child: ListView.builder(
            padding:    const EdgeInsets.all(16),
            itemCount:  filtered.length,
            itemBuilder: (_, i) => _SessionCard(
                session: filtered[i])
                .animate(
                delay: Duration(milliseconds: i * 80))
                .fadeIn()
                .slideY(begin: 0.2),
          ),
        );
      },
    );
  }
}

// ══════════════════════════════════════════════════════════
//  SESSION CARD
// ══════════════════════════════════════════════════════════
class _SessionCard extends StatelessWidget {
  const _SessionCard({required this.session});
  final WorkoutSession session;

  // Status colors
  Color get _statusColor {
    if (session.needsProof) return AppColors.warning;
    switch (session.status) {
      case 'completed': return AppColors.teal;
      case 'missed':    return AppColors.error;
      case 'cancelled': return AppColors.textMuted;
      default:          return AppColors.primary;
    }
  }

  String get _statusLabel {
    if (session.needsProof) return 'UPLOAD PROOF';
    switch (session.status) {
      case 'completed': return 'COMPLETED';
      case 'missed':    return 'MISSED';
      case 'cancelled': return 'CANCELLED';
      default:
      // Show invite status if pending
        if (session.isInvitePending)   return 'PENDING';
        if (session.isInviteDeclined)  return 'DECLINED';
        if (session.isInviteConfirmed) return 'CONFIRMED';
        return 'UPCOMING';
    }
  }

  String get _statusEmoji {
    if (session.needsProof)           return '📸';
    if (session.isInvitePending)      return '⏳';
    if (session.isInviteDeclined)     return '❌';
    switch (session.status) {
      case 'completed': return '✅';
      case 'missed':    return '😔';
      case 'cancelled': return '🚫';
      default:          return '⏰';
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('EEE, dd MMM');
    final timeFmt = DateFormat('h:mm a');

    final dateStr     = dateFmt.format(session.scheduledAt);
    final startStr    = timeFmt.format(session.scheduledAt);
    final endStr      = timeFmt.format(session.endTime);
    final timeRange   = '$startStr - $endStr';
    final isGroup     = session.isGroup;

    // Card border highlight
    final borderColor = session.needsProof
        ? AppColors.warning.withOpacity(0.4)
        : session.status == 'missed'
        ? AppColors.error.withOpacity(0.2)
        : session.isInviteDeclined
        ? AppColors.error.withOpacity(0.2)
        : AppColors.border;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color:        AppColors.surface1,
        borderRadius: BorderRadius.circular(16),
        border:       Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── Header ─────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Text(_statusEmoji,
                      style: const TextStyle(fontSize: 22)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Activity + Group label
                        Row(children: [
                          Text(
                            _capitalize(session.activity),
                            style: AppTextStyles.subtitle(),
                          ),
                          if (isGroup) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.teal
                                    .withOpacity(0.1),
                                borderRadius:
                                BorderRadius.circular(4),
                                border: Border.all(
                                    color: AppColors.teal
                                        .withOpacity(0.3)),
                              ),
                              child: Text('👥 Group',
                                  style: AppTextStyles.caption()
                                      .copyWith(
                                      color:
                                      AppColors.teal,
                                      fontWeight:
                                      FontWeight.w700)),
                            ),
                          ],
                        ]),
                        const SizedBox(height: 3),
                        // Date
                        Text(dateStr,
                            style: AppTextStyles.bodySM(
                                color:
                                AppColors.textSecondary)),
                        // Time range + duration
                        Text(
                          '$timeRange (${session.durationLabel})',
                          style: AppTextStyles.bodySM(
                              color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Status badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color:        _statusColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(
                          color: _statusColor.withOpacity(0.3)),
                    ),
                    child: Text(_statusLabel,
                        style: AppTextStyles.label(
                            color: _statusColor)),
                  ),
                ]),

                // ── Buddy / Gym row ───────────────────────
                if (session.buddyName != null ||
                    session.participants.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  const Divider(),
                  const SizedBox(height: 8),
                  Row(children: [
                    const Icon(Icons.people_outline,
                        size: 14,
                        color: AppColors.textMuted),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        isGroup
                            ? _groupNames()
                            : 'With ${session.buddyName}',
                        style: AppTextStyles.bodySM(),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (session.gymName != null) ...[
                      const SizedBox(width: 8),
                      const Icon(Icons.location_on_outlined,
                          size: 14,
                          color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(session.gymName!,
                            style: AppTextStyles.bodySM(),
                            overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ]),
                ],

                // ── Challenge link ───────────────────────
                if (session.challengeTitle != null) ...[
                  const SizedBox(height: 8),
                  Row(children: [
                    const Icon(Icons.bolt,
                        size: 14,
                        color: AppColors.warning),
                    const SizedBox(width: 5),
                    Text('${session.challengeTitle}',
                        style: AppTextStyles.bodySM(
                            color: AppColors.warning)),
                  ]),
                ],

                // ── XP earned ────────────────────────────
                if (session.xpEarned != null) ...[
                  const SizedBox(height: 8),
                  Row(children: [
                    const Icon(Icons.star,
                        color: AppColors.warning, size: 14),
                    const SizedBox(width: 4),
                    Text('+${session.xpEarned} XP earned',
                        style: AppTextStyles.bodySM(
                            color: AppColors.warning)
                            .copyWith(
                            fontWeight: FontWeight.w700)),
                  ]),
                ],

                // ── Invite pending: waiting message ───────
                if (session.isInvitePending &&
                    session.status == 'scheduled') ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color:
                          AppColors.warning.withOpacity(0.2)),
                    ),
                    child: Row(children: [
                      const Text('⏳',
                          style: TextStyle(fontSize: 14)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Waiting for buddy to confirm the session invite.',
                          style: AppTextStyles.bodySM(
                              color: AppColors.textMuted),
                        ),
                      ),
                    ]),
                  ),
                ],

                // ── Invite declined ───────────────────────
                if (session.isInviteDeclined) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color:
                          AppColors.error.withOpacity(0.2)),
                    ),
                    child: Row(children: [
                      const Text('😔',
                          style: TextStyle(fontSize: 14)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Buddy declined this session invite.',
                          style: AppTextStyles.bodySM(
                              color: AppColors.textMuted),
                        ),
                      ),
                    ]),
                  ),
                ],

                // ── Incomplete reason ─────────────────────
                if (session.isMissed &&
                    session.incompleteReason != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color:
                          AppColors.error.withOpacity(0.2)),
                    ),
                    child: Row(children: [
                      const Icon(Icons.info_outline,
                          size: 14,
                          color: AppColors.error),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          session.incompleteReason!,
                          style: AppTextStyles.bodySM(
                              color: AppColors.error),
                        ),
                      ),
                    ]),
                  ),
                ],
              ],
            ),
          ),

          // ── Upload Proof CTA (within 3hr window) ───────
          if (session.needsProof) ...[
            Container(
              margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: GestureDetector(
                onTap: () => context.push(
                    AppRoutes.uploadProof
                        .replaceAll(':sessionId', session.id)),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color:
                        AppColors.warning.withOpacity(0.4)),
                  ),
                  child: Row(children: [
                    const Text('📸',
                        style: TextStyle(fontSize: 20)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Text('Upload Proof',
                              style: AppTextStyles.subtitle(
                                  color: AppColors.warning)),
                          Text(
                            _proofWindowText(),
                            style: AppTextStyles.bodySM(
                                color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right,
                        color: AppColors.warning),
                  ]),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Proof window countdown
  String _proofWindowText() {
    final rem = session.proofWindowRemaining;
    if (rem.isNegative) return 'Window closed';
    final hrs  = rem.inHours;
    final mins = rem.inMinutes % 60;
    if (hrs > 0) return '${hrs}h ${mins}m remaining to upload';
    return '${mins}m remaining to upload';
  }

  // Group participant names
  String _groupNames() {
    if (session.participants.isEmpty) {
      return session.buddyName != null
          ? 'With ${session.buddyName}'
          : 'Group session';
    }
    final others = session.participants
        .map((p) => p.name.split(' ').first)
        .take(3)
        .join(', ');
    return 'With $others${session.participants.length > 3 ? ' +${session.participants.length - 3}' : ''}';
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1).toLowerCase();
}
