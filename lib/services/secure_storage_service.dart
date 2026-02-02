import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static const _storage = FlutterSecureStorage();
  static const _refreshTokenKey = 'refreshToken';

  // Private constructor
  SecureStorageService._();
  
  // Singleton instance
  static final SecureStorageService instance = SecureStorageService._();

  Future<void> saveRefreshToken(String token) async {
    await _storage.write(key: _refreshTokenKey, value: token);
  }

  Future<String?> getRefreshToken() async {
    return await _storage.read(key: _refreshTokenKey);
  }

  Future<void> deleteRefreshToken() async {
    await _storage.delete(key: _refreshTokenKey);
  }

  Future<void> deleteAll() async {
    await _storage.deleteAll();
  }
}
