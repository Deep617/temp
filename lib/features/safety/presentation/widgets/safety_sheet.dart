// ─────────────────────────────────────────────────────────
//  Safety sheet — Report / Block a user
//  Used from: chat (⋮), buddy profile (⋮), buddy view (⋮)
//
//  showSafetySheet(context, userId: .., name: .., source: 'chat')
//  Returns true when the user got blocked (caller should leave the screen).
// ─────────────────────────────────────────────────────────
import 'package:flutter/material.dart';

import '../../../../core/errors/app_error.dart';
import '../../../../core/services/monitoring_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/common/common_widgets.dart';
import '../../../../di_injection/dependency_injection.dart';
import '../../data/repositories/safety_repository.dart';

const _reasons = <(String, String, String)>[
  ('harassment', '😡', 'Harassment or bullying'),
  ('inappropriate', '🔞', 'Inappropriate messages or photos'),
  ('fake_profile', '🎭', 'Fake profile / catfish'),
  ('spam', '📢', 'Spam, scam or selling'),
  ('safety', '🚨', 'I feel unsafe'),
  ('underage', '🧒', 'Looks under 18'),
  ('other', '❓', 'Something else'),
];

Future<bool> showSafetySheet(
  BuildContext context, {
  required String userId,
  required String name,
  String source = 'profile',
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface1,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _SafetySheet(userId: userId, name: name, source: source),
  );
  return result == true;
}

class _SafetySheet extends StatefulWidget {
  const _SafetySheet({
    required this.userId,
    required this.name,
    required this.source,
  });

  final String userId;
  final String name;
  final String source;

  @override
  State<_SafetySheet> createState() => _SafetySheetState();
}

class _SafetySheetState extends State<_SafetySheet> {
  bool _reporting = false; // false = menu, true = report form
  String? _reason;
  bool _alsoBlock = true;
  bool _busy = false;
  final _details = TextEditingController();

  @override
  void dispose() {
    _details.dispose();
    super.dispose();
  }

  String get _first => widget.name.split(' ').first;

  Future<void> _block() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        backgroundColor: AppColors.surface2,
        title: Text('Block $_first?', style: AppTextStyles.h3()),
        content: Text(
          'You won\'t see each other in Discover, chats, profiles or the gym map. '
          '$_first won\'t be notified.',
          style: AppTextStyles.body(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(d, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(d, true),
            child: const Text('Block', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await getIt<SafetyRepository>().block(widget.userId);
      MonitoringService.instance.log('user_blocked', {'source': widget.source});
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context, true);
      messenger.showSnackBar(SnackBar(
        content: Text('$_first blocked'),
        behavior: SnackBarBehavior.floating,
      ));
    } catch (e) {
      _fail(e);
    }
  }

  Future<void> _submitReport() async {
    if (_reason == null) return;
    setState(() => _busy = true);
    try {
      await getIt<SafetyRepository>().report(
        userId: widget.userId,
        reason: _reason!,
        details: _details.text.trim(),
        context: widget.source,
        alsoBlock: _alsoBlock,
      );
      MonitoringService.instance.log('user_reported', {
        'reason': _reason!,
        'source': widget.source,
      });
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context, _alsoBlock);
      messenger.showSnackBar(const SnackBar(
        content: Text('Thanks for reporting — our team will review it within 24 hours 🙏'),
        behavior: SnackBarBehavior.floating,
      ));
    } catch (e) {
      _fail(e);
    }
  }

  void _fail(Object e) {
    if (!mounted) return;
    setState(() => _busy = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(e is AppError ? e.message : 'Something went wrong'),
      backgroundColor: AppColors.error,
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
          child: _reporting ? _reportForm() : _menu(),
        ),
      ),
    );
  }

  Widget _handle() => Center(
    child: Container(
      width: 36,
      height: 4,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.border2,
        borderRadius: BorderRadius.circular(2),
      ),
    ),
  );

  Widget _menu() => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _handle(),
      Text('Safety', style: AppTextStyles.h3()),
      const SizedBox(height: 4),
      Text(
        'Your report is anonymous.',
        style: AppTextStyles.bodySM(),
      ),
      const SizedBox(height: 14),
      _Option(
        icon: Icons.flag_outlined,
        color: AppColors.warning,
        title: 'Report $_first',
        subtitle: 'Inappropriate behaviour, fake profile, or you feel unsafe',
        onTap: _busy ? null : () => setState(() => _reporting = true),
      ),
      const SizedBox(height: 8),
      _Option(
        icon: Icons.block,
        color: AppColors.error,
        title: 'Block $_first',
        subtitle: 'You won\'t see each other anywhere',
        onTap: _busy ? null : _block,
      ),
    ],
  );

  Widget _reportForm() => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _handle(),
      Row(
        children: [
          IconButton(
            onPressed: _busy ? null : () => setState(() => _reporting = false),
            icon: const Icon(Icons.arrow_back, size: 20),
          ),
          Expanded(child: Text('Report $_first', style: AppTextStyles.h3())),
        ],
      ),
      const SizedBox(height: 6),
      ..._reasons.map((r) {
        final selected = _reason == r.$1;
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: _busy ? null : () => setState(() => _reason = r.$1),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.primary.withOpacity(0.12)
                    : AppColors.surface2,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selected
                      ? AppColors.primary.withOpacity(0.5)
                      : AppColors.border2,
                ),
              ),
              child: Row(
                children: [
                  Text(r.$2, style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(r.$3,
                        style: AppTextStyles.body(color: AppColors.textPrimary)),
                  ),
                  if (selected)
                    const Icon(Icons.check_circle,
                        color: AppColors.primary, size: 20),
                ],
              ),
            ),
          ),
        );
      }),
      const SizedBox(height: 8),
      TextField(
        controller: _details,
        maxLines: 3,
        maxLength: 1000,
        style: AppTextStyles.body(color: AppColors.textPrimary),
        decoration: InputDecoration(
          hintText: 'What happened? (optional)',
          hintStyle: AppTextStyles.body(color: AppColors.textMuted),
          filled: true,
          fillColor: AppColors.surface2,
          counterText: '',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        value: _alsoBlock,
        activeColor: AppColors.primary,
        onChanged: _busy ? null : (v) => setState(() => _alsoBlock = v),
        title: Text('Also block $_first',
            style: AppTextStyles.body(color: AppColors.textPrimary)),
      ),
      const SizedBox(height: 6),
      PrimaryButton(
        label: 'Submit Report',
        loading: _busy,
        onPressed: _reason == null || _busy ? null : _submitReport,
      ),
      const SizedBox(height: 8),
      Text(
        '🚨 In an emergency, call 112 immediately.',
        textAlign: TextAlign.center,
        style: AppTextStyles.caption(),
      ),
    ],
  );
}

class _Option extends StatelessWidget {
  const _Option({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(14),
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border2),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.subtitle(color: color)),
                Text(subtitle, style: AppTextStyles.caption()),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.textMuted),
        ],
      ),
    ),
  );
}

/// ⋮ button for app bars → opens the safety sheet.
/// [onBlocked] runs after a successful block (e.g. pop the screen).
class SafetyMenuButton extends StatelessWidget {
  const SafetyMenuButton({
    super.key,
    required this.userId,
    required this.name,
    this.source = 'profile',
    this.onBlocked,
    this.boxed = false,
  });

  final String userId;
  final String name;
  final String source;
  final VoidCallback? onBlocked;
  final bool boxed; // dark rounded box (for photo headers)

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: 'Report / Block',
    onPressed: () async {
      final blocked = await showSafetySheet(
        context,
        userId: userId,
        name: name,
        source: source,
      );
      if (blocked) onBlocked?.call();
    },
    icon: boxed
        ? Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.more_vert, size: 18, color: Colors.white),
          )
        : const Icon(Icons.more_vert, color: AppColors.textMuted),
  );
}
