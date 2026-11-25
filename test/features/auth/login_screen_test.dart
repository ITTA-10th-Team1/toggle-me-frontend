import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toggle_me/features/auth/presentation/login_screen.dart';
import 'package:toggle_me/features/auth/presentation/widgets/login_style.dart';
import 'package:toggle_me/features/auth/presentation/widgets/login_text_field.dart';
import 'package:toggle_me/features/auth/presentation/widgets/primary_button.dart';

/// 화면 전체가 스크롤 없이 보이도록 세로로 긴 화면에서 로그인 화면을 띄워요.
Future<void> _pumpLogin(WidgetTester tester) async {
  tester.view.physicalSize = const Size(412, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(const MaterialApp(home: LoginScreen()));
}

/// semanticLabel로 이미지 찾기
Finder _imageLabeled(String label) => find.byWidgetPredicate(
  (widget) => widget is Image && widget.semanticLabel == label,
);

Rect _rect(WidgetTester tester, Finder finder) => tester.getRect(finder);

/// 위 요소의 아래쪽 ~ 아래 요소의 위쪽 사이 간격
double _gap(WidgetTester tester, Finder upper, Finder lower) =>
    _rect(tester, lower).top - _rect(tester, upper).bottom;

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

  group('디자인 수정사항 (#38)', () {
    final back = find.byTooltip('뒤로가기');
    final logo = _imageLabeled('Toggle me');
    final intro = find.text('취향을 기록하고 발견하는\n공간형 아카이빙 서비스');
    final idField = find.byType(LoginTextField).at(0);
    final passwordField = find.byType(LoginTextField).at(1);
    final findAccount = find.widgetWithText(TextButton, '아이디·비밀번호 찾기');
    final loginButton = find.byType(PrimaryButton);
    final sns = find.text('SNS 간편 로그인');
    final kakao = _imageLabeled('카카오 로그인');
    final signUp = find.text('계정이 없으신가요?');

    testWidgets('크기: 뒤로가기 36, 로고 250x49, 입력창·버튼 높이 53, 카카오 54', (tester) async {
      await _pumpLogin(tester);

      expect(tester.getSize(back), const Size(36, 36));
      expect(tester.getSize(logo), const Size(250, 49));
      expect(tester.getSize(idField).height, 53);
      expect(tester.getSize(passwordField).height, 53);
      expect(tester.getSize(loginButton).height, 53);
      expect(tester.getSize(kakao), const Size(54, 54));
    });

    testWidgets('여백: 45 / 16 / 48 / 6 / 14 / 20 / 52 / 24 / 59', (
      tester,
    ) async {
      await _pumpLogin(tester);

      expect(_gap(tester, back, logo), LoginStyle.backToLogo);
      expect(_gap(tester, logo, intro), LoginStyle.logoToIntro);
      expect(_gap(tester, intro, idField), LoginStyle.introToId);
      expect(_gap(tester, idField, passwordField), LoginStyle.idToPassword);
      expect(
        _gap(tester, passwordField, findAccount),
        LoginStyle.passwordToFind,
      );
      expect(_gap(tester, findAccount, loginButton), LoginStyle.findToLogin);
      expect(_gap(tester, loginButton, sns), LoginStyle.loginToSns);
      expect(_gap(tester, sns, kakao), LoginStyle.snsToKakao);
      expect(_gap(tester, kakao, signUp), LoginStyle.kakaoToSignUp);
    });

    testWidgets('글자: 크기·굵기·색·자간 -2.5%', (tester) async {
      await _pumpLogin(tester);

      TextStyle styleOf(String text) =>
          tester.widget<Text>(find.text(text)).style!;

      final introStyle = tester.widget<Text>(intro).style!;
      expect(introStyle.fontSize, 18);
      expect(introStyle.fontWeight, FontWeight.w500);
      expect(introStyle.color, const Color(0xFF000000));
      expect(introStyle.letterSpacing, closeTo(-0.45, 0.001));

      expect(styleOf('아이디·비밀번호 찾기').fontSize, 14);
      expect(styleOf('아이디·비밀번호 찾기').fontWeight, FontWeight.w500);

      expect(styleOf('SNS 간편 로그인').fontSize, 16);
      expect(styleOf('SNS 간편 로그인').color, const Color(0xFF747474));

      expect(styleOf('계정이 없으신가요?').fontSize, 14);
      expect(styleOf('계정이 없으신가요?').color, const Color(0xFF747474));

      expect(styleOf('로그인').fontSize, 18);
      expect(styleOf('로그인').fontWeight, FontWeight.w500);

      // 입력창 힌트: Regular 18, #6E6E6E
      final hint = tester
          .widget<TextField>(find.byType(TextField).first)
          .decoration!
          .hintStyle!;
      expect(hint.fontSize, 18);
      expect(hint.fontWeight, FontWeight.w400);
      expect(hint.color, const Color(0xFF6E6E6E));
      expect(hint.letterSpacing, closeTo(-0.45, 0.001));
    });

    testWidgets('입력창은 양옆이 둥글고, 아이콘은 칸 끝에서 24 안쪽', (tester) async {
      await _pumpLogin(tester);

      final decoration = tester
          .widget<TextField>(find.byType(TextField).at(1))
          .decoration!;
      final border = decoration.enabledBorder! as OutlineInputBorder;
      expect(border.borderRadius, BorderRadius.circular(53 / 2));

      final field = _rect(tester, passwordField);
      final lock = _rect(tester, find.byIcon(Icons.lock_outline));
      final eye = _rect(tester, find.byIcon(Icons.visibility_off_outlined));
      expect(lock.left - field.left, 24);
      expect(field.right - eye.right, 24);
    });

    testWidgets('비밀번호 눈 아이콘을 누르면 보이기/숨기기가 바뀐다', (tester) async {
      await _pumpLogin(tester);

      bool obscured() =>
          tester.widget<TextField>(find.byType(TextField).at(1)).obscureText;

      expect(obscured(), isTrue); // 최초 진입 시 숨김
      await tester.tap(find.byTooltip('비밀번호 보기'));
      await tester.pump();
      expect(obscured(), isFalse);
      await tester.tap(find.byTooltip('비밀번호 숨기기'));
      await tester.pump();
      expect(obscured(), isTrue);
    });

    testWidgets('로그인 버튼이 켜지면(검정) 글자는 흰색으로 보인다', (tester) async {
      await _pumpLogin(tester);
      await tester.enterText(find.byType(TextFormField).at(0), 'test2');
      await tester.enterText(find.byType(TextFormField).at(1), '12');
      await tester.pumpAndSettle(); // 버튼 색이 바뀌는 애니메이션이 끝날 때까지

      final button = tester.widget<ElevatedButton>(
        find.descendant(of: loginButton, matching: find.byType(ElevatedButton)),
      );
      expect(button.onPressed, isNotNull); // 켜진 상태

      // 실제로 그려지는 글자 색 (RichText)
      final label = tester.widget<RichText>(
        find.descendant(of: loginButton, matching: find.byType(RichText)),
      );
      expect(label.text.style!.color, Colors.white);
    });
  });
}
