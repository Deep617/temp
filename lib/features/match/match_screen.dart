import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/common/common_widgets.dart';
import '../../routes/app_router.dart';
import '../auth/presentation/bloc/auth_bloc.dart';
import '../auth/presentation/bloc/auth_state.dart';
import '../dashboard/profile/presentation/bloc/profile_bloc.dart';
import '../dashboard/profile/presentation/bloc/profile_event.dart';
import '../dashboard/profile/presentation/bloc/profile_state.dart';
class MatchScreen extends StatefulWidget {
  const MatchScreen({super.key, required this.userId});
  final String userId;
  @override
  State<MatchScreen> createState() => _MatchScreenState();
}

class _MatchScreenState extends State<MatchScreen> with TickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late AnimationController _confettiCtrl;

  @override
  void initState() {
    super.initState();
    HapticFeedback.heavyImpact();

    _pulseCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _confettiCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 2000))
      ..forward();

    // Load the matched buddy's profile
    context.read<ProfileBloc>().add(BuddyProfileLoaded(userId: widget.userId));
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _confettiCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        final me = authState.user;

        return BlocBuilder<ProfileBloc, ProfileState>(
          builder: (context, profileState) {
            final buddy   = profileState.buddyProfile;
            final loading = profileState.isLoading || buddy == null;

            return Scaffold(
              backgroundColor: AppColors.bg,
              body: Stack(children: [
                // Background radial glow
                Positioned.fill(child: Container(
                  decoration: BoxDecoration(gradient: RadialGradient(
                    center: Alignment.topCenter, radius: 1.2,
                    colors: [AppColors.primary.withOpacity(0.12), AppColors.bg],
                  )),
                )),

                // Animated rings
                if (!loading)
                  ...List.generate(3, (i) => Positioned(
                    top: size.height * 0.18, left: 0, right: 0,
                    child: Center(child: AnimatedBuilder(
                      animation: _pulseCtrl,
                      builder: (_, __) => Container(
                        width:  200 + i * 70 + _pulseCtrl.value * 20,
                        height: 200 + i * 70 + _pulseCtrl.value * 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.06 - i * 0.015),
                            width: 1.5,
                          ),
                        ),
                      ),
                    )),
                  )),

                // Main content
                SafeArea(child: loading
                    ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                    : Column(children: [
                        const SizedBox(height: 40),

                        Text("It's a Match!", style: AppTextStyles.display(color: AppColors.primary))
                            .animate().scale(duration: 700.ms, curve: Curves.elasticOut).fadeIn(),

                        const SizedBox(height: 8),
                        Text('You both want to train together', style: AppTextStyles.body())
                            .animate(delay: 300.ms).fadeIn(),

                        const SizedBox(height: 48),

                        // Avatar pair
                        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          _AvatarBubble(
                            name:     me?.fullName ?? 'Me',
                            imageUrl: me?.avatarUrl,
                            isPro:    me?.isPro ?? false,
                            label:    'You',
                          ).animate(delay: 200.ms).slideX(begin: -0.5).fadeIn(),

                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Column(children: [
                              Container(
                                width: 48, height: 48,
                                decoration: BoxDecoration(
                                  gradient: AppColors.compatGradient,
                                  shape: BoxShape.circle,
                                  boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.4), blurRadius: 16)],
                                ),
                                child: const Icon(Icons.favorite, color: Colors.black, size: 24),
                              ).animate(delay: 400.ms).scale(duration: 600.ms, curve: Curves.elasticOut),
                              const SizedBox(height: 8),
                              CompatRing(score: buddy.compatibilityScore, size: 56)
                                  .animate(delay: 600.ms).fadeIn(),
                            ]),
                          ),

                          _AvatarBubble(
                            name:     buddy.fullName,
                            imageUrl: buddy.avatarUrl,
                            isPro:    buddy.isPro,
                            label:    buddy.firstName,
                          ).animate(delay: 200.ms).slideX(begin: 0.5).fadeIn(),
                        ]),

                        const SizedBox(height: 32),

                        // Buddy stats
                        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          _MatchStat(
                            icon: '🏋️',
                            value: buddy.primaryActivity != null
                                ? buddy.primaryActivity![0].toUpperCase() + buddy.primaryActivity!.substring(1)
                                : '—',
                            label: 'Activity',
                          ),
                          _MatchStat(icon: '⭐', value: buddy.levelName,          label: 'Level'),
                          _MatchStat(icon: '💪', value: '${buddy.sessionCount}',  label: 'Sessions'),
                        ]).animate(delay: 700.ms).fadeIn().slideY(begin: 0.2),

                        const Spacer(),

                        // Action buttons
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 28),
                          child: Column(children: [
                            PrimaryButton(
                              label: '💬 Send Message',
                              onPressed: () => context.go(
                                AppRoutes.chat.replaceAll(':chatId', widget.userId),
                                extra: {'buddyName': buddy.firstName, 'buddyAvatar': buddy.avatarUrl},
                              ),
                            ).animate(delay: 800.ms).fadeIn().slideY(begin: 0.3),

                            const SizedBox(height: 12),

                            GhostButton(
                              label: '📅 Schedule Session',
                              onPressed: () => context.push(AppRoutes.scheduleSession,
                                  extra: {'buddyId': widget.userId, 'buddyName': buddy.firstName}),
                            ).animate(delay: 900.ms).fadeIn(),

                            const SizedBox(height: 12),

                            TextButton(
                              onPressed: () => context.push(
                                  AppRoutes.buddyProfile.replaceAll(':userId', widget.userId)),
                              child: Text("View ${buddy.firstName}'s Profile",
                                  style: AppTextStyles.bodySM(color: AppColors.textMuted)),
                            ).animate(delay: 1000.ms).fadeIn(),

                            TextButton(
                              onPressed: () => context.go(AppRoutes.home),
                              child: Text('Keep Swiping', style: AppTextStyles.bodySM()),
                            ).animate(delay: 1100.ms).fadeIn(),

                            const SizedBox(height: 20),
                          ]),
                        ),
                      ])),
              ]),
            );
          },
        );
      },
    );
  }
}

class _AvatarBubble extends StatelessWidget {
  const _AvatarBubble({required this.name, this.imageUrl, required this.isPro, required this.label});
  final String name, label;
  final String? imageUrl;
  final bool isPro;

  @override
  Widget build(BuildContext context) => Column(children: [
    Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: isPro
            ? AppColors.compatGradient
            : const LinearGradient(colors: [AppColors.border2, AppColors.border]),
      ),
      child: AppAvatar(name: name, imageUrl: imageUrl, size: 90),
    ),
    const SizedBox(height: 8),
    Text(label, style: AppTextStyles.subtitle()),
    if (isPro) const AppBadge(label: 'PRO', small: true),
  ]);
}

class _MatchStat extends StatelessWidget {
  const _MatchStat({required this.icon, required this.value, required this.label});
  final String icon, value, label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Column(children: [
      Text(icon, style: const TextStyle(fontSize: 24)),
      const SizedBox(height: 4),
      Text(value, style: AppTextStyles.subtitle(color: AppColors.primary)),
      Text(label, style: AppTextStyles.caption()),
    ]),
  );
}
