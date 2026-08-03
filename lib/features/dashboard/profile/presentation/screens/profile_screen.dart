import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:seshlly/di_injection/dependency_injection.dart';
import 'package:seshlly/routes/app_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/widgets/common/common_widgets.dart';
import '../../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../../auth/presentation/bloc/auth_event.dart';
import '../../../challanges/data/repositories/challenge_repository.dart';
import '../../../challanges/data/response_ml/challange_model.dart';
import '../../../session/data/repositories/session_repository.dart';
import '../../../session/data/response_ml/workout_session.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Real data from APIs
  List<WorkoutSession> _recentSessions = [];
  List<ChallengeEntry> _completedTrophies = [];
  List<GlobalLeaderboardEntry> _leaderboard = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final challengeRepository = getIt<ChallengeRepository>();
    final sessionRepository = getIt<SessionRepository>();
    try {
      final results = await Future.wait([
        // Recent sessions
        sessionRepository.getSessions(status: 'completed', page: 1),
        // My challenge entries
        challengeRepository.getMyChallenges(),
        // Global leaderboard
        challengeRepository.getGlobalLeaderboard(),
      ]);

      if (!mounted) return;
      setState(() {
        _recentSessions = (results[0] as List<WorkoutSession>).take(3).toList();
        // Trophies = completed challenges only
        _completedTrophies = (results[1] as List<ChallengeEntry>)
            .where((e) => e.status == 'completed')
            .toList();
        // Find user's rank in leaderboard
        _leaderboard = results[2] as List<GlobalLeaderboardEntry>;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  // Get user rank from leaderboard entries
  int? _getUserRank(String? userId) {
    if (userId == null || _leaderboard.isEmpty) return null;
    try {
      return _leaderboard.firstWhere((e) => e.userId == userId).rank;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthBloc>().state.user;
    if (user == null) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    final thresholds = AppConstants.levelThresholds;
    final lvl = (user.level - 1).clamp(0, thresholds.length - 2);
    final xpMin = thresholds[lvl];
    final xpMax = thresholds[(lvl + 1).clamp(0, thresholds.length - 1)];
    final xpProgress = ((user.xpTotal - xpMin) / (xpMax - xpMin))
        .clamp(0.0, 1.0)
        .toDouble();

    // User ranks from real leaderboard
    final alltimeRank = _getUserRank(user.id);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _loadData,
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                // ── HEADER ──────────────────────────────────────
                Container(
                  color: AppColors.surface1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Icons row
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

                      // Avatar + Name
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Avatar
                            Stack(
                              children: [
                                Container(
                                  width: 72,
                                  height: 72,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      colors: [
                                        AppColors.primary,
                                        AppColors.teal,
                                      ],
                                    ),
                                  ),
                                  padding: const EdgeInsets.all(2.5),
                                  child: AppAvatar(
                                    name: user.fullName,
                                    imageUrl: user.avatarUrl,
                                    size: 67,
                                    verified: user.idVerified,
                                  ),
                                ),
                                Positioned(
                                  bottom: 3,
                                  right: 3,
                                  child: Container(
                                    width: 13,
                                    height: 13,
                                    decoration: BoxDecoration(
                                      color: AppColors.teal,
                                      shape: BoxShape.circle,
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
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.warning.withOpacity(
                                        0.14,
                                      ),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: AppColors.warning.withOpacity(
                                          0.32,
                                        ),
                                      ),
                                    ),
                                    child: Text(
                                      '⭐ ${user.levelName.toUpperCase()}',
                                      style: AppTextStyles.label(
                                        color: AppColors.warning,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  // Name — single line
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          user.fullName,
                                          style: AppTextStyles.h2(),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          softWrap: false,
                                        ),
                                      ),
                                      if (user.idVerified) ...[
                                        const SizedBox(width: 5),
                                        const Icon(
                                          Icons.verified,
                                          color: AppColors.blue,
                                          size: 16,
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 5),
                                  // Location — single row
                                  Row(
                                    children: [
                                      if (user.city != null) ...[
                                        const Icon(
                                          Icons.location_on,
                                          color: AppColors.textMuted,
                                          size: 12,
                                        ),
                                        const SizedBox(width: 2),
                                        Text(
                                          user.city!,
                                          style: AppTextStyles.bodySM(
                                            color: AppColors.textMuted,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          softWrap: false,
                                        ),
                                      ],
                                      if (user.city != null &&
                                          user.primaryGym != null)
                                        const SizedBox(width: 10),
                                      if (user.primaryGym != null) ...[
                                        const Icon(
                                          Icons.fitness_center,
                                          color: AppColors.textMuted,
                                          size: 12,
                                        ),
                                        const SizedBox(width: 2),
                                        Flexible(
                                          child: Text(
                                            user.primaryGym!,
                                            style: AppTextStyles.bodySM(
                                              color: AppColors.textMuted,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            softWrap: false,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // Edit btn
                            GestureDetector(
                              onTap: () => context.push(AppRoutes.editProfile),
                              child: Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: AppColors.surface2,
                                  borderRadius: BorderRadius.circular(9),
                                  border: Border.all(color: AppColors.border2),
                                ),
                                child: const Icon(
                                  Icons.edit_outlined,
                                  color: AppColors.textMuted,
                                  size: 15,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // XP bar
                      Container(
                        decoration: const BoxDecoration(
                          border: Border(
                            top: BorderSide(color: AppColors.border),
                          ),
                        ),
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Text(
                                      '⭐',
                                      style: TextStyle(fontSize: 14),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Level ${user.level} · ${user.levelName}',
                                      style: AppTextStyles.subtitle(),
                                    ),
                                  ],
                                ),
                                Text(
                                  '${user.xpTotal} XP total',
                                  style: AppTextStyles.caption(),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(99),
                              child: LinearProgressIndicator(
                                value: xpProgress,
                                minHeight: 6,
                                backgroundColor: AppColors.surface3,
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  AppColors.primary,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('0', style: AppTextStyles.caption()),
                                Text(
                                  '${user.xpTotal - xpMin} / ${xpMax - xpMin} XP → Level ${user.level + 1}',
                                  style: AppTextStyles.caption().copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  '${xpMax - xpMin}',
                                  style: AppTextStyles.caption(),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // ── BODY ────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: [
                      // Stats 2x2
                      GridView.count(
                        crossAxisCount: 2,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        shrinkWrap: true,
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
                          _StatCard(
                            value: '${user.challengeCount}',
                            label: 'Challenges',
                            color: AppColors.purple,
                          ),
                        ],
                      ).animate().fadeIn(duration: 400.ms),

                      const SizedBox(height: 10),

                      // Fitness Identity
                      if (user.activities.isNotEmpty || user.goals.isNotEmpty)
                        _Card(
                          title: 'Fitness Identity',
                          linkText: 'Edit',
                          onLink: () => context.push(AppRoutes.editProfile),
                          child: Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              ...user.activities.map((id) {
                                final a = AppConstants.activities.firstWhere(
                                  (x) => x['id'] == id,
                                  orElse: () => {
                                    'id': id,
                                    'emoji': '💪',
                                    'label': id,
                                    'color': 0xFF0A84FF,
                                  },
                                );
                                return ActivityChip(
                                  activity: a,
                                  selected: id == user.primaryActivity,
                                );
                              }),
                              if (user.experienceLevel != null)
                                _InfoChip(
                                  label: user.experienceLevel!,
                                  color: AppColors.teal,
                                ),
                              ...user.goals.take(3).map((id) {
                                final g = AppConstants.goals.firstWhere(
                                  (x) => x['id'] == id,
                                  orElse: () => {
                                    'id': id,
                                    'emoji': '🎯',
                                    'label': id,
                                  },
                                );
                                return _InfoChip(
                                  label: '${g['emoji']} ${g['label']}',
                                  color: AppColors.textSecondary,
                                );
                              }),
                            ],
                          ),
                        ).animate(delay: 50.ms).fadeIn(),

                      const SizedBox(height: 10),

                      // Trust Score
                      _Card(
                        title: 'Trust Score',
                        linkText: 'View Feeds',
                        onLink: () => context.push(AppRoutes.feed),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  '${user.trustScore.toInt()}',
                                  style: AppTextStyles.metric().copyWith(
                                    color: AppColors.teal,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Upload sessions to increase',
                                    style: AppTextStyles.bodySM(
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(99),
                              child: LinearProgressIndicator(
                                value: user.trustScore / 100,
                                minHeight: 6,
                                backgroundColor: AppColors.surface3,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  user.trustScore >= 70
                                      ? AppColors.teal
                                      : user.trustScore >= 40
                                      ? AppColors.warning
                                      : AppColors.error,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ).animate(delay: 100.ms).fadeIn(),

                      const SizedBox(height: 10),

                      // ── LEADERBOARD RANK — Real data ─────────────
                      _Card(
                        title: 'Leaderboard Rank',
                        linkText: 'View all',
                        onLink: () => context.push(AppRoutes.leaderboard),
                        child: _loading
                            ? const Center(
                                child: SizedBox(
                                  height: 32,
                                  child: CircularProgressIndicator(
                                    color: AppColors.primary,
                                    strokeWidth: 2,
                                  ),
                                ),
                              )
                            : _leaderboard.isEmpty
                            ? Text(
                                'No rank yet — complete sessions to appear!',
                                style: AppTextStyles.bodySM(
                                  color: AppColors.textMuted,
                                ),
                              )
                            : Row(
                                children: [
                                  _RankItem(
                                    rank: alltimeRank != null
                                        ? '#$alltimeRank'
                                        : '–',
                                    label: 'All-time',
                                  ),
                                  _RankDivider(),
                                  _RankItem(
                                    rank: '${user.xpTotal} XP',
                                    label: 'Total XP',
                                  ),
                                  _RankDivider(),
                                  _RankItem(
                                    rank: 'Lv ${user.level}',
                                    label: user.levelName,
                                  ),
                                ],
                              ),
                      ).animate(delay: 150.ms).fadeIn(),

                      const SizedBox(height: 10),

                      // ── TROPHIES — Real completed challenges ──────
                      _Card(
                        title: 'Trophies',
                        linkText: 'See all',
                        onLink: () => context.push(AppRoutes.challenges),
                        child: _loading
                            ? const SizedBox(
                                height: 44,
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: AppColors.primary,
                                    strokeWidth: 2,
                                  ),
                                ),
                              )
                            : _completedTrophies.isEmpty
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'No trophies yet',
                                    style: AppTextStyles.bodySM(
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Complete challenges to earn trophies 🏆',
                                    style: AppTextStyles.bodySM(
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ],
                              )
                            : Row(
                                children: _completedTrophies
                                    .take(4)
                                    .map(
                                      (e) => Padding(
                                        padding: const EdgeInsets.only(
                                          right: 8,
                                        ),
                                        child: _TrophyBadge(
                                          label: "e.challengeTitle" ?? 'Trophy',
                                          won: true,
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ),
                      ).animate(delay: 200.ms).fadeIn(),

                      const SizedBox(height: 10),

                      // ── RECENT SESSIONS — Real data ───────────────
                      _Card(
                        title: 'Recent Sessions',
                        linkText: 'View all',
                        onLink: () => context.push(AppRoutes.sessions),
                        child: _loading
                            ? const SizedBox(
                                height: 60,
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: AppColors.primary,
                                    strokeWidth: 2,
                                  ),
                                ),
                              )
                            : _recentSessions.isEmpty
                            ? Text(
                                'No sessions yet — schedule your first one!',
                                style: AppTextStyles.bodySM(
                                  color: AppColors.textMuted,
                                ),
                              )
                            : Column(
                                children: _recentSessions
                                    .asMap()
                                    .entries
                                    .map(
                                      (e) => _SessionRow(
                                        session: e.value,
                                        isLast:
                                            e.key == _recentSessions.length - 1,
                                      ),
                                    )
                                    .toList(),
                              ),
                      ).animate(delay: 250.ms).fadeIn(),

                      const SizedBox(height: 10),

                      // ── SOS EMERGENCY BUTTON ─────────────────────
                      const _SOSButton(),

                      const SizedBox(height: 10),

                      // Subscription — show plan card for Pro/Elite, upgrade CTA for Free
                      _SubscriptionCard(
                        plan: user.subscriptionPlan,
                        expiry: user.subscriptionExpiry,
                        onUpgrade: () => context.push(AppRoutes.subscription),
                      ).animate(delay: 300.ms).fadeIn(),

                      const SizedBox(height: 16),
                      Text(
                        'Member since ${_joinedDate(user.createdAt)}',
                        style: AppTextStyles.caption(),
                      ),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _joinedDate(DateTime? dt) {
    if (dt == null) return 'recently';
    const m = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${m[dt.month - 1]} ${dt.year}';
  }

  void _showSettingsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface1,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.only(bottom: 32),
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 20),
                decoration: BoxDecoration(
                  color: AppColors.border2,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text('Settings', style: AppTextStyles.h3()),
            ),
            const SizedBox(height: 16),

            // ── Notifications ───────────────────────────
            _SettingsTile(
              emoji: '🔔',
              label: 'Notifications',
              onTap: () {
                Navigator.pop(ctx);
                _showNotificationsSheet(context);
              },
            ),
            // ── Privacy ─────────────────────────────────
            _SettingsTile(
              emoji: '🔒',
              label: 'Privacy',
              onTap: () {
                Navigator.pop(ctx);
                _showPrivacySheet(context);
              },
            ),
            // ── Language ────────────────────────────────
            _SettingsTile(
              emoji: '🌐',
              label: 'Language',
              onTap: () {
                Navigator.pop(ctx);
                _showLanguageSheet(context);
              },
            ),
            // ── Support ─────────────────────────────────
            _SettingsTile(
              emoji: '💬',
              label: 'Support',
              onTap: () {
                Navigator.pop(ctx);
                _showSupportSheet(context);
              },
            ),
            // ── Terms & Privacy ──────────────────────────
            _SettingsTile(
              emoji: '📋',
              label: 'Terms & Privacy',
              onTap: () {
                Navigator.pop(ctx);
                _showTermsSheet(context);
              },
            ),

            const Divider(color: AppColors.border, height: 32),

            // ── Sign Out ─────────────────────────────────
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20),
              leading: const Text('🚪', style: TextStyle(fontSize: 22)),
              title: Text(
                'Sign Out',
                style: AppTextStyles.subtitle(color: AppColors.error),
              ),
              onTap: () {
                Navigator.pop(ctx);
                context.read<AuthBloc>().add(const AuthLoggedOut());
              },
            ),
          ],
        ),
      ),
    );
  }

  // ── 1. NOTIFICATIONS ─────────────────────────────────
  void _showNotificationsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface1,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _NotificationsSheet(),
    );
  }

  // ── 2. PRIVACY ───────────────────────────────────────
  void _showPrivacySheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface1,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _PrivacySheet(),
    );
  }

  // ── 3. LANGUAGE ──────────────────────────────────────
  void _showLanguageSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface1,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _LanguageSheet(),
    );
  }

  // ── 4. SUPPORT ───────────────────────────────────────
  void _showSupportSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface1,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _SupportSheet(),
    );
  }

  // ── 5. TERMS & PRIVACY ───────────────────────────────
  void _showTermsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface1,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _TermsSheet(),
    );
  }
}

// ══════════════════════════════════════════════════════════
//  LOCAL WIDGETS
// ══════════════════════════════════════════════════════════

class _HeaderIconBtn extends StatelessWidget {
  const _HeaderIconBtn({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: AppColors.surface2,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.border),
      ),
      child: Icon(icon, color: AppColors.textSecondary, size: 16),
    ),
  );
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.value,
    required this.label,
    required this.color,
  });

  final String value, label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: AppColors.surface1,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.border),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(value, style: AppTextStyles.h2(color: color)),
        const SizedBox(height: 4),
        Text(label, style: AppTextStyles.caption()),
      ],
    ),
  );
}

class _Card extends StatelessWidget {
  const _Card({
    required this.title,
    required this.child,
    this.linkText,
    this.onLink,
  });

  final String title;
  final Widget child;
  final String? linkText;
  final VoidCallback? onLink;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppColors.surface1,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: AppTextStyles.subtitle()),
            if (linkText != null && onLink != null)
              GestureDetector(
                onTap: onLink,
                child: Text(
                  linkText!,
                  style: AppTextStyles.bodySM(color: AppColors.primary),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        child,
      ],
    ),
  );
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(99),
      border: Border.all(color: color.withOpacity(0.25)),
    ),
    child: Text(
      label,
      style: AppTextStyles.bodySM(
        color: color,
      ).copyWith(fontWeight: FontWeight.w600),
    ),
  );
}

class _RankItem extends StatelessWidget {
  const _RankItem({required this.rank, required this.label});

  final String rank, label;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      children: [
        Text(rank, style: AppTextStyles.h3(color: AppColors.textPrimary)),
        const SizedBox(height: 3),
        Text(label, style: AppTextStyles.caption()),
      ],
    ),
  );
}

class _RankDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    width: 1,
    height: 32,
    color: AppColors.border,
    margin: const EdgeInsets.symmetric(horizontal: 4),
  );
}

class _TrophyBadge extends StatelessWidget {
  const _TrophyBadge({required this.label, this.won = false});

  final String label;
  final bool won;

  @override
  Widget build(BuildContext context) => Opacity(
    opacity: won ? 1.0 : 0.35,
    child: Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: won ? AppColors.warning.withOpacity(0.1) : AppColors.surface2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: won ? AppColors.warning.withOpacity(0.3) : AppColors.border2,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🏆', style: TextStyle(fontSize: 20)),
          const SizedBox(height: 2),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              label,
              style: AppTextStyles.caption().copyWith(
                color: won ? AppColors.warning : AppColors.textMuted,
                fontSize: 6,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    ),
  );
}

// Session row — uses real WorkoutSession model
class _SessionRow extends StatelessWidget {
  final dynamic session;

  const _SessionRow({required this.session, this.isLast = false});

  // final WorkoutSession session;
  final bool isLast;

  String get _timeLabel {
    final now = DateTime.now();
    final diff = now.difference(session.scheduledAt);
    if (diff.inDays == 0) return 'Today, ${_fmt(session.scheduledAt)}';
    if (diff.inDays == 1) return 'Yesterday, ${_fmt(session.scheduledAt)}';
    return '${diff.inDays} days ago';
  }

  String _fmt(DateTime dt) {
    final h = dt.hour > 12
        ? dt.hour - 12
        : dt.hour == 0
        ? 12
        : dt.hour;
    final m = dt.minute.toString().padLeft(2, '0');
    final a = dt.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $a';
  }

  Color get _dotColor {
    switch (session.activity.toLowerCase()) {
      case 'running':
        return AppColors.teal;
      case 'cycling':
        return AppColors.purple;
      case 'swimming':
        return const Color(0xFF0ABFCE);
      default:
        return AppColors.primary;
    }
  }

  String get _activityEmoji {
    const map = {
      'gym': '🏋️',
      'running': '🏃',
      'cycling': '🚴',
      'swimming': '🏊',
      'boxing': '🥊',
      'yoga': '🧘',
      'hiit': '💥',
      'crossfit': '🔥',
      'hyrox': '⚡',
    };
    return map[session.activity.toLowerCase()] ?? '💪';
  }

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.only(top: 8, bottom: isLast ? 0 : 8),
    decoration: BoxDecoration(
      border: isLast
          ? null
          : const Border(bottom: BorderSide(color: AppColors.border)),
    ),
    child: Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: _dotColor, shape: BoxShape.circle),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$_activityEmoji ${session.activity}'
                '${session.buddyId != null ? ' · with Buddy' : ' · Solo'}',
                style: AppTextStyles.bodySM(),
              ),
              const SizedBox(height: 2),
              Text(
                _timeLabel,
                style: AppTextStyles.bodySM(color: AppColors.textMuted),
              ),
            ],
          ),
        ),
        if (session.xpEarned != null)
          Text(
            '+${session.xpEarned} XP',
            style: AppTextStyles.label(color: AppColors.warning),
          ),
      ],
    ),
  );
}

// ══════════════════════════════════════════════════════════
//  SETTINGS HELPER TILE
// ══════════════════════════════════════════════════════════
class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.emoji,
    required this.label,
    required this.onTap,
  });

  final String emoji, label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
    leading: Text(emoji, style: const TextStyle(fontSize: 22)),
    title: Text(label, style: AppTextStyles.subtitle()),
    trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted),
    onTap: onTap,
  );
}

// ══════════════════════════════════════════════════════════
//  1. NOTIFICATIONS SHEET
// ══════════════════════════════════════════════════════════
class _NotificationsSheet extends StatefulWidget {
  const _NotificationsSheet();

  @override
  State<_NotificationsSheet> createState() => _NotificationsSheetState();
}

class _NotificationsSheetState extends State<_NotificationsSheet> {
  // Keys for SharedPreferences
  static const _kPush = 'notif_push';
  static const _kSession = 'notif_session';
  static const _kBuddy = 'notif_buddy';
  static const _kChallenge = 'notif_challenge';
  static const _kMarketing = 'notif_marketing';

  bool _push = true;
  bool _session = true;
  bool _buddy = true;
  bool _challenge = true;
  bool _marketing = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    setState(() {
      _push = p.getBool(_kPush) ?? true;
      _session = p.getBool(_kSession) ?? true;
      _buddy = p.getBool(_kBuddy) ?? true;
      _challenge = p.getBool(_kChallenge) ?? true;
      _marketing = p.getBool(_kMarketing) ?? false;
    });
  }

  Future<void> _save(String key, bool val) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(key, val);
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _SheetHandle(),
        _SheetTitle('Notifications'),
        const SizedBox(height: 8),
        _ToggleTile(
          emoji: '🔔',
          label: 'Push Notifications',
          sub: 'Master toggle for all notifications',
          value: _push,
          onChanged: (v) {
            setState(() => _push = v);
            _save(_kPush, v);
          },
        ),
        _Divider(),
        _ToggleTile(
          emoji: '🏋️',
          label: 'Session Reminders',
          sub: 'Reminders before your scheduled sessions',
          value: _session,
          enabled: _push,
          onChanged: (v) {
            setState(() => _session = v);
            _save(_kSession, v);
          },
        ),
        _Divider(),
        _ToggleTile(
          emoji: '🤝',
          label: 'Buddy Matches',
          sub: 'When someone matches with you',
          value: _buddy,
          enabled: _push,
          onChanged: (v) {
            setState(() => _buddy = v);
            _save(_kBuddy, v);
          },
        ),
        _Divider(),
        _ToggleTile(
          emoji: '⚡',
          label: 'Challenge Updates',
          sub: 'Leaderboard changes and challenge alerts',
          value: _challenge,
          enabled: _push,
          onChanged: (v) {
            setState(() => _challenge = v);
            _save(_kChallenge, v);
          },
        ),
        _Divider(),
        _ToggleTile(
          emoji: '📣',
          label: 'Promotions',
          sub: 'Tips, offers and app updates',
          value: _marketing,
          enabled: _push,
          onChanged: (v) {
            setState(() => _marketing = v);
            _save(_kMarketing, v);
          },
        ),
      ],
    ),
  );
}

// ══════════════════════════════════════════════════════════
//  2. PRIVACY SHEET
// ══════════════════════════════════════════════════════════
class _PrivacySheet extends StatefulWidget {
  const _PrivacySheet();

  @override
  State<_PrivacySheet> createState() => _PrivacySheetState();
}

class _PrivacySheetState extends State<_PrivacySheet> {
  static const _kVisibility = 'privacy_visibility';
  static const _kLocation = 'privacy_location';
  static const _kOnline = 'privacy_online';

  String _visibility = 'public'; // public | buddies | hidden
  bool _location = true;
  bool _online = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    setState(() {
      _visibility = p.getString(_kVisibility) ?? 'public';
      _location = p.getBool(_kLocation) ?? true;
      _online = p.getBool(_kOnline) ?? true;
    });
  }

  Future<void> _saveStr(String key, String val) async =>
      (await SharedPreferences.getInstance()).setString(key, val);

  Future<void> _saveBool(String key, bool val) async =>
      (await SharedPreferences.getInstance()).setBool(key, val);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _SheetHandle(),
        _SheetTitle('Privacy'),
        const SizedBox(height: 16),

        // Profile visibility
        Text(
          'Profile Visibility',
          style: AppTextStyles.bodySM(color: AppColors.textMuted),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _VisChip(
              label: '🌍 Public',
              val: 'public',
              selected: _visibility,
              onTap: (v) {
                setState(() => _visibility = v);
                _saveStr(_kVisibility, v);
              },
            ),
            const SizedBox(width: 8),
            _VisChip(
              label: '🤝 Buddies',
              val: 'buddies',
              selected: _visibility,
              onTap: (v) {
                setState(() => _visibility = v);
                _saveStr(_kVisibility, v);
              },
            ),
            const SizedBox(width: 8),
            _VisChip(
              label: '🔒 Hidden',
              val: 'hidden',
              selected: _visibility,
              onTap: (v) {
                setState(() => _visibility = v);
                _saveStr(_kVisibility, v);
              },
            ),
          ],
        ),

        const SizedBox(height: 20),
        _Divider(),

        _ToggleTile(
          emoji: '📍',
          label: 'Location Sharing',
          sub: 'Share your location for buddy discovery',
          value: _location,
          onChanged: (v) {
            setState(() => _location = v);
            _saveBool(_kLocation, v);
          },
        ),
        _Divider(),
        _ToggleTile(
          emoji: '🟢',
          label: 'Show Online Status',
          sub: 'Let buddies see when you\'re active',
          value: _online,
          onChanged: (v) {
            setState(() => _online = v);
            _saveBool(_kOnline, v);
          },
        ),
        _Divider(),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Text('🚫', style: TextStyle(fontSize: 22)),
          title: Text('Blocked Users', style: AppTextStyles.subtitle()),
          trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted),
          onTap: () {},
        ),
      ],
    ),
  );
}

class _VisChip extends StatelessWidget {
  const _VisChip({
    required this.label,
    required this.val,
    required this.selected,
    required this.onTap,
  });

  final String label, val, selected;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    final isSelected = val == selected;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(val),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withOpacity(0.12)
                : AppColors.surface2,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? AppColors.primary.withOpacity(0.4)
                  : AppColors.border2,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySM(
              color: isSelected ? AppColors.primary : AppColors.textMuted,
            ).copyWith(fontWeight: FontWeight.w600, fontSize: 11),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════
//  3. LANGUAGE SHEET
// ══════════════════════════════════════════════════════════
class _LanguageSheet extends StatefulWidget {
  const _LanguageSheet();

  @override
  State<_LanguageSheet> createState() => _LanguageSheetState();
}

class _LanguageSheetState extends State<_LanguageSheet> {
  static const _kLang = 'app_language';
  String _lang = 'en';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    setState(() => _lang = p.getString(_kLang) ?? 'en');
  }

  Future<void> _select(String val) async {
    setState(() => _lang = val);
    final p = await SharedPreferences.getInstance();
    await p.setString(_kLang, val);
    // TODO: apply locale change when i18n is implemented
  }

  static const _languages = [
    {'code': 'en', 'label': 'English', 'native': 'English', 'flag': '🇬🇧'},
    {'code': 'hi', 'label': 'Hindi', 'native': 'हिंदी', 'flag': '🇮🇳'},
    {'code': '__', 'label': 'More coming soon', 'native': '', 'flag': '🌐'},
  ];

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _SheetHandle(),
        _SheetTitle('Language'),
        const SizedBox(height: 16),
        ..._languages.map((l) {
          final isDisabled = l['code'] == '__';
          final isSelected = l['code'] == _lang;
          return Opacity(
            opacity: isDisabled ? 0.4 : 1.0,
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Text(l['flag']!, style: const TextStyle(fontSize: 26)),
              title: Text(l['label']!, style: AppTextStyles.subtitle()),
              subtitle: l['native']!.isNotEmpty
                  ? Text(
                      l['native']!,
                      style: AppTextStyles.bodySM(color: AppColors.textMuted),
                    )
                  : null,
              trailing: isSelected
                  ? const Icon(
                      Icons.check_circle,
                      color: AppColors.teal,
                      size: 22,
                    )
                  : null,
              onTap: isDisabled ? null : () => _select(l['code']!),
            ),
          );
        }),
      ],
    ),
  );
}

// ══════════════════════════════════════════════════════════
//  4. SUPPORT SHEET
// ══════════════════════════════════════════════════════════
class _SupportSheet extends StatelessWidget {
  const _SupportSheet();

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _SheetHandle(),
        _SheetTitle('Support'),
        const SizedBox(height: 8),
        _SupportTile(
          emoji: '🐛',
          label: 'Report a Bug',
          sub: 'Let us know what went wrong',
          onTap: () => _launch(
            'mailto:support@seshlly.com?subject=Bug Report&body=Describe the bug here',
          ),
        ),
        _Divider(),
        _SupportTile(
          emoji: '💬',
          label: 'Contact Us',
          sub: 'Email or WhatsApp our team',
          onTap: () =>
              _launch('mailto:support@seshlly.com?subject=Help Request'),
        ),
        _Divider(),
        _SupportTile(
          emoji: '❓',
          label: 'FAQ',
          sub: 'Frequently asked questions',
          onTap: () => _launch('https://seshlly.com/faq'),
        ),
        _Divider(),
        _SupportTile(
          emoji: '⭐',
          label: 'Rate Seshlly',
          sub: 'Enjoying the app? Leave us a review!',
          onTap: () {
            // TODO: replace with actual store links
            _launch(
              'https://play.google.com/store/apps/details?id=com.seshlly.app',
            );
          },
        ),
      ],
    ),
  );
}

class _SupportTile extends StatelessWidget {
  const _SupportTile({
    required this.emoji,
    required this.label,
    required this.sub,
    required this.onTap,
  });

  final String emoji, label, sub;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: Text(emoji, style: const TextStyle(fontSize: 24)),
    title: Text(label, style: AppTextStyles.subtitle()),
    subtitle: Text(
      sub,
      style: AppTextStyles.bodySM(color: AppColors.textMuted),
    ),
    trailing: const Icon(
      Icons.open_in_new,
      color: AppColors.textMuted,
      size: 18,
    ),
    onTap: onTap,
  );
}

// ══════════════════════════════════════════════════════════
//  5. TERMS & PRIVACY SHEET
// ══════════════════════════════════════════════════════════
class _TermsSheet extends StatelessWidget {
  const _TermsSheet();

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri))
      await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _SheetHandle(),
        _SheetTitle('Terms & Privacy'),
        const SizedBox(height: 8),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Text('📋', style: TextStyle(fontSize: 24)),
          title: Text('Terms & Conditions', style: AppTextStyles.subtitle()),
          subtitle: Text(
            'Read our terms of service',
            style: AppTextStyles.bodySM(color: AppColors.textMuted),
          ),
          trailing: const Icon(
            Icons.open_in_new,
            color: AppColors.textMuted,
            size: 18,
          ),
          onTap: () => _launch('https://seshlly.com/terms'),
        ),
        _Divider(),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Text('🔐', style: TextStyle(fontSize: 24)),
          title: Text('Privacy Policy', style: AppTextStyles.subtitle()),
          subtitle: Text(
            'How we handle your data',
            style: AppTextStyles.bodySM(color: AppColors.textMuted),
          ),
          trailing: const Icon(
            Icons.open_in_new,
            color: AppColors.textMuted,
            size: 18,
          ),
          onTap: () => _launch('https://seshlly.com/privacy'),
        ),
        const SizedBox(height: 16),
        Text('App Version 1.0.0', style: AppTextStyles.caption()),
      ],
    ),
  );
}

// ══════════════════════════════════════════════════════════
//  SOS BUTTON
// ══════════════════════════════════════════════════════════
class _SOSButton extends StatelessWidget {
  const _SOSButton();

  static const _kEmergencyNumber = 'sos_emergency_number';

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => _onSOSTap(context),
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.error.withOpacity(0.35),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.12),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.error.withOpacity(0.4)),
            ),
            child: const Icon(Icons.sos, color: AppColors.error, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SOS — Emergency Call',
                style: AppTextStyles.subtitle(color: AppColors.error),
              ),
              Text(
                'Tap to call your emergency contact',
                style: AppTextStyles.bodySM(
                  color: AppColors.error.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );

  Future<void> _onSOSTap(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final savedNumber = prefs.getString(_kEmergencyNumber);

    if (savedNumber == null || savedNumber.isEmpty) {
      // No number saved — ask user to set one
      _showSetNumberDialog(context, prefs);
      return;
    }

    // Show confirmation dialog with countdown
    _showSOSConfirmDialog(context, savedNumber);
  }

  void _showSetNumberDialog(BuildContext context, SharedPreferences prefs) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Set Emergency Contact', style: AppTextStyles.h3()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Enter a phone number to call in case of emergency during workouts.',
              style: AppTextStyles.bodySM(color: AppColors.textMuted),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: ctrl,
              keyboardType: TextInputType.phone,
              style: AppTextStyles.body(),
              decoration: InputDecoration(
                hintText: '+91 9876543210',
                hintStyle: AppTextStyles.bodySM(color: AppColors.textMuted),
                filled: true,
                fillColor: AppColors.surface2,
                prefixIcon: const Icon(
                  Icons.phone,
                  color: AppColors.textMuted,
                  size: 20,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: AppTextStyles.bodySM(color: AppColors.textMuted),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () async {
              final number = ctrl.text.trim();
              if (number.isNotEmpty) {
                await prefs.setString(_kEmergencyNumber, number);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Emergency contact saved: $number'),
                      backgroundColor: AppColors.success,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            child: Text('Save', style: AppTextStyles.btn()),
          ),
        ],
      ),
    );
  }

  void _showSOSConfirmDialog(BuildContext context, String number) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _SOSCountdownDialog(number: number),
    );
  }
}

// Countdown dialog — 3 seconds before calling
class _SOSCountdownDialog extends StatefulWidget {
  const _SOSCountdownDialog({required this.number});

  final String number;

  @override
  State<_SOSCountdownDialog> createState() => _SOSCountdownDialogState();
}

class _SOSCountdownDialogState extends State<_SOSCountdownDialog> {
  int _count = 3;
  late final _timer = Stream.periodic(const Duration(seconds: 1), (i) => 2 - i)
      .take(3)
      .listen((c) {
        if (mounted) setState(() => _count = c);
        if (c == 0) _makeCall();
      });

  Future<void> _makeCall() async {
    _timer.cancel();
    if (!mounted) return;
    Navigator.of(context).pop();
    final uri = Uri.parse('tel:${widget.number}');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    backgroundColor: AppColors.surface1,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: AppColors.error.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.error, width: 2),
          ),
          child: Center(
            child: Text(
              '$_count',
              style: AppTextStyles.h1().copyWith(
                color: AppColors.error,
                fontSize: 28,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Calling Emergency Contact',
          style: AppTextStyles.h3(),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          widget.number,
          style: AppTextStyles.subtitle(color: AppColors.primary),
        ),
        const SizedBox(height: 4),
        Text(
          'Calling in $_count seconds...',
          style: AppTextStyles.bodySM(color: AppColors.textMuted),
          textAlign: TextAlign.center,
        ),
      ],
    ),
    actions: [
      SizedBox(
        width: double.infinity,
        child: TextButton(
          onPressed: () {
            _timer.cancel();
            Navigator.pop(context);
          },
          child: Text(
            'Cancel',
            style: AppTextStyles.subtitle(color: AppColors.textMuted),
          ),
        ),
      ),
    ],
  );
}

// ══════════════════════════════════════════════════════════
//  SHARED SHEET HELPERS
// ══════════════════════════════════════════════════════════
class _SheetHandle extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
    child: Container(
      width: 36,
      height: 4,
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: AppColors.border2,
        borderRadius: BorderRadius.circular(2),
      ),
    ),
  );
}

class _SheetTitle extends StatelessWidget {
  const _SheetTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: Text(title, style: AppTextStyles.h3()),
  );
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      const Divider(color: AppColors.border, height: 1);
}

class _ToggleTile extends StatelessWidget {
  const _ToggleTile({
    required this.emoji,
    required this.label,
    required this.value,
    required this.onChanged,
    this.sub,
    this.enabled = true,
  });

  final String emoji, label;
  final String? sub;
  final bool value, enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => Opacity(
    opacity: enabled ? 1.0 : 0.5,
    child: ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Text(emoji, style: const TextStyle(fontSize: 22)),
      title: Text(label, style: AppTextStyles.subtitle()),
      subtitle: sub != null
          ? Text(sub!, style: AppTextStyles.bodySM(color: AppColors.textMuted))
          : null,
      trailing: Switch(
        value: enabled ? value : false,
        onChanged: enabled ? onChanged : null,
        activeColor: AppColors.teal,
        inactiveTrackColor: AppColors.surface3,
      ),
    ),
  );
}

// ══════════════════════════════════════════════════════════
//  SUBSCRIPTION CARD
//  Shows current plan for Pro/Elite users
//  Shows upgrade CTA for Free users
// ══════════════════════════════════════════════════════════
class _SubscriptionCard extends StatelessWidget {
  const _SubscriptionCard({
    required this.plan,
    required this.onUpgrade,
    this.expiry,
  });

  final String plan;
  final DateTime? expiry;
  final VoidCallback onUpgrade;

  bool get _isPro => plan == 'pro' || plan == 'elite';

  bool get _isElite => plan == 'elite';

  String get _planLabel {
    switch (plan) {
      case 'elite':
        return '💎 Elite';
      case 'pro':
        return '⚡ Pro';
      default:
        return '🆓 Free Plan';
    }
  }

  Color get _planColor {
    switch (plan) {
      case 'elite':
        return AppColors.purple;
      case 'pro':
        return AppColors.primary;
      default:
        return AppColors.textMuted;
    }
  }

  String? get _expiryLabel {
    if (expiry == null) return null;
    final diff = expiry!.difference(DateTime.now());
    if (diff.inDays > 30)
      return 'Renews in ${(diff.inDays / 30).floor()} months';
    if (diff.inDays > 0) return 'Expires in ${diff.inDays} days';
    return 'Expired';
  }

  @override
  Widget build(BuildContext context) {
    if (_isPro) {
      // Show active plan card
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _planColor.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _planColor.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _planColor.withOpacity(0.15),
                shape: BoxShape.circle,
                border: Border.all(color: _planColor.withOpacity(0.3)),
              ),
              child: Center(
                child: Text(
                  _isElite ? '💎' : '⚡',
                  style: const TextStyle(fontSize: 22),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        _planLabel,
                        style: AppTextStyles.subtitle(color: _planColor),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.teal.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: AppColors.teal.withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          'ACTIVE',
                          style: AppTextStyles.label(
                            color: AppColors.teal,
                          ).copyWith(fontSize: 9),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _expiryLabel ?? 'Unlimited access',
                    style: AppTextStyles.bodySM(color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            // Manage button
            GestureDetector(
              onTap: onUpgrade,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: _planColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _planColor.withOpacity(0.3)),
                ),
                child: Text(
                  'Manage',
                  style: AppTextStyles.bodySM(
                    color: _planColor,
                  ).copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Free plan — show upgrade CTA
    return GestureDetector(
      onTap: onUpgrade,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: AppColors.membershipGradient,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.primary.withOpacity(0.25)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Upgrade to Pro',
                    style: AppTextStyles.subtitle(color: AppColors.primary),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Unlimited swipes & more',
                    style: AppTextStyles.bodySM(),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Text('Upgrade', style: AppTextStyles.btn()),
            ),
          ],
        ),
      ),
    );
  }
}
