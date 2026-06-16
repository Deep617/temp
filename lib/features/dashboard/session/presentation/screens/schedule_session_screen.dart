import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/widgets/common/common_widgets.dart';
import '../bloc/session_bloc.dart';
import '../bloc/session_event.dart';
import '../bloc/session_state.dart';

class ScheduleSessionScreen extends StatefulWidget {
  const ScheduleSessionScreen({
    super.key,
    required this.buddyId,
    required this.buddyName,
  });

  final String buddyId, buddyName;

  @override
  State<ScheduleSessionScreen> createState() => _ScheduleSessionScreenState();
}

class _ScheduleSessionScreenState extends State<ScheduleSessionScreen> {
  String? _activity;
  DateTime? _date;
  TimeOfDay? _time;
  final _gymCtrl = TextEditingController();

  @override
  void dispose() {
    _gymCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.primary,
            surface: AppColors.surface1,
          ),
        ),
        child: child!,
      ),
    );
    if (d != null) setState(() => _date = d);
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 7, minute: 0),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.primary,
            surface: AppColors.surface1,
          ),
        ),
        child: child!,
      ),
    );
    if (t != null) setState(() => _time = t);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SessionBloc, SessionState>(
      listener: (context, state) {
        if (state.status == SessionStatus.scheduled) {
          context.pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Session scheduled with ${widget.buddyName}! 💪',
                style: AppTextStyles.body(),
              ),
            ),
          );
        }
        if (state.status == SessionStatus.failure && state.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                state.error!.message,
                style: AppTextStyles.bodySM(color: AppColors.error),
              ),
            ),
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: AppColors.bg,
          appBar: AppBar(
            backgroundColor: AppColors.bg,
            title: Text('Schedule Session', style: AppTextStyles.h3()),
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => context.pop(),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.people,
                        color: AppColors.primary,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Session with ${widget.buddyName}',
                        style: AppTextStyles.subtitle(color: AppColors.primary),
                      ),
                    ],
                  ),
                ).animate().fadeIn(),

                const SizedBox(height: 24),

                if (state.error != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.error.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      state.error!.message,
                      style: AppTextStyles.bodySM(color: AppColors.error),
                    ),
                  ),

                Text('ACTIVITY', style: AppTextStyles.label()),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: AppConstants.activities
                      .take(6)
                      .map(
                        (a) => ActivityChip(
                          activity: a,
                          selected: _activity == a['id'],
                          onTap: () =>
                              setState(() => _activity = a['id'] as String),
                        ),
                      )
                      .toList(),
                ).animate(delay: 100.ms).fadeIn(),

                const SizedBox(height: 24),
                Text('DATE & TIME', style: AppTextStyles.label()),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: _pickDate,
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.surface2,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _date != null
                                  ? AppColors.primary.withOpacity(0.4)
                                  : AppColors.border2,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.calendar_today_outlined,
                                color: _date != null
                                    ? AppColors.primary
                                    : AppColors.textMuted,
                                size: 15,
                              ),
                              const SizedBox(width: 10),
                              Flexible(
                                child: Text(
                                  _date != null
                                      ? DateFormat(
                                          'EEE,dd MMM yyyy',
                                        ).format(_date!)
                                      : 'Select date',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.body(
                                    color: _date != null
                                        ? AppColors.textPrimary
                                        : AppColors.textDim,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GestureDetector(
                        onTap: _pickTime,
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.surface2,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _time != null
                                  ? AppColors.primary.withOpacity(0.4)
                                  : AppColors.border2,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.access_time_outlined,
                                color: _time != null
                                    ? AppColors.primary
                                    : AppColors.textMuted,
                                size: 18,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                _time != null
                                    ? _time!.format(context)
                                    : 'Select time',
                                style: AppTextStyles.body(
                                  color: _time != null
                                      ? AppColors.textPrimary
                                      : AppColors.textDim,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ).animate(delay: 200.ms).fadeIn(),

                const SizedBox(height: 24),
                AppInput(
                  label: 'Gym Name (optional)',
                  hint: 'e.g. Gold\'s Gym, Sector 12',
                  controller: _gymCtrl,
                  prefixIcon: Icons.location_on_outlined,
                  textCapitalization: TextCapitalization.words,
                ).animate(delay: 300.ms).fadeIn(),

                const SizedBox(height: 32),
                PrimaryButton(
                  label: 'Confirm Session',
                  loading: state.isScheduling,
                  disabled: _activity == null || _date == null || _time == null,
                  onPressed: () {
                    final scheduledAt = DateTime(
                      _date!.year,
                      _date!.month,
                      _date!.day,
                      _time!.hour,
                      _time!.minute,
                    );
                    context.read<SessionBloc>().add(
                      SessionScheduled(
                        buddyId: widget.buddyId,
                        activity: _activity!,
                        scheduledAt: scheduledAt,
                        gymName: _gymCtrl.text.trim().isNotEmpty
                            ? _gymCtrl.text.trim()
                            : null,
                      ),
                    );
                  },
                ).animate(delay: 400.ms).fadeIn(),
              ],
            ),
          ),
        );
      },
    );
  }
}
