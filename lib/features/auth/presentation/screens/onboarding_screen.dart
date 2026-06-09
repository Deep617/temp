import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:seshlly/core/services/storage_service.dart';
import 'package:seshlly/features/dashboard/profile/presentation/bloc/profile_bloc.dart';
import 'package:seshlly/features/dashboard/profile/presentation/bloc/profile_event.dart';
import 'package:seshlly/routes/app_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/common/common_widgets.dart';
import '../../../../core/widgets/error_widget.dart';
import '../../../../di_injection/dependency_injection.dart';
import '../../../dashboard/profile/presentation/bloc/profile_state.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageCtrl = PageController();
  int _page = 0;

  String? _selectedActivity;
  String? _selectedLevel;
  List<String> _selectedGoals = [];
  String? _selectedGender;
  final _cityCtrl = TextEditingController();

  int get _totalPages => 5;

  bool get _canProceed {
    switch (_page) {
      case 0:
        return _selectedActivity != null;
      case 1:
        return _selectedLevel != null;
      case 2:
        return _selectedGoals.isNotEmpty;
      case 3:
        return _selectedGender != null;
      default:
        return true;
    }
  }

  void _next() {
    if (_page < _totalPages - 1) {
      _pageCtrl.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
      setState(() => _page++);
    } else {
      _finish();
    }
  }

  StorageService storageService = getIt<StorageService>();

  Future<void> _finish() async {
    context.read<ProfileBloc>().add(
      ProfileUpdated(
        data: {
          'primaryActivity': _selectedActivity,
          'experienceLevel': _selectedLevel,
          'goals': _selectedGoals,
          'city': _cityCtrl.text.trim().isNotEmpty
              ? _cityCtrl.text.trim()
              : null,
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: BlocConsumer<ProfileBloc, ProfileState>(
          listener: (context, state) {
            if (state.isUpdated) {
              storageService.setOnboarding();
              context.go(AppRoutes.home);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Onboarded Successfully 💪',
                    style: AppTextStyles.body(),
                  ),
                ),
              );
            }
          },
          builder: (context, state) => getState(state),
        ),
      ),
    );
  }

  getState(ProfileState state) {
    if (state.isInitial) {
      return mainUI(state);
    } else if (state.isFailure) {
      return ErrorView(
        message: state.error!.message!,
        apiFailure: state.error!,
        onRetry: () {
          _finish();
        },
      );
    } else {
      return mainUI(state);
    }
  }

  mainUI(ProfileState state) {
    return Column(
      children: [
        // Progress
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 20, 28, 0),
          child: Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(100),
                  child: LinearProgressIndicator(
                    value: (_page + 1) / _totalPages,
                    backgroundColor: AppColors.surface2,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.primary,
                    ),
                    minHeight: 4,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${_page + 1}$_totalPages',
                style: AppTextStyles.caption(),
              ),
            ],
          ),
        ),

        // Pages
        Expanded(
          child: PageView(
            controller: _pageCtrl,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _ActivityPage(
                selected: _selectedActivity,
                onSelect: (a) => setState(() => _selectedActivity = a),
              ),
              _LevelPage(
                selected: _selectedLevel,
                onSelect: (l) => setState(() => _selectedLevel = l),
              ),
              _GoalsPage(
                selected: _selectedGoals,
                onToggle: (g) => setState(
                  () => _selectedGoals.contains(g)
                      ? _selectedGoals.remove(g)
                      : _selectedGoals.add(g),
                ),
              ),
              _GenderPage(
                selected: _selectedGender,
                onSelect: (g) => setState(() => _selectedGender = g),
              ),
              _LocationPage(controller: _cityCtrl),
            ],
          ),
        ),

        // CTA
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
          child: Column(
            children: [
              PrimaryButton(
                label: _page == _totalPages - 1
                    ? 'Start Matching!'
                    : 'Continue',
                loading: state.isLoading,
                disabled: !_canProceed,
                onPressed: _next,
              ),
              if (_page < _totalPages - 1) ...[
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _next,
                  child: Text('Skip for now', style: AppTextStyles.bodySM()),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// ── Step widgets (identical to original, kept intact) ─────
class _ActivityPage extends StatelessWidget {
  const _ActivityPage({required this.selected, required this.onSelect});

  final String? selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(28, 24, 28, 0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'What\'s your\nfavourite activity?',
          style: AppTextStyles.h1(),
        ).animate().fadeIn(),
        const SizedBox(height: 8),
        Text(
          'We\'ll match you with people who share your passion',
          style: AppTextStyles.body(),
        ).animate(delay: 100.ms).fadeIn(),
        const SizedBox(height: 28),
        Expanded(
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 2.2,
            ),
            itemCount: AppConstants.activities.length,
            itemBuilder: (_, i) {
              final a = AppConstants.activities[i];
              final isSelected = selected == a['id'];
              final color = Color(a['color'] as int);
              return GestureDetector(
                onTap: () => onSelect(a['id'] as String),
                child:
                    AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? color.withOpacity(0.18)
                                : AppColors.surface2,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? color.withOpacity(0.5)
                                  : AppColors.border2,
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                a['emoji'] as String,
                                style: const TextStyle(fontSize: 22),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                a['label'] as String,
                                style: AppTextStyles.subtitle(
                                  color: isSelected
                                      ? color
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        )
                        .animate(delay: Duration(milliseconds: i * 60))
                        .fadeIn()
                        .scale(begin: const Offset(0.9, 0.9)),
              );
            },
          ),
        ),
      ],
    ),
  );
}

class _LevelPage extends StatelessWidget {
  const _LevelPage({required this.selected, required this.onSelect});

  final String? selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(28, 24, 28, 0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your experience\nlevel?',
          style: AppTextStyles.h1(),
        ).animate().fadeIn(),
        const SizedBox(height: 28),
        ...AppConstants.levels.asMap().entries.map((e) {
          final l = e.value;
          final isSelected = selected == l['id'];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GestureDetector(
              onTap: () => onSelect(l['id']!),
              child:
                  AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary.withOpacity(0.12)
                              : AppColors.surface2,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary.withOpacity(0.4)
                                : AppColors.border2,
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primary.withOpacity(0.2)
                                    : AppColors.surface3,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: Text(
                                  '${e.key + 1}',
                                  style: AppTextStyles.h3(
                                    color: isSelected
                                        ? AppColors.primary
                                        : AppColors.textMuted,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l['label']!,
                                    style: AppTextStyles.subtitle(
                                      color: isSelected
                                          ? AppColors.primary
                                          : AppColors.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    l['desc']!,
                                    style: AppTextStyles.bodySM(),
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              const Icon(
                                Icons.check_circle,
                                color: AppColors.primary,
                                size: 20,
                              ),
                          ],
                        ),
                      )
                      .animate(delay: Duration(milliseconds: e.key * 80))
                      .fadeIn()
                      .slideX(begin: 0.2),
            ),
          );
        }),
      ],
    ),
  );
}

class _GoalsPage extends StatelessWidget {
  const _GoalsPage({required this.selected, required this.onToggle});

  final List<String> selected;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(28, 24, 28, 0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your fitness\ngoals?',
          style: AppTextStyles.h1(),
        ).animate().fadeIn(),
        const SizedBox(height: 28),
        Expanded(
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 2.0,
            ),
            itemCount: AppConstants.goals.length,
            itemBuilder: (_, i) {
              final g = AppConstants.goals[i];
              final isSelected = selected.contains(g['id']);
              return GestureDetector(
                onTap: () => onToggle(g['id']!),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withOpacity(0.12)
                        : AppColors.surface2,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary.withOpacity(0.4)
                          : AppColors.border2,
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(g['emoji']!, style: const TextStyle(fontSize: 24)),
                      const SizedBox(height: 4),
                      Text(
                        g['label']!,
                        style: AppTextStyles.bodySM(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.textSecondary,
                        ).copyWith(fontWeight: FontWeight.w600),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ).animate(delay: Duration(milliseconds: i * 60)).fadeIn(),
              );
            },
          ),
        ),
      ],
    ),
  );
}

class _GenderPage extends StatelessWidget {
  const _GenderPage({required this.selected, required this.onSelect});

  final String? selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(28, 24, 28, 0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Your gender?', style: AppTextStyles.h1()).animate().fadeIn(),
        const SizedBox(height: 40),
        ...[
          {'id': 'male', 'label': 'Male', 'emoji': '👨'},
          {'id': 'female', 'label': 'Female', 'emoji': '👩'},
          {'id': 'other', 'label': 'Other', 'emoji': '🧑'},
        ].asMap().entries.map((e) {
          final g = e.value;
          final isSelected = selected == g['id'];
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: GestureDetector(
              onTap: () => onSelect(g['id']!),
              child:
                  AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary.withOpacity(0.12)
                              : AppColors.surface2,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary.withOpacity(0.4)
                                : AppColors.border2,
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(
                              g['emoji']!,
                              style: const TextStyle(fontSize: 28),
                            ),
                            const SizedBox(width: 16),
                            Text(
                              g['label']!,
                              style: AppTextStyles.subtitle(
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.textPrimary,
                              ),
                            ),
                            const Spacer(),
                            if (isSelected)
                              const Icon(
                                Icons.check_circle,
                                color: AppColors.primary,
                              ),
                          ],
                        ),
                      )
                      .animate(delay: Duration(milliseconds: e.key * 100))
                      .fadeIn()
                      .slideX(begin: 0.2),
            ),
          );
        }),
      ],
    ),
  );
}

class _LocationPage extends StatelessWidget {
  const _LocationPage({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(28, 24, 28, 0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Where are you\nbased?',
          style: AppTextStyles.h1(),
        ).animate().fadeIn(),
        const SizedBox(height: 40),
        AppInput(
          label: 'City',
          hint: 'e.g. Mumbai, Delhi, Bangalore',
          controller: controller,
          prefixIcon: Icons.location_on_outlined,
          textCapitalization: TextCapitalization.words,
        ).animate(delay: 200.ms).fadeIn(),
      ],
    ),
  );
}
