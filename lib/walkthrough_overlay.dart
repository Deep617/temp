// ─────────────────────────────────────────────────────────────
//  walkthrough_overlay.dart
//  First-time feature walkthrough — shown once after onboarding
//  Uses SharedPreferences (same pattern as onboarding) to track
// ─────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';

import 'core/services/storage_service.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_text_styles.dart';
import 'di_injection/dependency_injection.dart';

class WalkthroughOverlay extends StatefulWidget {
  const WalkthroughOverlay({super.key, required this.child});

  final Widget child;

  @override
  State<WalkthroughOverlay> createState() => _WalkthroughOverlayState();
}

class _WalkthroughOverlayState extends State<WalkthroughOverlay> {
  bool _show = false;
  int _step = 0;

  final _steps = const [
    _WStep(
      icon: '🔍',
      title: 'Discover Tab',
      desc: 'Swipe right to like a buddy, left to skip. Mutual like = match!',
      hint: 'Tab 1 of 5',
    ),
    _WStep(
      icon: '💬',
      title: 'Chats',
      desc: 'Chat only unlocks after a match. Tokens are used per message.',
      hint: 'Tab 2 of 5',
    ),
    _WStep(
      icon: '🏋️',
      title: 'Sessions',
      desc: 'Schedule a workout. Upload proof within 8 hours to earn +50 XP.',
      hint: 'Tab 3 of 5',
    ),
    _WStep(
      icon: '⚡',
      title: 'Challenges',
      desc: 'Solo or with a buddy. Complete stations to climb the leaderboard.',
      hint: 'Tab 4 of 5',
    ),
    _WStep(
      icon: '👤',
      title: 'Profile',
      desc: 'Track your XP, level, trust score, and earned trophies here.',
      hint: 'Tab 5 of 5',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _checkSeen();
  }

  Future<void> _checkSeen() async {
    final seen = await getIt<StorageService>().getWalkThrogh();
    if (!seen && mounted) setState(() => _show = true);
  }

  Future<void> _dismiss() async {
    await getIt<StorageService>().setWalkThrogh();
    if (mounted) setState(() => _show = false);
  }

  void _next() {
    if (_step < _steps.length - 1) {
      setState(() => _step++);
    } else {
      _dismiss();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [widget.child, if (_show) _buildOverlay()]);
  }

  Widget _buildOverlay() {
    final step = _steps[_step];
    return GestureDetector(
      onTap: _next,
      child: Container(
        color: Colors.black.withOpacity(0.75),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(step.icon, style: const TextStyle(fontSize: 56)),
                const SizedBox(height: 20),
                Text(
                  step.title,
                  style: AppTextStyles.h2(),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  step.desc,
                  style: AppTextStyles.body(),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                // Progress dots
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _steps.length,
                    (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: i == _step ? 20 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: i == _step
                            ? AppColors.primary
                            : AppColors.surface3,
                        borderRadius: BorderRadius.circular(100),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    // Skip
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _dismiss,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.border2),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Skip',
                          style: AppTextStyles.subtitle(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Next / Done
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _next,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          _step == _steps.length - 1 ? "Let's go! 🚀" : 'Next',
                          style: AppTextStyles.subtitle(color: Colors.black),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(step.hint, style: AppTextStyles.caption()),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WStep {
  const _WStep({
    required this.icon,
    required this.title,
    required this.desc,
    required this.hint,
  });

  final String icon, title, desc, hint;
}
