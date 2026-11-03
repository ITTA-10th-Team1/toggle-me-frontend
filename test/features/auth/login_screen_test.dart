import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toggle_me/features/auth/presentation/login_screen.dart';

void main() {
  testWidgets('아이디 입력창은 영문 소문자와 숫자만 입력된다', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

    // 첫 번째 입력창 = 아이디
    final idField = find.byType(TextFormField).first;
    await tester.enterText(idField, 'Test User@12');
    await tester.pump();

    // 대문자 T·U, 공백, @ 는 빠지고 소문자·숫자만 남아야 해요.
    expect(find.text('estser12'), findsOneWidget);
  });
}
