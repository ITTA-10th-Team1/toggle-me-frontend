/// 친구 목록에 보이는 사용자 한 명 (소셜 화면설계서 4번)
/// 소셜 API 명세가 아직 없어서 필드 이름은 초안이에요.
// TODO(api): 소셜 API 명세가 나오면 필드 이름과 타입 맞추기
class SocialUser {
  const SocialUser({
    required this.memberId,
    required this.nickname,
    required this.handle,
    this.profileImageUrl,
  });

  /// 회원 번호 (놀러가기에 사용)
  final int memberId;

  /// 닉네임
  final String nickname;

  /// 공개 아이디. 화면에는 '@handle'로 보여줘요. (로그인 아이디 아님)
  final String handle;

  /// 프로필 사진 주소. 없으면 null → 화면에서 기본 이미지
  final String? profileImageUrl;

  /// 서버 JSON → SocialUser
  factory SocialUser.fromJson(Map<String, dynamic> json) {
    return SocialUser(
      memberId: json['memberId'] as int,
      nickname: json['nickname'] as String,
      handle: json['handle'] as String,
      profileImageUrl: json['profileImageUrl'] as String?,
    );
  }
}
