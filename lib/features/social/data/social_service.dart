import 'models/social_user_page.dart';

/// 소셜 기능 목록(틀). 화면은 이 틀만 알고, 진짜인지 가짜인지는 몰라요.
/// 지금은 FakeSocialService를 쓰고, 소셜 API가 나오면
/// 이 틀을 채운 진짜 서비스를 만들어 바꿔 끼우면 돼요.
abstract class SocialService {
  /// 한 번에 받는 인원 (정책 9)
  static const pageSize = 20;

  /// 기본 목록: 방이 ON인 사용자를 무작위로 (정책 2)
  /// cursor가 null이면 새로 섞은 목록의 첫 묶음을 줘요.
  Future<SocialUserPage> fetchUsers({String? cursor});

  /// 검색: 닉네임 또는 아이디 부분 일치, 방이 ON인 사용자만 (정책 3)
  Future<SocialUserPage> searchUsers({required String query, String? cursor});

  /// 놀러가기 직전 확인: 상대 방이 아직 ON이면 true
  Future<bool> canVisit(int memberId);
}

/// 소셜 요청이 실패했을 때 던지는 오류. message는 화면에 그대로 보여줘요.
class SocialException implements Exception {
  const SocialException([this.message = '목록을 불러오지 못했어요.']);

  final String message;

  @override
  String toString() => 'SocialException: $message';
}
