import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:new_arch/features/auth/data/models/register_request.dart';
import 'package:new_arch/features/auth/presentation/bloc/auth_state.dart';
import 'package:new_arch/routes/app_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/common/common_widgets.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstCtrl = TextEditingController();
  final _lastCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _showPass = false;
  bool _agreeTerms = false;
  String? _termsError;

  @override
  void dispose() {
    for (final c in [_firstCtrl, _lastCtrl, _emailCtrl, _phoneCtrl, _passCtrl])
      c.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreeTerms) {
      setState(() => _termsError = 'Please accept the terms');
      return;
    }
    setState(() => _termsError = null);
    context.read<AuthBloc>().add(
      RegisterSubmitted(
        registerRequest: RegisterRequest(
          firstName: _firstCtrl.text.trim(),
          lastName: _lastCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          phone: _phoneCtrl.text.trim(),
          password: _passCtrl.text,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text('Create Account', style: AppTextStyles.h3()),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: BlocConsumer<AuthBloc, LoginState>(
            listener: (context, state) {
              if (state.isSuccess) {
                context.push(AppRoutesPath.onboarding);
              } // Router handles redirect to onboarding
              // on success
            },
            builder: (context, state) => Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),

                  if (state.error != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.error.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.warning_amber,
                            color: AppColors.error,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              state.error!.message,
                              style: AppTextStyles.bodySM(
                                color: AppColors.error,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  Row(
                    children: [
                      Expanded(
                        child: AppInput(
                          label: 'First Name',
                          hint: 'Alex',
                          controller: _firstCtrl,
                          textCapitalization: TextCapitalization.words,
                          validator: (v) =>
                              (v?.isEmpty ?? true) ? 'Required' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppInput(
                          label: 'Last Name',
                          hint: 'Rivera',
                          controller: _lastCtrl,
                          textCapitalization: TextCapitalization.words,
                          validator: (v) =>
                              (v?.isEmpty ?? true) ? 'Required' : null,
                        ),
                      ),
                    ],
                  ).animate(delay: 100.ms).fadeIn().slideY(begin: 0.2),

                  const SizedBox(height: 16),
                  AppInput(
                    label: 'Email Address',
                    hint: 'you@example.com',
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: Icons.email_outlined,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Email required';
                      if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v))
                        return 'Invalid email';
                      return null;
                    },
                  ).animate(delay: 150.ms).fadeIn().slideY(begin: 0.2),

                  const SizedBox(height: 16),
                  AppInput(
                    label: 'Phone Number',
                    hint: '+91 98765 43210',
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                    prefixIcon: Icons.phone_outlined,
                    validator: (v) =>
                        (v?.isEmpty ?? true) ? 'Phone required' : null,
                  ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.2),

                  const SizedBox(height: 16),
                  AppInput(
                    label: 'Password',
                    hint: '••••••••',
                    controller: _passCtrl,
                    obscure: !_showPass,
                    prefixIcon: Icons.lock_outline,
                    suffix: GestureDetector(
                      onTap: () => setState(() => _showPass = !_showPass),
                      child: Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: Icon(
                          _showPass
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: AppColors.textDim,
                          size: 20,
                        ),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.length < 8) return 'Min 8 characters';
                      if (!RegExp(r'(?=.*[A-Z])(?=.*[0-9])').hasMatch(v))
                        return 'Include uppercase + number';
                      return null;
                    },
                  ).animate(delay: 250.ms).fadeIn().slideY(begin: 0.2),

                  const SizedBox(height: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Checkbox(
                            value: _agreeTerms,
                            onChanged: (v) =>
                                setState(() => _agreeTerms = v ?? false),
                          ),
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: 'I agree to the ',
                                    style: AppTextStyles.bodySM(),
                                  ),
                                  TextSpan(
                                    text: 'Terms of Service',
                                    style: AppTextStyles.bodySM(
                                      color: AppColors.primary,
                                    ).copyWith(fontWeight: FontWeight.w700),
                                  ),
                                  TextSpan(
                                    text: ' and ',
                                    style: AppTextStyles.bodySM(),
                                  ),
                                  TextSpan(
                                    text: 'Privacy Policy',
                                    style: AppTextStyles.bodySM(
                                      color: AppColors.primary,
                                    ).copyWith(fontWeight: FontWeight.w700),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (_termsError != null)
                        Padding(
                          padding: const EdgeInsets.only(left: 12),
                          child: Text(
                            _termsError!,
                            style: AppTextStyles.bodySM(color: AppColors.error),
                          ),
                        ),
                    ],
                  ).animate(delay: 300.ms).fadeIn(),

                  const SizedBox(height: 28),

                  PrimaryButton(
                    label: 'Create Account',
                    loading: state.isLoading,
                    onPressed: _submit,
                  ).animate(delay: 350.ms).fadeIn().slideY(begin: 0.3),

                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Already have an account? ',
                        style: AppTextStyles.bodySM(),
                      ),
                      GestureDetector(
                        onTap: () =>
                            context.pushReplacement(AppRoutesPath.login),
                        child: Text(
                          'Sign In',
                          style: AppTextStyles.bodySM(
                            color: AppColors.primary,
                          ).copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ).animate(delay: 400.ms).fadeIn(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
