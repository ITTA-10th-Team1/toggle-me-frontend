import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/widgets/app_notice.dart';
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
  static const codeTimeLimit = Duration(minutes: 3);

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
  bool? _idAvailable; // null = 아직 확인 안 함

  // 이메일 인증
  bool _sendingCode = false;
  bool _verifying = false;
  bool _emailVerified = false;

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

  bool get _canSubmit =>
      _idAvailable == true &&
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
        _idAvailable = null;
      }
    });
  }

  Future<void> _checkId() async {
    final id = _id;
    setState(() => _checkingId = true);
    try {
      final available = await widget.service.isLoginIdAvailable(id);
      if (!mounted || id != _id) return; // 기다리는 동안 아이디를 고쳤으면 무시
      setState(() {
        _checkedId = id;
        _idAvailable = available;
      });
    } catch (_) {
      _showError();
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
    _emailVerified = false;
    _remaining = Duration.zero;
    _emailMessage = null;
    _codeController.clear();
  }

  Future<void> _requestCode() async {
    final email = _email;
    setState(() => _sendingCode = true);
    try {
      await widget.service.requestEmailCode(email);
      if (!mounted) return;
      setState(() {
        _sentEmail = email;
        _emailMessage = null;
        _codeController.clear();
        _startTimer();
      });
      showAppNotice(context, '인증번호를 보냈어요.');
    } catch (_) {
      _showError();
    } finally {
      if (mounted) setState(() => _sendingCode = false);
    }
  }

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
    setState(() => _verifying = true);
    try {
      final ok = await widget.service.verifyEmailCode(
        email: _sentEmail!,
        code: _codeController.text,
      );
      if (!mounted) return;
      setState(() {
        if (ok) {
          _emailVerified = true;
          _timer?.cancel();
          _emailMessage = '이메일 인증이 완료됐어요.';
          _emailMessageColor = SignupStyle.success;
        } else {
          _emailMessage = '인증번호가 올바르지 않아요.';
          _emailMessageColor = SignupStyle.error;
        }
      });
    } catch (_) {
      _showError();
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
        SignupAccount(loginId: _id, password: _password, email: _sentEmail!),
      );
    } catch (_) {
      _showError();
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showError() {
    if (!mounted) return;
    // TODO(api): API가 나오면 서버 오류 메시지(message)를 그대로 보여주기
    showAppNotice(context, '잠시 후 다시 시도해 주세요.');
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
    final (String text, Color? color) = switch (_idAvailable) {
      true => ('사용할 수 있는 아이디예요.', SignupStyle.success),
      false => ('이미 사용 중인 아이디예요.', SignupStyle.error),
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
          onPressed: _idValid && _idAvailable == null ? _checkId : null,
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
    final canRequest = _emailValid && !_emailVerified && !_sendingCode;
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
        enabled: !_emailVerified,
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
        enabled: _codeSent && !_emailVerified,
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
