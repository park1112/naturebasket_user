import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // 데이터 저장
  Future<void> write({required String key, required String value}) async {
    await _storage.write(key: key, value: value);
  }

  // 데이터 읽기
  Future<String?> read({required String key}) async {
    return await _storage.read(key: key);
  }

  // 데이터 삭제
  Future<void> delete({required String key}) async {
    await _storage.delete(key: key);
  }

  // 모든 데이터 삭제
  Future<void> deleteAll() async {
    await _storage.deleteAll();
  }

  // 모든 데이터 조회
  Future<Map<String, String>> readAll() async {
    return await _storage.readAll();
  }

  // 토큰 관련 메서드
  Future<void> saveAccessToken(String token) async {
    await write(key: 'accessToken', value: token);
  }

  Future<String?> getAccessToken() async {
    return await read(key: 'accessToken');
  }

  Future<void> clearTokens() async {
    await delete(key: 'accessToken');
    await delete(key: 'refreshToken');
  }
}
