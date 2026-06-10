import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static const _kAccessToken = "access_token";
  static const _kRefreshToken = "refresh_token";

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<void> saveAccessToken(String token) async {
    await _storage.write(key: _kAccessToken, value: token);
  }

  Future<String?> getAccessToken() async {
    return await _storage.read(key: _kAccessToken);
  }

  Future<void> saveRefreshToken(String token) async {
    await _storage.write(key: _kRefreshToken, value: token);
  }

  Future<String?> getRefreshToken() async {
    return await _storage.read(key: _kRefreshToken);
  }

  Future<void> clearStorage() async {
    await _storage.deleteAll();
  }

  Future<void> clearAccessToken() async {
    await _storage.delete(key: _kAccessToken);
  }

  Future<void> clearRefreshToken() async {
    await _storage.delete(key: _kRefreshToken);
  }
}
