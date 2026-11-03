/// 인증 오류 code 모음.
class AuthErrorCode {
  AuthErrorCode._();

  // ───────── 서버 오류 code (백엔드 API 명세). 대소문자까지 명세와 같아요. ─────────

  /// 400: 필수 값 누락 또는 비밀번호 72바이트 초과
  static const invalidInputValue = 'INVALID_INPUT_VALUE';

  /// 401: 아이디 없음·비밀번호 불일치·탈퇴 회원·이메일 시도 (모두 같은 응답)
  static const credentialsInvalid = 'CREDENTIALS_INVALID';

  /// 401: 카카오가 토큰을 거절함 (만료·위조)
  static const invalidKakaoToken = 'INVALID_KAKAO_TOKEN';

  /// 502: 카카오 서버 통신 오류. 재시도 가능
  static const kakaoApiError = 'KAKAO_API_ERROR';

  /// 401: Refresh Token이 없음·만료·폐기·이미 사용됨
  static const invalidRefreshToken = 'INVALID_REFRESH_TOKEN';

  // ───────── 앱에서만 쓰는 code (서버가 보내는 값 아님) ─────────

  /// 서버 응답 없음, 시간 초과, 인터넷 끊김
  static const networkError = 'NETWORK_ERROR';

  /// dart_defines.json에 API_BASE_URL이 없음
  static const apiBaseUrlMissing = 'API_BASE_URL_MISSING';

  /// 서버 응답을 알아볼 수 없음 (JSON이 아니거나 code가 없음)
  static const unknown = 'UNKNOWN';
}

/// 인증 API가 실패했을 때 던지는 예외.
/// [code]는 오류 code, [message]는 화면에 보여줄 문장이에요.
class AuthException implements Exception {
  const AuthException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => message;
}
