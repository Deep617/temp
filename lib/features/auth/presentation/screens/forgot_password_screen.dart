// ─────────────────────────────────────────────────────────
//  forgot_password_screen.dart
//  3 steps: Enter email → OTP verify → New password
//  Navigate: context.push(AppRoutes.forgotPassword)
// ─────────────────────────────────────────────────────────
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:seshlly/di_injection/dependency_injection.dart';
import 'package:seshlly/features/auth/domain/repositories/auth_repository.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../routes/app_router.dart';

enum _Step { email, otp, newPassword, success }

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  _Step _step = _Step.email;
  bool _loading = false;
  String? _error;
  String _email = '';

  // Controllers
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _otpCtrls = List.generate(6, (_) => TextEditingController());
  final _otpFocus = List.generate(6, (_) => FocusNode());

  // OTP resend timer
  int _resendSeconds = 60;
  Timer? _timer;
  bool _obscurePass = true;
  bool _obscureConfirm = true;
  late AuthRepository _authRepository;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _authRepository = getIt<AuthRepository>();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    for (final c in _otpCtrls) c.dispose();
    for (final f in _otpFocus) f.dispose();
    _timer?.cancel();
    super.dispose();
  }

  // ── Step 1: Send OTP to email ─────────────────────────
  Future<void> _sendOtp() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _error = 'Please enter a valid email address');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _authRepository.sendForgotPasswordOtp(email);
      _email = email;
      setState(() {
        _step = _Step.otp;
        _loading = false;
      });
      _startResendTimer();
    } catch (e) {
      setState(() {
        _error = 'No account found with this email';
        _loading = false;
      });
    }
  }

  // ── Step 2: Verify OTP ────────────────────────────────
  Future<void> _verifyOtp() async {
    final otp = _otpCtrls.map((c) => c.text).join();
    if (otp.length < 6) {
      setState(() => _error = 'Enter the complete 6-digit code');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _authRepository.verifyForgotPasswordOtp(email: _email, otp: otp);
      setState(() {
        _step = _Step.newPassword;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Incorrect code. Please try again';
        _loading = false;
      });
      // Clear OTP fields on error
      for (final c in _otpCtrls) c.clear();
      _otpFocus[0].requestFocus();
    }
  }

  // ── Step 3: Reset password ────────────────────────────
  Future<void> _resetPassword() async {
    final pass = _passwordCtrl.text;
    final confirm = _confirmCtrl.text;

    if (pass.length < 8) {
      setState(() => _error = 'Password must be at least 8 characters');
      return;
    }
    if (pass != confirm) {
      setState(() => _error = 'Passwords do not match');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final otp = _otpCtrls.map((c) => c.text).join();
      _authRepository.resetPassword(email: _email, otp: otp, newPassword: pass);
      setState(() {
        _step = _Step.success;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to reset password. Please try again';
        _loading = false;
      });
    }
  }

  // ── Resend OTP timer ──────────────────────────────────
  void _startResendTimer() {
    _resendSeconds = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) {
        _timer?.cancel();
        return;
      }
      setState(() {
        if (_resendSeconds > 0)
          _resendSeconds--;
        else
          _timer?.cancel();
      });
    });
  }

  Future<void> _resendOtp() async {
    if (_resendSeconds > 0) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _authRepository.sendForgotPasswordOtp(_email);
      setState(() => _loading = false);
      _startResendTimer();
      // Clear old OTP
      for (final c in _otpCtrls) c.clear();
      _otpFocus[0].requestFocus();
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        leading: _step != _Step.success
            ? IconButton(
                icon: const Icon(
                  Icons.arrow_back,
                  color: Colors.white54,
                  size: 28,
                ),
                onPressed: () {
                  if (_step == _Step.otp || _step == _Step.newPassword) {
                    setState(() {
                      _step = _Step.email;
                      _error = null;
                    });
                  } else {
                    Navigator.of(context).pop();
                  }
                },
              )
            : null,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _buildStep(),
          ),
        ),
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case _Step.email:
        return _buildEmailStep();
      case _Step.otp:
        return _buildOtpStep();
      case _Step.newPassword:
        return _buildNewPasswordStep();
      case _Step.success:
        return _buildSuccessStep();
    }
  }

  // ── STEP 1: Email ─────────────────────────────────────
  Widget _buildEmailStep() => Column(
    key: const ValueKey('email'),
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SizedBox(height: 20),
      const Text('🔑', style: TextStyle(fontSize: 40)),
      const SizedBox(height: 16),
      Text('Forgot password?', style: AppTextStyles.h2()),
      const SizedBox(height: 8),
      Text(
        'Enter your registered email address. We\'ll send a verification code.',
        style: AppTextStyles.body(color: AppColors.textMuted),
      ),
      const SizedBox(height: 32),
      _label('Email Address'),
      const SizedBox(height: 6),
      TextField(
        controller: _emailCtrl,
        keyboardType: TextInputType.emailAddress,
        autofocus: true,
        style: const TextStyle(color: Colors.white, fontSize: 15),
        decoration: _inputDeco('you@example.com'),
        onSubmitted: (_) => _sendOtp(),
      ),
      if (_error != null) _errorText(_error!),
      const SizedBox(height: 24),
      _primaryButton(
        label: 'Send Verification Code',
        onTap: _sendOtp,
        loading: _loading,
      ),
    ],
  );

  // ── STEP 2: OTP ───────────────────────────────────────
  Widget _buildOtpStep() => Column(
    key: const ValueKey('otp'),
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SizedBox(height: 20),
      const Text('📩', style: TextStyle(fontSize: 40)),
      const SizedBox(height: 16),
      Text('Check your email', style: AppTextStyles.h2()),
      const SizedBox(height: 8),
      RichText(
        text: TextSpan(
          style: AppTextStyles.body(color: AppColors.textMuted),
          children: [
            const TextSpan(text: 'We sent a 6-digit code to '),
            TextSpan(
              text: _email,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 32),
      _label('Verification Code'),
      const SizedBox(height: 10),
      // OTP boxes
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(
          6,
          (i) => _OtpBox(
            controller: _otpCtrls[i],
            focusNode: _otpFocus[i],
            onChanged: (val) {
              if (val.length == 1 && i < 5) {
                _otpFocus[i + 1].requestFocus();
              } else if (val.isEmpty && i > 0) {
                _otpFocus[i - 1].requestFocus();
              }
              // Auto verify when all filled
              if (_otpCtrls.every((c) => c.text.length == 1)) {
                Future.delayed(const Duration(milliseconds: 100), _verifyOtp);
              }
            },
          ),
        ),
      ),
      if (_error != null) _errorText(_error!),
      const SizedBox(height: 24),
      _primaryButton(
        label: 'Verify Code',
        onTap: _verifyOtp,
        loading: _loading,
      ),
      const SizedBox(height: 16),
      // Resend
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Didn\'t receive it? ',
            style: AppTextStyles.bodySM(color: AppColors.textMuted),
          ),
          GestureDetector(
            onTap: _resendOtp,
            child: Text(
              _resendSeconds > 0
                  ? 'Resend in ${_resendSeconds}s'
                  : 'Resend code',
              style: AppTextStyles.bodySM(
                color: _resendSeconds > 0
                    ? AppColors.textMuted
                    : AppColors.primary,
              ).copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    ],
  );

  // ── STEP 3: New Password ──────────────────────────────
  Widget _buildNewPasswordStep() => Column(
    key: const ValueKey('password'),
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SizedBox(height: 20),
      const Text('🔒', style: TextStyle(fontSize: 40)),
      const SizedBox(height: 16),
      Text('Create new password', style: AppTextStyles.h2()),
      const SizedBox(height: 8),
      Text(
        'Your new password must be at least 8 characters long.',
        style: AppTextStyles.body(color: AppColors.textMuted),
      ),
      const SizedBox(height: 32),
      _label('New Password'),
      const SizedBox(height: 6),
      TextField(
        controller: _passwordCtrl,
        obscureText: _obscurePass,
        style: const TextStyle(color: Colors.white, fontSize: 15),
        decoration: _inputDeco('Minimum 8 characters').copyWith(
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePass
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: AppColors.textMuted,
              size: 20,
            ),
            onPressed: () => setState(() => _obscurePass = !_obscurePass),
          ),
        ),
      ),
      const SizedBox(height: 16),
      _label('Confirm Password'),
      const SizedBox(height: 6),
      TextField(
        controller: _confirmCtrl,
        obscureText: _obscureConfirm,
        style: const TextStyle(color: Colors.white, fontSize: 15),
        decoration: _inputDeco('Repeat your new password').copyWith(
          suffixIcon: IconButton(
            icon: Icon(
              _obscureConfirm
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: AppColors.textMuted,
              size: 20,
            ),
            onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
          ),
        ),
        onSubmitted: (_) => _resetPassword(),
      ),
      // Password strength
      if (_passwordCtrl.text.isNotEmpty) ...[
        const SizedBox(height: 10),
        _PasswordStrength(password: _passwordCtrl.text),
      ],
      if (_error != null) _errorText(_error!),
      const SizedBox(height: 24),
      _primaryButton(
        label: 'Reset Password',
        onTap: _resetPassword,
        loading: _loading,
      ),
    ],
  );

  // ── STEP 4: Success ───────────────────────────────────
  Widget _buildSuccessStep() => Column(
    key: const ValueKey('success'),
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      const SizedBox(height: 60),
      const Center(child: Text('🎉', style: TextStyle(fontSize: 64))),
      const SizedBox(height: 24),
      Center(
        child: Text(
          'Password reset!',
          style: AppTextStyles.h2(),
          textAlign: TextAlign.center,
        ),
      ),
      const SizedBox(height: 8),
      Center(
        child: Text(
          'Your password has been updated successfully.\nYou can now log in with your new password.',
          style: AppTextStyles.body(color: AppColors.textMuted),
          textAlign: TextAlign.center,
        ),
      ),
      const SizedBox(height: 40),
      _primaryButton(
        label: 'Back to Login',
        onTap: () => context.go(AppRoutes.login),
      ),
    ],
  );

  // ── Helpers ───────────────────────────────────────────
  Widget _label(String text) => Text(
    text.toUpperCase(),
    style: TextStyle(
      color: Colors.white.withOpacity(0.4),
      fontSize: 10,
      fontWeight: FontWeight.w700,
      letterSpacing: .5,
    ),
  );

  Widget _errorText(String msg) => Padding(
    padding: const EdgeInsets.only(top: 8),
    child: Text(
      msg,
      style: const TextStyle(color: Color(0xFFFF3B30), fontSize: 13),
    ),
  );

  InputDecoration _inputDeco(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 14),
    filled: true,
    fillColor: const Color(0xFF141C2E),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFF0A84FF)),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  );

  Widget _primaryButton({
    required String label,
    required VoidCallback onTap,
    bool loading = false,
  }) => SizedBox(
    width: double.infinity,
    child: ElevatedButton(
      onPressed: loading ? null : onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF0A84FF),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 0,
      ),
      child: loading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Text(
              label,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
    ),
  );
}

// ── OTP Box widget ────────────────────────────────────────
class _OtpBox extends StatelessWidget {
  const _OtpBox({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final void Function(String) onChanged;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 44,
    height: 54,
    child: TextField(
      controller: controller,
      focusNode: focusNode,
      textAlign: TextAlign.center,
      keyboardType: TextInputType.number,
      maxLength: 1,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 22,
        fontWeight: FontWeight.w700,
      ),
      decoration: InputDecoration(
        counterText: '',
        filled: true,
        fillColor: const Color(0xFF141C2E),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF0A84FF), width: 1.5),
        ),
      ),
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      onChanged: onChanged,
    ),
  );
}

// ── Password Strength Indicator ───────────────────────────
class _PasswordStrength extends StatelessWidget {
  const _PasswordStrength({required this.password});

  final String password;

  int get _strength {
    int s = 0;
    if (password.length >= 8) s++;
    if (password.contains(RegExp(r'[A-Z]'))) s++;
    if (password.contains(RegExp(r'[0-9]'))) s++;
    if (password.contains(RegExp(r'[!@#\$%^&*]'))) s++;
    return s;
  }

  @override
  Widget build(BuildContext context) {
    final s = _strength;
    final color = s <= 1
        ? const Color(0xFFFF3B30)
        : s == 2
        ? const Color(0xFFF59E0B)
        : const Color(0xFF00D0A3);
    final label = s <= 1
        ? 'Weak'
        : s == 2
        ? 'Fair'
        : 'Strong';

    return Row(
      children: [
        ...List.generate(
          4,
          (i) => Expanded(
            child: Container(
              height: 3,
              margin: EdgeInsets.only(right: i < 3 ? 4 : 0),
              decoration: BoxDecoration(
                color: i < s ? color : Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
