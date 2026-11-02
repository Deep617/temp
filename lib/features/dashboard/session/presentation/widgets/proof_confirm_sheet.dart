// ─────────────────────────────────────────────────────────
//  ProofConfirmSheet — one-tap "Confirm" for a buddy's proof
//  Opened from: home banner, push notification tap, chat proof card
//  POST /sessions/:id/confirm
// ─────────────────────────────────────────────────────────
import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../../core/errors/app_error.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/widgets/common/common_widgets.dart';
import '../../../../../di_injection/dependency_injection.dart';
import '../../data/repositories/session_repository.dart';
import '../../data/response_ml/pending_proof_confirm.dart';
import '../../../../../core/services/monitoring_service.dart';
import '../../../../../core/services/growth_service.dart';

/// Shows the sheet. Returns true if the user confirmed.
Future<bool> showProofConfirmSheet(
  BuildContext context,
  PendingProofConfirm item,
) async {
  final ok = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => ProofConfirmSheet(item: item),
  );
  return ok == true;
}

/// "1h 23m" / "12m" / "45s"
String formatTimeLeft(Duration d) {
  if (d.isNegative) return '0m';
  final h = d.inHours;
  final m = d.inMinutes.remainder(60);
  if (h > 0) return '${h}h ${m}m';
  if (d.inMinutes > 0) return '${d.inMinutes}m';
  return '${d.inSeconds}s';
}

class ProofConfirmSheet extends StatefulWidget {
  const ProofConfirmSheet({super.key, required this.item});

  final PendingProofConfirm item;

  @override
  State<ProofConfirmSheet> createState() => _ProofConfirmSheetState();
}

class _ProofConfirmSheetState extends State<ProofConfirmSheet> {
  Timer? _ticker;
  bool _confirming = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Live countdown
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _confirm() async {
    if (_confirming) return;
    setState(() {
      _confirming = true;
      _error = null;
    });
    try {
      await getIt<SessionRepository>().confirmProof(widget.item.sessionId);
      MonitoringService.instance.log('proof_confirmed', {'source': 'sheet'});
      GrowthService.instance.onSessionCompleted();
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop(true);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            '✅ Confirmed! +${widget.item.potentialXp} XP for you and '
            '${widget.item.uploaderName ?? 'your buddy'}',
          ),
          backgroundColor: AppColors.teal,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _confirming = false;
        _error = e is AppError ? e.message : AppError.fromException(e).message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final left = item.timeLeft;
    final expired = item.isExpired;
    final urgent = left.inMinutes < 15;
    final name = item.uploaderName ?? 'Your buddy';

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface1,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border2,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('$name sent a session proof 📸', style: AppTextStyles.h3()),
              const SizedBox(height: 4),
              Text(
                '${item.activity} session · confirm it and you both earn XP',
                style: AppTextStyles.bodySM(),
              ),
              const SizedBox(height: 16),

              // Proof photo
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: AspectRatio(
                  aspectRatio: 4 / 5,
                  child: item.imageUrl != null
                      ? Image.network(
                          item.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: AppColors.surface2,
                            child: const Center(
                              child: Icon(Icons.broken_image_outlined,
                                  color: AppColors.textMuted),
                            ),
                          ),
                        )
                      : Container(color: AppColors.surface2),
                ),
              ),
              const SizedBox(height: 14),

              // Countdown + XP
              Row(
                children: [
                  Icon(
                    Icons.timer_outlined,
                    size: 18,
                    color: urgent ? AppColors.error : AppColors.warning,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      expired
                          ? 'Confirmation time is over'
                          : '${formatTimeLeft(left)} left to confirm',
                      style: AppTextStyles.body(
                        color: urgent ? AppColors.error : AppColors.warning,
                      ).copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  if (item.potentialXp > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.teal.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(
                            color: AppColors.teal.withOpacity(0.4)),
                      ),
                      child: Text(
                        '+${item.potentialXp} XP',
                        style: AppTextStyles.bodySM(color: AppColors.teal)
                            .copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                ],
              ),
              if (!expired) ...[
                const SizedBox(height: 6),
                Text(
                  'If time runs out, $name still gets XP '
                  'but you lose yours (Trust -2).',
                  style: AppTextStyles.caption(),
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(_error!,
                    style: AppTextStyles.bodySM(color: AppColors.error)),
              ],
              const SizedBox(height: 18),
              PrimaryButton(
                label: expired ? 'Time up' : '✅ Confirm Proof',
                loading: _confirming,
                onPressed: expired || _confirming ? null : _confirm,
                height: 52,
              ),
              const SizedBox(height: 8),
              GhostButton(
                label: 'Later',
                height: 44,
                onPressed: () => Navigator.of(context).pop(false),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
