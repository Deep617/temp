import 'package:seshlly/core/errors/app_error.dart';
import 'package:seshlly/features/subscription/data/datasource/subscription_remote_datasource.dart';
import 'package:seshlly/features/subscription/data/repositories/subscription_repository.dart';

import '../../../../../core/api/base_repository.dart';
import '../../../../../core/services/secure_storage_service.dart';

class SubscriptionRepositoriesImpl extends BaseRepository
    implements SubscriptionRepository {
  final SubscriptionRemoteDataSource remote;

  SubscriptionRepositoriesImpl(
    this.remote,
    super.connectivity,
  );

  @override
  Future<Map<String, dynamic>> buyTokens(int pack) {
    return remote.buyTokens(pack).catchError((e) {
      throw AppError.fromException(e);
    });
  }

  @override
  Future<Map<String, dynamic>> createOrder(String planId) {
    return remote.createOrder(planId).catchError((e) {
      throw AppError.fromException(e);
    });
  }

  @override
  Future<List<Map<String, dynamic>>> getPlans() {
    return remote.getPlans().catchError((e) {
      throw AppError.fromException(e);
    });
  }

  @override
  Future<Map<String, dynamic>> verifyPayment(Map<String, dynamic> data) {
    return remote.verifyPayment(data).catchError((e) {
      throw AppError.fromException(e);
    });
  }
}
