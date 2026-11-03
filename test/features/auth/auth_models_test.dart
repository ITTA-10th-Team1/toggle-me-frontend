import 'package:flutter_test/flutter_test.dart';
import 'package:toggle_me/features/auth/data/models/login_response.dart';
import 'package:toggle_me/features/auth/data/models/onboarding_step.dart';

void main() {
  group('OnboardingStep', () {
    test('서버 문자열(대문자)을 enum으로 바꾼다', () {
      expect(OnboardingStep.fromValue('PROFILE'), OnboardingStep.profile);
      expect(OnboardingStep.fromValue('FURNITURE'), OnboardingStep.furniture);
      expect(OnboardingStep.fromValue('DONE'), OnboardingStep.done);
    });

    test('대소문자가 다르거나 모르는 값이면 오류를 낸다', () {
      expect(() => OnboardingStep.fromValue('done'), throwsFormatException);
      expect(() => OnboardingStep.fromValue('ROOM'), throwsFormatException);
    });
  });

  group('LoginResponse', () {
    // 백엔드 API 명세 자체 로그인 성공 응답 예시와 같은 모양
    const json = {
      'accessToken': 'eyJraWQiOi...',
      'refreshToken': 'Rv4fSf6BuNcsaMmI3Y5cccLGIbPZyiDstI0Wau311SM',
      'tokenType': 'Bearer',
      'expiresIn': 1800,
      'onboardingRequired': false,
      'onboardingStep': 'DONE',
    };

    test('명세 JSON을 읽는다', () {
      final response = LoginResponse.fromJson(json);

      expect(response.accessToken, 'eyJraWQiOi...');
      expect(
        response.refreshToken,
        'Rv4fSf6BuNcsaMmI3Y5cccLGIbPZyiDstI0Wau311SM',
      );
      expect(response.tokenType, 'Bearer');
      expect(response.expiresIn, 1800);
      expect(response.onboardingRequired, false);
      expect(response.onboardingStep, OnboardingStep.done);
    });

    test('toJson은 명세와 같은 키·값으로 되돌린다', () {
      expect(LoginResponse.fromJson(json).toJson(), json);
    });
  });
}
