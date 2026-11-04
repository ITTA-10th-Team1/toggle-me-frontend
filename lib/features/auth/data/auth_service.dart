import 'auth_api_client.dart';
import 'kakao_auth_client.dart';
import 'models/login_response.dart';
import 'token_storage.dart';

/// 로그인 담당. 서버에 로그인 요청을 보내고, 성공하면 토큰을 저장해요.
/// 실패하면 AuthException을 던져요. (메시지는 화면에 그대로 보여주면 돼요)
class AuthService {
  AuthService({
    KakaoAuthClient? kakaoAuthClient,
    AuthApiClient? apiClient,
    TokenStorage? tokenStorage,
  }) : _kakaoAuthClient = kakaoAuthClient ?? KakaoAuthClient(),
       _apiClient = apiClient ?? AuthApiClient(),
       _tokenStorage = tokenStorage ?? TokenStorage();

  static const loginPath = '/api/v1/auth/login';
  static const kakaoLoginPath = '/api/v1/auth/oauth/kakao';

  final KakaoAuthClient _kakaoAuthClient;
  final AuthApiClient _apiClient;
  final TokenStorage _tokenStorage;

  /// 자체 로그인 (POST /api/v1/auth/login)
  Future<LoginResponse> login({
    required String id,
    required String password,
  }) async {
    // 요청 본문 필드 이름은 백엔드 API 명세 그대로
    final json = await _apiClient.post(loginPath, {
      'loginId': id,
      'password': password,
    });
    return _saveAndReturn(json);
  }

  /// 카카오 로그인 (POST /api/v1/auth/oauth/kakao)
  /// 사용자가 카카오 로그인을 취소하면 서버 요청 없이 null을 돌려줘요. (설계서 상태 5)
  Future<LoginResponse?> loginWithKakao() async {
    final kakaoAccessToken = await _kakaoAuthClient.login();
    if (kakaoAccessToken == null) return null; // 취소

    // 카카오 SDK로 받은 카카오 Access Token을 보내면 서버가 우리 토큰을 줘요.
    final json = await _apiClient.post(kakaoLoginPath, {
      'accessToken': kakaoAccessToken,
    });
    return _saveAndReturn(json);
  }

  Future<void> loginWithNaver() async {
    // TODO: 네이버 로그인 연결 (MVP 이후)
    throw UnimplementedError('네이버 로그인은 아직 준비 중이에요.');
  }

  Future<void> loginWithGoogle() async {
    // TODO: 구글 로그인 연결 (MVP 이후)
    throw UnimplementedError('구글 로그인은 아직 준비 중이에요.');
  }

  /// 응답을 읽고, 받은 토큰을 기기에 저장해요.
  Future<LoginResponse> _saveAndReturn(Map<String, dynamic> json) async {
    final response = LoginResponse.fromJson(json);
    await _tokenStorage.saveTokens(
      accessToken: response.accessToken,
      refreshToken: response.refreshToken,
    );
    return response;
  }
}
