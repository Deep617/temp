import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:seshlly/core/services/storage_service.dart';
import 'package:seshlly/di_injection/dependency_injection.dart';
import 'package:seshlly/features/auth/presentation/bloc/auth_event.dart';
import 'package:seshlly/features/auth/presentation/bloc/auth_state.dart';
import 'package:seshlly/routes/app_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/common/common_widgets.dart';
import '../bloc/auth_bloc.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _showPass = false;
  bool isOnBoarded = false;

  @override
  void initState() {
    super.initState();
    getOnboarding();
  }

  getOnboarding() async {
    isOnBoarded = await storageService.getOnboarding();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthBloc>().add(
      LoginSubmitted(email: _emailCtrl.text.trim(), password: _passCtrl.text),
    );
  }

  StorageService storageService = getIt<StorageService>();

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, LoginState>(
      listener: (context, state) {
        // Navigation handled by GoRouter redirect — nothing to do here.
        // Errors are surfaced via BlocBuilder below.
        if (state.isSuccess) {
          if (isOnBoarded) {
            context.push(AppRoutes.home);
          } else {
            context.push(AppRoutes.onboarding);
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Login Successfully 💪',
                style: AppTextStyles.body(),
              ),
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.bg,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
            onPressed: () => context.pop(),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: BlocBuilder<AuthBloc, LoginState>(
              builder: (context, state) {
                return Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      Text(
                        'Welcome back',
                        style: AppTextStyles.h1(),
                      ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.2),
                      const SizedBox(height: 8),
                      Text(
                        'Sign in to your FitConnect account',
                        style: AppTextStyles.body(),
                      ).animate(delay: 100.ms).fadeIn(),
                      const SizedBox(height: 40),

                      // Error banner
                      if (state.error != null)
                        Container(
                          margin: const EdgeInsets.only(bottom: 20),
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
                        ).animate().fadeIn().shake(),

                      AppInput(
                        label: 'Email Address',
                        hint: 'you@example.com',
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        prefixIcon: Icons.email_outlined,
                        validator: (v) {
                          if (v == null || v.isEmpty)
                            return 'Email is required';
                          if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v))
                            return 'Enter a valid email';
                          return null;
                        },
                      ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.2),

                      const SizedBox(height: 18),

                      AppInput(
                        label: 'Password',
                        hint: '••••••••',
                        controller: _passCtrl,
                        obscure: !_showPass,
                        keyboardType: TextInputType.visiblePassword,
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
                        validator: (v) => (v == null || v.length < 6)
                            ? 'Password must be at least 6 characters'
                            : null,
                      ).animate(delay: 300.ms).fadeIn().slideY(begin: 0.2),

                      const SizedBox(height: 12),

                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {},
                          child: Text(
                            'Forgot password?',
                            style: AppTextStyles.bodySM(
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 28),

                      PrimaryButton(
                        label: 'Sign In',
                        loading: state.isLoading,
                        onPressed: _submit,
                      ).animate(delay: 400.ms).fadeIn().slideY(begin: 0.3),

                      const SizedBox(height: 32),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Don't have an account? ",
                            style: AppTextStyles.bodySM(),
                          ),
                          GestureDetector(
                            onTap: () =>
                                context.pushReplacement(AppRoutes.register),
                            child: Text(
                              'Sign Up',
                              style: AppTextStyles.bodySM(
                                color: AppColors.primary,
                              ).copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ).animate(delay: 500.ms).fadeIn(),

                      const SizedBox(height: 40),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
