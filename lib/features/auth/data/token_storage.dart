import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// 로그인 토큰을 기기의 안전한 저장소에 보관하는 담당.
/// (Android: 암호화 저장소, iOS: 키체인)
///
/// TODO(token): 토큰 꺼내기·지우기(로그아웃), 자동 갱신은
///   팀 API 통신 구조가 정해지면 같이 추가해요.
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
}
