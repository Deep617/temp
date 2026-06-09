import 'package:dio/dio.dart';

import '../../../../core/api/dio_client.dart';

class SubscriptionRemoteDataSource {
  final DioClient _dio;

  SubscriptionRemoteDataSource(this._dio);

  // SUBSCRIPTIONS
  Future<List<Map<String, dynamic>>> getPlans() async {
    final res = await _dio.get('/subscriptions/plans');
    return (_body(res)['data'] as List).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> createOrder(String planId) async {
    final res = await _dio.post(
      '/subscriptions/order',
      data: {'planId': planId},
    );
    return _body(res)['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> verifyPayment(Map<String, dynamic> data) async {
    final res = await _dio.post('/subscriptions/verify-payment', data: data);
    return _body(res)['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> buyTokens(int pack) async {
    final res = await _dio.post('/tokens/buy', data: {'pack': pack});
    return _body(res)['data'] as Map<String, dynamic>;
  }

  Map<String, dynamic> _body(Response res) {
    if (res.statusCode != null &&
        res.statusCode! >= 200 &&
        res.statusCode! < 300) {
      return res.data as Map<String, dynamic>;
    }
    throw Exception(
      (res.data as Map<String, dynamic>?)?['message'] ?? 'Request failed',
    );
  }
}
