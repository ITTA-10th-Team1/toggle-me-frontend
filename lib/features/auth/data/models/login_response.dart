import 'onboarding_step.dart';

/// 자체 로그인(POST /api/v1/auth/login)과
/// 카카오 로그인(POST /api/v1/auth/oauth/kakao)의 성공 응답 (백엔드 API 명세).
/// 두 API의 응답 모양이 같아서 하나의 클래스로 써요.
class LoginResponse {
  const LoginResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.tokenType,
    required this.expiresIn,
    required this.onboardingRequired,
    required this.onboardingStep,
  });

  /// 우리 서비스 JWT. 수명 30분
  final String accessToken;

  /// 토큰 갱신용. 수명 14일, 1회용 (갱신하면 새 값으로 교체)
  final String refreshToken;

  /// 항상 'Bearer'
  final String tokenType;

  /// accessToken 수명(초). 1800
  final int expiresIn;

  /// onboardingStep != DONE
  final bool onboardingRequired;

  /// 다음에 갈 화면
  final OnboardingStep onboardingStep;

  /// 서버 JSON → LoginResponse. 키 이름은 백엔드 API 명세와 똑같이 맞췄어요.
  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      tokenType: json['tokenType'] as String,
      expiresIn: json['expiresIn'] as int,
      onboardingRequired: json['onboardingRequired'] as bool,
      onboardingStep: OnboardingStep.fromValue(
        json['onboardingStep'] as String,
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    'accessToken': accessToken,
    'refreshToken': refreshToken,
    'tokenType': tokenType,
    'expiresIn': expiresIn,
    'onboardingRequired': onboardingRequired,
    'onboardingStep': onboardingStep.value,
  };
}
