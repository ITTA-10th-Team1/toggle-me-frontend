import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:toggle_me/features/social/data/fake_social_service.dart';
import 'package:toggle_me/features/social/data/fake_social_users.dart';
import 'package:toggle_me/features/social/data/models/social_user.dart';
import 'package:toggle_me/features/social/data/models/social_user_page.dart';
import 'package:toggle_me/features/social/data/social_service.dart';

void main() {
  // 테스트는 기다리지 않고(Duration.zero), 섞는 순서도 매번 같게(Random(0))
  FakeSocialService createService({double failureRate = 0}) {
    return FakeSocialService(
      failureRate: failureRate,
      delay: Duration.zero,
      random: Random(0),
    );
  }

  /// cursor를 따라 끝까지 받아서 한 목록으로 합쳐요.
  Future<List<SocialUser>> fetchAll(
    Future<SocialUserPage> Function(String? cursor) request,
  ) async {
    final all = <SocialUser>[];
    String? cursor;
    do {
      final page = await request(cursor);
      all.addAll(page.users);
      cursor = page.nextCursor;
    } while (cursor != null);
    return all;
  }

  Set<int> idsOf(List<SocialUser> users) =>
      users.map((u) => u.memberId).toSet();

  group('기본 목록', () {
    test('첫 요청은 20명이고 다음 묶음이 있다', () async {
      final page = await createService().fetchUsers();

      expect(page.users.length, SocialService.pageSize);
      expect(page.hasMore, isTrue);
    });

    test('20 → 20 → 10명으로 끝나고, 합치면 50명이며 중복이 없다', () async {
      final service = createService();
      final first = await service.fetchUsers();
      final second = await service.fetchUsers(cursor: first.nextCursor);
      final third = await service.fetchUsers(cursor: second.nextCursor);

      expect(second.users.length, 20);
      expect(third.users.length, 10);
      expect(third.hasMore, isFalse);

      final all = [...first.users, ...second.users, ...third.users];
      expect(idsOf(all).length, 50);
    });

    test('나와 방 OFF 사용자는 목록에 없다', () async {
      final service = createService();
      final ids = idsOf(await fetchAll((c) => service.fetchUsers(cursor: c)));

      expect(ids, isNot(contains(fakeMyMemberId)));
      expect(ids, isNot(contains(anyOf(52, 53, 54, 55))));
    });
  });

  group('검색', () {
    Future<Set<int>> search(String query) async {
      final service = createService();
      return idsOf(
        await fetchAll((c) => service.searchUsers(query: query, cursor: c)),
      );
    }

    test('닉네임 일부로 찾는다', () async {
      expect(await search('토글'), {2, 6});
    });

    test('아이디 일부로 찾는다', () async {
      expect(await search('butler'), {4});
    });

    test('대소문자를 구분하지 않고, 닉네임·아이디 어느 쪽이든 찾는다', () async {
      // 방 OFF인 Cat Off(54)는 빠져야 해요.
      expect(await search('CAT'), {3, 4, 17, 30, 40});
    });

    test("맨 앞 '@'와 앞뒤 공백은 무시한다", () async {
      expect(await search('  @toggle  '), {2, 6, 12, 36});
    });

    test('나는 검색 결과에 없다', () async {
      expect(await search('toggle_me'), isEmpty);
    });

    test('결과가 없거나 검색어가 비어 있으면 빈 목록', () async {
      expect(await search('없는사람'), isEmpty);
      expect(await search('   '), isEmpty);
    });
  });

  group('실패', () {
    test('failureRate가 1이면 항상 SocialException을 던진다', () async {
      final service = createService(failureRate: 1);

      expect(service.fetchUsers(), throwsA(isA<SocialException>()));
      expect(
        service.searchUsers(query: 'cat'),
        throwsA(isA<SocialException>()),
      );
    });
  });

  group('놀러가기 확인', () {
    test('방이 ON이면 true', () async {
      expect(await createService().canVisit(2), isTrue);
    });

    test('놀러가기 직전에 OFF로 바꾼 사람, OFF, 없는 회원이면 false', () async {
      final service = createService();
      expect(await service.canVisit(6), isFalse);
      expect(await service.canVisit(52), isFalse);
      expect(await service.canVisit(999), isFalse);
    });
  });
}
