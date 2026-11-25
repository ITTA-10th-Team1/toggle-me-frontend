import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// �α��� ��ū�� ����� ������ ����ҿ� �����ϴ� ���.
/// (Android: ��ȣȭ �����, iOS: Űü��)
///
/// TODO(token): ��ū �����⡤�����(�α׾ƿ�), �ڵ� ������
///   �� API ��� ������ �������� ���� �߰��ؿ�.
class TokenStorage {
  TokenStorage({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const accessTokenKey = 'accessToken';
  static const refreshTokenKey = 'refreshToken';

  final FlutterSecureStorage _storage;

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _storage.write(key: accessTokenKey, value: accessToken);
    await _storage.write(key: refreshTokenKey, value: refreshToken);
  }

  Future<String?> getAccessToken() async {
    return _storage.read(key: accessTokenKey);
  }

  Future<String?> getRefreshToken() async {
    return _storage.read(key: refreshTokenKey);
  }

  Future<void> clearTokens() async {
    await _storage.delete(key: accessTokenKey);
    await _storage.delete(key: refreshTokenKey);
  }
}
