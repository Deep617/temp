import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/common/common_widgets.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../bloc/subscription_bloc.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  late Razorpay _razorpay;
  String? _selectedPlanId;
  int? _selectedTokenPack;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _onPaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _onPaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _onExternalWallet);

    // Load plans via BLoC
    context.read<SubscriptionBloc>().add(const SubscriptionPlansLoaded());
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  void _subscribePlan(Map<String, dynamic> plan) {
    _selectedPlanId = plan['id'] as String;
    _selectedTokenPack = null;
    context.read<SubscriptionBloc>().add(
      SubscriptionOrderCreated(planId: plan['id'] as String),
    );
  }

  void _buyTokens(int pack) {
    _selectedTokenPack = pack;
    _selectedPlanId = null;
    context.read<SubscriptionBloc>().add(TokensOrderCreated(pack: pack));
  }

  void _openRazorpay(Map<String, dynamic> order, String description) {
    final user = context.read<AuthBloc>().state.user;
    final options = {
      'key': order['razorpayKeyId'] ?? 'rzp_test_xxxxxxxxxx',
      'amount': order['amount'],
      'currency': order['currency'] ?? 'INR',
      'name': 'FitConnect',
      'description': description,
      'order_id': order['id'],
      'prefill': {'name': user?.fullName ?? '', 'email': user?.email ?? ''},
      'theme': {'color': '#BAEE0B'},
    };
    _razorpay.open(options);
  }

  void _onPaymentSuccess(PaymentSuccessResponse res) {
    context.read<SubscriptionBloc>().add(
      SubscriptionPaymentVerified(
        data: {
          'razorpay_order_id': res.orderId,
          'razorpay_payment_id': res.paymentId,
          'razorpay_signature': res.signature,
          'planId': _selectedPlanId,
          'tokenPack': _selectedTokenPack,
        },
      ),
    );
  }

  void _onPaymentError(PaymentFailureResponse res) {
    _showError(res.message ?? 'Payment failed');
  }

  void _onExternalWallet(ExternalWalletResponse res) {
    /* wallet chosen – wait for success/error event */
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: AppTextStyles.bodySM(color: AppColors.error)),
        backgroundColor: AppColors.surface2,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SubscriptionBloc, SubscriptionState>(
      listener: (context, state) {
        // When order is ready, open Razorpay
        if (state.isOrderReady && state.order != null) {
          final desc = _selectedPlanId != null
              ? 'Subscription'
              : '$_selectedTokenPack Chat Tokens';
          _openRazorpay(state.order!, desc);
        }

        // Payment verified — refresh auth user, pop screen
        if (state.isVerified) {
          context.read<AuthBloc>().add(const AuthCheckRequested());
          context.pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Payment successful! 🎉',
                style: AppTextStyles.body(),
              ),
            ),
          );
        }

        if (state.status == SubscriptionStatus.failure && state.error != null) {
          _showError(state.error!.message);
        }
      },
      builder: (context, state) {
        final user = context.watch<AuthBloc>().state.user;

        return Scaffold(
          backgroundColor: AppColors.bg,
          appBar: AppBar(
            backgroundColor: AppColors.bg,
            title: Text('Upgrade', style: AppTextStyles.h3()),
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => context.pop(),
            ),
          ),
          body:
              state.status == SubscriptionStatus.initial ||
                  state.status == SubscriptionStatus.loading &&
                      state.plans.isEmpty
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                )
              : state.status == SubscriptionStatus.failure &&
                    state.plans.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Failed to load plans', style: AppTextStyles.body()),
                      const SizedBox(height: 16),
                      GhostButton(
                        label: 'Retry',
                        onPressed: () => context.read<SubscriptionBloc>().add(
                          const SubscriptionPlansLoaded(),
                        ),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Hero Banner ─────────────────
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: AppColors.membershipGradient,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.3),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '🏆 Unlock Your Full Potential',
                              style: AppTextStyles.h3(color: AppColors.primary),
                            ),
                            const SizedBox(height: 12),
                            for (final f in [
                              '♾️  Unlimited daily swipes',
                              '⚡  Priority match algorithm',
                              '💬  Free chat tokens every month',
                              '✅  Pro badge on your profile',
                              '📊  Advanced analytics',
                            ])
                              Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(f, style: AppTextStyles.bodySM()),
                              ),
                          ],
                        ),
                      ).animate().fadeIn().slideY(begin: -0.2),

                      const SizedBox(height: 24),

                      // ── Plans ────────────────────────
                      Text('CHOOSE A PLAN', style: AppTextStyles.label()),
                      const SizedBox(height: 14),

                      ...state.plans.asMap().entries.map((e) {
                        final plan = e.value;
                        final isPopular = plan['isPopular'] == true;
                        final isCurrent =
                            user?.subscriptionPlan == plan['slug'];
                        final isProcessing =
                            state.isLoading && _selectedPlanId == plan['id'];

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: GestureDetector(
                            onTap: (isCurrent || state.isLoading)
                                ? null
                                : () => _subscribePlan(plan),
                            child: Container(
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: isPopular
                                    ? AppColors.primary.withOpacity(0.08)
                                    : AppColors.surface1,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isCurrent
                                      ? AppColors.teal.withOpacity(0.5)
                                      : isPopular
                                      ? AppColors.primary.withOpacity(0.4)
                                      : AppColors.border2,
                                  width: isPopular ? 1.5 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              plan['name'] as String,
                                              style: AppTextStyles.subtitle(),
                                            ),
                                            if (isPopular) ...[
                                              const SizedBox(width: 8),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 3,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: AppColors.primary,
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        100,
                                                      ),
                                                ),
                                                child: Text(
                                                  'POPULAR',
                                                  style: AppTextStyles.label(
                                                    color: Colors.black,
                                                  ).copyWith(fontSize: 9),
                                                ),
                                              ),
                                            ],
                                            if (isCurrent) ...[
                                              const SizedBox(width: 8),
                                              const Icon(
                                                Icons.check_circle,
                                                color: AppColors.teal,
                                                size: 16,
                                              ),
                                            ],
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          plan['description'] as String? ?? '',
                                          style: AppTextStyles.bodySM(),
                                        ),
                                        if (plan['features'] != null) ...[
                                          const SizedBox(height: 8),
                                          ...(plan['features'] as List)
                                              .take(3)
                                              .map(
                                                (f) => Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                        bottom: 2,
                                                      ),
                                                  child: Text(
                                                    '· $f',
                                                    style:
                                                        AppTextStyles.bodySM(),
                                                  ),
                                                ),
                                              ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '₹${plan['price']}',
                                        style: AppTextStyles.h2(
                                          color: isPopular
                                              ? AppColors.primary
                                              : AppColors.textPrimary,
                                        ),
                                      ),
                                      Text(
                                        '${(plan['interval'] as String?)?.toLowerCase() ?? 'mo'}',
                                        style: AppTextStyles.caption(),
                                      ),
                                      const SizedBox(height: 8),
                                      if (!isCurrent)
                                        isProcessing
                                            ? const SizedBox(
                                                width: 20,
                                                height: 20,
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      color: AppColors.primary,
                                                    ),
                                              )
                                            : Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 14,
                                                      vertical: 7,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: isPopular
                                                      ? AppColors.primary
                                                      : AppColors.surface3,
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                                child: Text(
                                                  'Select',
                                                  style: AppTextStyles.btn(
                                                    color: isPopular
                                                        ? Colors.black
                                                        : AppColors.textPrimary,
                                                  ).copyWith(fontSize: 12),
                                                ),
                                              )
                                      else
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 5,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.teal.withOpacity(
                                              0.15,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Text(
                                            'Active',
                                            style: AppTextStyles.label(
                                              color: AppColors.teal,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ).animate(delay: Duration(milliseconds: e.key * 100)).fadeIn().slideY(begin: 0.2),
                          ),
                        );
                      }),

                      const SizedBox(height: 24),

                      // ── Token Packs ──────────────────
                      const Divider(),
                      const SizedBox(height: 20),
                      SectionHeader(
                        title: 'Buy Chat Tokens',
                        subtitle: 'Tokens are deducted when you miss a session',
                        action: user != null
                            ? '${user.chatTokens} remaining'
                            : null,
                      ).animate(delay: 300.ms).fadeIn(),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          _TokenPack(
                            tokens: 10,
                            price: 29,
                            processing:
                                state.isLoading && _selectedTokenPack == 10,
                            onBuy: () => _buyTokens(10),
                          ),
                          const SizedBox(width: 10),
                          _TokenPack(
                            tokens: 20,
                            price: 49,
                            popular: true,
                            processing:
                                state.isLoading && _selectedTokenPack == 20,
                            onBuy: () => _buyTokens(20),
                          ),
                          const SizedBox(width: 10),
                          _TokenPack(
                            tokens: 50,
                            price: 99,
                            processing:
                                state.isLoading && _selectedTokenPack == 50,
                            onBuy: () => _buyTokens(50),
                          ),
                        ],
                      ).animate(delay: 350.ms).fadeIn(),

                      const SizedBox(height: 24),

                      Center(
                        child: Column(
                          children: [
                            Text(
                              'Secure payments powered by Razorpay',
                              style: AppTextStyles.caption(),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Subscriptions auto-renew. Cancel anytime.',
                              style: AppTextStyles.caption(),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
        );
      },
    );
  }
}

class _TokenPack extends StatelessWidget {
  const _TokenPack({
    required this.tokens,
    required this.price,
    required this.onBuy,
    required this.processing,
    this.popular = false,
  });

  final int tokens, price;
  final VoidCallback onBuy;
  final bool processing, popular;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: processing ? null : onBuy,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: popular
                ? AppColors.primary.withOpacity(0.1)
                : AppColors.surface1,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: popular
                  ? AppColors.primary.withOpacity(0.4)
                  : AppColors.border2,
              width: popular ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              if (popular)
                Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    'BEST',
                    style: AppTextStyles.label(
                      color: Colors.black,
                    ).copyWith(fontSize: 9),
                  ),
                ),
              const Text('🎫', style: TextStyle(fontSize: 28)),
              const SizedBox(height: 6),
              Text(
                '$tokens',
                style: AppTextStyles.h2(
                  color: popular ? AppColors.primary : AppColors.textPrimary,
                ),
              ),
              Text('tokens', style: AppTextStyles.caption()),
              const SizedBox(height: 8),
              processing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    )
                  : Text(
                      '₹$price',
                      style: AppTextStyles.subtitle(
                        color: popular
                            ? AppColors.primary
                            : AppColors.textSecondary,
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
