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
    final user = context.watch<AuthBloc>().state.user;

    if (user == null) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    // XP progress calculation
    final thresholds = AppConstants.levelThresholds;
    final lvl        = (user.level - 1).clamp(0, thresholds.length - 2);
    final xpMin      = thresholds[lvl];
    final xpMax      = thresholds[(lvl + 1).clamp(0, thresholds.length - 1)];
    final xpProgress = ((user.xpTotal! - xpMin) / (xpMax - xpMin))
        .clamp(0.0, 1.0)
        .toDouble();

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [

              // ── HEADER BLOCK ──────────────────────────────────
              Container(
                color: AppColors.surface1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // Notification + Settings icons — inside header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          _HeaderIconBtn(
                            icon: Icons.notifications_outlined,
                            onTap: () =>
                                context.push(AppRoutes.notifications),
                          ),
                          const SizedBox(width: 8),
                          _HeaderIconBtn(
                            icon: Icons.settings_outlined,
                            onTap: () => _showSettingsSheet(context),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Avatar + Name + Edit
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          // Avatar with online dot
                          Stack(
                            children: [
                              Container(
                                width:       72,
                                height:      72,
                                decoration: BoxDecoration(
                                  shape:    BoxShape.circle,
                                  gradient: LinearGradient(
                                    begin:  Alignment.topLeft,
                                    end:    Alignment.bottomRight,
                                    colors: [
                                      AppColors.primary,
                                      AppColors.teal,
                                    ],
                                  ),
                                ),
                                padding: const EdgeInsets.all(2.5),
                                child: AppAvatar(
                                  name:     user.fullName,
                                  imageUrl: user.avatarUrl,
                                  size:     67,
                                  verified: user.idVerified!,
                                ),
                              ),
                              Positioned(
                                bottom: 3,
                                right:  3,
                                child: Container(
                                  width:  13,
                                  height: 13,
                                  decoration: BoxDecoration(
                                    color:  AppColors.teal,
                                    shape:  BoxShape.circle,
                                    border: Border.all(
                                      color: AppColors.surface1,
                                      width: 2.5,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(width: 12),

                          // Name block
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [

                                // Level badge
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.warning
                                        .withOpacity(0.14),
                                    borderRadius:
                                    BorderRadius.circular(6),
                                    border: Border.all(
                                      color: AppColors.warning
                                          .withOpacity(0.32),
                                    ),
                                  ),
                                  child: Text(
                                    '⭐ ${user.levelName.toUpperCase()}',
                                    style: AppTextStyles.label(
                                        color: AppColors.warning),
                                  ),
                                ),

                                const SizedBox(height: 5),

                                // Name — single line, no wrap
                                Row(children: [
                                  Flexible(
                                    child: Text(
                                      user.fullName,
                                      style: AppTextStyles.h2(),
                                      maxLines:  1,
                                      overflow:
                                      TextOverflow.ellipsis,
                                      softWrap:  false,
                                    ),
                                  ),
                                  if (user.idVerified!) ...[
                                    const SizedBox(width: 5),
                                    const Icon(
                                      Icons.verified,
                                      color: AppColors.blue,
                                      size:  16,
                                    ),
                                  ],
                                ]),

                                const SizedBox(height: 5),

                                // Location + Gym — single row, no wrap
                                Row(children: [
                                  if (user.city != null) ...[
                                    const Icon(Icons.location_on,
                                        color: AppColors.textMuted,
                                        size:  12),
                                    const SizedBox(width: 2),
                                    Text(
                                      user.city!,
                                      style: AppTextStyles.bodySM(
                                          color: AppColors.textMuted),
                                      maxLines:  1,
                                      overflow:
                                      TextOverflow.ellipsis,
                                      softWrap:  false,
                                    ),
                                  ],
                                  if (user.city != null &&
                                      user.primaryGym != null)
                                    const SizedBox(width: 10),
                                  if (user.primaryGym != null) ...[
                                    const Icon(Icons.fitness_center,
                                        color: AppColors.textMuted,
                                        size:  12),
                                    const SizedBox(width: 2),
                                    Flexible(
                                      child: Text(
                                        user.primaryGym!,
                                        style: AppTextStyles.bodySM(
                                            color: AppColors.textMuted),
                                        maxLines:  1,
                                        overflow:
                                        TextOverflow.ellipsis,
                                        softWrap:  false,
                                      ),
                                    ),
                                  ],
                                ]),
                              ],
                            ),
                          ),

                          // Edit button
                          GestureDetector(
                            onTap: () =>
                                context.push(AppRoutes.editProfile),
                            child: Container(
                              width:  30,
                              height: 30,
                              decoration: BoxDecoration(
                                color:        AppColors.surface2,
                                borderRadius: BorderRadius.circular(9),
                                border:       Border.all(
                                    color: AppColors.border2),
                              ),
                              child: const Icon(
                                Icons.edit_outlined,
                                color: AppColors.textMuted,
                                size:  15,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // XP bar — inside header
                    Container(
                      decoration: const BoxDecoration(
                        border: Border(
                          top: BorderSide(color: AppColors.border),
                        ),
                      ),
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                      child: Column(children: [
                        Row(
                          mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                          children: [
                            Row(children: [
                              const Text('⭐',
                                  style: TextStyle(fontSize: 14)),
                              const SizedBox(width: 6),
                              Text(
                                'Level ${user.level} · ${user.levelName}',
                                style: AppTextStyles.subtitle(),
                              ),
                            ]),
                            Text('${user.xpTotal} XP total',
                                style: AppTextStyles.caption()),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(99),
                          child: LinearProgressIndicator(
                            value:       xpProgress,
                            minHeight:   6,
                            backgroundColor: AppColors.surface3,
                            valueColor:
                            const AlwaysStoppedAnimation<Color>(
                                AppColors.primary),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                          children: [
                            Text('0',
                                style: AppTextStyles.caption()),
                            Text(
                              '${user.xpTotal! - xpMin} / ${xpMax - xpMin} XP'
                                  ' → Level ${user.level + 1}',
                              style: AppTextStyles.caption()
                                  .copyWith(
                                  color:      AppColors.primary,
                                  fontWeight: FontWeight.w700),
                            ),
                            Text('${xpMax - xpMin}',
                                style: AppTextStyles.caption()),
                          ],
                        ),
                      ]),
                    ),
                  ],
                ),
              ),

              // ── BODY ─────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(children: [

                  // Stats 2x2
                  GridView.count(
                    crossAxisCount:   2,
                    crossAxisSpacing: 8,
                    mainAxisSpacing:  8,
                    shrinkWrap:       true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: 1.6,
                    children: [
                      _StatCard(
                        value: '${user.buddyCount}',
                        label: 'Buddies',
                        color: AppColors.primary,
                      ),
                      _StatCard(
                        value: '${user.sessionCount}',
                        label: 'Sessions',
                        color: AppColors.warning,
                      ),
                      _StatCard(
                        value: '${user.trustScore.toInt()}',
                        label: 'Trust Score',
                        color: AppColors.teal,
                      ),
/*                      _StatCard(
                        value: '${user.challengeCount! ?? 0}',
                        label: 'Challenges',
                        color: AppColors.purple,
                      ),*/
                    ],
                  ).animate().fadeIn(duration: 400.ms),

                  const SizedBox(height: 10),

                  // Fitness Identity
                  _Card(
                    title:   'Fitness Identity',
                    linkText: 'Edit',
                    onLink:  () => context.push(AppRoutes.editProfile),
                    child: Wrap(
                      spacing: 6, runSpacing: 6,
                      children: [
                        if (user.primaryActivity != null) ...[
                              () {
                            final a = AppConstants.activities
                                .firstWhere(
                                  (x) => x['id'] == user.primaryActivity,
                              orElse: () => {
                                'emoji': '💪',
                                'label': user.primaryActivity,
                                'color': 0xFF0A84FF,
                              },
                            );
                            return ActivityChip(
                                activity: a, selected: true);
                          }(),
                        ],
                        if (user.experienceLevel != null)
                          _InfoChip(
                            label: user.experienceLevel!,
                            color: AppColors.teal,
                          ),
                        if (user.primaryGym != null)
                          _InfoChip(
                            label: '💪 ${user.primaryGym!}',
                            color: AppColors.warning,
                          ),
                        ...user.goals!.take(3).map((id) {
                          final g = AppConstants.goals.firstWhere(
                                (x) => x['id'] == id,
                            orElse: () =>
                            {'id': id, 'emoji': '🎯', 'label': id},
                          );
                          return _InfoChip(
                            label: g['label']!,
                            color: AppColors.textSecondary,
                          );
                        }),
                        if (user.primaryActivity == null &&
                            user.goals!.isEmpty)
                          GestureDetector(
                            onTap: () =>
                                context.push(AppRoutes.editProfile),
                            child: Text(
                              '+ Add activities',
                              style: AppTextStyles.bodySM(
                                  color: AppColors.primary),
                            ),
                          ),
                      ],
                    ),
                  ).animate(delay: 50.ms).fadeIn(),

                  const SizedBox(height: 10),

                  // Trust Score
                  _Card(
                    title:    'Trust Score',
                    linkText: 'How it works',
                    onLink:   () {},
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Text(
                            '${user.trustScore.toInt()}',
                            style: AppTextStyles.metric()
                                .copyWith(color: AppColors.teal),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Upload sessions to increase',
                              style: AppTextStyles.bodySM(
                                  color: AppColors.textMuted),
                            ),
                          ),
                        ]),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(99),
                          child: LinearProgressIndicator(
                            value:     user.trustScore / 100,
                            minHeight: 6,
                            backgroundColor: AppColors.surface3,
                            valueColor:
                            const AlwaysStoppedAnimation<Color>(
                                AppColors.teal),
                          ),
                        ),
                      ],
                    ),
                  ).animate(delay: 100.ms).fadeIn(),

                  const SizedBox(height: 10),

                  // Leaderboard Rank
                  _Card(
                    title: 'Leaderboard Rank',
                    child: Row(children: [
                      _RankItem(rank: '#284',    label: 'Weekly'),
                      _RankDivider(),
                      _RankItem(rank: '#1,204',  label: 'Monthly'),
                      _RankDivider(),
                      _RankItem(rank: '#8,441',  label: 'All-time'),
                    ]),
                  ).animate(delay: 150.ms).fadeIn(),

                  const SizedBox(height: 10),

                  // Trophies
                  _Card(
                    title:   'Trophies',
                    linkText: 'See all',
                    onLink:  () {},
                    child: Row(children: [
                      _TrophyBadge(
                          emoji: '🏆',
                          label: 'Iron Will',
                          won:   true),
                      const SizedBox(width: 8),
                      _TrophyBadge(emoji: '🏅', label: 'Locked'),
                      const SizedBox(width: 8),
                      _TrophyBadge(emoji: '⚡',  label: 'Locked'),
                      const SizedBox(width: 8),
                      _TrophyBadge(emoji: '🔥', label: 'Locked'),
                    ]),
                  ).animate(delay: 200.ms).fadeIn(),

                  const SizedBox(height: 10),

                  // Recent Sessions
                  _Card(
                    title:   'Recent Sessions',
                    linkText: 'View all',
                    onLink:  () => context.push(AppRoutes.sessions),
                    child: Column(children: [
                      _SessionRow(
                        emoji: '🏋️',
                        title: 'Gym · with Deepak',
                        sub:   'Today, 7:00 AM',
                        xp:    '+50 XP',
                        color: AppColors.primary,
                      ),
                      _SessionRow(
                        emoji: '🏃',
                        title: 'Running · Solo',
                        sub:   'Yesterday, 6:30 AM',
                        xp:    '+50 XP',
                        color: AppColors.teal,
                      ),
                      _SessionRow(
                        emoji: '🏋️',
                        title: 'Gym · Solo',
                        sub:   '2 days ago',
                        xp:    '+50 XP',
                        color: AppColors.warning,
                        isLast: true,
                      ),
                    ]),
                  ).animate(delay: 250.ms).fadeIn(),

                  const SizedBox(height: 10),

                  // Upgrade CTA
                  if (!user.isPro)
                    GestureDetector(
                      onTap: () =>
                          context.push(AppRoutes.subscription),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: AppColors.membershipGradient,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.25),
                          ),
                        ),
                        child: Row(children: [
                          Expanded(child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [
                              Text('Upgrade to Pro',
                                  style: AppTextStyles.subtitle(
                                      color: AppColors.primary)),
                              const SizedBox(height: 3),
                              Text('Unlimited swipes & more',
                                  style: AppTextStyles.bodySM()),
                            ],
                          )),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color:        AppColors.primary,
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: Text('Upgrade',
                                style: AppTextStyles.btn()),
                          ),
                        ]),
                      ),
                    ).animate(delay: 300.ms).fadeIn(),

                  const SizedBox(height: 16),

                  Text(
                    'Member since ${_joinedDate(user.createdAt)}',
                    style: AppTextStyles.caption(),
                  ),

                  const SizedBox(height: 80),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _joinedDate(DateTime? dt) {
    if (dt == null) return 'recently';
    const months = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'
    ];
    return '${months[dt.month - 1]} ${dt.year}';
  }

  void _showSettingsSheet(BuildContext context) {
    showModalBottomSheet(
      context:         context,
      backgroundColor: AppColors.surface1,
      shape: const RoundedRectangleBorder(
        borderRadius:
        BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36, height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 20),
              decoration: BoxDecoration(
                color:        AppColors.border2,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text('Settings', style: AppTextStyles.h3()),
            const SizedBox(height: 12),
            ...[
              ('🔔', 'Notifications',   () {}),
              ('🔒', 'Privacy',         () {}),
              ('🌐', 'Language',        () {}),
              ('💬', 'Support',         () {}),
              ('📋', 'Terms & Privacy', () {}),
            ].map((item) => ListTile(
              leading: Text(item.$1,
                  style: const TextStyle(fontSize: 20)),
              title:   Text(item.$2, style: AppTextStyles.subtitle()),
              trailing: const Icon(Icons.chevron_right,
                  color: AppColors.textMuted),
              onTap: item.$3,
            )),
            const Divider(color: AppColors.border),
            ListTile(
              leading: const Text('🚪',
                  style: TextStyle(fontSize: 20)),
              title: Text('Sign Out',
                  style: AppTextStyles.subtitle(
                      color: AppColors.error)),
              onTap: () {
                Navigator.pop(context);
                context.read<AuthBloc>().add(const LogoutSubmitted());
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════
//  LOCAL WIDGETS — same pattern as existing codebase
// ══════════════════════════════════════════════════════════

// Header icon button
class _HeaderIconBtn extends StatelessWidget {
  const _HeaderIconBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width:  32, height: 32,
      decoration: BoxDecoration(
        color:        AppColors.surface2,
        shape:        BoxShape.circle,
        border:       Border.all(color: AppColors.border),
      ),
      child: Icon(icon, color: AppColors.textSecondary, size: 16),
    ),
  );
}

// Stat card
class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.value,
    required this.label,
    required this.color,
  });
  final String value, label;
  final Color  color;
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color:        AppColors.surface1,
      borderRadius: BorderRadius.circular(14),
      border:       Border.all(color: AppColors.border),
    ),
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Text(value,
          style: AppTextStyles.h2(color: color)),
      const SizedBox(height: 4),
      Text(label, style: AppTextStyles.caption()),
    ]),
  );
}

// Generic card wrapper
class _Card extends StatelessWidget {
  const _Card({
    required this.title,
    required this.child,
    this.linkText,
    this.onLink,
  });
  final String    title;
  final Widget    child;
  final String?   linkText;
  final VoidCallback? onLink;
  @override
  Widget build(BuildContext context) => Container(
    width:   double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color:        AppColors.surface1,
      borderRadius: BorderRadius.circular(14),
      border:       Border.all(color: AppColors.border),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(title, style: AppTextStyles.subtitle()),
        if (linkText != null && onLink != null)
          GestureDetector(
            onTap: onLink,
            child: Text(linkText!,
                style: AppTextStyles.bodySM(color: AppColors.primary)),
          ),
      ]),
      const SizedBox(height: 12),
      child,
    ]),
  );
}

// Info chip (level, gym, goals)
class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label, required this.color});
  final String label;
  final Color  color;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color:        color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(99),
      border:       Border.all(color: color.withOpacity(0.25)),
    ),
    child: Text(label,
        style: AppTextStyles.bodySM(color: color)
            .copyWith(fontWeight: FontWeight.w600)),
  );
}

// Leaderboard rank item
class _RankItem extends StatelessWidget {
  const _RankItem({required this.rank, required this.label});
  final String rank, label;
  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(children: [
      Text(rank,
          style: AppTextStyles.h3(color: AppColors.textPrimary)),
      const SizedBox(height: 3),
      Text(label, style: AppTextStyles.caption()),
    ]),
  );
}

class _RankDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    width: 1, height: 32,
    color: AppColors.border,
    margin: const EdgeInsets.symmetric(horizontal: 4),
  );
}

// Trophy badge
class _TrophyBadge extends StatelessWidget {
  const _TrophyBadge({
    required this.emoji,
    required this.label,
    this.won = false,
  });
  final String emoji, label;
  final bool   won;
  @override
  Widget build(BuildContext context) => Opacity(
    opacity: won ? 1.0 : 0.4,
    child: Container(
      width: 48, height: 48,
      decoration: BoxDecoration(
        color:        won
            ? AppColors.warning.withOpacity(0.1)
            : AppColors.surface2,
        borderRadius: BorderRadius.circular(12),
        border:       Border.all(
          color: won
              ? AppColors.warning.withOpacity(0.3)
              : AppColors.border2,
        ),
      ),
      child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppTextStyles.caption().copyWith(
                  color:    won ? AppColors.warning : AppColors.textMuted,
                  fontSize: 6),
            ),
          ]),
    ),
  );
}

// Session row
class _SessionRow extends StatelessWidget {
  const _SessionRow({
    required this.emoji,
    required this.title,
    required this.sub,
    required this.xp,
    required this.color,
    this.isLast = false,
  });
  final String emoji, title, sub, xp;
  final Color  color;
  final bool   isLast;
  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.only(
        top: 8, bottom: isLast ? 0 : 8),
    decoration: BoxDecoration(
      border: isLast
          ? null
          : const Border(
        bottom: BorderSide(color: AppColors.border),
      ),
    ),
    child: Row(children: [
      Container(
        width: 8, height: 8,
        decoration: BoxDecoration(
            color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 10),
      Expanded(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$emoji $title',
              style: AppTextStyles.bodySM()),
          const SizedBox(height: 2),
          Text(sub,
              style: AppTextStyles.bodySM(
                  color: AppColors.textMuted)),
        ],
      )),
      Text(xp,
          style: AppTextStyles.label(color: AppColors.warning)),
    ]),
  );
}

