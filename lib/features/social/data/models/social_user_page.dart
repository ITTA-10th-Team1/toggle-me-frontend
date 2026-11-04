import 'social_user.dart';

/// 한 번 요청해서 받는 사용자 묶음 (최대 20명)
class SocialUserPage {
  const SocialUserPage({required this.users, this.nextCursor});

  final List<SocialUser> users;

  /// 다음 묶음을 받을 때 서버에 그대로 다시 보내는 표시. null이면 더 없음
  /// 무한 스크롤에서 중복 없이 이어 받기 위해 써요. (정책 9)
  final String? nextCursor;

  /// 더 불러올 사용자가 있는지
  bool get hasMore => nextCursor != null;
}
