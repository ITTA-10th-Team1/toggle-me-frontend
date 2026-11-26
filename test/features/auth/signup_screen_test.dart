import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:toggle_me/app/router/app_routes.dart';
import 'package:toggle_me/features/auth/data/models/auth_error_code.dart';
import 'package:toggle_me/features/auth/data/models/signup_request.dart';
import 'package:toggle_me/features/auth/data/signup_service.dart';
import 'package:toggle_me/features/auth/presentation/signup_screen.dart';
import 'package:toggle_me/features/auth/presentation/widgets/primary_button.dart';
import 'package:toggle_me/features/auth/presentation/widgets/signup_fields.dart';
import 'package:toggle_me/features/auth/presentation/widgets/signup_style.dart';

/// 가짜 서비스를 그대로 쓰되, 기다림 없이 바로 답하고 가입 요청을 기록해요.
class _RecordingService extends FakeSignupService {
  _RecordingService() : super(delay: Duration.zero);

  SignupRequest? signedUp;

  @override
  Future<void> signup(SignupRequest request) async => signedUp = request;
}

/// 서버 응답을 정해 둘 수 있는 가짜 서비스 (실제 API처럼 오류를 던져요)
class _ScriptedService extends FakeSignupService {
  _ScriptedService({
    this.idCheck = LoginIdCheck.available,
    this.requestError,
    this.signupError,
  }) : super(delay: Duration.zero);

  final LoginIdCheck idCheck;
  final AuthException? requestError;
  AuthException? signupError;
  int signupCalls = 0;

  @override
  Future<LoginIdCheck> checkLoginId(String loginId) async => idCheck;

  @override
  Future<void> requestEmailCode(String email) async {
    if (requestError != null) throw requestError!;
  }

  @override
  Future<void> signup(SignupRequest request) async {
    signupCalls++;
    if (signupError != null) throw signupError!;
  }
}

/// 화면 전체가 스크롤 없이 보이도록 세로로 긴 화면에서 회원가입 화면을 띄워요.
Future<void> _pumpSignup(WidgetTester tester, SignupService service) async {
  tester.view.physicalSize = const Size(412, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final router = GoRouter(
    initialLocation: AppRoutes.signup,
    routes: [
      GoRoute(
        path: AppRoutes.signup,
        builder: (_, _) => SignupScreen(service: service),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (_, _) => const Scaffold(body: Text('login-target')),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(MaterialApp.router(routerConfig: router));
}

Finder _field(int index) => find.byType(TextField).at(index);

/// 가짜 서비스가 답할 때까지 조금 기다리고 화면을 다시 그려요.
/// (타이머가 돌고 있어서 pumpAndSettle은 끝나지 않아요.)
Future<void> _waitForService(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 10));
  await tester.pump();
}

bool _enabled(WidgetTester tester, String text) {
  final primary = find.widgetWithText(PrimaryButton, text);
  if (primary.evaluate().isNotEmpty) {
    return tester
            .widget<ElevatedButton>(
              find.descendant(
                of: primary,
                matching: find.byType(ElevatedButton),
              ),
            )
            .onPressed !=
        null;
  }
  return tester
          .widget<OutlinedButton>(find.widgetWithText(OutlinedButton, text))
          .onPressed !=
      null;
}

Color? _helperColor(WidgetTester tester, String text) =>
    tester.widget<Text>(find.text(text)).style?.color;

/// 1단계를 채우고 [다음]을 눌러 2단계로 가요.
Future<void> _goToAccountStep(WidgetTester tester) async {
  await tester.enterText(_field(0), '토글러');
  await tester.tap(find.text('여성'));
  await tester.pump();
  await tester.tap(find.text('다음'));
  await tester.pumpAndSettle();
}

/// 2단계를 모두 채우고 이메일 인증까지 마쳐요.
Future<void> _fillAccountStep(WidgetTester tester) async {
  await tester.enterText(_field(0), 'hello1');
  await tester.pump();
  await tester.tap(find.text('중복확인'));
  await tester.pumpAndSettle();
  await tester.enterText(_field(1), 'abcd123!');
  await tester.enterText(_field(2), 'abcd123!');
  await tester.enterText(_field(3), 'me@toggle.com');
  await tester.pump();
  await tester.tap(find.text('인증요청'));
  await _waitForService(tester);
  await tester.enterText(_field(4), FakeSignupService.validCode);
  await tester.pump();
  await tester.tap(find.text('확인'));
  await _waitForService(tester);
}

void main() {
  group('1단계: 닉네임·성별·생년월일', () {
    testWidgets('닉네임과 성별을 모두 고르면 [다음]이 켜진다', (tester) async {
      await _pumpSignup(tester, _RecordingService());

      expect(_enabled(tester, '다음'), isFalse);

      await tester.enterText(_field(0), '토글러');
      await tester.pump();
      expect(_enabled(tester, '다음'), isFalse); // 성별 아직

      await tester.tap(find.text('남성'));
      await tester.pump();
      expect(_enabled(tester, '다음'), isTrue);
    });

    testWidgets('닉네임이 2자보다 짧으면 안내 문구가 빨간색', (tester) async {
      await _pumpSignup(tester, _RecordingService());
      const helper = '한글, 영문, 숫자 2~10자';

      expect(_helperColor(tester, helper), SignupStyle.grayText);

      await tester.enterText(_field(0), 'a');
      await tester.pump();
      expect(_helperColor(tester, helper), SignupStyle.error);

      await tester.enterText(_field(0), 'ab');
      await tester.pump();
      expect(_helperColor(tester, helper), SignupStyle.grayText);
    });

    testWidgets('닉네임에 특수문자·공백은 입력되지 않고 10자까지만', (tester) async {
      await _pumpSignup(tester, _RecordingService());

      await tester.enterText(_field(0), '토글 me!@12');
      await tester.pump();
      expect(find.text('토글me12'), findsOneWidget);

      await tester.enterText(_field(0), 'abcdefghijkl');
      await tester.pump();
      expect(find.text('abcdefghij'), findsOneWidget);
    });

    testWidgets('성별은 하나만 선택된다', (tester) async {
      await _pumpSignup(tester, _RecordingService());

      bool selected(String label) => tester
          .widget<SignupChoiceButton>(
            find.widgetWithText(SignupChoiceButton, label),
          )
          .selected;

      await tester.tap(find.text('남성'));
      await tester.pump();
      expect(selected('남성'), isTrue);
      expect(selected('여성'), isFalse);

      await tester.tap(find.text('여성'));
      await tester.pump();
      expect(selected('남성'), isFalse);
      expect(selected('여성'), isTrue);
    });

    testWidgets('생년월일 칸을 누르면 목록이 펼쳐지고, 고르면 바뀐다', (tester) async {
      await _pumpSignup(tester, _RecordingService());

      expect(find.text('2000'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('birth_year')));
      await tester.pump();
      expect(find.text('2000 년'), findsOneWidget); // 고른 값은 단위와 함께
      await tester.tap(find.text('2001'));
      await tester.pump();
      expect(find.text('2000 년'), findsNothing); // 닫힘
      expect(find.text('2001'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('birth_month')));
      await tester.pump();
      await tester.tap(find.text('03'));
      await tester.pump();
      expect(find.text('03'), findsOneWidget);
    });

    testWidgets('목록 밖을 누르면 닫힌다', (tester) async {
      await _pumpSignup(tester, _RecordingService());

      await tester.tap(find.byKey(const ValueKey('birth_day')));
      await tester.pump();
      expect(find.text('01 일'), findsOneWidget);

      await tester.tapAt(const Offset(200, 900));
      await tester.pump();
      expect(find.text('01 일'), findsNothing);
    });

    testWidgets('입력값으로 2단계에 넘어가고, ←를 누르면 입력값이 남아 있다', (tester) async {
      await _pumpSignup(tester, _RecordingService());
      await _goToAccountStep(tester);

      expect(find.text('아이디 *'), findsOneWidget);
      expect(find.text('닉네임 *'), findsNothing);

      await tester.tap(find.byTooltip('뒤로가기'));
      await tester.pumpAndSettle();
      expect(find.text('토글러'), findsOneWidget);
      expect(_enabled(tester, '다음'), isTrue);

      // 1단계에서 ←는 로그인 화면으로
      await tester.tap(find.byTooltip('뒤로가기'));
      await tester.pumpAndSettle();
      expect(find.text('login-target'), findsOneWidget);
    });
  });

  group('디자인 값', () {
    testWidgets('상단 바 52, 입력칸·버튼 높이 53, 여백 22 / 8 / 6 / 32', (tester) async {
      await _pumpSignup(tester, _RecordingService());

      final nicknameLabel = tester.getRect(find.text('닉네임 *'));
      final field = tester.getRect(find.byType(SignupTextField));
      final helper = tester.getRect(find.text('한글, 영문, 숫자 2~10자'));
      final genderLabel = tester.getRect(find.text('성별 *'));
      final male = tester.getRect(
        find.widgetWithText(SignupChoiceButton, '남성'),
      );
      final female = tester.getRect(
        find.widgetWithText(SignupChoiceButton, '여성'),
      );

      expect(nicknameLabel.top, 52 + 22); // 상단 바 52 + 여백 22
      expect(field.top - nicknameLabel.bottom, 8);
      expect(field.height, 53);
      expect(helper.top - field.bottom, 6);
      expect(genderLabel.top - helper.bottom, 32);
      expect(male.height, 53);
      expect(female.left - male.right, 6);
      expect(
        tester.getSize(find.byType(PrimaryButton)).height,
        SignupStyle.controlHeight,
      );

      // 제목·설명 문구·입력 글자는 모두 같은 위치에서 시작 (왼쪽 정렬)
      expect(nicknameLabel.left, field.left + SignupStyle.textInset);
      expect(helper.left, field.left + SignupStyle.textInset);
    });
  });

  group('2단계: 아이디·비밀번호·이메일 인증', () {
    testWidgets('아이디 중복확인: 사용 중 / 사용 가능 / 고치면 다시 확인', (tester) async {
      await _pumpSignup(tester, _RecordingService());
      await _goToAccountStep(tester);

      expect(_enabled(tester, '중복확인'), isFalse);
      await tester.enterText(_field(0), 'abc');
      await tester.pump();
      expect(_enabled(tester, '중복확인'), isFalse); // 4자 미만

      await tester.enterText(_field(0), 'test1');
      await tester.pump();
      await tester.tap(find.text('중복확인'));
      await tester.pumpAndSettle();
      expect(find.text('이미 사용 중인 아이디예요.'), findsOneWidget);

      await tester.enterText(_field(0), 'hello1');
      await tester.pump();
      expect(find.text('영문 소문자, 숫자 조합 4~12자'), findsOneWidget);
      await tester.tap(find.text('중복확인'));
      await tester.pumpAndSettle();
      expect(find.text('사용할 수 있는 아이디예요.'), findsOneWidget);
      expect(_enabled(tester, '중복확인'), isFalse); // 이미 확인함

      await tester.enterText(_field(0), 'hello12');
      await tester.pump();
      expect(find.text('사용할 수 있는 아이디예요.'), findsNothing);
      expect(_enabled(tester, '중복확인'), isTrue);
    });

    testWidgets('아이디에는 영문 소문자·숫자만 입력된다', (tester) async {
      await _pumpSignup(tester, _RecordingService());
      await _goToAccountStep(tester);

      await tester.enterText(_field(0), 'Hello World_1');
      await tester.pump();
      expect(find.text('elloorld1'), findsOneWidget);
    });

    testWidgets('비밀번호 규칙과 비밀번호 확인 일치 검사', (tester) async {
      await _pumpSignup(tester, _RecordingService());
      await _goToAccountStep(tester);
      const helper = '영문, 숫자, 특수문자 포함 8~16자';

      await tester.enterText(_field(1), 'abcd1234'); // 특수문자 없음
      await tester.pump();
      expect(_helperColor(tester, helper), SignupStyle.error);

      await tester.enterText(_field(1), 'abcd123!');
      await tester.pump();
      expect(_helperColor(tester, helper), SignupStyle.grayText);

      await tester.enterText(_field(2), 'abcd123?');
      await tester.pump();
      expect(find.text('비밀번호가 일치하지 않아요.'), findsOneWidget);

      await tester.enterText(_field(2), 'abcd123!');
      await tester.pump();
      expect(find.text('비밀번호가 일치하지 않아요.'), findsNothing);
    });

    testWidgets('이메일 인증: 요청 → 타이머 → 틀린 번호 → 맞는 번호', (tester) async {
      await _pumpSignup(tester, _RecordingService());
      await _goToAccountStep(tester);

      expect(_enabled(tester, '인증요청'), isFalse);
      await tester.enterText(_field(3), 'me@toggle.com');
      await tester.pump();
      expect(_enabled(tester, '인증요청'), isTrue);

      await tester.tap(find.text('인증요청'));
      await _waitForService(tester);
      expect(find.text('03:00'), findsOneWidget);
      expect(find.text('재요청'), findsOneWidget);

      await tester.pump(const Duration(seconds: 1));
      expect(find.text('02:59'), findsOneWidget);

      await tester.enterText(_field(4), '111111');
      await tester.pump();
      await tester.tap(find.text('확인'));
      await _waitForService(tester);
      expect(find.text('인증번호가 올바르지 않아요.'), findsOneWidget);

      await tester.enterText(_field(4), FakeSignupService.validCode);
      await tester.pump();
      await tester.tap(find.text('확인'));
      await _waitForService(tester);
      expect(find.text('이메일 인증이 완료됐어요.'), findsOneWidget);
      expect(find.text('02:59'), findsNothing); // 타이머 사라짐
      expect(_enabled(tester, '인증요청'), isFalse);

      await tester.pumpAndSettle(); // 안내(스낵바) 정리
    });

    testWidgets('3분이 지나면 인증번호를 확인할 수 없다', (tester) async {
      await _pumpSignup(tester, _RecordingService());
      await _goToAccountStep(tester);

      await tester.enterText(_field(3), 'me@toggle.com');
      await tester.pump();
      await tester.tap(find.text('인증요청'));
      await _waitForService(tester);
      await tester.enterText(_field(4), FakeSignupService.validCode);
      await tester.pump();
      expect(_enabled(tester, '확인'), isTrue);

      for (var i = 0; i < 180; i++) {
        await tester.pump(const Duration(seconds: 1));
      }
      expect(find.text('인증 시간이 지났어요. 다시 요청해 주세요.'), findsOneWidget);
      expect(_enabled(tester, '확인'), isFalse);
    });

    testWidgets('모두 마치면 [가입 완료하기] → 가입 요청 → 로그인 화면', (tester) async {
      final service = _RecordingService();
      await _pumpSignup(tester, service);
      await _goToAccountStep(tester);

      await tester.enterText(_field(0), 'hello1');
      await tester.pump();
      await tester.tap(find.text('중복확인'));
      await tester.pumpAndSettle();
      await tester.enterText(_field(1), 'abcd123!');
      await tester.enterText(_field(2), 'abcd123!');
      await tester.enterText(_field(3), 'me@toggle.com');
      await tester.pump();
      expect(_enabled(tester, '가입 완료하기'), isFalse); // 이메일 인증 전

      await tester.tap(find.text('인증요청'));
      await _waitForService(tester);
      await tester.enterText(_field(4), FakeSignupService.validCode);
      await tester.pump();
      await tester.tap(find.text('확인'));
      await _waitForService(tester);
      expect(_enabled(tester, '가입 완료하기'), isTrue);

      await tester.tap(find.text('가입 완료하기'));
      await tester.pumpAndSettle();

      final request = service.signedUp!;
      expect(request.profile.nickname, '토글러');
      expect(request.profile.gender, Gender.female);
      expect(request.profile.birthDate, DateTime(2000, 1, 1));
      expect(request.account.loginId, 'hello1');
      expect(request.account.password, 'abcd123!');
      expect(request.account.email, 'me@toggle.com');
      expect(request.account.emailVerificationToken, 'fake-verification-token');
      expect(find.text('login-target'), findsOneWidget);
    });
  });

  group('서버 오류 처리', () {
    testWidgets('중복확인 API가 없으면 형식만 확인하고 가입할 수 있다', (tester) async {
      final service = _ScriptedService(idCheck: LoginIdCheck.formatOnly);
      await _pumpSignup(tester, service);
      await _goToAccountStep(tester);
      await _fillAccountStep(tester);

      expect(find.text('사용할 수 있는 형식이에요. 중복 여부는 가입할 때 확인해요.'), findsOneWidget);
      expect(_enabled(tester, '가입 완료하기'), isTrue);
    });

    testWidgets('가입할 때 409 아이디 중복이면 아이디 칸 아래에 알려준다', (tester) async {
      final service = _ScriptedService(
        idCheck: LoginIdCheck.formatOnly,
        signupError: const AuthException(
          AuthErrorCode.loginIdAlreadyExists,
          '이미 사용 중인 아이디입니다.',
        ),
      );
      await _pumpSignup(tester, service);
      await _goToAccountStep(tester);
      await _fillAccountStep(tester);

      await tester.tap(find.text('가입 완료하기'));
      await _waitForService(tester);

      expect(find.text('이미 사용 중인 아이디예요.'), findsOneWidget);
      expect(find.text('login-target'), findsNothing); // 화면에 남아 있음
      expect(_enabled(tester, '가입 완료하기'), isFalse);

      // 아이디를 고치면 다시 확인하고 가입할 수 있어요. (이메일 인증은 유지)
      service.signupError = null;
      await tester.enterText(_field(0), 'hello2');
      await tester.pump();
      await tester.tap(find.text('중복확인'));
      await tester.pumpAndSettle();
      expect(_enabled(tester, '가입 완료하기'), isTrue);
    });

    testWidgets('가입 토큰이 만료되면 이메일 인증을 처음부터 다시 한다', (tester) async {
      final service = _ScriptedService(
        signupError: const AuthException(
          AuthErrorCode.emailVerificationRequired,
          '이메일 인증이 필요합니다.',
        ),
      );
      await _pumpSignup(tester, service);
      await _goToAccountStep(tester);
      await _fillAccountStep(tester);

      await tester.tap(find.text('가입 완료하기'));
      await _waitForService(tester);

      expect(find.text('이메일 인증을 다시 진행해 주세요.'), findsOneWidget);
      expect(_enabled(tester, '인증요청'), isTrue);
      expect(_enabled(tester, '가입 완료하기'), isFalse);
    });

    testWidgets('인증요청이 실패하면 서버 문장을 이메일 칸 아래에 보여준다', (tester) async {
      final service = _ScriptedService(
        requestError: const AuthException(
          AuthErrorCode.emailAlreadyExists,
          '이미 사용 중인 이메일입니다.',
        ),
      );
      await _pumpSignup(tester, service);
      await _goToAccountStep(tester);

      await tester.enterText(_field(3), 'me@toggle.com');
      await tester.pump();
      await tester.tap(find.text('인증요청'));
      await _waitForService(tester);

      expect(find.text('이미 사용 중인 이메일입니다.'), findsOneWidget);
      expect(find.text('03:00'), findsNothing); // 타이머 시작 안 함
    });
  });
}
