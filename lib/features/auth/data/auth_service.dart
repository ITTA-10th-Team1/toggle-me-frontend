import 'kakao_auth_client.dart';
import 'models/auth_error_code.dart';
import 'models/login_response.dart';

/// 로그인 담당.
/// 백엔드가 아직 연결되지 않아서 지금은 '가짜' 서버 응답을 돌려줘요.
/// 응답 모양은 백엔드 API 명세와 똑같이 맞춰 뒀어요.
/// 백엔드가 연결되면 TODO 부분만 실제 서버 요청으로 바꾸면 돼요. (화면 코드는 그대로)
class AuthService {
  AuthService({KakaoAuthClient? kakaoAuthClient})
    : _kakaoAuthClient = kakaoAuthClient ?? KakaoAuthClient();

  final KakaoAuthClient _kakaoAuthClient;

  /// 자체 로그인 (POST /api/v1/auth/login)
  /// 테스트용 계정: 아이디 test1234 / 비밀번호 12345678
  Future<LoginResponse> login({
    required String id,
    required String password,
  }) async {
    // 서버에 보낼 요청 본문 (백엔드 API 명세 필드 이름 그대로)
    final body = {'loginId': id, 'password': password};

    // TODO(backend): POST /api/v1/auth/login 으로 body 전송
    final response = await _fakeLogin(body);

    // TODO(token): accessToken, refreshToken 기기에 저장 (flutter_secure_storage)
    return response;
  }

  /// 카카오 로그인 (POST /api/v1/auth/oauth/kakao)
  /// 사용자가 카카오 로그인을 취소하면 서버 요청 없이 null을 돌려줘요. (설계서 상태 5)
  Future<LoginResponse?> loginWithKakao() async {
    final kakaoAccessToken = await _kakaoAuthClient.login();
    if (kakaoAccessToken == null) return null; // 취소

    // 서버에 보낼 요청 본문: 카카오 SDK로 받은 카카오 Access Token
    final body = {'accessToken': kakaoAccessToken};

    // TODO(backend): POST /api/v1/auth/oauth/kakao 로 body 전송
    final response = await _fakeKakaoLogin(body);

    // TODO(token): accessToken, refreshToken 기기에 저장 (flutter_secure_storage)
    return response;
  }

  Future<void> loginWithNaver() async {
    // TODO: 네이버 로그인 연결 (MVP 이후)
    throw UnimplementedError('네이버 로그인은 아직 준비 중이에요.');
  }

  Future<void> loginWithGoogle() async {
    // TODO: 구글 로그인 연결 (MVP 이후)
    throw UnimplementedError('구글 로그인은 아직 준비 중이에요.');
  }

  // ───────── 가짜 서버 (백엔드 연결 후 삭제) ─────────

  Future<LoginResponse> _fakeLogin(Map<String, String> body) async {
    await Future.delayed(const Duration(seconds: 1)); // 서버 응답 흉내

    if (body['loginId'] != 'test1234' || body['password'] != '12345678') {
      // 실제 서버: 401 { "code": "CREDENTIALS_INVALID", ... }
      throw const AuthException(
        AuthErrorCode.credentialsInvalid,
        '아이디 또는 비밀번호가 올바르지 않습니다.',
      );
    }

    // 실제 서버 200 응답과 같은 모양 (기존 사용자 → DONE)
    return LoginResponse.fromJson(const {
      'accessToken': 'fake-access-token',
      'refreshToken': 'fake-refresh-token',
      'tokenType': 'Bearer',
      'expiresIn': 1800,
      'onboardingRequired': false,
      'onboardingStep': 'DONE',
    });
  }

  Future<LoginResponse> _fakeKakaoLogin(Map<String, String> body) async {
    await Future.delayed(const Duration(seconds: 1)); // 서버 응답 흉내

    // 실제 서버 200 응답과 같은 모양 (최초 로그인 = 신규 사용자 → PROFILE)
    return LoginResponse.fromJson(const {
      'accessToken': 'fake-access-token',
      'refreshToken': 'fake-refresh-token',
      'tokenType': 'Bearer',
      'expiresIn': 1800,
      'onboardingRequired': true,
      'onboardingStep': 'PROFILE',
    });
  }
}
