import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/errors/app_error.dart';
import '../../data/repositories/subscription_repository.dart';

part 'subscription_event.dart';
part 'subscription_state.dart';

class SubscriptionBloc extends Bloc<SubscriptionEvent, SubscriptionState> {
  SubscriptionBloc({required SubscriptionRepository subscriptionRepository})
      : _repo = subscriptionRepository,
        super(const SubscriptionState()) {
    on<SubscriptionPlansLoaded>   (_onPlansLoaded);
    on<SubscriptionOrderCreated>  (_onOrderCreated);
    on<SubscriptionPaymentVerified>(_onPaymentVerified);
    on<TokensOrderCreated>        (_onTokensOrder);
  }

  final SubscriptionRepository _repo;

  Future<void> _onPlansLoaded(
    SubscriptionPlansLoaded event,
    Emitter<SubscriptionState> emit,
  ) async {
    emit(state.copyWith(status: SubscriptionStatus.loading, clearError: true));
    try {
      final plans = await _repo.getPlans();
      emit(state.copyWith(status: SubscriptionStatus.plansLoaded, plans: plans));
    } on AppError catch (e) {
      emit(state.copyWith(status: SubscriptionStatus.failure, error: e));
    }
  }

  Future<void> _onOrderCreated(
    SubscriptionOrderCreated event,
    Emitter<SubscriptionState> emit,
  ) async {
    emit(state.copyWith(status: SubscriptionStatus.loading, clearError: true));
    try {
      final order = await _repo.createOrder(event.planId);
      emit(state.copyWith(status: SubscriptionStatus.orderReady, order: order));
    } on AppError catch (e) {
      emit(state.copyWith(status: SubscriptionStatus.failure, error: e));
    }
  }

  Future<void> _onPaymentVerified(
    SubscriptionPaymentVerified event,
    Emitter<SubscriptionState> emit,
  ) async {
    emit(state.copyWith(status: SubscriptionStatus.loading));
    try {
      await _repo.verifyPayment(event.data);
      emit(state.copyWith(
        status:     SubscriptionStatus.paymentVerified,
        clearOrder: true,
      ));
    } on AppError catch (e) {
      emit(state.copyWith(status: SubscriptionStatus.failure, error: e));
    }
  }

  Future<void> _onTokensOrder(
    TokensOrderCreated event,
    Emitter<SubscriptionState> emit,
  ) async {
    emit(state.copyWith(status: SubscriptionStatus.loading, clearError: true));
    try {
      final order = await _repo.buyTokens(event.pack);
      emit(state.copyWith(status: SubscriptionStatus.orderReady, order: order));
    } on AppError catch (e) {
      emit(state.copyWith(status: SubscriptionStatus.failure, error: e));
    }
  }
}
