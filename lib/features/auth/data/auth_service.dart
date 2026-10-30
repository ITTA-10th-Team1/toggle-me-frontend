/// 로그인 담당.
/// 백엔드가 아직 없어서 지금은 '가짜'로 동작해요.
/// 백엔드 API가 나오면 이 파일의 함수 안쪽만 실제 서버 호출로 바꾸면 돼요.
/// (화면 코드는 안 건드려도 됨)
class AuthService {
  /// 테스트용 계정: 아이디 test1234 / 비밀번호 12345678
  Future<void> login({required String id, required String password}) async {
    await Future.delayed(const Duration(seconds: 1)); // 서버 응답 흉내

    if (id != 'test1234' || password != '12345678') {
      throw Exception('아이디 또는 비밀번호가 올바르지 않아요.');
    }
    // TODO: 백엔드 연결 시 서버에서 받은 토큰을 저장하기
  }

  Future<void> loginWithKakao() async {
    // TODO: 카카오 로그인 연결
    throw UnimplementedError('카카오 로그인은 아직 준비 중이에요.');
  }

  Future<void> loginWithNaver() async {
    // TODO: 네이버 로그인 연결
    throw UnimplementedError('네이버 로그인은 아직 준비 중이에요.');
  }

  Future<void> loginWithGoogle() async {
    // TODO: 구글 로그인 연결
    throw UnimplementedError('구글 로그인은 아직 준비 중이에요.');
  }
}
