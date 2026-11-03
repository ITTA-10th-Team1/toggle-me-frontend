/// 로그인 후 어느 화면으로 갈지 알려주는 값 (백엔드 API 명세의 onboardingStep).
///
/// 서버는 'PROFILE' / 'FURNITURE' / 'DONE' 문자열로 보내요.
/// Dart 규칙상 enum 이름은 소문자로 쓰고, [value]에 서버 문자열을 그대로 둬요.
enum OnboardingStep {
  /// 최초 프로필 설정 화면 (신규 사용자)
  profile('PROFILE'),

  /// 가구 선택 화면 (튜토리얼)
  furniture('FURNITURE'),

  /// 온보딩 완료 → 마이홈
  done('DONE');

  const OnboardingStep(this.value);

  /// 서버와 주고받는 문자열 (대소문자까지 명세와 같아야 해요)
  final String value;

  /// 서버 문자열 → enum. 모르는 값이면 오류를 내요.
  static OnboardingStep fromValue(String value) {
    for (final step in OnboardingStep.values) {
      if (step.value == value) return step;
    }
    throw FormatException('알 수 없는 onboardingStep 값: $value');
  }
}
