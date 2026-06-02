import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:seshlly/features/auth/presentation/bloc/auth_state.dart';
import 'package:seshlly/routes/app_router.dart';

import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/widgets/common/common_widgets.dart';
import '../../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../../auth/presentation/bloc/auth_event.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, LoginState>(
      builder: (context, authState) {
        final user = authState.loginResponse!.user;
        if (user == null)
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );

        final thresholds = AppConstants.levelThresholds;
        final lvl = (user.level - 1).clamp(0, thresholds.length - 2);
        final xpMin = thresholds[lvl];
        final xpMax = thresholds[(lvl + 1).clamp(0, thresholds.length - 1)];
        final xpPct = ((user.xpTotal! - xpMin) / (xpMax - xpMin)).clamp(
          0.0,
          1.0,
        );

        return Scaffold(
          backgroundColor: AppColors.bg,
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 280,
                pinned: true,
                backgroundColor: AppColors.surface1,
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            center: Alignment.topCenter,
                            radius: 1.2,
                            colors: [
                              AppColors.primary.withOpacity(0.12),
                              AppColors.surface1,
                            ],
                          ),
                        ),
                      ),
                      SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 56, 20, 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(3),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: user.isPro
                                          ? AppColors.compatGradient
                                          : const LinearGradient(
                                              colors: [
                                                AppColors.border2,
                                                AppColors.border,
                                              ],
                                            ),
                                    ),
                                    child: AppAvatar(
                                      name: user.fullName,
                                      imageUrl: user.avatarUrl,
                                      size: 80,
                                      verified: user.idVerified ?? false,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Flexible(
                                              child: Text(
                                                user.fullName,
                                                style: AppTextStyles.h2(),
                                              ),
                                            ),
                                            if (user.idVerified!) ...[
                                              const SizedBox(width: 6),
                                              const Icon(
                                                Icons.verified,
                                                color: AppColors.blue,
                                                size: 18,
                                              ),
                                            ],
                                          ],
                                        ),
                                        if (user.username != null) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            '@\${user.username}',
                                            style: AppTextStyles.bodySM(
                                              color: AppColors.primary,
                                            ),
                                          ),
                                        ],
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            AppBadge(
                                              label: user.levelName,
                                              small: true,
                                            ),
                                            if (user.isPro) ...[
                                              const SizedBox(width: 6),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 3,
                                                    ),
                                                decoration: BoxDecoration(
                                                  gradient:
                                                      AppColors.compatGradient,
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        100,
                                                      ),
                                                ),
                                                child: Text(
                                                  'PRO',
                                                  style: AppTextStyles.label(
                                                    color: Colors.black,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () =>
                                        context.push(AppRoutes.editProfile),
                                    icon: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: AppColors.surface3,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: AppColors.border2,
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.edit_outlined,
                                        color: AppColors.textMuted,
                                        size: 16,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              if (user.bio != null && user.bio!.isNotEmpty)
                                Text(
                                  user.bio!,
                                  style: AppTextStyles.body(),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  if (user.city != null) ...[
                                    const Icon(
                                      Icons.location_on,
                                      color: AppColors.textMuted,
                                      size: 14,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      user.city!,
                                      style: AppTextStyles.bodySM(),
                                    ),
                                    const SizedBox(width: 12),
                                  ],
                                  if (user.primaryGym != null) ...[
                                    const Icon(
                                      Icons.fitness_center,
                                      color: AppColors.textMuted,
                                      size: 14,
                                    ),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        user.primaryGym!,
                                        style: AppTextStyles.bodySM(),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined),
                    onPressed: () => context.push(AppRoutes.notifications),
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings_outlined),
                    onPressed: () => _showSettings(context),
                  ),
                ],
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // XP Bar
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface1,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                const Text('⭐', style: TextStyle(fontSize: 20)),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Level \${user.level} · \${user.levelName}',
                                            style: AppTextStyles.subtitle(),
                                          ),
                                          Text(
                                            '\${user.xpTotal} XP total',
                                            style: AppTextStyles.caption(),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(
                                          100,
                                        ),
                                        child: LinearProgressIndicator(
                                          value: xpPct,
                                          minHeight: 6,
                                          backgroundColor: AppColors.surface3,
                                          valueColor:
                                              const AlwaysStoppedAnimation<
                                                Color
                                              >(AppColors.primary),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '\${user.xpTotal - xpMin} / \${xpMax - xpMin} XP to Level \${user.level + 1}',
                                        style: AppTextStyles.caption(),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ).animate().fadeIn(),

                      const SizedBox(height: 12),
                      // Stats
                      Row(
                        children: [
                          _StatCard(
                            value: user.buddyCount!,
                            label: 'Buddies',
                            emoji: '🤝',
                          ),
                          const SizedBox(width: 10),
                          _StatCard(
                            value: user.sessionCount!,
                            label: 'Sessions',
                            emoji: '💪',
                          ),
                          const SizedBox(width: 10),
                          _StatCard(
                            value: user.chatTokens!,
                            label: 'Tokens',
                            emoji: '🎫',
                          ),
                        ],
                      ).animate(delay: 100.ms).fadeIn(),

                      const SizedBox(height: 12),
                      // Activities
                      _sectionCard(
                        title: 'Activities',
                        child: user.activities!.isEmpty
                            ? GestureDetector(
                                onTap: () =>
                                    context.push(AppRoutes.editProfile),
                                child: Text(
                                  '+ Add your activities',
                                  style: AppTextStyles.bodySM(
                                    color: AppColors.primary,
                                  ).copyWith(fontWeight: FontWeight.w700),
                                ),
                              )
                            : Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: user.activities!.map((id) {
                                  final a = AppConstants.activities.firstWhere(
                                    (x) => x['id'] == id,
                                    orElse: () => {
                                      'id': id,
                                      'emoji': '💪',
                                      'label': id,
                                      'color': 0xFFBAEE0B,
                                    },
                                  );
                                  return ActivityChip(
                                    activity: a,
                                    selected: id == user.primaryActivity,
                                  );
                                }).toList(),
                              ),
                      ),

                      const SizedBox(height: 12),
                      // Upgrade CTA
                      if (!user.isPro)
                        GestureDetector(
                          onTap: () => context.push(AppRoutes.subscription),
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: AppColors.membershipGradient,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppColors.primary.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Upgrade to Pro',
                                        style: AppTextStyles.h3(
                                          color: AppColors.primary,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Unlimited swipes, priority matches & more',
                                        style: AppTextStyles.bodySM(),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    'Upgrade',
                                    style: AppTextStyles.btn(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ).animate(delay: 200.ms).fadeIn(),

                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _sectionCard({required String title, required Widget child}) =>
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface1,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(title: title),
            const SizedBox(height: 14),
            child,
          ],
        ),
      );

  void _showSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: AppColors.border2,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text('Settings', style: AppTextStyles.h3()),
            const SizedBox(height: 20),
            const Divider(),
            ListTile(
              leading: const Text('🚪', style: TextStyle(fontSize: 20)),
              title: Text(
                'Sign Out',
                style: AppTextStyles.subtitle(color: AppColors.error),
              ),
              onTap: () {
                Navigator.pop(context);
                context.read<AuthBloc>().add(const LogoutSubmitted());
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.value,
    required this.label,
    required this.emoji,
  });

  final int value;
  final String label, emoji;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface1,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 6),
          Text('\$value', style: AppTextStyles.h3(color: AppColors.primary)),
          Text(label, style: AppTextStyles.caption()),
        ],
      ),
    ),
  );
}
