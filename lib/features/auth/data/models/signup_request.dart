/// 성별 (회원가입 1단계)
enum Gender { male, female }

/// 회원가입 1단계에서 받는 정보: 닉네임, 성별, 생년월일
class SignupProfile {
  const SignupProfile({
    required this.nickname,
    required this.gender,
    required this.birthDate,
  });

  final String nickname;
  final Gender gender;
  final DateTime birthDate;
}

/// 회원가입 2단계에서 받는 정보: 아이디, 비밀번호, 인증된 이메일
class SignupAccount {
  const SignupAccount({
    required this.loginId,
    required this.password,
    required this.email,
  });

  final String loginId;
  final String password;
  final String email;
}

/// 서버에 보낼 회원가입 정보 (1단계 + 2단계)
/// TODO(api): 회원가입 API가 나오면 필드 이름·형식(성별 값, 날짜 형식)을 명세에 맞추기
class SignupRequest {
  const SignupRequest({required this.profile, required this.account});

  final SignupProfile profile;
  final SignupAccount account;
}
