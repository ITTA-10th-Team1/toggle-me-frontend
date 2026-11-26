import 'models/signup_request.dart';

/// 회원가입 담당: 아이디 중복확인, 이메일 인증, 가입
/// 화면은 이 틀만 알아요. API가 나오면 이 틀을 채운 실제 서비스를 만들어 바꿔 끼우면 돼요.
abstract class SignupService {
  /// 아이디를 쓸 수 있으면 true, 이미 있으면 false
  Future<bool> isLoginIdAvailable(String loginId);

  /// 이메일로 인증번호 6자리를 보내요.
  Future<void> requestEmailCode(String email);

  /// 인증번호가 맞으면 true
  Future<bool> verifyEmailCode({required String email, required String code});

  /// 회원가입
  Future<void> signup(SignupRequest request);
}

/// 가짜 회원가입 서비스 (API가 나오기 전까지 사용)
/// TODO(api): 회원가입·아이디 중복확인·이메일 인증 API가 나오면 실제 서비스로 교체
class FakeSignupService implements SignupService {
  const FakeSignupService({this.delay = const Duration(milliseconds: 500)});

  /// 서버 응답을 기다리는 것처럼 잠깐 멈추는 시간
  final Duration delay;

  /// 이미 가입된 것으로 칠 아이디
  static const takenLoginIds = {'test1', 'admin', 'toggleme'};

  /// 맞는 것으로 칠 인증번호
  static const validCode = '123456';

  @override
  Future<bool> isLoginIdAvailable(String loginId) async {
    await Future<void>.delayed(delay);
    return !takenLoginIds.contains(loginId);
  }

  @override
  Future<void> requestEmailCode(String email) => Future<void>.delayed(delay);

  @override
  Future<bool> verifyEmailCode({
    required String email,
    required String code,
  }) async {
    await Future<void>.delayed(delay);
    return code == validCode;
  }

  @override
  Future<void> signup(SignupRequest request) => Future<void>.delayed(delay);
}
