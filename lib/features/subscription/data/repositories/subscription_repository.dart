// ── SubscriptionRepository ────────────────────────────────
abstract class SubscriptionRepository {
  SubscriptionRepository();

  Future<List<Map<String, dynamic>>> getPlans();

  Future<Map<String, dynamic>> createOrder(String planId);

  Future<Map<String, dynamic>> verifyPayment(Map<String, dynamic> data);

  Future<Map<String, dynamic>> buyTokens(int pack);
}
