import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:seshlly/di_injection/dependency_injection.dart';
import 'package:seshlly/features/dashboard/session/data/repositories/session_repository.dart';

import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/widgets/common/common_widgets.dart';
import '../../../../../routes/app_router.dart';
import '../../../discover/data/response_ml/buddy_profile.dart';
import '../bloc/session_bloc.dart';
import '../bloc/session_event.dart';
import '../bloc/session_state.dart';

class ScheduleSessionScreen extends StatefulWidget {
  const ScheduleSessionScreen({
    super.key,
    this.buddyId,
    this.buddyName,
  });
  final String? buddyId;
  final String? buddyName;

  @override
  State<ScheduleSessionScreen> createState() =>
      _ScheduleSessionScreenState();
}

class _ScheduleSessionScreenState extends State<ScheduleSessionScreen> {
  List<BuddyProfile>  _buddies        = [];
  List<BuddyProfile>  _selectedBuddies = []; // multi-select for group
  bool                _loadingBuddies  = true;

  String?  _activity;
  DateTime _scheduledAt  = DateTime.now().add(const Duration(hours: 1));
  int      _durationMins = 60; // 45 | 60 | 90 | 120
  final    _gymCtrl      = TextEditingController();
  bool     _submitting   = false;

  static const _durations = [
    (45,  '45 mins'),
    (60,  '1 hour'),
    (90,  '1.5 hours'),
    (120, '2 hours'),
  ];

  @override
  void initState() {
    super.initState();
    _loadBuddies();
  }

  @override
  void dispose() {
    _gymCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadBuddies() async {
    try {
      final buddies = await getIt<SessionRepository>().getMyBuddies();
      if (!mounted) return;
      setState(() {
        _buddies        = buddies;
        _loadingBuddies = false;
        // Pre-select buddy if passed from navigation
        if (widget.buddyId != null) {
          try {
            _selectedBuddies = _buddies
                .where((b) => b.id == widget.buddyId)
                .toList();
          } catch (_) {}
        }
      });
    } catch (_) {
      if (mounted) setState(() => _loadingBuddies = false);
    }
  }

  // No match = cannot submit, must select at least 1 buddy
  bool get _canSubmit =>
      _buddies.isNotEmpty &&
          _selectedBuddies.isNotEmpty &&
          _activity != null;

  bool _isBuddySelected(BuddyProfile b) =>
      _selectedBuddies.any((s) => s.id == b.id);

  void _toggleBuddy(BuddyProfile b) {
    setState(() {
      if (_isBuddySelected(b)) {
        _selectedBuddies.removeWhere((s) => s.id == b.id);
      } else {
        if (_selectedBuddies.length < 9) { // max 9 buddies + self = 10
          _selectedBuddies.add(b);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: const Text('Maximum 9 buddies per session (10 total)'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ));
        }
      }
    });
  }

  Future<void> _submit() async {
    if (!_canSubmit || _submitting) return;
    setState(() => _submitting = true);
    try {
      await getIt<SessionRepository>().scheduleSession(
        buddyIds:     _selectedBuddies.map((b) => b.id).toList(),
        activity:     _activity!,
        scheduledAt:  _scheduledAt,
        durationMins: _durationMins,
        gymName:      _gymCtrl.text.trim().isEmpty
            ? null : _gymCtrl.text.trim(),
      );
      if (mounted) {
        final names = _selectedBuddies.map((b) => b.firstName).join(', ');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_selectedBuddies.length == 1
              ? 'Session invite sent to $names! 🤝'
              : 'Group session invite sent to $names! 🤝'),
          backgroundColor: AppColors.success,
          behavior:        SnackBarBehavior.floating,
        ));
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString().contains('buddies')
              ? 'You can only schedule with your Seshlly buddies!'
              : 'Failed to schedule. Please try again.'),
          backgroundColor: AppColors.error,
          behavior:        SnackBarBehavior.floating,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.bg,
    appBar: AppBar(
      backgroundColor: AppColors.surface1,
      title: Text('Schedule Session', style: AppTextStyles.h3()),
      leading: IconButton(
        icon:      const Icon(Icons.close),
        onPressed: _submitting ? null : () => context.pop(),
      ),
    ),
    body: _loadingBuddies
        ? const Center(child: CircularProgressIndicator(
        color: AppColors.primary))
    // ── NO MATCHES → Wall ─────────────────────────────
        : _buddies.isEmpty
        ? _NoMatchWall()
    // ── HAS MATCHES → Form ───────────────────────────
        : SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── Choose Buddy ─────────────────────
          Text('Choose Buddy', style: AppTextStyles.subtitle()),
          const SizedBox(height: 10),

          // Group label
          if (_selectedBuddies.length > 1)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color:        AppColors.teal.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: AppColors.teal.withOpacity(0.3)),
                ),
                child: Text(
                  '👥 Group Session — ${_selectedBuddies.length + 1} people',
                  style: AppTextStyles.bodySM(color: AppColors.teal)
                      .copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ),

          ..._buddies.map((b) => _BuddyOption(
            buddy:    b,
            selected: _isBuddySelected(b),
            onTap:    () => _toggleBuddy(b),
          )).toList()
              .animate(delay: 50.ms)
              .fadeIn(),

          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 4),
            child: Text(
              'Select up to 9 buddies for a group session',
              style: AppTextStyles.caption(),
            ),
          ),

          const SizedBox(height: 20),

          // ── Activity ─────────────────────────
          Text('Activity', style: AppTextStyles.subtitle()),
          const SizedBox(height: 10),

          Wrap(
            spacing: 8, runSpacing: 8,
            children: AppConstants.activities.map((a) =>
                GestureDetector(
                  onTap: () => setState(
                          () => _activity = a['id'] as String),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: _activity == a['id']
                          ? Color(a['color'] as int)
                          .withOpacity(0.12)
                          : AppColors.surface2,
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(
                        color: _activity == a['id']
                            ? Color(a['color'] as int)
                            .withOpacity(0.4)
                            : AppColors.border2,
                      ),
                    ),
                    child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(a['emoji'] as String,
                              style: const TextStyle(fontSize: 16)),
                          const SizedBox(width: 6),
                          Text(a['label'] as String,
                              style: AppTextStyles.bodySM(
                                color: _activity == a['id']
                                    ? Color(a['color'] as int)
                                    : AppColors.textSecondary,
                              ).copyWith(
                                  fontWeight: FontWeight.w600)),
                        ]),
                  ),
                ),
            ).toList(),
          ).animate(delay: 80.ms).fadeIn(),

          const SizedBox(height: 20),

          // ── Duration ─────────────────────────────
          Text('Duration', style: AppTextStyles.subtitle()),
          const SizedBox(height: 10),
          Row(children: _durations.map((d) =>
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _durationMins = d.$1),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: _durationMins == d.$1
                          ? AppColors.primary.withOpacity(0.12)
                          : AppColors.surface2,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _durationMins == d.$1
                            ? AppColors.primary.withOpacity(0.4)
                            : AppColors.border2,
                      ),
                    ),
                    child: Text(d.$2,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.caption().copyWith(
                          color: _durationMins == d.$1
                              ? AppColors.primary
                              : AppColors.textMuted,
                          fontWeight: _durationMins == d.$1
                              ? FontWeight.w700
                              : FontWeight.normal,
                        )),
                  ),
                ),
              ),
          ).toList()).animate(delay: 90.ms).fadeIn(),

          const SizedBox(height: 20),

          // ── Date & Time ──────────────────────
          Text('Date & Time', style: AppTextStyles.subtitle()),
          const SizedBox(height: 10),

          GestureDetector(
            onTap: _pickDateTime,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color:        AppColors.surface1,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(children: [
                const Icon(Icons.calendar_today,
                    color: AppColors.primary, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    DateFormat('EEE, MMM d · h:mm a')
                        .format(_scheduledAt),
                    style: AppTextStyles.subtitle(),
                  ),
                ),
                const Icon(Icons.chevron_right,
                    color: AppColors.textMuted),
              ]),
            ),
          ).animate(delay: 100.ms).fadeIn(),

          const SizedBox(height: 20),

          // ── Gym / Location ───────────────────
          Text('Gym / Location (optional)',
              style: AppTextStyles.subtitle()),
          const SizedBox(height: 10),

          TextField(
            controller: _gymCtrl,
            style:      AppTextStyles.body(),
            decoration: InputDecoration(
              hintText: 'e.g. Gold\'s Gym, Andheri',
              hintStyle: AppTextStyles.bodySM(
                  color: AppColors.textMuted),
              prefixIcon: const Icon(Icons.fitness_center,
                  color: AppColors.textMuted, size: 20),
              filled:     true,
              fillColor:  AppColors.surface1,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                    color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                    color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                    color: AppColors.primary, width: 1.5),
              ),
            ),
          ).animate(delay: 120.ms).fadeIn(),

          const SizedBox(height: 32),

          // ── Submit ───────────────────────────
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _canSubmit && !_submitting
                  ? _submit : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                disabledBackgroundColor: AppColors.surface3,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(
                    vertical: 16),
              ),
              child: _submitting
                  ? const SizedBox(
                  width: 22, height: 22,
                  child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5))
                  : Text(
                _selectedBuddies.isEmpty
                    ? 'Select a buddy first'
                    : _selectedBuddies.length == 1
                    ? 'Schedule with ${_selectedBuddies.first.firstName} 🤝'
                    : 'Schedule Group Session (${_selectedBuddies.length + 1} people) 👥',
                style: AppTextStyles.btn(),
              ),
            ),
          ).animate(delay: 150.ms).fadeIn(),

          const SizedBox(height: 40),
        ],
      ),
    ),
  );

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context:     context,
      initialDate: _scheduledAt,
      firstDate:   DateTime.now(),
      lastDate:    DateTime.now().add(const Duration(days: 90)),
      builder: (_, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.dark(
            primary: AppColors.primary,
            surface: AppColors.surface1,
          ),
        ),
        child: child!,
      ),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context:     context,
      initialTime: TimeOfDay.fromDateTime(_scheduledAt),
      builder: (_, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.dark(
            primary: AppColors.primary,
            surface: AppColors.surface1,
          ),
        ),
        child: child!,
      ),
    );
    if (time == null || !mounted) return;

    setState(() {
      _scheduledAt = DateTime(
        date.year, date.month, date.day,
        time.hour, time.minute,
      );
    });
  }
}

// ══════════════════════════════════════════════════════════
//  NO MATCH WALL
//  Shown when user has 0 matches — cannot book session
// ══════════════════════════════════════════════════════════
class _NoMatchWall extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [

          // Icon
          Container(
            width: 90, height: 90,
            decoration: BoxDecoration(
              color:  AppColors.primary.withOpacity(0.08),
              shape:  BoxShape.circle,
              border: Border.all(
                  color: AppColors.primary.withOpacity(0.2)),
            ),
            child: const Center(
              child: Text('🤝', style: TextStyle(fontSize: 40)),
            ),
          ).animate().scale(duration: 400.ms),

          const SizedBox(height: 24),

          Text('Find a Buddy First',
              style: AppTextStyles.h2(),
              textAlign: TextAlign.center)
              .animate().fadeIn(delay: 100.ms),

          const SizedBox(height: 12),

          Text(
            'Sessions can only be booked after matching with someone.\n\nThis protects XP and Trust Score from fake sessions.',
            style: AppTextStyles.body(),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 200.ms),

          const SizedBox(height: 32),

          // Go to Discover
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                context.pop();
                context.go(AppRoutes.discover);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text('Find Workout Buddies 🔍',
                  style: AppTextStyles.btn()),
            ),
          ).animate().fadeIn(delay: 300.ms),

          const SizedBox(height: 12),

          // Cancel
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => context.pop(),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.border2),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text('Go Back',
                  style: AppTextStyles.btn(
                      color: AppColors.textMuted)),
            ),
          ).animate().fadeIn(delay: 350.ms),

        ],
      ),
    ),
  );
}

// ══════════════════════════════════════════════════════════
//  BUDDY OPTION ROW
// ══════════════════════════════════════════════════════════
class _BuddyOption extends StatelessWidget {
  const _BuddyOption({
    required this.buddy,
    required this.selected,
    required this.onTap,
  });
  final BuddyProfile buddy;
  final bool         selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:        selected
            ? AppColors.primary.withOpacity(0.08)
            : AppColors.surface1,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selected
              ? AppColors.primary.withOpacity(0.4)
              : AppColors.border,
          width: selected ? 1.5 : 1,
        ),
      ),
      child: Row(children: [
        AppAvatar(
          name:     buddy.fullName,
          imageUrl: buddy.avatarUrl,
          size:     44,
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(buddy.fullName,
                style: AppTextStyles.subtitle(
                  color: selected
                      ? AppColors.primary
                      : AppColors.textPrimary,
                )),
            const SizedBox(height: 3),
            Row(children: [
              if (buddy.primaryActivity != null) ...[
                    () {
                  final a = AppConstants.activities.firstWhere(
                        (x) => x['id'] == buddy.primaryActivity,
                    orElse: () => {
                      'emoji': '💪',
                      'label': buddy.primaryActivity,
                    },
                  );
                  return Text(
                    '${a['emoji']} ${a['label']}',
                    style: AppTextStyles.bodySM(
                        color: AppColors.textMuted),
                  );
                }(),
                const SizedBox(width: 8),
              ],
              if (buddy.city != null)
                Text('📍 ${buddy.city}',
                    style: AppTextStyles.bodySM(
                        color: AppColors.textMuted)),
            ]),
          ],
        )),
        if (selected)
          const Icon(Icons.check_circle,
              color: AppColors.primary, size: 22),
      ]),
    ),
  );
}

