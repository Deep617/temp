// ─────────────────────────────────────────────────────────
//  chats_list_screen.dart
//  2 tabs: Chats | Requests
//  Requests tab: pending match requests with
//    View Profile / Accept / Decline actions
// ─────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/widgets/common/common_widgets.dart';
import '../../../../../di_injection/dependency_injection.dart';
import '../../../../../routes/app_router.dart';
import '../../../../auth/data/response_ml/register_response.dart';
import '../../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../../auth/presentation/bloc/auth_state.dart';
import '../bloc/chat_bloc.dart';
import '../bloc/match_request_bloc.dart';

class ChatsListScreen extends StatefulWidget {
  const ChatsListScreen({super.key});

  @override
  State<ChatsListScreen> createState() => _ChatsListScreenState();
}

class _ChatsListScreenState extends State<ChatsListScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    // Load match requests via BLoC
    context.read<MatchRequestBloc>().add(const MatchRequestsLoaded());
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
        title: Text('Messages', style: AppTextStyles.h3()),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: AppColors.textMuted),
            onPressed: () {},
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: AppColors.primary,
          indicatorWeight: 2,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textMuted,
          labelStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
          tabs: [
            const Tab(text: 'Chats'),
            Tab(
              child: BlocBuilder<MatchRequestBloc, MatchRequestState>(
                buildWhen: (p, c) => p.count != c.count,
                builder: (_, reqState) => Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Requests'),
                    if (reqState.count > 0) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(
                          '${reqState.count}',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.black,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      body: BlocListener<MatchRequestBloc, MatchRequestState>(
        // Navigate to chat after accept
        listenWhen: (p, c) =>
            c.acceptedMatchId != null && p.acceptedMatchId != c.acceptedMatchId,
        listener: (_, reqState) {
          if (reqState.acceptedMatchId != null &&
              reqState.acceptedUser != null) {
            context.push(
              AppRoutes.chat.replaceAll(':chatId', reqState.acceptedMatchId!),
              extra: {
                'buddyName': reqState.acceptedUser!.firstName,
                'buddyId': reqState.acceptedUser!.id,
                'buddyAvatar': reqState.acceptedUser!.avatarUrl,
                'matchId': reqState.acceptedMatchId,
              },
            );
          }
        },
        child: TabBarView(
          controller: _tabs,
          children: [
            _ChatsTab(),
            BlocBuilder<MatchRequestBloc, MatchRequestState>(
              builder: (_, reqState) => _RequestsTab(
                requests: reqState.requests,
                loading: reqState.status == MatchRequestStatus.loading,
                onRefresh: () => context.read<MatchRequestBloc>().add(
                  const MatchRequestsLoaded(),
                ),
                onAccept: (req) => context.read<MatchRequestBloc>().add(
                  MatchRequestAccepted(swipeId: req.swipeId, user: req.user),
                ),
                onDecline: (req) => context.read<MatchRequestBloc>().add(
                  MatchRequestDeclined(swipeId: req.swipeId),
                ),
                actingSwipeId: reqState.actingSwipeId,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── CHATS TAB ─────────────────────────────────────────────
class _ChatsTab extends StatefulWidget {
  @override
  State<_ChatsTab> createState() => _ChatsTabState();
}

class _ChatsTabState extends State<_ChatsTab> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Token warning
        BlocBuilder<AuthBloc, AuthState>(
          builder: (context, authState) {
            final user = authState.user;
            if (user == null || user.chatTokens >= 5) {
              return const SizedBox.shrink();
            }
            return Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.warning.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Text('🎫', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${user.chatTokens} tokens remaining',
                          style: AppTextStyles.subtitle(
                            color: AppColors.warning,
                          ),
                        ),
                        Text(
                          'Buy tokens to keep chatting',
                          style: AppTextStyles.bodySM(),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.push(AppRoutes.subscription),
                    child: Text(
                      'Buy',
                      style: AppTextStyles.bodySM(
                        color: AppColors.primary,
                      ).copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn().slideY(begin: -0.2);
          },
        ),

        // Chat list
        Expanded(
          child: BlocBuilder<ChatBloc, ChatState>(
            builder: (context, state) {
              if (state.isLoading) {
                return ListView.builder(
                  itemCount: 6,
                  itemBuilder: (_, i) => Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        const SkeletonAvatar(size: 52),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              SkeletonBox(width: 120, height: 14, radius: 6),
                              SizedBox(height: 6),
                              SkeletonBox(
                                width: double.infinity,
                                height: 12,
                                radius: 4,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              if (state.chats.isEmpty) {
                return const EmptyState(
                  emoji: '💬',
                  title: 'No conversations yet',
                  subtitle: 'Match with a buddy and start chatting!',
                );
              }

              return RefreshIndicator(
                color: AppColors.primary,
                backgroundColor: AppColors.surface2,
                onRefresh: () async =>
                    context.read<ChatBloc>().add(const ChatListLoaded()),
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: state.chats.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, indent: 80),
                  itemBuilder: (_, i) {
                    final chat = state.chats[i];
                    final unread = chat['unreadCount'] as int? ?? 0;
                    return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          leading: AppAvatar(
                            name: chat['buddyName'] ?? '?',
                            imageUrl: chat['buddyAvatar'],
                            size: 52,
                            online: chat['isOnline'] ?? false,
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  chat['buddyName'] ?? 'Unknown',
                                  style: AppTextStyles.subtitle(
                                    color: unread > 0
                                        ? AppColors.textPrimary
                                        : AppColors.textSecondary,
                                  ),
                                ),
                              ),
                              Text(
                                chat['lastMessageAt'] != null
                                    ? timeago.format(
                                        DateTime.parse(chat['lastMessageAt']),
                                        locale: 'en_short',
                                      )
                                    : '',
                                style: AppTextStyles.caption(
                                  color: unread > 0
                                      ? AppColors.primary
                                      : AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                          subtitle: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  chat['lastMessage'] ?? 'No messages yet',
                                  style: AppTextStyles.bodySM(
                                    color: unread > 0
                                        ? AppColors.textSecondary
                                        : AppColors.textMuted,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (unread > 0)
                                Container(
                                  margin: const EdgeInsets.only(left: 8),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(100),
                                  ),
                                  child: Text(
                                    '$unread',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.black,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          onTap: () => context.push(
                            AppRoutes.chat.replaceAll(':chatId', chat['id']),
                            extra: {
                              'buddyName': chat['buddyName'],
                              'buddyAvatar': chat['buddyAvatar'],
                              'buddyId': chat['buddyId'],
                              'matchId': chat['matchId'],
                            },
                          ),
                        )
                        .animate(delay: Duration(milliseconds: i * 50))
                        .fadeIn()
                        .slideX(begin: -0.1);
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ── REQUESTS TAB ──────────────────────────────────────────
class _RequestsTab extends StatelessWidget {
  const _RequestsTab({
    required this.requests,
    required this.loading,
    required this.onRefresh,
    required this.onAccept,
    required this.onDecline,
    this.actingSwipeId,
  });

  final List<MatchRequest> requests;
  final bool loading;
  final VoidCallback onRefresh;
  final void Function(MatchRequest) onAccept;
  final void Function(MatchRequest) onDecline;
  final String? actingSwipeId; // Which swipe is being processed

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (requests.isEmpty) {
      return const EmptyState(
        emoji: '🤝',
        title: 'No match requests',
        subtitle: 'When someone wants to train with you, they\'ll appear here.',
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: AppColors.surface2,
      onRefresh: () async => onRefresh(),
      child: ListView(
        padding: const EdgeInsets.only(top: 4, bottom: 24),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
            child: Text(
              '${requests.length} ${requests.length == 1 ? 'person wants' : 'people want'} to train with you',
              style: AppTextStyles.bodySM(color: AppColors.textMuted),
            ),
          ),
          ...requests.asMap().entries.map(
            (e) =>
                _RequestItem(
                      request: e.value,
                      isActing: actingSwipeId == e.value.swipeId,
                      onAccept: () => onAccept(e.value),
                      onDecline: () => onDecline(e.value),
                    )
                    .animate(delay: Duration(milliseconds: e.key * 60))
                    .fadeIn()
                    .slideX(begin: 0.1),
          ),
        ],
      ),
    );
  }
}

// ── SINGLE REQUEST ITEM ───────────────────────────────────
class _RequestItem extends StatelessWidget {
  const _RequestItem({
    required this.request,
    required this.onAccept,
    required this.onDecline,
    this.isActing = false,
  });

  final MatchRequest request;
  final VoidCallback onAccept;
  final VoidCallback onDecline;
  final bool isActing; // From MatchRequestBloc.actingSwipeId

  @override
  Widget build(BuildContext context) {
    final user = request.user;
    final isSuperLike = request.isSuperLike;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface1,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSuperLike
              ? AppColors.teal.withOpacity(0.25)
              : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          // Avatar
          AppAvatar(name: user.firstName, imageUrl: user.avatarUrl, size: 44),
          const SizedBox(width: 10),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name + match %
                Row(
                  children: [
                    Text(
                      '${user.firstName}, ${user.age ?? ''}',
                      style: AppTextStyles.subtitle(),
                    ),
                    const SizedBox(width: 6),
                    if (isSuperLike)
                      _Chip('⭐ Super', AppColors.teal)
                    else
                      _Chip('${user.matchScore ?? 80}%', AppColors.primary),
                  ],
                ),
                const SizedBox(height: 3),

                // Activity + location
                Text(
                  '${_actEmoji(user.primaryActivity)} ${user.primaryActivity ?? 'Fitness'} · ${user.city ?? ''}',
                  style: AppTextStyles.bodySM(color: AppColors.textMuted),
                ),

                const SizedBox(height: 7),

                // View Profile button
                GestureDetector(
                  onTap: () => context.push(
                    AppRoutes.buddyProfile.replaceAll(':userId', user.id),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface2,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      'View Profile',
                      style: AppTextStyles.caption(
                        color: AppColors.textMuted,
                      ).copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Accept / Decline
          if (isActing)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary,
              ),
            )
          else
            Column(
              children: [
                // Decline
                GestureDetector(
                  onTap: isActing ? null : onDecline,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.error.withOpacity(0.1),
                      border: Border.all(
                        color: AppColors.error.withOpacity(0.3),
                      ),
                    ),
                    child: const Center(
                      child: Text(
                        '✕',
                        style: TextStyle(
                          color: AppColors.error,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                // Accept
                GestureDetector(
                  onTap: isActing ? null : onAccept,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.teal.withOpacity(0.1),
                      border: Border.all(
                        color: AppColors.teal.withOpacity(0.3),
                      ),
                    ),
                    child: const Center(
                      child: Text(
                        '✓',
                        style: TextStyle(
                          color: AppColors.teal,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _Chip(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: color.withOpacity(0.12),
      borderRadius: BorderRadius.circular(4),
      border: Border.all(color: color.withOpacity(0.3)),
    ),
    child: Text(
      label,
      style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700),
    ),
  );

  String _actEmoji(String? act) {
    const m = {
      'gym': '🏋️',
      'running': '🏃',
      'cycling': '🚴',
      'yoga': '🧘',
      'boxing': '🥊',
      'swimming': '🏊',
    };
    return m[act?.toLowerCase()] ?? '💪';
  }
}
