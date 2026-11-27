import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/widgets/app_notice.dart';
import '../../data/models/auth_error_code.dart';
import '../../data/models/signup_request.dart';
import '../../data/signup_service.dart';
import 'primary_button.dart';
import 'signup_fields.dart';
import 'signup_style.dart';

/// 회원가입 2단계: 아이디, 비밀번호, 이메일 인증 (피그마 Android_앱 내 회원가입2)
/// - 아이디 중복확인, 비밀번호 일치, 이메일 인증을 모두 마치면 [가입 완료하기]가 켜져요.
/// - 누르면 [onSubmit]으로 입력값을 넘기고, 끝날 때까지 로딩을 보여줘요.
class SignupAccountStep extends StatefulWidget {
  const SignupAccountStep({
    super.key,
    required this.service,
    required this.onSubmit,
  });

  final SignupService service;
  final Future<void> Function(SignupAccount account) onSubmit;

  /// 인증번호 입력 제한 시간
  static const codeTimeLimit = Duration(minutes: 10);

  @override
  State<SignupAccountStep> createState() => _SignupAccountStepState();
}

class _SignupAccountStepState extends State<SignupAccountStep> {
  /// 아이디: 영문 소문자, 숫자 4~12자
  static final _idPattern = RegExp(r'^[a-z0-9]{4,12}$');

  /// 비밀번호: 영문·숫자·특수문자를 모두 포함한 8~16자 (공백 불가)
  static final _passwordPattern = RegExp(
    r'^(?=.*[A-Za-z])(?=.*\d)(?=.*[^A-Za-z0-9])\S{8,16}$',
  );

  static final _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  final _idController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmController = TextEditingController();
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();

  // 아이디 중복확인
  bool _checkingId = false;

  /// 중복확인한 아이디. 아이디를 고치면 다시 확인해야 해요.
  String? _checkedId;
  LoginIdCheck? _idCheck; // null = 아직 확인 안 함

  // 이메일 인증
  bool _sendingCode = false;
  bool _verifying = false;

  /// 인증에 성공하면 받는 가입용 토큰. 있으면 인증 완료예요.
  String? _verificationToken;

  /// 인증번호를 보낸 이메일. 이메일을 고치면 인증을 처음부터 다시 해요.
  String? _sentEmail;
  Timer? _timer;
  Duration _remaining = Duration.zero;

  /// 인증 결과 안내 (null이면 기본 안내 문구)
  String? _emailMessage;
  Color? _emailMessageColor;

  bool _submitting = false;

  String get _id => _idController.text;
  String get _password => _passwordController.text;
  String get _email => _emailController.text.trim();

  bool get _idValid => _idPattern.hasMatch(_id);
  bool get _passwordValid => _passwordPattern.hasMatch(_password);
  bool get _passwordMatches => _passwordConfirmController.text == _password;
  bool get _emailValid => _emailPattern.hasMatch(_email);
  bool get _codeSent => _sentEmail != null;
  bool get _timeLeft => _remaining > Duration.zero;
  bool get _emailVerified => _verificationToken != null;

  /// 이메일 인증 요청·확인 응답을 기다리는 중
  bool get _waitingEmail => _sendingCode || _verifying;

  /// 중복확인을 통과했는지 (서버에 확인 API가 없으면 형식 확인만으로 통과)
  bool get _idChecked =>
      _idCheck == LoginIdCheck.available || _idCheck == LoginIdCheck.formatOnly;

  bool get _canSubmit =>
      _idChecked &&
      _passwordValid &&
      _passwordMatches &&
      _emailVerified &&
      !_submitting;

  @override
  void initState() {
    super.initState();
    _idController.addListener(_onIdChanged);
    _emailController.addListener(_onEmailChanged);
    // 나머지 칸은 입력할 때마다 다시 그려서 버튼·안내 색을 갱신해요.
    for (final c in [
      _passwordController,
      _passwordConfirmController,
      _codeController,
    ]) {
      c.addListener(_refresh);
    }
  }

  void _refresh() => setState(() {});

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in [
      _idController,
      _passwordController,
      _passwordConfirmController,
      _emailController,
      _codeController,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  // ───────── 아이디 ─────────

  void _onIdChanged() {
    setState(() {
      if (_id != _checkedId) {
        _checkedId = null;
        _idCheck = null;
      }
    });
  }

  Future<void> _checkId() async {
    final id = _id;
    setState(() => _checkingId = true);
    try {
      final result = await widget.service.checkLoginId(id);
      if (!mounted || id != _id) return; // 기다리는 동안 아이디를 고쳤으면 무시
      setState(() {
        _checkedId = id;
        _idCheck = result;
      });
    } catch (e) {
      _showError(e);
    } finally {
      if (mounted) setState(() => _checkingId = false);
    }
  }

  // ───────── 이메일 인증 ─────────

  void _onEmailChanged() {
    setState(() {
      if (_codeSent && _email != _sentEmail) _resetEmailVerification();
    });
  }

  void _resetEmailVerification() {
    _timer?.cancel();
    _sentEmail = null;
    _verificationToken = null;
    _remaining = Duration.zero;
    _emailMessage = null;
    _codeController.clear();
  }

  Future<void> _requestCode() async {
    final email = _email;
    setState(() => _sendingCode = true);
    try {
      await widget.service.requestEmailCode(email);
      // 아래 _isStale과 같은 확인이지만, 바로 아래에서 context를 쓰려면
      // mounted를 여기서 직접 확인해야 분석기가 안전하다고 알아봐요.
      if (!mounted || _isStale(email)) return;
      setState(() {
        _sentEmail = email;
        _emailMessage = null;
        _codeController.clear();
        _startTimer();
      });
      showAppNotice(context, '인증번호를 보냈어요.');
    } on AuthException catch (e) {
      if (_isStale(email)) return;
      // 이미 가입된 이메일, 너무 자주 요청함 등은 이메일 칸 아래에 서버 문장을 보여줘요.
      if (_isServerError(e)) {
        setState(() => _setEmailMessage(e.message, SignupStyle.error));
      } else {
        _showError(e);
      }
    } catch (e) {
      if (_isStale(email)) return;
      _showError(e);
    } finally {
      if (mounted) setState(() => _sendingCode = false);
    }
  }

  /// 응답을 기다리는 동안 화면을 나갔거나 이메일을 고쳤으면 true.
  /// 그때 온 응답은 지금 화면과 맞지 않아서 무시해요. (PR #46 리뷰)
  bool _isStale(String requestedEmail) => !mounted || _email != requestedEmail;

  void _startTimer() {
    _timer?.cancel();
    _remaining = SignupAccountStep.codeTimeLimit;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _remaining -= const Duration(seconds: 1);
        if (!_timeLeft) {
          timer.cancel();
          _emailMessage = '인증 시간이 지났어요. 다시 요청해 주세요.';
          _emailMessageColor = SignupStyle.error;
        }
      });
    });
  }

  Future<void> _verifyCode() async {
    FocusScope.of(context).unfocus();
    final email = _sentEmail!;
    setState(() => _verifying = true);
    try {
      final token = await widget.service.verifyEmailCode(
        email: email,
        code: _codeController.text,
      );
      if (_isStale(email)) return;
      setState(() {
        _verificationToken = token;
        _timer?.cancel();
        _setEmailMessage('이메일 인증이 완료됐어요.', SignupStyle.success);
      });
    } on AuthException catch (e) {
      if (_isStale(email)) return;
      // 번호 틀림, 만료, 5번 틀림 등은 서버 문장을 그대로 보여줘요.
      if (_isServerError(e)) {
        setState(() => _setEmailMessage(e.message, SignupStyle.error));
      } else {
        _showError(e);
      }
    } catch (e) {
      if (_isStale(email)) return;
      _showError(e);
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  // ───────── 가입 ─────────

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() => _submitting = true);
    try {
      await widget.onSubmit(
        SignupAccount(
          loginId: _id,
          password: _password,
          email: _sentEmail!,
          emailVerificationToken: _verificationToken!,
        ),
      );
    } on AuthException catch (e) {
      _onSignupFailed(e);
    } catch (e) {
      _showError(e);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  /// 가입 실패: 어느 칸 문제인지에 따라 그 칸 아래에 안내해요.
  void _onSignupFailed(AuthException e) {
    if (!mounted) return;
    switch (e.code) {
      case AuthErrorCode.loginIdAlreadyExists:
        // 중복확인 API가 없어서 가입할 때 처음 알게 될 수 있어요.
        setState(() {
          _checkedId = _id;
          _idCheck = LoginIdCheck.taken;
        });
      case AuthErrorCode.emailAlreadyExists:
        setState(() {
          _resetEmailVerification();
          _setEmailMessage(e.message, SignupStyle.error);
        });
      case AuthErrorCode.emailVerificationRequired:
        // 토큰 만료(30분) 등: 이메일 인증을 처음부터 다시 해요.
        setState(() {
          _resetEmailVerification();
          _setEmailMessage('이메일 인증을 다시 진행해 주세요.', SignupStyle.error);
        });
      default:
        _showError(e);
    }
  }

  void _setEmailMessage(String message, Color color) {
    _emailMessage = message;
    _emailMessageColor = color;
  }

  /// 서버가 이유를 알려준 오류인지 (네트워크 끊김·알 수 없는 오류가 아님)
  bool _isServerError(AuthException e) => !const {
    AuthErrorCode.networkError,
    AuthErrorCode.apiBaseUrlMissing,
    AuthErrorCode.unknown,
  }.contains(e.code);

  /// 화면 아래 안내(스낵바)로 오류를 보여줘요.
  void _showError(Object error) {
    if (!mounted) return;
    final message =
        error is AuthException && error.code != AuthErrorCode.unknown
        ? error
              .message // 서버 문장, '네트워크 연결을 확인해 주세요.' 등
        : '잠시 후 다시 시도해 주세요.';
    showAppNotice(context, message);
  }

  // ───────── 화면 ─────────

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              SignupStyle.screenPadding,
              SignupStyle.barToLabel,
              SignupStyle.screenPadding,
              24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ..._buildIdSection(),
                const SizedBox(height: SignupStyle.sectionGap),
                ..._buildPasswordSection(),
                const SizedBox(height: SignupStyle.sectionGap),
                ..._buildEmailSection(),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            SignupStyle.screenPadding,
            0,
            SignupStyle.screenPadding,
            16,
          ),
          child: PrimaryButton(
            text: '가입 완료하기',
            isLoading: _submitting,
            onPressed: _canSubmit ? _submit : null,
          ),
        ),
      ],
    );
  }

  List<Widget> _buildIdSection() {
    final (String text, Color? color) = switch (_idCheck) {
      LoginIdCheck.available => ('사용할 수 있는 아이디예요.', SignupStyle.success),
      LoginIdCheck.formatOnly => (
        '사용할 수 있는 형식이에요. 중복 여부는 가입할 때 확인해요.',
        SignupStyle.success,
      ),
      LoginIdCheck.taken => ('이미 사용 중인 아이디예요.', SignupStyle.error),
      null => (
        '영문 소문자, 숫자 조합 4~12자',
        _id.isNotEmpty && !_idValid ? SignupStyle.error : null,
      ),
    };

    return [
      const SignupLabel('아이디'),
      const SizedBox(height: SignupStyle.labelToField),
      SignupTextField(
        controller: _idController,
        hintText: '아이디 입력',
        textInputAction: TextInputAction.next,
        // 영문 소문자, 숫자만 입력돼요. (로그인 화면과 같은 규칙)
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[a-z0-9]')),
          LengthLimitingTextInputFormatter(12),
        ],
        trailing: SignupInlineButton(
          label: '중복확인',
          isLoading: _checkingId,
          onPressed: _idValid && _idCheck == null ? _checkId : null,
        ),
      ),
      const SizedBox(height: SignupStyle.fieldToHelper),
      SignupHelper(text, color: color),
    ];
  }

  List<Widget> _buildPasswordSection() {
    final confirm = _passwordConfirmController.text;
    final showMismatch = confirm.isNotEmpty && !_passwordMatches;

    return [
      const SignupLabel('비밀번호'),
      const SizedBox(height: SignupStyle.labelToField),
      SignupTextField(
        controller: _passwordController,
        hintText: '비밀번호 입력',
        isPassword: true,
        textInputAction: TextInputAction.next,
        inputFormatters: [
          FilteringTextInputFormatter.deny(RegExp(r'\s')),
          LengthLimitingTextInputFormatter(16),
        ],
      ),
      const SizedBox(height: SignupStyle.fieldToHelper),
      SignupHelper(
        '영문, 숫자, 특수문자 포함 8~16자',
        color: _password.isNotEmpty && !_passwordValid
            ? SignupStyle.error
            : null,
      ),
      const SizedBox(height: SignupStyle.fieldToField),
      SignupTextField(
        controller: _passwordConfirmController,
        hintText: '비밀번호 확인',
        isPassword: true,
        textInputAction: TextInputAction.next,
        inputFormatters: [
          FilteringTextInputFormatter.deny(RegExp(r'\s')),
          LengthLimitingTextInputFormatter(16),
        ],
      ),
      if (showMismatch) ...[
        const SizedBox(height: SignupStyle.fieldToHelper),
        const SignupHelper('비밀번호가 일치하지 않아요.', color: SignupStyle.error),
      ],
    ];
  }

  List<Widget> _buildEmailSection() {
    final canRequest = _emailValid && !_emailVerified && !_waitingEmail;
    final canVerify =
        _codeSent &&
        !_emailVerified &&
        _timeLeft &&
        _codeController.text.length == 6;

    return [
      const SignupLabel('이메일 인증'),
      const SizedBox(height: SignupStyle.labelToField),
      SignupTextField(
        controller: _emailController,
        hintText: '이메일 주소 입력',
        // 인증요청·확인을 기다리는 동안에는 주소를 못 바꾸게 잠가요.
        enabled: !_emailVerified && !_waitingEmail,
        keyboardType: TextInputType.emailAddress,
        textInputAction: TextInputAction.done,
        inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'\s'))],
        trailing: SignupInlineButton(
          label: _codeSent && !_emailVerified ? '재요청' : '인증요청',
          isLoading: _sendingCode,
          onPressed: canRequest ? _requestCode : null,
        ),
      ),
      const SizedBox(height: SignupStyle.fieldToField),
      SignupTextField(
        controller: _codeController,
        hintText: '인증번호 6자리',
        enabled: _codeSent && !_emailVerified && !_verifying,
        keyboardType: TextInputType.number,
        textInputAction: TextInputAction.done,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(6),
        ],
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_codeSent && !_emailVerified) ...[
              Text(_formatRemaining(), style: SignupStyle.timerText),
              const SizedBox(width: 18),
            ],
            SignupInlineButton(
              label: '확인',
              filled: true,
              isLoading: _verifying,
              onPressed: canVerify ? _verifyCode : null,
            ),
          ],
        ),
      ),
      const SizedBox(height: SignupStyle.fieldToHelper),
      SignupHelper(
        _emailMessage ?? '이메일로 발송된 인증번호를 입력해주세요.',
        color: _emailMessage == null ? null : _emailMessageColor,
      ),
    ];
  }

  /// 남은 시간 '02:59' 형식
  String _formatRemaining() {
    final minutes = _remaining.inMinutes.toString().padLeft(2, '0');
    final seconds = (_remaining.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
