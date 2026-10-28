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

    expect(find.text('온보딩 화면 준비 중'), findsOneWidget);
  });

  testWidgets('로그인 화면으로 이동할 수 있다', (tester) async {
    await tester.pumpWidget(const ToggleMeApp());
    await tester.pumpAndSettle();

    appRouter.go(AppRoutes.login);
    await tester.pumpAndSettle();

    expect(find.text('로그인 화면 준비 중'), findsOneWidget);
  });

  testWidgets('존재하지 않는 경로에서 404 화면이 표시된다', (tester) async {
    await tester.pumpWidget(const ToggleMeApp());
    await tester.pumpAndSettle();

    appRouter.go('/unknown');
    await tester.pumpAndSettle();

    expect(find.text('404 - 페이지를 찾을 수 없습니다.'), findsOneWidget);
  });
}
