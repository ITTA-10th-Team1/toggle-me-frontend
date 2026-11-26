import 'auth_api_client.dart';
import 'models/auth_error_code.dart';
import 'models/signup_request.dart';

/// 아이디 중복확인 결과
enum LoginIdCheck {
  /// 쓸 수 있는 아이디
  available,

  /// 이미 있는 아이디
  taken,

  /// 서버에 확인할 방법이 없어서 형식만 확인함. 중복은 가입할 때 알려줘요.
  formatOnly,
}

/// 회원가입 담당: 아이디 중복확인, 이메일 인증, 가입
/// 화면은 이 틀만 알아요. 실패하면 [AuthException]을 던져요.
abstract class SignupService {
  Future<LoginIdCheck> checkLoginId(String loginId);

  /// 이메일로 인증번호 6자리를 보내요.
  Future<void> requestEmailCode(String email);

  /// 인증번호가 맞으면 가입용 토큰(verificationToken)을 돌려줘요.
  Future<String> verifyEmailCode({required String email, required String code});

  /// 회원가입
  Future<void> signup(SignupRequest request);
}

/// 실제 서버에 요청하는 회원가입 서비스
/// 흐름: 인증 코드 발송 → 인증 코드 확인(토큰 받기) → 회원가입(토큰 함께 보내기)
/// 이메일 인증 API는 백엔드 PR #81 기준이라, 서버에 배포되기 전에는 실패할 수 있어요.
class ApiSignupService implements SignupService {
  ApiSignupService({AuthApiClient? client})
    : _client = client ?? AuthApiClient();

  final AuthApiClient _client;

  /// TODO(api): 아이디 중복확인 API가 없어요(백엔드에 요청 예정).
  ///   생기면 여기서 요청하고, 그전까지는 형식만 확인해요.
  ///   실제 중복은 가입할 때 409 LOGIN_ID_ALREADY_EXISTS로 알려줘요.
  @override
  Future<LoginIdCheck> checkLoginId(String loginId) async =>
      LoginIdCheck.formatOnly;

  @override
  Future<void> requestEmailCode(String email) => _client.postWithoutResponse(
    '/api/v1/auth/email-verifications',
    {'email': email},
  );

  @override
  Future<String> verifyEmailCode({
    required String email,
    required String code,
  }) async {
    final json = await _client.post(
      '/api/v1/auth/email-verifications/confirm',
      {
        'email': email,
        'code': code, // 앞자리 0이 사라지지 않게 문자열로 보내요.
      },
    );
    final token = json['verificationToken'];
    if (token is! String || token.isEmpty) {
      throw const AuthException(AuthErrorCode.unknown, '인증 중 문제가 생겼어요.');
    }
    return token;
  }

  /// 가입에 성공하면 서버가 로그인 토큰도 주지만, 지금은 저장하지 않고
  /// 로그인 화면에서 직접 로그인해요. (팀 결정)
  @override
  Future<void> signup(SignupRequest request) =>
      _client.post('/api/v1/auth/signup', request.toJson());
}

/// 가짜 회원가입 서비스 (테스트·서버 없이 화면 확인용)
class FakeSignupService implements SignupService {
  const FakeSignupService({this.delay = const Duration(milliseconds: 500)});

  /// 서버 응답을 기다리는 것처럼 잠깐 멈추는 시간
  final Duration delay;

  /// 이미 가입된 것으로 칠 아이디
  static const takenLoginIds = {'test1', 'admin', 'toggleme'};

  /// 맞는 것으로 칠 인증번호
  static const validCode = '123456';

  @override
  Future<LoginIdCheck> checkLoginId(String loginId) async {
    await Future<void>.delayed(delay);
    return takenLoginIds.contains(loginId)
        ? LoginIdCheck.taken
        : LoginIdCheck.available;
  }

  @override
  Future<void> requestEmailCode(String email) => Future<void>.delayed(delay);

  @override
  Future<String> verifyEmailCode({
    required String email,
    required String code,
  }) async {
    await Future<void>.delayed(delay);
    if (code != validCode) {
      throw const AuthException(
        AuthErrorCode.emailVerificationCodeInvalid,
        '인증번호가 올바르지 않아요.',
      );
    }
    return 'fake-verification-token';
  }

  @override
  Future<void> signup(SignupRequest request) async {
    await Future<void>.delayed(delay);
    if (takenLoginIds.contains(request.account.loginId)) {
      throw const AuthException(
        AuthErrorCode.loginIdAlreadyExists,
        '이미 사용 중인 아이디예요.',
      );
    }
  }
}
