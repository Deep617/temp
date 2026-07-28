// ─────────────────────────────────────────────────────────
//  GlobalLeaderboardScreen
//  /leaderboard/global
//  Weekly / Monthly / All-time tabs + city filter
// ─────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:seshlly/di_injection/dependency_injection.dart';
import 'package:seshlly/features/dashboard/challanges/data/repositories/challenge_repository.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/widgets/common/common_widgets.dart';
import '../../../../auth/presentation/bloc/auth_bloc.dart';
import '../../data/response_ml/challange_model.dart';
import '../bloc/challenge_bloc.dart';
import '../bloc/challenge_event.dart';



class GlobalLeaderboardScreen extends StatefulWidget {
  const GlobalLeaderboardScreen({super.key});

  @override
  State<GlobalLeaderboardScreen> createState() =>
      _GlobalLeaderboardScreenState();
}

class _GlobalLeaderboardScreenState extends State<GlobalLeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  List<GlobalLeaderboardEntry> _entries = [];
  bool    _loading = true;
  String  _period  = 'alltime';
  String? _city;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _tabs.addListener(() {
      if (_tabs.indexIsChanging) return;
      final periods = ['weekly', 'monthly', 'alltime'];
      setState(() => _period = periods[_tabs.index]);
      _load();
    });
    _load();
  }

  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final entries = await getIt<ChallengeRepository>().getGlobalLeaderboard(
        period: _period,
        city:   _city,
      );
      if (mounted) setState(() { _entries = entries; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final myId = context.read<AuthBloc>().state.user?.id;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.surface1,
        title: Text('Global Leaderboard', style: AppTextStyles.h3()),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            decoration: BoxDecoration(
              color: AppColors.surface2,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: TabBar(
              controller: _tabs,
              labelColor:           AppColors.primary,
              unselectedLabelColor: AppColors.textMuted,
              indicator: BoxDecoration(
                color:        AppColors.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelStyle: AppTextStyles.label(color: AppColors.primary),
              tabs: const [
                Tab(text: 'WEEKLY'),
                Tab(text: 'MONTHLY'),
                Tab(text: 'ALL-TIME'),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          _CityFilter(
            selected: _city,
            onSelect: (city) { setState(() => _city = city); _load(); },
          ),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary))
                : _entries.isEmpty
                    ? const Center(
                        child: Text('No data yet.',
                            style: TextStyle(color: AppColors.textMuted)))
                    : RefreshIndicator(
                        onRefresh: _load,
                        color: AppColors.primary,
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                          itemCount: _entries.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, i) {
                            final e = _entries[i];
                            return _GlobalLeaderRow(entry: e, isMe: e.userId == myId)
                                .animate()
                                .fadeIn(delay: Duration(milliseconds: i * 40));
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

// ── City Filter ───────────────────────────────────────────
class _CityFilter extends StatelessWidget {
  const _CityFilter({required this.selected, required this.onSelect});
  final String?            selected;
  final ValueChanged<String?> onSelect;

  @override
  Widget build(BuildContext context) {
    const cities = [
      {'id': null,          'label': 'All India'},
      {'id': 'Mumbai',      'label': 'Mumbai'},
      {'id': 'Delhi',       'label': 'Delhi'},
      {'id': 'Bangalore',   'label': 'Bangalore'},
      {'id': 'Hyderabad',   'label': 'Hyderabad'},
      {'id': 'Chennai',     'label': 'Chennai'},
      {'id': 'Pune',        'label': 'Pune'},
    ];
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: cities.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final c = cities[i];
          final isActive = selected == c['id'];
          return GestureDetector(
            onTap: () => onSelect(c['id'] as String?),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isActive
                    ? AppColors.primary.withOpacity(0.12)
                    : AppColors.surface2,
                borderRadius: BorderRadius.circular(99),
                border: Border.all(
                  color: isActive
                      ? AppColors.primary.withOpacity(0.4)
                      : AppColors.border,
                ),
              ),
              child: Text(
                c['label'] as String,
                style: AppTextStyles.label(
                  color: isActive ? AppColors.primary : AppColors.textMuted,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Leader Row ────────────────────────────────────────────
class _GlobalLeaderRow extends StatelessWidget {
  const _GlobalLeaderRow({required this.entry, required this.isMe});
  final GlobalLeaderboardEntry entry;
  final bool                   isMe;

  Color get _rankColor {
    switch (entry.rank) {
      case 1:  return AppColors.gold;
      case 2:  return AppColors.textSecondary;
      case 3:  return AppColors.orange;
      default: return AppColors.textMuted;
    }
  }

  String _activityEmoji(String? act) {
    const map = {
      'gym': '🏋️', 'powerlifting': '🏋️', 'bodybuilding': '💪',
      'running': '🏃', 'cycling': '🚴', 'swimming': '🏊',
      'hyrox': '⚡', 'crossfit': '🔥', 'boxing': '🥊',
      'mma': '🥋', 'yoga': '🧘', 'calisthenics': '🤸',
      'hiit': '💥', 'climbing': '🧗', 'rowing': '🚣',
      'triathlon': '🏊', 'tennis': '🎾', 'pilates': '🩰',
      'kettlebell': '🔔', 'dance_fit': '💃',
    };
    return map[act] ?? '⚡';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isMe
            ? AppColors.primary.withOpacity(0.06)
            : entry.rank <= 3
                ? _rankColor.withOpacity(0.05)
                : AppColors.surface2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isMe
              ? AppColors.primary.withOpacity(0.3)
              : entry.rank <= 3
                  ? _rankColor.withOpacity(0.2)
                  : AppColors.border,
          width: isMe ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text('#${entry.rank}',
                style: AppTextStyles.bodySM()
                    .copyWith(color: _rankColor, fontSize: 13)),
          ),
          AppAvatar(name: entry.displayName, imageUrl: entry.avatarUrl, size: 36),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Text(entry.displayName, style: AppTextStyles.bodySM()),
                  if (isMe) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text('You',
                          style: AppTextStyles.label(color: AppColors.primary)),
                    ),
                  ],
                ]),
                Text(
                  [
                    if (entry.primaryActivity != null)
                      '${_activityEmoji(entry.primaryActivity)} ${entry.primaryActivity}',
                    if (entry.city != null) entry.city!,
                    'Lv ${entry.level}',
                  ].join(' · '),
                  style: AppTextStyles.bodySM(color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          Text('${entry.xpTotal} XP',
              style: AppTextStyles.label(color: AppColors.warning)),
        ],
      ),
    );
  }
}
