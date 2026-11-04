import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:toggle_me/app/router/app_router.dart';
import 'package:toggle_me/app/router/app_routes.dart';
import 'package:toggle_me/features/auth/presentation/login_screen.dart';
import 'package:toggle_me/features/auth/presentation/widgets/primary_button.dart';
import 'package:toggle_me/features/auth/data/auth_service.dart';
import 'package:toggle_me/features/auth/data/models/login_response.dart';
import 'package:toggle_me/features/auth/data/models/onboarding_step.dart';
import 'package:toggle_me/features/auth/data/models/auth_error_code.dart';

class _TestAuthService extends AuthService {
  final response = Completer<LoginResponse>();
  int requests = 0;

  @override
  Future<LoginResponse> login({required String id, required String password}) {
    requests++;
    return response.future;
  }
}

Future<GoRouter> _openLogin(
  WidgetTester tester,
  _TestAuthService service,
) async {
  final router = GoRouter(
    initialLocation: AppRoutes.login,
    routes: [
      GoRoute(
        path: AppRoutes.login,
        builder: (_, _) => LoginScreen(authService: service),
      ),
      GoRoute(
        path: AppRoutes.room,
        builder: (_, _) => const Scaffold(body: Text('room-flow-target')),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (_, _) => const Scaffold(body: Text('onboarding-flow-target')),
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
  return router;
}

void main() {
  test('normal startup begins at onboarding without ROOM_DEMO_ENTRY', () {
    expect(
      appRouter.routeInformationProvider.value.uri.path,
      AppRoutes.onboarding,
    );
  });

  testWidgets(
    'DONE response navigates from login to room without real API or storage',
    (tester) async {
      final service = _TestAuthService();
      final router = await _openLogin(tester, service);
      service.response.complete(
        const LoginResponse(
          accessToken: 'test-access',
          refreshToken: 'test-refresh',
          tokenType: 'Bearer',
          expiresIn: 1800,
          onboardingRequired: false,
          onboardingStep: OnboardingStep.done,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('room-flow-target'), findsOneWidget);
      expect(router.routeInformationProvider.value.uri.path, AppRoutes.room);
    },
  );

  testWidgets('invalid credentials retain ID and clear only the password', (
    tester,
  ) async {
    final service = _TestAuthService();
    await _openLogin(tester, service);
    service.response.completeError(
      const AuthException(
        AuthErrorCode.credentialsInvalid,
        '아이디 또는 비밀번호가 올바르지 않습니다.',
      ),
    );
    await tester.pumpAndSettle();
    final fields = tester
        .widgetList<TextFormField>(find.byType(TextFormField))
        .toList();
    expect(fields[0].controller!.text, 'test1234');
    expect(fields[1].controller!.text, isEmpty);
    expect(find.text('아이디 또는 비밀번호가 올바르지 않습니다.'), findsOneWidget);
  });

  testWidgets('leaving login during a request safely ignores a late failure', (
    tester,
  ) async {
    final service = _TestAuthService();
    final router = await _openLogin(tester, service);
    router.go(AppRoutes.onboarding);
    await tester.pumpAndSettle();
    service.response.completeError(
      const AuthException(AuthErrorCode.credentialsInvalid, 'late failure'),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('onboarding-flow-target'), findsOneWidget);
    expect(find.text('late failure'), findsNothing);
  });
}
