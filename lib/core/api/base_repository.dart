import '../errors/app_error.dart';
import '../network/connectivity_service.dart';

abstract class BaseRepository {
  final ConnectivityService connectivity;

  BaseRepository(this.connectivity);

  Future<T> safeApiCall<T>(Future<T> Function() apiCall) async {
    try {
      /* final connected = await connectivity.isConnected();
      if (!connected) {
        throw AppException(message: "No Internet Connection");
      }*/
      return await apiCall();
    } on AppError {
      rethrow;
    } catch (e) {
      throw AppError.fromException(e);
    }
  }
}
