import 'package:flutter_test/flutter_test.dart';
import 'package:toggle_me/features/auth/data/auth_service.dart';
import 'package:toggle_me/features/auth/data/kakao_auth_client.dart';
import 'package:toggle_me/features/auth/data/models/auth_error_code.dart';
import 'package:toggle_me/features/auth/data/models/onboarding_step.dart';

/// 실제 카카오 SDK 대신 쓰는 가짜. [token]이 null이면 '사용자가 취소'한 상황이에요.
class _FakeKakaoAuthClient extends KakaoAuthClient {
  _FakeKakaoAuthClient(this.token);

  final String? token;

  @override
  Future<String?> login() async => token;
}

void main() {
  group('자체 로그인', () {
    test('테스트 계정이면 DONE 응답을 돌려준다', () async {
      final response = await AuthService().login(
        id: 'test1234',
        password: '12345678',
      );

      expect(response.tokenType, 'Bearer');
      expect(response.expiresIn, 1800);
      expect(response.onboardingRequired, false);
      expect(response.onboardingStep, OnboardingStep.done);
    });

    test('틀리면 CREDENTIALS_INVALID 오류를 낸다', () async {
      await expectLater(
        AuthService().login(id: 'test1234', password: 'wrong'),
        throwsA(
          isA<AuthException>().having(
            (e) => e.code,
            'code',
            'CREDENTIALS_INVALID',
          ),
        ),
      );
    });
  });

  group('카카오 로그인', () {
    test('성공하면 신규 사용자(PROFILE) 응답을 돌려준다', () async {
      final service = AuthService(
        kakaoAuthClient: _FakeKakaoAuthClient('kakao-token'),
      );

      final response = await service.loginWithKakao();

      expect(response, isNotNull);
      expect(response!.onboardingRequired, true);
      expect(response.onboardingStep, OnboardingStep.profile);
    });

    test('사용자가 취소하면 서버 요청 없이 null을 돌려준다', () async {
      final service = AuthService(kakaoAuthClient: _FakeKakaoAuthClient(null));

      expect(await service.loginWithKakao(), isNull);
    });
  });
}
