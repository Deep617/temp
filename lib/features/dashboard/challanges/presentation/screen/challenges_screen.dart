// ─────────────────────────────────────────────────────────
//  ChallengesScreen — V2
//  lib/presentation/screens/challenges/challenges_screen.dart
//
//  The Challenges Tab (5th bottom nav item).
//  Shows:
//   - Active Pack Event (hero card)
//   - My active entries with station progress
//   - Browse all challenges by tier
// ─────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../routes/app_router.dart';
import '../../../../auth/presentation/bloc/auth_bloc.dart';
import '../../data/response_ml/challange_model.dart';
import '../bloc/challenge_bloc.dart';
import '../bloc/challenge_event.dart';
import '../bloc/challenge_state.dart';

class ChallengesScreen extends StatefulWidget {
  const ChallengesScreen({super.key});
  @override
  State<ChallengesScreen> createState() => _ChallengesScreenState();
}

class _ChallengesScreenState extends State<ChallengesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  String? _environment; // null = All

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    // Smart default — set environment based on user's primary activity
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthBloc>().state.user;
      final env  = _envForActivity(user?.primaryActivity);
      setState(() => _environment = env);
      _loadChallenges(env);
    });
  }

  /// Map primary activity → default environment filter
  String? _envForActivity(String? activity) {
    if (activity == null) return null;
    const gymActivities = ['gym', 'powerlifting', 'bodybuilding', 'kettlebell'];
    const outdoorActivities = ['running', 'cycling', 'triathlon', 'rowing'];
    const noGymActivities = ['hiit', 'calisthenics', 'yoga', 'pilates', 'mma', 'boxing'];
    if (gymActivities.contains(activity))    return 'gym';
    if (outdoorActivities.contains(activity)) return 'outdoor';
    if (noGymActivities.contains(activity))  return 'no_gym';
    return null; // hyrox, crossfit, climbing, tennis, dance_fit → show all
  }

  void _loadChallenges(String? env) {
    context.read<ChallengeBloc>()
      ..add(ChallengesLoaded(environment: env))
      ..add(const MyChallengesLoaded());
  }

  void _onFilterTap(String? env) {
    setState(() => _environment = env);
    context.read<ChallengeBloc>().add(ChallengesLoaded(environment: env));
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ChallengeBloc, ChallengeState>(
      listenWhen: (p, c) =>
      c.successMessage != null && c.successMessage != p.successMessage,
      listener: (context, state) {
        if (state.successMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.successMessage!),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
          context.read<ChallengeBloc>().add(const ChallengeStatusCleared());
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.bg,
        body: SafeArea(
          child: Column(
            children: [
              _Header(),
              _TierTabs(controller: _tabs),
              // Environment filter chips
              _EnvironmentFilter(
                selected:  _environment,
                onSelect:  _onFilterTap,
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabs,
                  children: [
                    _ChallengesList(tier: null),
                    _ChallengesList(tier: 1),
                    _MyEntriesTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────
class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthBloc>().state.user;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Seshlly Hyrox',
                    style: AppTextStyles.h2()),
                Text(
                  'Level ${user?.level ?? 1} · ${user?.xpTotal ?? 0} XP total',
                  style: AppTextStyles.bodySM(color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          // XP badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.bolt, size: 14, color: Colors.white),
                const SizedBox(width: 4),
                Text(
                  '${user?.xpTotal ?? 0} XP',
                  style: AppTextStyles.label(color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Environment Filter ────────────────────────────────────
class _EnvironmentFilter extends StatelessWidget {
  const _EnvironmentFilter({required this.selected, required this.onSelect});
  final String?                    selected;
  final ValueChanged<String?> onSelect;

  static const _filters = [
    {'id': null,       'label': 'All',        'emoji': '⚡'},
    {'id': 'gym',      'label': 'Gym',        'emoji': '🏋️'},
    {'id': 'outdoor',  'label': 'Outdoor',    'emoji': '🌿'},
    {'id': 'no_gym',   'label': 'No Gym',     'emoji': '🤸'},
    {'id': 'any',      'label': 'Any',        'emoji': '⭐'},
  ];

  Color _color(String? id) {
    switch (id) {
      case 'gym':     return AppColors.primary;
      case 'outdoor': return AppColors.teal;
      case 'no_gym':  return AppColors.purple;
      case 'any':     return AppColors.warning;
      default:        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection:  Axis.horizontal,
        padding:          const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        itemCount:        _filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final f        = _filters[i];
          final fid      = f['id'] as String?;
          final isActive = selected == fid;
          final color    = _color(fid);
          return GestureDetector(
            onTap: () => onSelect(fid),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: isActive
                    ? color.withOpacity(0.12)
                    : AppColors.surface2,
                borderRadius: BorderRadius.circular(99),
                border: Border.all(
                  color: isActive
                      ? color.withOpacity(0.45)
                      : AppColors.border,
                  width: isActive ? 1.5 : 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(f['emoji'] as String,
                      style: const TextStyle(fontSize: 12)),
                  const SizedBox(width: 5),
                  Text(
                    f['label'] as String,
                    style: AppTextStyles.label(
                      color: isActive ? color : AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Tier Tabs ─────────────────────────────────────────────
class _TierTabs extends StatelessWidget {
  const _TierTabs({required this.controller});
  final TabController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: TabBar(
        controller: controller,
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textMuted,
        indicator: BoxDecoration(
          color: AppColors.primary.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelStyle: AppTextStyles.label(color: AppColors.primary),
        tabs: const [
          Tab(text: 'ALL'),
          Tab(text: 'OPEN'),
          Tab(text: 'MY ACTIVE'),
        ],
      ),
    );
  }
}

// ── Challenges List ───────────────────────────────────────
class _ChallengesList extends StatelessWidget {
  const _ChallengesList({this.tier});
  final int? tier;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ChallengeBloc, ChallengeState>(
      builder: (context, state) {
        if (state.status == ChallengeStatus.loading &&
            state.challenges.isEmpty) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.primary));
        }

        final list = tier == null
            ? state.challenges
            : state.challenges.where((c) => c.tier == tier).toList();

        if (list.isEmpty) {
          return _EmptyState(
            icon: Icons.emoji_events_outlined,
            title: 'No challenges yet',
            subtitle: 'Check back soon for new Pack Events.',
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
          itemCount: list.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, i) {
            final c = list[i];
            return _ChallengeCard(challenge: c)
                .animate()
                .fadeIn(delay: Duration(milliseconds: i * 60))
                .slideY(begin: 0.1, end: 0);
          },
        );
      },
    );
  }
}

// ── Challenge Card ────────────────────────────────────────
class _ChallengeCard extends StatelessWidget {
  const _ChallengeCard({required this.challenge});
  final Challenge challenge;

  Color get _tierColor {
    switch (challenge.tier) {
      case 1: return AppColors.textMuted;
      case 2: return AppColors.primary;
      case 3: return AppColors.teal;
      case 4: return AppColors.gold;
      default: return AppColors.primary;
    }
  }

  String get _tierLabel {
    switch (challenge.tier) {
      case 1: return 'OPEN';
      case 2: return 'CONTENDER';
      case 3: return 'ELITE';
      case 4: return 'GOAT';
      default: return 'OPEN';
    }
  }

  String get _typeLabel {
    switch (challenge.type) {
      case 'solo':  return 'Solo Sprint';
      case 'duel':  return 'Buddy Duel';
      case 'pack':  return 'Pack Event';
      default:      return challenge.type;
    }
  }

  @override
  Widget build(BuildContext context) {
    final enrolled = challenge.isEnrolled;
    final progress = challenge.progressPercent;

    return GestureDetector(
      onTap: () => context.push('/challenges/\${challenge.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface2,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: enrolled
                ? AppColors.primary.withOpacity(0.4)
                : AppColors.border,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top bar with tier badge
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              decoration: BoxDecoration(
                color: _tierColor.withOpacity(0.06),
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _tierColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                          color: _tierColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      _tierLabel,
                      style: AppTextStyles.label(color: _tierColor),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.surface3,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _typeLabel,
                      style: AppTextStyles.label(
                          color: AppColors.textMuted),
                    ),
                  ),
                  const Spacer(),
                  if (enrolled)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle,
                              size: 11, color: AppColors.success),
                          const SizedBox(width: 4),
                          Text('Enrolled',
                              style: AppTextStyles.label(
                                  color: AppColors.success)),
                        ],
                      ),
                    ),
                  // Days left
                  if (!enrolled) ...[
                    Icon(Icons.schedule,
                        size: 12, color: AppColors.textMuted),
                    const SizedBox(width: 4),
                    Text(
                      '${challenge.daysLeft}d left',
                      style: AppTextStyles.label(
                          color: AppColors.textMuted),
                    ),
                  ],
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(challenge.title, style: AppTextStyles.h3()),
                  const SizedBox(height: 4),
                  Text(
                    challenge.description,
                    style: AppTextStyles.bodySM(
                        color: AppColors.textMuted),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  // Environment tag — color coded
                  _EnvironmentTag(environment: challenge.environment),
                  const SizedBox(height: 10),

                  // Stats row
                  Row(
                    children: [
                      _Stat(
                        icon: Icons.bolt,
                        value: '${challenge.xpPool}',
                        label: 'XP Pool',
                        color: AppColors.warning,
                      ),
                      const SizedBox(width: 16),
                      _Stat(
                        icon: Icons.people_outline,
                        value: '${challenge.participantCount}',
                        label: 'Joined',
                        color: AppColors.info,
                      ),
                      const SizedBox(width: 16),
                      _Stat(
                        icon: Icons.grid_view,
                        value: '${challenge.stations.length}',
                        label: 'Stations',
                        color: AppColors.teal,
                      ),
                      if (enrolled) ...[
                        const SizedBox(width: 16),
                        _Stat(
                          icon: Icons.schedule,
                          value: '${challenge.daysLeft}d',
                          label: 'Left',
                          color: challenge.daysLeft <= 5
                              ? AppColors.error
                              : AppColors.textMuted,
                        ),
                      ],
                    ],
                  ),

                  // Progress bar if enrolled
                  if (enrolled) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Text(
                          '${challenge.myEntry!.completions.length}/${challenge.stations.length} stations',
                          style: AppTextStyles.label(
                              color: AppColors.textMuted),
                        ),
                        const Spacer(),
                        Text(
                          '${(progress * 100).toInt()}%',
                          style: AppTextStyles.label(
                              color: AppColors.primary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: AppColors.surface3,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          progress >= 1.0
                              ? AppColors.success
                              : AppColors.primary,
                        ),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Environment Tag ───────────────────────────────────────
class _EnvironmentTag extends StatelessWidget {
  const _EnvironmentTag({required this.environment});
  final String environment;

  _EnvMeta get _meta {
    switch (environment) {
      case 'gym':
        return _EnvMeta('🏋️ Gym only', AppColors.primary);
      case 'outdoor':
        return _EnvMeta('🌿 Outdoor', AppColors.teal);
      case 'no_gym':
        return _EnvMeta('🤸 No gym needed', AppColors.purple);
      default:
        return _EnvMeta('⭐ Any activity', AppColors.warning);
    }
  }

  @override
  Widget build(BuildContext context) {
    final m = _meta;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color:        m.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border:       Border.all(color: m.color.withOpacity(0.25)),
      ),
      child: Text(m.label, style: AppTextStyles.label(color: m.color)),
    );
  }
}

class _EnvMeta {
  const _EnvMeta(this.label, this.color);
  final String label;
  final Color  color;
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });
  final IconData icon;
  final String   value;
  final String   label;
  final Color    color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value,
                style: AppTextStyles.label(color: AppColors.textPrimary)),
            Text(label,
                style: AppTextStyles.label(color: AppColors.textMuted)
                    .copyWith(fontSize: 9)),
          ],
        ),
      ],
    );
  }
}

// ── My Entries Tab ────────────────────────────────────────
class _MyEntriesTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ChallengeBloc, ChallengeState>(
      builder: (context, state) {
        if (state.myEntries.isEmpty) {
          return _EmptyState(
            icon: Icons.emoji_events_outlined,
            title: 'No active challenges',
            subtitle:
            'Join a Pack Event or Solo Sprint to start earning XP.',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
          itemCount: state.myEntries.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, i) {
            final entry = state.myEntries[i];
            // Find matching challenge
            final challenge = state.challenges
                .where((c) => c.id == entry.challengeId)
                .firstOrNull;
            return _MyEntryCard(entry: entry, challenge: challenge)
                .animate()
                .fadeIn(delay: Duration(milliseconds: i * 60));
          },
        );
      },
    );
  }
}

class _MyEntryCard extends StatelessWidget {
  const _MyEntryCard({required this.entry, this.challenge});
  final ChallengeEntry entry;
  final Challenge?     challenge;

  @override
  Widget build(BuildContext context) {
    final stationsDone = entry.completions.length;
    final stationsTotal = challenge?.stations.length ?? 8;
    final progress = stationsTotal > 0
        ? stationsDone / stationsTotal
        : 0.0;

    return GestureDetector(
      onTap: () => context.push('/challenges/\${entry.challengeId}'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface2,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary.withOpacity(0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    challenge?.title ?? 'Challenge',
                    style: AppTextStyles.bodySM(),
                  ),
                ),
                Text(
                  '+${entry.totalXpEarned} XP',
                  style: AppTextStyles.label(color: AppColors.warning),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  '$stationsDone / $stationsTotal stations complete',
                  style: AppTextStyles.bodySM(color: AppColors.textMuted),
                ),
                const Spacer(),
                if (challenge != null)
                  Text(
                    '${challenge!.daysLeft}d left',
                    style: AppTextStyles.label(
                      color: challenge!.daysLeft <= 5
                          ? AppColors.error
                          : AppColors.textMuted,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: AppColors.surface3,
                valueColor: AlwaysStoppedAnimation<Color>(
                  progress >= 1.0 ? AppColors.success : AppColors.primary,
                ),
                minHeight: 6,
              ),
            ),
            if (entry.buddyId != null) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.people_outline,
                      size: 13, color: AppColors.teal),
                  const SizedBox(width: 4),
                  Text(
                    'Buddy challenge',
                    style: AppTextStyles.label(color: AppColors.teal),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Empty State ───────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
  final IconData icon;
  final String   title;
  final String   subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 56, color: AppColors.textDim),
            const SizedBox(height: 16),
            Text(title,
                style: AppTextStyles.h3(),
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(subtitle,
                style: AppTextStyles.bodySM(color: AppColors.textMuted),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}