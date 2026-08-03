// ─────────────────────────────────────────────────────────
//  leaderboard_screen.dart
//  Clickable leaderboard — Global + City filters
//  Auto-shuffles animation every 30s
//  Tap row → buddy profile
// ─────────────────────────────────────────────────────────
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/common/common_widgets.dart';
import '../../../../di_injection/dependency_injection.dart';
import '../../../../routes/app_router.dart';
import '../../../auth/data/response_ml/register_response.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../dashboard/challanges/data/repositories/challenge_repository.dart';
import '../../../dashboard/challanges/data/response_ml/challange_model.dart';



class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});
  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  List<GlobalLeaderboardEntry> _entries = [];
  bool    _loading = true;
  String  _period  = 'alltime'; // weekly | monthly | alltime
  String? _cityFilter;          // null = global
  Timer?  _shuffleTimer;
  bool    _shuffling = false;

  final _periods = [
    ('weekly',  'This Week'),
    ('monthly', 'This Month'),
    ('alltime', 'All-time'),
  ];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _tabs.addListener(() {
      if (!_tabs.indexIsChanging) {
        setState(() => _period = _periods[_tabs.index].$1);
        _load();
      }
    });
    _load();
    // Auto-shuffle every 30 seconds — subtle animation
    _shuffleTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _triggerShuffle();
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    _shuffleTimer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final challengeRepository = getIt<ChallengeRepository>();
      final entries = await challengeRepository.getGlobalLeaderboard(
        period: _period,
        city:   _cityFilter,
      );
      if (mounted) setState(() { _entries = entries; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _triggerShuffle() {
    if (!mounted || _entries.isEmpty) return;
    setState(() => _shuffling = true);
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) setState(() => _shuffling = false);
    });
  }

  // My rank in current list
  String? get _myRank {
    final me = context.read<AuthBloc>().state.user;
    if (me == null) return null;
    try {
      final e = _entries.firstWhere((e) => e.userId == me.id);
      return '#${e.rank}';
    } catch (_) { return null; }
  }

  @override
  Widget build(BuildContext context) {
    final me = context.read<AuthBloc>().state.user;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(children: [

          // ── Header ─────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Leaderboard', style: AppTextStyles.h2()),
                    if (_myRank != null)
                      Text('Your rank: $_myRank',
                          style: AppTextStyles.bodySM(
                              color: AppColors.primary)),
                  ],
                ),
              ),
              // City filter chip
              GestureDetector(
                onTap: () => _showCityFilter(),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color:        _cityFilter != null
                        ? AppColors.primary.withOpacity(0.12)
                        : AppColors.surface2,
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(
                      color: _cityFilter != null
                          ? AppColors.primary.withOpacity(0.4)
                          : AppColors.border2,
                    ),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(
                      _cityFilter != null
                          ? Icons.location_on
                          : Icons.public,
                      size:  14,
                      color: _cityFilter != null
                          ? AppColors.primary
                          : AppColors.textMuted,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      _cityFilter ?? 'Global',
                      style: AppTextStyles.bodySM(
                        color: _cityFilter != null
                            ? AppColors.primary
                            : AppColors.textMuted,
                      ).copyWith(fontWeight: FontWeight.w700),
                    ),
                    if (_cityFilter != null) ...[
                      const SizedBox(width: 5),
                      GestureDetector(
                        onTap: () {
                          setState(() => _cityFilter = null);
                          _load();
                        },
                        child: const Icon(Icons.close,
                            size: 13, color: AppColors.primary),
                      ),
                    ],
                  ]),
                ),
              ),
            ]),
          ),

          const SizedBox(height: 12),

          // ── Period tabs ────────────────────────────────
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color:        AppColors.surface1,
              borderRadius: BorderRadius.circular(12),
              border:       Border.all(color: AppColors.border),
            ),
            child: TabBar(
              controller:         _tabs,
              indicatorSize:      TabBarIndicatorSize.tab,
              indicator:          BoxDecoration(
                color:        AppColors.primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: AppColors.primary.withOpacity(0.3)),
              ),
              dividerColor:       Colors.transparent,
              labelColor:         AppColors.primary,
              unselectedLabelColor: AppColors.textMuted,
              labelStyle:    AppTextStyles.bodySM()
                  .copyWith(fontWeight: FontWeight.w700),
              unselectedLabelStyle: AppTextStyles.bodySM(),
              tabs: _periods
                  .map((p) => Tab(text: p.$2))
                  .toList(),
            ),
          ),

          const SizedBox(height: 10),

          // ── Top 3 podium ───────────────────────────────
          if (!_loading && _entries.length >= 3)
            _Podium(entries: _entries.take(3).toList(), me: me)
                .animate().fadeIn(duration: 400.ms),

          const SizedBox(height: 8),

          // ── Full list ──────────────────────────────────
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(
                    color: AppColors.primary))
                : _entries.isEmpty
                    ? Center(
                        child: Text(
                          'No entries yet — complete sessions to appear!',
                          style: AppTextStyles.bodySM(
                              color: AppColors.textMuted),
                          textAlign: TextAlign.center,
                        ))
                    : RefreshIndicator(
                        color:    AppColors.primary,
                        onRefresh: _load,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(
                              16, 0, 16, 80),
                          itemCount: _entries.length,
                          itemBuilder: (_, i) {
                            final e  = _entries[i];
                            final isMe = e.userId == me?.id;
                            return _LeaderboardRow(
                              entry:     e,
                              isMe:      isMe,
                              shuffling: _shuffling,
                              onTap:     isMe
                                  ? null
                                  : () => context.push(
                                      AppRoutes.buddyProfile
                                          .replaceAll(':userId', e.userId)),
                            ).animate(
                              delay: Duration(milliseconds: i * 30),
                            ).fadeIn(duration: 300.ms);
                          },
                        ),
                      ),
          ),
        ]),
      ),
    );
  }

  void _showCityFilter() {
    final user = context.read<AuthBloc>().state.user;
    final cities = <String?>[null];
    if (user?.city != null) cities.insert(1, user!.city);
    // Collect unique cities from entries
    for (final e in _entries) {
      if (e.city != null && !cities.contains(e.city)) cities.add(e.city);
    }

    showModalBottomSheet(
      context:         context,
      backgroundColor: AppColors.surface1,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 36, height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: AppColors.border2,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Text('Filter by Location', style: AppTextStyles.h3()),
          const SizedBox(height: 16),
          ...cities.map((city) => ListTile(
            leading: Icon(
              city == null ? Icons.public : Icons.location_on,
              color: _cityFilter == city
                  ? AppColors.primary
                  : AppColors.textMuted,
            ),
            title: Text(city ?? 'Global',
                style: AppTextStyles.subtitle(
                  color: _cityFilter == city
                      ? AppColors.primary
                      : AppColors.textPrimary,
                )),
            trailing: _cityFilter == city
                ? const Icon(Icons.check_circle,
                    color: AppColors.primary, size: 20)
                : null,
            onTap: () {
              Navigator.pop(context);
              setState(() => _cityFilter = city);
              _load();
            },
          )),
        ]),
      ),
    );
  }
}

// ── Podium — Top 3 ───────────────────────────────────────
class _Podium extends StatelessWidget {
  const _Podium({required this.entries, required this.me});
  final List<GlobalLeaderboardEntry> entries;
  final UserModel? me;

  @override
  Widget build(BuildContext context) {
    final first  = entries[0];
    final second = entries[1];
    final third  = entries[2];

    return IntrinsicHeight(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 2nd
          _PodiumItem(entry: second, height: 80,  medal: '🥈',
              isMe: second.userId == me?.id,
              onTap: () => context.push(
                  AppRoutes.buddyProfile.replaceAll(':userId', second.userId))),
          const SizedBox(width: 8),
          // 1st
          _PodiumItem(entry: first,  height: 110, medal: '🥇',
              isMe: first.userId == me?.id,
              onTap: () => context.push(
                  AppRoutes.buddyProfile.replaceAll(':userId', first.userId))),
          const SizedBox(width: 8),
          // 3rd
          _PodiumItem(entry: third,  height: 65,  medal: '🥉',
              isMe: third.userId == me?.id,
              onTap: () => context.push(
                  AppRoutes.buddyProfile.replaceAll(':userId', third.userId))),
        ],
      ),
    );
  }
}

class _PodiumItem extends StatelessWidget {
  const _PodiumItem({
    required this.entry,
    required this.height,
    required this.medal,
    required this.isMe,
    required this.onTap,
  });
  final GlobalLeaderboardEntry entry;
  final double height;
  final String medal;
  final bool   isMe;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: SizedBox(
      width: 90,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(medal, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 4),
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isMe
                    ? AppColors.teal
                    : AppColors.border2,
                width: isMe ? 2 : 1,
              ),
            ),
            child: AppAvatar(
              name:     entry.displayName,
              imageUrl: entry.avatarUrl,
              size:     42,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            entry.displayName.split(' ').first,
            style: AppTextStyles.bodySM(
                color: isMe ? AppColors.teal : AppColors.textPrimary)
                .copyWith(fontWeight: FontWeight.w700),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text('${entry.xpTotal} XP',
              style: AppTextStyles.caption()),
          Container(
            width: double.infinity,
            height: height,
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color:        isMe
                  ? AppColors.teal.withOpacity(0.1)
                  : AppColors.surface1,
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(8)),
              border: Border.all(
                  color: isMe
                      ? AppColors.teal.withOpacity(0.3)
                      : AppColors.border),
            ),
          ),
        ],
      ),
    ),
  );
}

// ── Leaderboard Row ───────────────────────────────────────
class _LeaderboardRow extends StatelessWidget {
  const _LeaderboardRow({
    required this.entry,
    required this.isMe,
    required this.shuffling,
    required this.onTap,
  });
  final GlobalLeaderboardEntry entry;
  final bool         isMe, shuffling;
  final VoidCallback? onTap;

  Color get _rankColor {
    switch (entry.rank) {
      case 1:  return AppColors.warning;
      case 2:  return const Color(0xFFC0C0C0);
      case 3:  return const Color(0xFFCD7F32);
      default: return AppColors.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: const Duration(milliseconds: 600),
    curve:    Curves.easeInOut,
    margin: const EdgeInsets.only(bottom: 6),
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color:        isMe
              ? AppColors.primary.withOpacity(0.08)
              : AppColors.surface1,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isMe
                ? AppColors.primary.withOpacity(0.3)
                : AppColors.border,
            width: isMe ? 1.5 : 1,
          ),
        ),
        child: Row(children: [
          // Rank
          SizedBox(
            width: 32,
            child: Text(
              '#${entry.rank}',
              style: AppTextStyles.subtitle(color: _rankColor),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 10),
          // Avatar
          AppAvatar(
            name:     entry.displayName,
            imageUrl: entry.avatarUrl,
            size:     38,
          ),
          const SizedBox(width: 10),
          // Name + city
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Flexible(
                  child: Text(
                    isMe ? '${entry.displayName} (You)' : entry.displayName,
                    style: AppTextStyles.bodySM(),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ]),
              if (entry.city != null)
                Text('📍 ${entry.city}',
                    style: AppTextStyles.bodySM(
                        color: AppColors.textMuted)),
            ],
          )),
          // XP + level
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('${entry.xpTotal} XP',
                style: AppTextStyles.subtitle(color: AppColors.warning)),
            Text('Lv ${entry.level}',
                style: AppTextStyles.caption()),
          ]),
          if (onTap != null) ...[
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right,
                color: AppColors.textMuted, size: 18),
          ],
        ]),
      ),
    ),
  );
}
