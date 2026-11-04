import 'dart:math';

import 'fake_social_users.dart';
import 'models/social_user.dart';
import 'models/social_user_page.dart';
import 'social_service.dart';

/// 소셜 API가 나오기 전까지 쓰는 가짜 서비스.
/// 서버처럼 조금 늦게 대답하고, 원하면 일부러 실패하게 할 수도 있어요.
// TODO(api): 소셜 API가 나오면 SocialService를 채운 진짜 서비스로 교체
class FakeSocialService implements SocialService {
  FakeSocialService({
    this.failureRate = 0,
    this.delay = const Duration(milliseconds: 500),
    Random? random,
  }) : assert(failureRate >= 0 && failureRate <= 1),
       _random = random ?? Random();

  /// 요청이 실패할 확률. 0 = 실패 안 함, 0.2 = 5번에 1번꼴, 1 = 항상 실패
  final double failureRate;

  /// 가짜 응답 지연 시간 (로딩 표시 확인용)
  final Duration delay;

  final Random _random;

  /// 이번에 섞은 순서. 스크롤하는 동안 순서를 유지하려고 기억해 둬요. (정책 10)
  List<SocialUser> _shuffledUsers = [];

  @override
  Future<SocialUserPage> fetchUsers({String? cursor}) async {
    await _simulateNetwork();
    // 첫 요청이면 새로 섞고, 이어서 받을 때는 같은 순서에서 잘라 줘요.
    if (cursor == null) {
      _shuffledUsers = _visibleUsers()..shuffle(_random);
    }
    return _page(_shuffledUsers, cursor);
  }

  @override
  Future<SocialUserPage> searchUsers({
    required String query,
    String? cursor,
  }) async {
    await _simulateNetwork();
    final keyword = _normalize(query);
    if (keyword.isEmpty) return const SocialUserPage(users: []);

    // 닉네임 또는 아이디에 검색어가 들어 있으면 결과에 포함 (부분 일치)
    final results = _visibleUsers()
        .where(
          (user) =>
              user.nickname.toLowerCase().contains(keyword) ||
              user.handle.toLowerCase().contains(keyword),
        )
        .toList();
    return _page(results, cursor);
  }

  @override
  Future<bool> canVisit(int memberId) async {
    await _simulateNetwork();
    for (final member in fakeMembers) {
      if (member.user.memberId == memberId) {
        return member.isRoomOn && !member.closesBeforeVisit;
      }
    }
    return false; // 없는 회원
  }

  // ───────── 내부 도우미 ─────────

  /// 목록에 보여도 되는 사람: 방 ON이고 내가 아닌 사람 (정책 4)
  List<SocialUser> _visibleUsers() {
    return fakeMembers
        .where((m) => m.isRoomOn && m.user.memberId != fakeMyMemberId)
        .map((m) => m.user)
        .toList();
  }

  /// 전체 목록에서 cursor 위치부터 20명을 잘라 줘요.
  /// 가짜에서는 cursor가 '몇 번째부터'를 글자로 바꾼 값이에요. ('20', '40')
  SocialUserPage _page(List<SocialUser> all, String? cursor) {
    final start = cursor == null ? 0 : int.parse(cursor);
    final end = min(start + SocialService.pageSize, all.length);
    return SocialUserPage(
      users: List.unmodifiable(all.sublist(start, end)),
      nextCursor: end < all.length ? '$end' : null,
    );
  }

  /// 검색어 정리: 앞뒤 공백 제거, 맨 앞 '@' 제거, 소문자로
  String _normalize(String query) {
    var keyword = query.trim().toLowerCase();
    if (keyword.startsWith('@')) keyword = keyword.substring(1);
    return keyword;
  }

  /// 서버처럼 잠깐 기다리고, failureRate 확률로 실패해요.
  Future<void> _simulateNetwork() async {
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    if (failureRate > 0 && _random.nextDouble() < failureRate) {
      throw const SocialException();
    }
  }
}
