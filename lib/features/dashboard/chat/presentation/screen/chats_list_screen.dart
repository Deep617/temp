import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/widgets/common/common_widgets.dart';
import '../../../../../routes/app_router.dart';
import '../../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../../auth/presentation/bloc/auth_state.dart';
import '../bloc/chat_bloc.dart';

class ChatsListScreen extends StatelessWidget {
  const ChatsListScreen({super.key});

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
      ),
      body: Column(
        children: [
          // Token warning
          BlocBuilder<AuthBloc, AuthState>(
            builder: (context, authState) {
              final user = authState.user;
              if (user == null || user.chatTokens! >= 5)
                return const SizedBox.shrink();
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
                            '\${user.chatTokens} tokens remaining',
                            style: AppTextStyles.subtitle(
                              color: AppColors.warning,
                            ),
                          ),
                          Text(
                            'Buy tokens to keep chatting after missed sessions',
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

                if (state.chats.isEmpty)
                  return const EmptyState(
                    emoji: '💬',
                    title: 'No conversations yet',
                    subtitle: 'Match with a buddy and start chatting!',
                  );

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
                                      '\$unread',
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
      ),
    );
  }
}
