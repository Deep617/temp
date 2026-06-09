import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/widgets/common/common_widgets.dart';
import '../../../../../routes/app_router.dart';
import '../../../discover/data/response_ml/buddy_profile.dart';
import '../bloc/profile_bloc.dart';
import '../bloc/profile_event.dart';
import '../bloc/profile_state.dart';

class BuddyProfileScreen extends StatefulWidget {
  const BuddyProfileScreen({super.key, required this.userId});
  final String userId;
  @override
  State<BuddyProfileScreen> createState() => _BuddyProfileScreenState();
}

class _BuddyProfileScreenState extends State<BuddyProfileScreen> {
  @override
  void initState() {
    super.initState();
    context.read<ProfileBloc>().add(BuddyProfileLoaded(userId: widget.userId));
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileBloc, ProfileState>(
      builder: (context, state) {
        if (state.isLoading || state.buddyProfile == null) {
          return Scaffold(
            backgroundColor: AppColors.bg,
            body: state.error != null
                ? Center(child: Text(state.error!.message, style: AppTextStyles.body()))
                : const Center(child: CircularProgressIndicator(color: AppColors.primary)),
          );
        }

        final p = state.buddyProfile!;
        final actColor = p.primaryActivity != null
            ? Color(AppConstants.activities.firstWhere(
                (a) => a['id'] == p.primaryActivity,
                orElse: () => {'color': 0xFFBAEE0B})['color'] as int)
            : AppColors.primary;

        return Scaffold(
          backgroundColor: AppColors.bg,
          body: CustomScrollView(slivers: [
            SliverAppBar(
              expandedHeight: 300,
              pinned: true,
              backgroundColor: AppColors.surface1,
              leading: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.arrow_back, size: 18),
                ),
                onPressed: () => context.pop(),
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(fit: StackFit.expand, children: [
                  p.avatarUrl != null
                      ? Image.network(p.avatarUrl!, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _coverFallback(p, actColor))
                      : _coverFallback(p, actColor),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter, end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black.withOpacity(0.9)],
                        stops: const [0.4, 1.0],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 20, left: 20, right: 20,
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Text(p.fullName, style: AppTextStyles.h2()),
                        if (p.idVerified) ...[const SizedBox(width: 6), const Icon(Icons.verified, color: AppColors.blue, size: 20)],
                        if (p.isInfluencer) ...[const SizedBox(width: 4), const Icon(Icons.star, color: AppColors.gold, size: 20)],
                      ]),
                      const SizedBox(height: 6),
                      Row(children: [
                        AppBadge(label: p.levelName, small: true),
                        const SizedBox(width: 8),
                        if (p.isPro) Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(gradient: AppColors.compatGradient, borderRadius: BorderRadius.circular(100)),
                          child: Text('PRO', style: AppTextStyles.label(color: Colors.black)),
                        ),
                        if (p.isOnline) ...[
                          const SizedBox(width: 8),
                          Row(children: [
                            Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.teal, shape: BoxShape.circle)),
                            const SizedBox(width: 5),
                            Text('Online', style: AppTextStyles.bodySM(color: AppColors.teal).copyWith(fontWeight: FontWeight.w600)),
                          ]),
                        ],
                      ]),
                    ]),
                  ),
                ]),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(children: [
                  // Actions
                  Row(children: [
                    Expanded(child: PrimaryButton(
                      label: '💬 Message', height: 44,
                      onPressed: () => context.push(
                        AppRoutes.chat.replaceAll(':chatId', widget.userId),
                        extra: {'buddyName': p.firstName, 'buddyAvatar': p.avatarUrl},
                      ),
                    )),
                    const SizedBox(width: 10),
                    Expanded(child: GhostButton(
                      label: '📅 Schedule', height: 44,
                      onPressed: () => context.push(AppRoutes.scheduleSession,
                          extra: {'buddyId': widget.userId, 'buddyName': p.firstName}),
                    )),
                  ]).animate().fadeIn().slideY(begin: 0.2),

                  const SizedBox(height: 16),

                  // Compat
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface1, borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(children: [
                      CompatRing(score: p.compatibilityScore, size: 72),
                      const SizedBox(width: 16),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Compatibility Score', style: AppTextStyles.subtitle()),
                        const SizedBox(height: 4),
                        Text(
                          p.compatibilityScore >= 80 ? '🔥 Excellent match! You train the same way.' :
                          p.compatibilityScore >= 60 ? '👍 Good match. Similar fitness goals.' :
                          p.compatibilityScore >= 40 ? '🤝 Decent match. Worth a try.' :
                          '⚡ Different styles — might be complementary!',
                          style: AppTextStyles.bodySM(),
                        ),
                      ])),
                    ]),
                  ).animate(delay: 100.ms).fadeIn(),

                  const SizedBox(height: 12),

                  // Stats
                  Row(children: [
                    _InfoCard(emoji: '🤝', value: '${p.buddyCount}',              label: 'Buddies'),
                    const SizedBox(width: 10),
                    _InfoCard(emoji: '💪', value: '${p.sessionCount}',            label: 'Sessions'),
                    const SizedBox(width: 10),
                    _InfoCard(emoji: '⭐', value: '${p.trustScore.toInt()}',      label: 'Trust'),
                  ]).animate(delay: 150.ms).fadeIn(),

                  const SizedBox(height: 12),

                  // Bio
                  if (p.bio != null && p.bio!.isNotEmpty)
                    Container(
                      width: double.infinity, padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface1, borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('About', style: AppTextStyles.subtitle()),
                        const SizedBox(height: 8),
                        Text(p.bio!, style: AppTextStyles.body()),
                      ]),
                    ).animate(delay: 200.ms).fadeIn(),

                  if (p.bio != null) const SizedBox(height: 12),

                  // Training info
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface1, borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const SectionHeader(title: 'Training Info'),
                      const SizedBox(height: 14),
                      if (p.primaryActivity != null)
                        _InfoRow(label: 'Main Activity', value: p.primaryActivity![0].toUpperCase() + p.primaryActivity!.substring(1)),
                      if (p.experienceLevel != null)
                        _InfoRow(label: 'Level', value: p.experienceLevel![0].toUpperCase() + p.experienceLevel!.substring(1)),
                      if (p.primaryGym != null)  _InfoRow(label: 'Gym', value: p.primaryGym!),
                      if (p.city != null)         _InfoRow(label: 'Location', value: p.city!),
                      if (p.distanceKm != null)   _InfoRow(label: 'Distance', value: '${p.distanceKm!.toStringAsFixed(1)} km away'),
                    ]),
                  ).animate(delay: 250.ms).fadeIn(),

                  const SizedBox(height: 12),

                  // Goals
                  if (p.goals.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface1, borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const SectionHeader(title: 'Goals'),
                        const SizedBox(height: 12),
                        Wrap(spacing: 8, runSpacing: 8,
                          children: p.goals.map((id) {
                            final g = AppConstants.goals.firstWhere(
                                (x) => x['id'] == id, orElse: () => {'id': id, 'emoji': '🎯', 'label': id});
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(color: AppColors.surface2, borderRadius: BorderRadius.circular(100), border: Border.all(color: AppColors.border2)),
                              child: Row(mainAxisSize: MainAxisSize.min, children: [
                                Text(g['emoji']!, style: const TextStyle(fontSize: 14)),
                                const SizedBox(width: 6),
                                Text(g['label']!, style: AppTextStyles.bodySM(color: AppColors.textSecondary).copyWith(fontWeight: FontWeight.w600)),
                              ]),
                            );
                          }).toList(),
                        ),
                      ]),
                    ).animate(delay: 300.ms).fadeIn(),

                  const SizedBox(height: 80),
                ]),
              ),
            ),
          ]),
        );
      },
    );
  }

  Widget _coverFallback(BuddyProfile p, Color actColor) => Container(
    decoration: BoxDecoration(gradient: LinearGradient(
      begin: Alignment.topLeft, end: Alignment.bottomRight,
      colors: [actColor.withOpacity(0.3), AppColors.bg],
    )),
    child: Center(child: Text(p.firstName[0].toUpperCase(),
        style: TextStyle(fontSize: 80, fontWeight: FontWeight.w800, color: actColor))),
  );
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.emoji, required this.value, required this.label});
  final String emoji, value, label;
  @override
  Widget build(BuildContext context) => Expanded(child: Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: AppColors.surface1, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
    child: Column(children: [
      Text(emoji, style: const TextStyle(fontSize: 20)),
      const SizedBox(height: 4),
      Text(value, style: AppTextStyles.h3(color: AppColors.primary)),
      Text(label, style: AppTextStyles.caption()),
    ]),
  ));
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label, value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: AppTextStyles.bodySM()),
      Text(value, style: AppTextStyles.bodySM(color: AppColors.textPrimary).copyWith(fontWeight: FontWeight.w600)),
    ]),
  );
}
