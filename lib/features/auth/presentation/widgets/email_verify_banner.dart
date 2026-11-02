// ─────────────────────────────────────────────────────────
//  EmailVerifyBanner — "Verify your email" card on the Profile screen.
//
//  A 6-digit code is emailed at sign-up (POST /auth/email/send-code to
//  resend). Verified email is needed for referral rewards and makes
//  password reset reliable. Hidden once the user is verified.
// ─────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/api/dio_client.dart';
import '../../../../core/errors/app_error.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/common/common_widgets.dart';
import '../../../../di_injection/dependency_injection.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';

class EmailVerifyBanner extends StatelessWidget {
  const EmailVerifyBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.select((AuthBloc b) => b.state.user);
    if (user == null || user.emailVerified) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.warning.withOpacity(0.35)),
      ),
      child: Row(children: [
        const Icon(Icons.mark_email_unread_outlined, color: AppColors.warning),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Verify your email', style: AppTextStyles.subtitle()),
              Text(
                'Needed for referral rewards and account recovery.',
                style: AppTextStyles.bodySM(color: AppColors.textMuted),
              ),
            ],
          ),
        ),
        TextButton(
          onPressed: () => showModalBottomSheet<void>(
            context: context,
            isScrollControlled: true,
            backgroundColor: AppColors.surface1,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            builder: (_) => BlocProvider.value(
              value: context.read<AuthBloc>(),
              child: _VerifySheet(email: user.email),
            ),
          ),
          child: const Text('Verify'),
        ),
      ]),
    );
  }
}

class _VerifySheet extends StatefulWidget {
  const _VerifySheet({required this.email});
  final String email;

  @override
  State<_VerifySheet> createState() => _VerifySheetState();
}

class _VerifySheetState extends State<_VerifySheet> {
  final _code = TextEditingController();
  bool _busy = false;
  String? _error;
  String? _info;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _resend() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await getIt<DioClient>().post('/auth/email/send-code');
      if (mounted) setState(() => _info = 'New code sent to ${widget.email}');
    } catch (e) {
      if (mounted) setState(() => _error = AppError.fromException(e).message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _verify() async {
    final otp = _code.text.trim();
    if (otp.length != 6) {
      setState(() => _error = 'Enter the 6-digit code');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await getIt<DioClient>().post('/auth/email/verify', data: {'otp': otp});
      if (!mounted) return;
      final bloc = context.read<AuthBloc>();
      final u = bloc.state.user;
      if (u != null) bloc.add(AuthUserUpdated(user: u.copyWith(emailVerified: true)));
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop();
      messenger.showSnackBar(const SnackBar(
        content: Text('Email verified ✅'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ));
    } catch (e) {
      if (mounted) setState(() => _error = AppError.fromException(e).message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Verify your email', style: AppTextStyles.h3()),
          const SizedBox(height: 6),
          Text(
            'Enter the 6-digit code we sent to ${widget.email}. '
            'Check your spam folder too.',
            style: AppTextStyles.bodySM(color: AppColors.textMuted),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _code,
            autofocus: true,
            keyboardType: TextInputType.number,
            maxLength: 6,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: AppTextStyles.h3(),
            decoration: const InputDecoration(hintText: '123456', counterText: ''),
            onSubmitted: (_) => _verify(),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: AppTextStyles.bodySM(color: AppColors.error)),
          ] else if (_info != null) ...[
            const SizedBox(height: 8),
            Text(_info!, style: AppTextStyles.bodySM(color: AppColors.teal)),
          ],
          const SizedBox(height: 16),
          PrimaryButton(label: 'Verify', loading: _busy, onPressed: _busy ? null : _verify),
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: _busy ? null : _resend,
              child: const Text('Send a new code'),
            ),
          ),
        ],
      ),
    );
  }
}
