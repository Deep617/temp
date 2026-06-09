part of 'subscription_bloc.dart';

enum SubscriptionStatus { initial, loading, plansLoaded, orderReady, paymentVerified, failure }

class SubscriptionState extends Equatable {
  const SubscriptionState({
    this.status = SubscriptionStatus.initial,
    this.plans  = const [],
    this.order,
    this.error,
  });

  final SubscriptionStatus          status;
  final List<Map<String, dynamic>>  plans;
  final Map<String, dynamic>?       order;  // Razorpay order payload
  final AppError?                   error;

  bool get isLoading       => status == SubscriptionStatus.loading;
  bool get isOrderReady    => status == SubscriptionStatus.orderReady;
  bool get isVerified      => status == SubscriptionStatus.paymentVerified;

  SubscriptionState copyWith({
    SubscriptionStatus?          status,
    List<Map<String, dynamic>>?  plans,
    Map<String, dynamic>?        order,
    AppError?                    error,
    bool                         clearError = false,
    bool                         clearOrder = false,
  }) =>
      SubscriptionState(
        status: status ?? this.status,
        plans:  plans  ?? this.plans,
        order:  clearOrder ? null : order ?? this.order,
        error:  clearError ? null : error ?? this.error,
      );

  @override
  List<Object?> get props => [status, plans, order, error];
}
