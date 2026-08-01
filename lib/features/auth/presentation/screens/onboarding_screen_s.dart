import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:seshlly/core/services/storage_service.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/common/common_widgets.dart';
import '../../../../di_injection/dependency_injection.dart';
import '../../../dashboard/profile/presentation/bloc/profile_bloc.dart';
import '../../../dashboard/profile/presentation/bloc/profile_event.dart';
import '../../../dashboard/profile/presentation/bloc/profile_state.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';

class OnboardingScreenS extends StatefulWidget {
  const OnboardingScreenS({super.key});

  @override
  State<OnboardingScreenS> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreenS> {
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

  Future<void> _finish() async {
    final data = <String, dynamic>{
      'primaryActivity': _selectedActivity,
      'experienceLevel': _selectedLevel,
      'goals': _selectedGoals,
      'gender': _selectedGender,
    };
    if (_cityCtrl.text.trim().isNotEmpty) {
      data['city'] = _cityCtrl.text.trim();
    }
    //await context.read<ProfileRepository>().updateProfile(data);
    context.read<ProfileBloc>().add(ProfileUpdated(data: data));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProfileBloc, ProfileState>(
    //  listenWhen: (prev, curr) => prev.status != curr.status,
      listener: (context, state) async {
        if (state.isUpdated) {
          context.read<AuthBloc>().add(const AuthOnboardingCompleted());
          await getIt<StorageService>().setOnboarding();
          SnackBar(
            content: Text('Save successfully'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          );
        }
        if (state.status == ProfileStatus.failure && state.error != null) {
          /*  ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.error!.message,
                style: AppTextStyles.bodySM(color: AppColors.error))),
          );*/

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Save failed. Please check your connection and try again.',
              ),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              action: SnackBarAction(
                label: 'Retry',
                textColor: AppColors.textPrimary,
                onPressed: _finish,
              ),
            ),
          );
        }
      },
      builder: (context, state) {
        final user = context.watch<AuthBloc>().state.user;
        return Scaffold(
          backgroundColor: AppColors.bg,
          body: SafeArea(
            child: Column(
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
                        '${_page + 1}/$_totalPages',
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
                        primaryActivity: _selectedActivity,
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
                        loading: state.isUpdating,
                        disabled: !_canProceed,
                        onPressed: _next,
                      ),
                      if (_page < _totalPages - 1) ...[
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: _next,
                          child: Text(
                            'Skip for now',
                            style: AppTextStyles.bodySM(),
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
      },
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
        const SizedBox(height: 6),
        Text(
          'We\'ll match you with people who share your passion',
          style: AppTextStyles.body(),
        ).animate(delay: 100.ms).fadeIn(),
        const SizedBox(height: 20),
        Expanded(
          child: ListView.builder(
            itemCount: AppConstants.activityCategories.length,
            itemBuilder: (_, catIdx) {
              final category = AppConstants.activityCategories[catIdx];
              final categoryActivities = AppConstants.activities
                  .where((a) => a['category'] == category)
                  .toList();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8, top: 4),
                    child: Text(
                      category.toUpperCase(),
                      style: AppTextStyles.label(color: AppColors.textMuted),
                    ),
                  ),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 2.4,
                        ),
                    itemCount: categoryActivities.length,
                    itemBuilder: (_, i) {
                      final a = categoryActivities[i];
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
                                        style: const TextStyle(fontSize: 20),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        a['label'] as String,
                                        style: AppTextStyles.bodySM(
                                          color: isSelected
                                              ? color
                                              : AppColors.textSecondary,
                                        ).copyWith(fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                )
                                .animate(delay: Duration(milliseconds: i * 40))
                                .fadeIn()
                                .scale(begin: const Offset(0.9, 0.9)),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                ],
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
  const _GoalsPage({
    required this.selected,
    required this.onToggle,
    required this.primaryActivity,
  });

  final List<String> selected;
  final ValueChanged<String> onToggle;
  final String? primaryActivity;

  @override
  Widget build(BuildContext context) {
    // Get recommended goals for selected activity
    final recommendedIds = primaryActivity != null
        ? (AppConstants.activityGoals[primaryActivity] ?? [])
        : <String>[];
    final recommended = AppConstants.goals
        .where((g) => recommendedIds.contains(g['id']))
        .toList();
    final allOther = AppConstants.goals
        .where((g) => !recommendedIds.contains(g['id']))
        .toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your fitness\ngoals?',
            style: AppTextStyles.h1(),
          ).animate().fadeIn(),
          const SizedBox(height: 20),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Recommended section
                  if (recommended.isNotEmpty) ...[
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.teal.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: AppColors.teal.withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            '⭐ Recommended for you',
                            style: AppTextStyles.label(color: AppColors.teal),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: recommended.asMap().entries.map((e) {
                        final g = e.value;
                        final isSel = selected.contains(g['id']);
                        return GestureDetector(
                          onTap: () => onToggle(g['id']!),
                          child:
                              AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSel
                                          ? AppColors.teal.withOpacity(0.15)
                                          : AppColors.surface2,
                                      borderRadius: BorderRadius.circular(100),
                                      border: Border.all(
                                        color: isSel
                                            ? AppColors.teal.withOpacity(0.5)
                                            : AppColors.teal.withOpacity(0.2),
                                        width: isSel ? 1.5 : 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          g['emoji']!,
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          g['label']!,
                                          style:
                                              AppTextStyles.bodySM(
                                                color: isSel
                                                    ? AppColors.teal
                                                    : AppColors.textSecondary,
                                              ).copyWith(
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                      ],
                                    ),
                                  )
                                  .animate(
                                    delay: Duration(milliseconds: e.key * 40),
                                  )
                                  .fadeIn(),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    Divider(color: AppColors.border),
                    const SizedBox(height: 12),
                  ],
                  // All goals section
                  Text(
                    'ALL GOALS',
                    style: AppTextStyles.label(color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: allOther.asMap().entries.map((e) {
                      final g = e.value;
                      final isSel = selected.contains(g['id']);
                      return GestureDetector(
                        onTap: () => onToggle(g['id']!),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: isSel
                                ? AppColors.primary.withOpacity(0.15)
                                : AppColors.surface2,
                            borderRadius: BorderRadius.circular(100),
                            border: Border.all(
                              color: isSel
                                  ? AppColors.primary.withOpacity(0.4)
                                  : AppColors.border2,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                g['emoji']!,
                                style: const TextStyle(fontSize: 14),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                g['label']!,
                                style: AppTextStyles.bodySM(
                                  color: isSel
                                      ? AppColors.primary
                                      : AppColors.textSecondary,
                                ).copyWith(fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
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
