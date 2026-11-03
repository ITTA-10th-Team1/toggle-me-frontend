import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:toggle_me/app/router/app_router.dart';
import 'package:toggle_me/app/router/app_routes.dart';
import 'package:toggle_me/features/auth/presentation/login_screen.dart';
import 'package:toggle_me/features/auth/presentation/widgets/primary_button.dart';

void main() {
  test('normal startup begins at onboarding without ROOM_DEMO_ENTRY', () {
    expect(
      appRouter.routeInformationProvider.value.uri.path,
      AppRoutes.onboarding,
    );
  });

  testWidgets(
    'existing test account DONE response navigates from login to room',
    (tester) async {
      final router = GoRouter(
        initialLocation: AppRoutes.login,
        routes: [
          GoRoute(
            path: AppRoutes.login,
            builder: (_, _) => const LoginScreen(),
          ),
          GoRoute(
            path: AppRoutes.room,
            builder: (_, _) => const Scaffold(body: Text('room-flow-target')),
          ),
          GoRoute(
            path: AppRoutes.onboarding,
            builder: (_, _) =>
                const Scaffold(body: Text('onboarding-flow-target')),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).at(0), 'test1234');
      await tester.enterText(find.byType(TextFormField).at(1), '12345678');
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byType(PrimaryButton));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(PrimaryButton));
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
      expect(find.text('room-flow-target'), findsOneWidget);
      expect(router.routeInformationProvider.value.uri.path, AppRoutes.room);
    },
  );
}
