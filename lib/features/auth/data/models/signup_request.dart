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
    required this.emailVerificationToken,
  });

  final String loginId;
  final String password;
  final String email;

  /// 이메일 인증 코드 확인에서 받은 가입용 토큰 (30분 유효, 1회용)
  final String emailVerificationToken;
}

/// 서버에 보낼 회원가입 정보 (1단계 + 2단계)
class SignupRequest {
  const SignupRequest({required this.profile, required this.account});

  final SignupProfile profile;
  final SignupAccount account;

  /// POST /api/v1/auth/signup 요청 본문
  // TODO(api): 회원가입 API에 성별·생년월일 필드가 없어요.
  //   보낼 API(프로필 설정 등)가 정해지면 profile.gender, profile.birthDate 연결하기
  Map<String, dynamic> toJson() => {
    'loginId': account.loginId,
    'email': account.email,
    'emailVerificationToken': account.emailVerificationToken,
    'password': account.password,
    'nickname': profile.nickname,
  };
}
