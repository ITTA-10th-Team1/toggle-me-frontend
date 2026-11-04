import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:toggle_me/app/router/app_routes.dart';
import 'package:toggle_me/features/social/data/fake_social_service.dart';
import 'package:toggle_me/features/social/data/models/social_user_page.dart';
import 'package:toggle_me/features/social/data/social_service.dart';
import 'package:toggle_me/features/social/presentation/friend_list_screen.dart';
import 'package:toggle_me/features/social/presentation/widgets/friend_list_tile.dart';

/// 테스트용 서비스: 가짜 서비스와 같지만, 실패시키거나 요청을 기록할 수 있어요.
class _TestSocialService extends FakeSocialService {
  _TestSocialService({super.delay = Duration.zero}) : super(random: Random(0));

  bool shouldFail = false;
  final requestedCursors = <String?>[];

  @override
  Future<SocialUserPage> fetchUsers({String? cursor}) {
    requestedCursors.add(cursor);
    if (shouldFail) throw const SocialException();
    return super.fetchUsers(cursor: cursor);
  }
}

void main() {
  /// 소셜 화면 + 놀러가기 도착 화면(ROOM)만 있는 작은 앱
  Future<void> openScreen(WidgetTester tester, SocialService service) async {
    final router = GoRouter(
      initialLocation: AppRoutes.social,
      routes: [
        GoRoute(
          path: AppRoutes.social,
          builder: (context, state) => FriendListScreen(service: service),
        ),
        GoRoute(
          path: AppRoutes.room,
          builder: (context, state) => const Scaffold(body: Text('ROOM')),
        ),
      ],
    );
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
  }

  /// 검색어 입력 후 0.3초(debounce) 지나 결과까지 기다리기
  Future<void> search(WidgetTester tester, String text) async {
    await tester.enterText(find.byType(TextField), text);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
  }

  testWidgets('처음엔 로딩 표시, 불러오면 제목·검색창·카드가 보인다', (tester) async {
    await openScreen(
      tester,
      _TestSocialService(delay: const Duration(milliseconds: 500)),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    expect(find.text('친구 목록'), findsOneWidget);
    expect(find.text('아이디 검색'), findsOneWidget);
    expect(find.byType(FriendListTile), findsWidgets);
  });

  testWidgets('불러오기 실패 → [다시 시도]를 누르면 다시 불러온다', (tester) async {
    final service = _TestSocialService()..shouldFail = true;
    await openScreen(tester, service);
    await tester.pumpAndSettle();

    expect(find.text('목록을 불러오지 못했어요.'), findsOneWidget);

    service.shouldFail = false;
    await tester.tap(find.text('다시 시도'));
    await tester.pumpAndSettle();

    expect(find.text('목록을 불러오지 못했어요.'), findsNothing);
    expect(find.byType(FriendListTile), findsWidgets);
  });

  testWidgets('검색은 입력이 0.3초 멈춘 뒤에 하고, 지우면 기본 목록으로', (tester) async {
    await openScreen(tester, _TestSocialService());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'butler');
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('@cat.butler22'), findsNothing); // 아직 검색 전

    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();
    expect(find.byType(FriendListTile), findsOneWidget);
    expect(find.text('@cat.butler22'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.cancel)); // X 버튼
    await tester.pumpAndSettle();
    expect(find.byType(FriendListTile), findsWidgets);
    expect(find.byType(FriendListTile), isNot(findsOneWidget));
  });

  testWidgets("검색 결과가 없으면 '검색 결과가 없어요.'", (tester) async {
    await openScreen(tester, _TestSocialService());
    await tester.pumpAndSettle();

    await search(tester, '없는사람');

    expect(find.text('검색 결과가 없어요.'), findsOneWidget);
  });

  testWidgets('목록 끝 근처까지 스크롤하면 다음 20명을 요청한다', (tester) async {
    final service = _TestSocialService();
    await openScreen(tester, service);
    await tester.pumpAndSettle();
    expect(service.requestedCursors, [null]);

    await tester.drag(find.byType(ListView), const Offset(0, -3000));
    await tester.pumpAndSettle();

    expect(service.requestedCursors, contains('20'));
  });

  testWidgets('놀러가기 직전에 방이 OFF가 됐으면 스낵바를 띄우고 목록에서 뺀다', (tester) async {
    await openScreen(tester, _TestSocialService());
    await tester.pumpAndSettle();
    await search(tester, '토글토글'); // 6번: 놀러가기 직전에 OFF로 바꾸는 사람

    await tester.tap(find.text('놀러가기'));
    await tester.pumpAndSettle();

    expect(find.text('지금은 방문할 수 없는 방이에요.'), findsOneWidget);
    // 검색창에도 '토글토글'이 있으니, 카드는 아이디로 확인해요.
    expect(find.text('@toggle_2'), findsNothing);
    expect(find.byType(FriendListTile), findsNothing);
  });

  testWidgets('놀러가기 성공 → 이동하고, 뒤로 오면 검색 결과가 그대로다', (tester) async {
    await openScreen(tester, _TestSocialService());
    await tester.pumpAndSettle();
    await search(tester, 'butler');

    await tester.tap(find.text('놀러가기'));
    await tester.pumpAndSettle();
    expect(find.text('ROOM'), findsOneWidget);

    // 뒤로 돌아오기 (push로 갔으니 pop하면 친구 목록이 그대로 있어요)
    final context = tester.element(find.text('ROOM'));
    GoRouter.of(context).pop();
    await tester.pumpAndSettle();

    expect(find.text('@cat.butler22'), findsOneWidget);
  });

  testWidgets('뒤로가기를 누르면 메인 홈으로 이동한다', (tester) async {
    await openScreen(tester, _TestSocialService());
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('뒤로가기'));
    await tester.pumpAndSettle();

    expect(find.text('ROOM'), findsOneWidget);
  });
}
