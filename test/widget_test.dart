import 'package:flutter_test/flutter_test.dart';
import 'package:toggle_me/app/app.dart';
import 'package:toggle_me/app/router/app_router.dart';
import 'package:toggle_me/app/router/app_routes.dart';

void main() {
  setUp(() {
    appRouter.go(AppRoutes.onboarding);
  });

  testWidgets('앱 실행 시 온보딩 화면이 표시된다', (tester) async {
    await tester.pumpWidget(const ToggleMeApp());
    await tester.pumpAndSettle();

    expect(find.text('취향을 모으는 가장 나다운 방법'), findsOneWidget);
    expect(find.text('비회원으로 시작하기'), findsOneWidget);
    expect(find.text('로그인'), findsOneWidget);
  });

  testWidgets('로그인 화면으로 이동할 수 있다', (tester) async {
    await tester.pumpWidget(const ToggleMeApp());
    await tester.pumpAndSettle();

    appRouter.go(AppRoutes.login);
    await tester.pumpAndSettle();

    expect(find.text('SNS 간편 로그인'), findsOneWidget);
  });

  testWidgets('비회원 안내 화면으로 이동할 수 있다', (tester) async {
    await tester.pumpWidget(const ToggleMeApp());
    await tester.pumpAndSettle();

    appRouter.go(AppRoutes.guestIntro);
    await tester.pumpAndSettle();

    expect(find.text('비회원 이용 안내'), findsOneWidget);
  });

  testWidgets('존재하지 않는 경로에서 404 화면이 표시된다', (tester) async {
    await tester.pumpWidget(const ToggleMeApp());
    await tester.pumpAndSettle();

    appRouter.go('/unknown');
    await tester.pumpAndSettle();

    expect(find.text('404 - 페이지를 찾을 수 없습니다.'), findsOneWidget);
  });
}
