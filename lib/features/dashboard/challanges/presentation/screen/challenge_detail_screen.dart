// ─────────────────────────────────────────────────────────
//  ChallengeDetailScreen — V2
//  Stations progress, proof feed, leaderboard, join button
// ─────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/widgets/common/common_widgets.dart';
import '../../../../auth/presentation/bloc/auth_bloc.dart';
import '../../data/response_ml/challange_model.dart';
import '../bloc/challenge_bloc.dart';
import '../bloc/challenge_event.dart';
import '../bloc/challenge_state.dart';

class ChallengeDetailScreen extends StatefulWidget {
  const ChallengeDetailScreen({super.key, required this.challengeId});

  final String challengeId;

  @override
  State<ChallengeDetailScreen> createState() => _ChallengeDetailScreenState();
}

class _ChallengeDetailScreenState extends State<ChallengeDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    context.read<ChallengeBloc>()
      ..add(ChallengeDetailLoaded(widget.challengeId))
      ..add(ChallengeFeedLoaded(widget.challengeId))
      ..add(LeaderboardLoaded(challengeId: widget.challengeId));
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ChallengeBloc, ChallengeState>(
      listenWhen: (p, c) =>
          c.successMessage != null && c.successMessage != p.successMessage ||
          c.errorMessage != null && c.errorMessage != p.errorMessage,
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
        if (state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
          context.read<ChallengeBloc>().add(const ChallengeStatusCleared());
        }
      },
      builder: (context, state) {
        final challenge = state.selectedChallenge;

        if (state.status == ChallengeStatus.loading && challenge == null) {
          return Scaffold(
            backgroundColor: AppColors.bg,
            body: const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }
        if (challenge == null) {
          return Scaffold(
            backgroundColor: AppColors.bg,
            appBar: AppBar(backgroundColor: AppColors.bg),
            body: const Center(child: Text('Challenge not found')),
          );
        }

        return Scaffold(
          backgroundColor: AppColors.bg,
          body: CustomScrollView(
            slivers: [
              _HeroHeader(challenge: challenge),
              SliverToBoxAdapter(
                child: _TabsSection(
                  controller: _tabs,
                  challenge: challenge,
                  state: state,
                ),
              ),
            ],
          ),
          bottomNavigationBar: _JoinBar(challenge: challenge, state: state),
        );
      },
    );
  }
}

// ── Hero Header ───────────────────────────────────────────
class _HeroHeader extends StatelessWidget {
  const _HeroHeader({required this.challenge});

  final Challenge challenge;

  @override
  Widget build(BuildContext context) {
    final daysLeft = challenge.daysLeft;
    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      backgroundColor: AppColors.surface1,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, size: 18),
        onPressed: () => context.pop(),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary.withOpacity(0.2),
                    AppColors.teal.withOpacity(0.1),
                  ],
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 48, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _TierBadge(tier: challenge.tier),
                        const SizedBox(width: 8),
                        _TypeBadge(type: challenge.type),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: daysLeft <= 5
                                ? AppColors.error.withOpacity(0.15)
                                : AppColors.surface3,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${daysLeft}d left',
                            style: AppTextStyles.label(
                              color: daysLeft <= 5
                                  ? AppColors.error
                                  : AppColors.textMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(challenge.title, style: AppTextStyles.h2()),
                    const SizedBox(height: 4),
                    Text(
                      challenge.description,
                      style: AppTextStyles.bodySM(
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _StatChip(
                          icon: Icons.bolt,
                          label: '${challenge.xpPool} XP',
                          color: AppColors.warning,
                        ),
                        const SizedBox(width: 8),
                        _StatChip(
                          icon: Icons.people_outline,
                          label: '${challenge.participantCount} joined',
                          color: AppColors.info,
                        ),
                        const SizedBox(width: 8),
                        _StatChip(
                          icon: Icons.grid_view,
                          label: '${challenge.stations.length} stations',
                          color: AppColors.teal,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(label, style: AppTextStyles.label(color: color)),
        ],
      ),
    );
  }
}

// ── Tabs ──────────────────────────────────────────────────
class _TabsSection extends StatelessWidget {
  const _TabsSection({
    required this.controller,
    required this.challenge,
    required this.state,
  });

  final TabController controller;
  final Challenge challenge;
  final ChallengeState state;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
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
              Tab(text: 'STATIONS'),
              Tab(text: 'FEED'),
              Tab(text: 'BOARD'),
            ],
          ),
        ),
        SizedBox(
          height: 600,
          child: TabBarView(
            controller: controller,
            children: [
              _StationsTab(challenge: challenge),
              _FeedTab(posts: state.feedPosts, loading: state.isFeedLoading),
              _LeaderboardTab(entries: state.leaderboard),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Stations Tab ──────────────────────────────────────────
class _StationsTab extends StatelessWidget {
  const _StationsTab({required this.challenge});

  final Challenge challenge;

  @override
  Widget build(BuildContext context) {
    final completedNums =
        challenge.myEntry?.completions.map((c) => c.stationNum).toSet() ?? {};

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      itemCount: challenge.stations.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final station = challenge.stations[i];
        final done = completedNums.contains(station.stationNum);
        final isCurrent =
            station.stationNum == (challenge.myEntry?.currentStation ?? 1);
        return _StationCard(
          station: station,
          isDone: done,
          isCurrent: isCurrent && !done,
        ).animate().fadeIn(delay: Duration(milliseconds: i * 50));
      },
    );
  }
}

class _StationCard extends StatelessWidget {
  const _StationCard({
    required this.station,
    required this.isDone,
    required this.isCurrent,
  });

  final ChallengeStation station;
  final bool isDone;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    Color borderColor = AppColors.border;
    Color numColor = AppColors.textMuted;
    Color numBg = AppColors.surface3;

    if (isDone) {
      borderColor = AppColors.success.withOpacity(0.4);
      numColor = AppColors.success;
      numBg = AppColors.success.withOpacity(0.1);
    } else if (isCurrent) {
      borderColor = AppColors.primary.withOpacity(0.4);
      numColor = AppColors.primary;
      numBg = AppColors.primary.withOpacity(0.1);
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Station number
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: numBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: borderColor),
            ),
            alignment: Alignment.center,
            child: isDone
                ? Icon(Icons.check, size: 18, color: AppColors.success)
                : Text(
                    'S${station.stationNum}',
                    style: AppTextStyles.label(color: numColor),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        station.title,
                        style: AppTextStyles.caption(),
                      ),
                    ),
                    Text(
                      '+${station.xpReward} XP',
                      style: AppTextStyles.label(color: AppColors.warning),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  station.description,
                  style: AppTextStyles.bodySM(color: AppColors.textMuted),
                ),
                if (station.buddyRequired) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.people_outline,
                        size: 12,
                        color: AppColors.teal,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Buddy required',
                        style: AppTextStyles.label(color: AppColors.teal),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Feed Tab ──────────────────────────────────────────────
class _FeedTab extends StatelessWidget {
  const _FeedTab({required this.posts, required this.loading});

  final List<ChallengeFeedPost> posts;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    if (loading && posts.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }
    if (posts.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: Text(
            'No proof posts yet.\nBe the first to upload.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textMuted),
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      itemCount: posts.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final post = posts[i];
        return _FeedPostCard(
          post: post,
        ).animate().fadeIn(delay: Duration(milliseconds: i * 50));
      },
    );
  }
}

class _FeedPostCard extends StatelessWidget {
  const _FeedPostCard({required this.post});

  final ChallengeFeedPost post;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: post.isCollab
            ? AppColors.primary.withOpacity(0.04)
            : AppColors.surface2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: post.isCollab
              ? AppColors.primary.withOpacity(0.2)
              : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar + name row
          Row(
            children: [
              AppAvatar(
                name: post.displayName,
                imageUrl: post.avatarUrl,
                size: 36,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.isCollab
                          ? '${post.displayName} + ${post.collabUserName ?? "buddy"}'
                          : post.displayName,
                      style: AppTextStyles.caption(),
                    ),
                    Text(
                      'S${post.stationNum} · ${post.stationTitle}',
                      style: AppTextStyles.bodySM(color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '+${post.xpAwarded} XP',
                    style: AppTextStyles.label(color: AppColors.warning),
                  ),
                  Text(
                    DateFormat('d MMM').format(post.postedAt),
                    style: AppTextStyles.label(color: AppColors.textMuted),
                  ),
                ],
              ),
            ],
          ),
          if (post.proofImageUrl != null) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.network(
                  post.proofImageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: AppColors.surface3,
                    child: const Icon(
                      Icons.image_not_supported,
                      color: AppColors.textDim,
                    ),
                  ),
                ),
              ),
            ),
          ],
          if (post.isCollab) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 12,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Collab',
                    style: AppTextStyles.label(color: AppColors.primary),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Leaderboard Tab ───────────────────────────────────────
class _LeaderboardTab extends StatelessWidget {
  const _LeaderboardTab({required this.entries});

  final List<LeaderboardEntry> entries;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: Text(
            'Leaderboard loading...',
            style: TextStyle(color: AppColors.textMuted),
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      itemCount: entries.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final entry = entries[i];
        return _LeaderRow(
          entry: entry,
        ).animate().fadeIn(delay: Duration(milliseconds: i * 40));
      },
    );
  }
}

class _LeaderRow extends StatelessWidget {
  const _LeaderRow({required this.entry});

  final LeaderboardEntry entry;

  Color get _rankColor {
    switch (entry.rank) {
      case 1:
        return AppColors.gold;
      case 2:
        return AppColors.textSecondary;
      case 3:
        return AppColors.orange;
      default:
        return AppColors.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: entry.rank <= 3
            ? _rankColor.withOpacity(0.05)
            : AppColors.surface2,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: entry.rank <= 3
              ? _rankColor.withOpacity(0.2)
              : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              '#${entry.rank}',
              style: AppTextStyles.caption().copyWith(
                color: _rankColor,
                fontSize: 13,
              ),
            ),
          ),
          AppAvatar(
            name: entry.displayName,
            imageUrl: entry.avatarUrl,
            size: 34,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.displayName, style: AppTextStyles.caption()),
                if (entry.buddyName != null)
                  Text(
                    '+ ${entry.buddyName}',
                    style: AppTextStyles.label(color: AppColors.teal),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${entry.xpEarned} XP',
                style: AppTextStyles.label(color: AppColors.warning),
              ),
              Text(
                '${entry.stationsCompleted} stations',
                style: AppTextStyles.label(color: AppColors.textMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Join / Enrolled Bar ───────────────────────────────────
class _JoinBar extends StatelessWidget {
  const _JoinBar({required this.challenge, required this.state});

  final Challenge challenge;
  final ChallengeState state;

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthBloc>().state.user;

    if (challenge.isEnrolled) {
      return Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        decoration: BoxDecoration(
          color: AppColors.surface1,
          border: const Border(top: BorderSide(color: AppColors.border)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'In progress',
                    style: AppTextStyles.label(color: AppColors.success),
                  ),
                  Text(
                    '${challenge.myEntry?.completions.length ?? 0} / ${challenge.stations.length} stations done',
                    style: AppTextStyles.caption(),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.success.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, size: 16, color: AppColors.success),
                  const SizedBox(width: 6),
                  Text(
                    'Enrolled',
                    style: AppTextStyles.caption().copyWith(
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Check level gating
    final userLevel = user?.level ?? 1;
    final locked = userLevel < challenge.entryLevelRequired;
    final trustLocked = (user?.trustScore ?? 50) < challenge.trustRequired;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: BoxDecoration(
        color: AppColors.surface1,
        border: const Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (locked || trustLocked)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                locked
                    ? 'Requires Level ${challenge.entryLevelRequired}'
                    : 'Requires Trust Score ${challenge.trustRequired}+',
                style: AppTextStyles.bodySM(color: AppColors.error),
                textAlign: TextAlign.center,
              ),
            ),
          Row(
            children: [
              Expanded(
                child: PrimaryButton(
                  label: state.isJoining ? 'Joining...' : 'Join Solo',
                  onPressed: (locked || trustLocked || state.isJoining)
                      ? null
                      : () => context.read<ChallengeBloc>().add(
                          ChallengeJoined(challenge.id),
                        ),
                  loading: state.isJoining,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GhostButton(
                  label: 'Invite Buddy',
                  // variant: AppButtonVariant.secondary,
                  onPressed: (locked || trustLocked)
                      ? null
                      : () => _showBuddyPicker(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showBuddyPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface1,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => BlocProvider.value(
        value: context.read<ChallengeBloc>(),
        child: _BuddyPickerSheet(challengeId: challenge.id),
      ),
    );
  }
}

class _BuddyPickerSheet extends StatelessWidget {
  const _BuddyPickerSheet({required this.challengeId});

  final String challengeId;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Challenge with a buddy', style: AppTextStyles.h3()),
          const SizedBox(height: 6),
          Text(
            'Enter your buddy\'s user ID, or go to their profile and tap "Challenge together."',
            style: AppTextStyles.bodySM(color: AppColors.textMuted),
          ),
          const SizedBox(height: 20),
          AppInput(
            label: 'Buddy User ID',
            hint: 'e.g. usr_abc123',
            onChanged: (_) {},
          ),
          const SizedBox(height: 16),
          PrimaryButton(
            label: 'Send Challenge Invite',
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}

// ── Tier / Type badges ────────────────────────────────────
class _TierBadge extends StatelessWidget {
  const _TierBadge({required this.tier});

  final int tier;

  static const _labels = {1: 'OPEN', 2: 'CONTENDER', 3: 'ELITE', 4: 'GOAT'};
  static const _colors = {
    1: AppColors.textMuted,
    2: AppColors.primary,
    3: AppColors.teal,
    4: AppColors.gold,
  };

  @override
  Widget build(BuildContext context) {
    final color = _colors[tier] ?? AppColors.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        _labels[tier] ?? 'TIER $tier',
        style: AppTextStyles.label(color: color),
      ),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  const _TypeBadge({required this.type});

  final String type;

  static const _labels = {
    'solo': 'Solo Sprint',
    'duel': 'Buddy Duel',
    'pack': 'Pack Event',
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.surface3,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        _labels[type] ?? type,
        style: AppTextStyles.label(color: AppColors.textMuted),
      ),
    );
  }
}
