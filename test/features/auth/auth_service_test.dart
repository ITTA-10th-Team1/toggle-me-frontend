import 'package:flutter_test/flutter_test.dart';
import 'package:toggle_me/features/auth/data/auth_api_client.dart';
import 'package:toggle_me/features/auth/data/auth_service.dart';
import 'package:toggle_me/features/auth/data/kakao_auth_client.dart';
import 'package:toggle_me/features/auth/data/models/auth_error_code.dart';
import 'package:toggle_me/features/auth/data/models/onboarding_step.dart';
import 'package:toggle_me/features/auth/data/token_storage.dart';

/// 실제 카카오 SDK 대신 쓰는 가짜. [token]이 null이면 '사용자가 취소'한 상황이에요.
class _FakeKakaoAuthClient extends KakaoAuthClient {
  _FakeKakaoAuthClient(this.token);

  final String? token;

  @override
  Future<String?> login() async => token;
}

/// 실제 서버 대신 정해진 응답을 돌려주는 가짜. 보낸 요청을 기록해요.
class _FakeAuthApiClient extends AuthApiClient {
  _FakeAuthApiClient({this.response, this.error});

  final Map<String, dynamic>? response;
  final AuthException? error;

  final requests = <({String path, Map<String, dynamic> body})>[];

  @override
  Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> body,
  ) async {
    requests.add((path: path, body: body));
    if (error != null) throw error!;
    return response!;
  }
}

/// 기기 저장소 대신 메모리에 저장하는 가짜
class _FakeTokenStorage extends TokenStorage {
  String? accessToken;
  String? refreshToken;

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    this.accessToken = accessToken;
    this.refreshToken = refreshToken;
  }
}

// 백엔드 API 명세 성공 응답 예시와 같은 모양
const _doneResponse = {
  'accessToken': 'access-1',
  'refreshToken': 'refresh-1',
  'tokenType': 'Bearer',
  'expiresIn': 1800,
  'onboardingRequired': false,
  'onboardingStep': 'DONE',
};

const _profileResponse = {
  'accessToken': 'access-2',
  'refreshToken': 'refresh-2',
  'tokenType': 'Bearer',
  'expiresIn': 1800,
  'onboardingRequired': true,
  'onboardingStep': 'PROFILE',
};

void main() {
  group('자체 로그인', () {
    test('명세대로 요청을 보내고, 성공하면 토큰을 저장한다', () async {
      final api = _FakeAuthApiClient(response: _doneResponse);
      final storage = _FakeTokenStorage();
      final service = AuthService(apiClient: api, tokenStorage: storage);

      final response = await service.login(id: 'toggle01', password: 'pw1234');

      expect(api.requests.single.path, '/api/v1/auth/login');
      expect(api.requests.single.body, {
        'loginId': 'toggle01',
        'password': 'pw1234',
      });
      expect(response.onboardingStep, OnboardingStep.done);
      expect(storage.accessToken, 'access-1');
      expect(storage.refreshToken, 'refresh-1');
    });

    test('실패하면 오류를 그대로 전달하고 토큰은 저장하지 않는다', () async {
      final storage = _FakeTokenStorage();
      final service = AuthService(
        apiClient: _FakeAuthApiClient(
          error: const AuthException(
            AuthErrorCode.credentialsInvalid,
            '아이디 또는 비밀번호가 올바르지 않습니다.',
          ),
        ),
        tokenStorage: storage,
      );

      await expectLater(
        service.login(id: 'toggle01', password: 'wrong'),
        throwsA(
          isA<AuthException>().having(
            (e) => e.code,
            'code',
            'CREDENTIALS_INVALID',
          ),
        ),
      );
      expect(storage.accessToken, isNull);
    });
  });

  group('카카오 로그인', () {
    test('카카오 토큰을 서버로 보내고, 성공하면 토큰을 저장한다', () async {
      final api = _FakeAuthApiClient(response: _profileResponse);
      final storage = _FakeTokenStorage();
      final service = AuthService(
        kakaoAuthClient: _FakeKakaoAuthClient('kakao-token'),
        apiClient: api,
        tokenStorage: storage,
      );

      final response = await service.loginWithKakao();

      expect(api.requests.single.path, '/api/v1/auth/oauth/kakao');
      expect(api.requests.single.body, {'accessToken': 'kakao-token'});
      expect(response!.onboardingStep, OnboardingStep.profile);
      expect(storage.accessToken, 'access-2');
      expect(storage.refreshToken, 'refresh-2');
    });

    test('사용자가 취소하면 서버 요청 없이 null을 돌려준다', () async {
      final api = _FakeAuthApiClient(response: _profileResponse);
      final service = AuthService(
        kakaoAuthClient: _FakeKakaoAuthClient(null),
        apiClient: api,
        tokenStorage: _FakeTokenStorage(),
      );

      expect(await service.loginWithKakao(), isNull);
      expect(api.requests, isEmpty);
    });
  });
}
