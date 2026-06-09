// ── subscription_event.dart ───────────────────────────────
part of 'subscription_bloc.dart';

abstract class SubscriptionEvent extends Equatable {
  const SubscriptionEvent();
  @override
  List<Object?> get props => [];
}

class SubscriptionPlansLoaded extends SubscriptionEvent {
  const SubscriptionPlansLoaded();
}

class SubscriptionOrderCreated extends SubscriptionEvent {
  const SubscriptionOrderCreated({required this.planId});
  final String planId;
  @override
  List<Object?> get props => [planId];
}

class SubscriptionPaymentVerified extends SubscriptionEvent {
  const SubscriptionPaymentVerified({required this.data});
  final Map<String, dynamic> data;
  @override
  List<Object?> get props => [data];
}

class TokensOrderCreated extends SubscriptionEvent {
  const TokensOrderCreated({required this.pack});
  final int pack;
  @override
  List<Object?> get props => [pack];
}
