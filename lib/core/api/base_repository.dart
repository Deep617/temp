import '../errors/app_exception.dart';
import '../network/connectivity_service.dart';

abstract class BaseRepository {
  final ConnectivityService connectivity;

  BaseRepository(this.connectivity);

  Future<T> safeApiCall<T>(Future<T> Function() apiCall) async {
    try {
/*      final connected = await connectivity.isConnected();
      if (!connected) {
        throw AppException(message: "No Internet Connection");
      }*/
      return await apiCall();
    } catch (e) {
      throw AppException.handle(e);
    }
  }
}
