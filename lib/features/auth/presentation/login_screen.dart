import '../../../core/widgets/app_notice.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../data/auth_service.dart';
import '../data/kakao_auth_client.dart';
import '../data/models/auth_error_code.dart';
import '../data/models/login_response.dart';
import '../data/models/onboarding_step.dart';
import '../../../app/theme/app_colors.dart';
import 'widgets/login_style.dart';
import 'widgets/login_text_field.dart';
import 'widgets/primary_button.dart';
import 'widgets/social_login_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.authService, this.onAuthenticated});

  final AuthService? authService;
  final ValueChanged<LoginResponse>? onAuthenticated;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // ACC-01: MVP������ īī���� �������.
  // ���̹������� ��ư �ڵ�� �״�� �־, MVP ���� �� ��Ͽ� �߰��ϸ� �ٽ� ������.
  static const _visibleSocialTypes = [SocialType.kakao];

  final _formKey = GlobalKey<FormState>();
  final _idController = TextEditingController();
  final _passwordController = TextEditingController();
  late final _authService = widget.authService ?? AuthService();

  bool _isLoading = false;

  // ȭ�鼳�輭 8��: ���̵�� ��й�ȣ�� ��� �Էµž� �α��� ��ư Ȱ��ȭ
  bool get _canLogin =>
      _idController.text.trim().isNotEmpty &&
      _passwordController.text.isNotEmpty;

  @override
  void initState() {
    super.initState();
    // ���ڸ� �Է��� ������ ȭ���� �ٽ� �׷��� ��ư Ȱ��ȭ ���θ� �����ؿ�.
    _idController.addListener(_onInputChanged);
    _passwordController.addListener(_onInputChanged);
  }

  void _onInputChanged() => setState(() {});

  @override
  void dispose() {
    _idController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ������������������ ���� ������������������

  Future<void> _onLoginPressed() async {
    if (_isLoading) return; // ��û �� �ߺ� Ŭ�� ����
    FocusScope.of(context).unfocus(); // Ű���� ������
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final response = await _authService.login(
        id: _idController.text.trim(),
        password: _passwordController.text,
      );
      _goNextScreen(response);
    } on AuthException catch (e) {
      if (!mounted) return;
      // ���輭 ���� 3: �α��� ���� �� ���̵�� ����, ��й�ȣ�� �ʱ�ȭ
      if (e.code == AuthErrorCode.credentialsInvalid) {
        _passwordController.clear();
      }
      _showMessage(e.message);
    } catch (e) {
      _showMessage('�α��� �� ������ ������.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _onSocialPressed(SocialType type) async {
    if (_isLoading) return; // ��û �� �ߺ� Ŭ�� ����

    try {
      switch (type) {
        case SocialType.kakao:
          await _onKakaoPressed();
        case SocialType.naver:
          await _authService.loginWithNaver();
        case SocialType.google:
          await _authService.loginWithGoogle();
      }
    } on UnimplementedError catch (e) {
      _showMessage(e.message ?? '�غ� ���̿���.');
    } on KakaoAppKeyMissingException catch (e) {
      _showMessage(e.toString());
    } on AuthException catch (e) {
      _showMessage(e.message);
    } catch (e) {
      _showMessage('�α��� �� ������ ������.');
    }
  }

  Future<void> _onKakaoPressed() async {
    setState(() => _isLoading = true);
    try {
      final response = await _authService.loginWithKakao();
      // ���輭 ���� 5: īī�� ���� ��� �� ���� �޽��� ���� �α��� ȭ�� ����
      if (response == null) return;
      _goNextScreen(response);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// �α��� ���� �� ���� ȭ������ �̵�
  void _goNextScreen(LoginResponse response) {
    if (!mounted) return;
    if (widget.onAuthenticated != null) {
      widget.onAuthenticated!(response);
      return;
    }
    // Completed accounts can enter the main room without replacing the
    // login team's authentication or onboarding state model.
    if (response.onboardingStep == OnboardingStep.done) {
      context.go(AppRoutes.room);
      return;
    }
    // TODO(router): ������ ����/Ʃ�丮�� ��� �߰� �� onboardingStep�� �б�
    //   OnboardingStep.profile   �� ���� ������ ����
    //   OnboardingStep.furniture �� Ʃ�丮��(���� ����)
    // PROFILE/FURNITURE destinations still await their owning screens.
    context.go(AppRoutes.onboarding);
  }

  void _showMessage(String message) {
    if (!mounted) return;
    showAppNotice(context, message);
  }

  // ������������������ �Է� �˻� ������������������

  String? _validateId(String? value) {
    if (value == null || value.trim().isEmpty) return '���̵� �Է����ּ���.';
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return '��й�ȣ�� �Է����ּ���.';
    return null;
  }

  // ������������������ ȭ�� ������������������

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBackButton(),
                const SizedBox(height: LoginStyle.backToLogo),
                _buildHeader(),
                const SizedBox(height: LoginStyle.introToId),
                LoginTextField(
                  controller: _idController,
                  hintText: '���̵� �Է�',
                  icon: Icons.person_outline,
                  keyboardType: TextInputType.text,
                  textInputAction: TextInputAction.next,
                  // ȭ�鼳�輭 4��: ���� �ҹ���(a~z), ����(0~9)�� �Է� ����
                  // �빮��, ����, Ư�����ڴ� ������ �Էµ��� �ʾƿ�.
                  // TODO: �鿣�� ���̵� ����(�̸���?) �� Ȯ�� �� ���߱�
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[a-z0-9]')),
                  ],
                  validator: _validateId,
                ),
                const SizedBox(height: LoginStyle.idToPassword),
                LoginTextField(
                  controller: _passwordController,
                  hintText: '��й�ȣ �Է�',
                  icon: Icons.lock_outline,
                  isPassword: true,
                  textInputAction: TextInputAction.done,
                  validator: _validatePassword,
                ),
                const SizedBox(height: LoginStyle.passwordToFind),
                _buildOptionsRow(),
                const SizedBox(height: LoginStyle.findToLogin),
                PrimaryButton(
                  text: '�α���',
                  isLoading: _isLoading,
                  // null�� �ѱ�� ��ư�� ��Ȱ��ȭ(ȸ��, �� ����)�ſ�.
                  onPressed: _canLogin ? _onLoginPressed : null,
                ),
                const SizedBox(height: LoginStyle.loginToSns),
                _buildSocialSection(),
                const SizedBox(height: LoginStyle.kakaoToSignUp),
                _buildSignUpRow(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackButton() {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: IconButton(
        tooltip: '�ڷΰ���',
        padding: EdgeInsets.zero,
        // ��ư ũ�⸦ ������(36x36)�� �� ���缭, �Ʒ� �ΰ����� ���� 45�� ��Ȯ�ؿ�.
        constraints: const BoxConstraints.tightFor(
          width: LoginStyle.backIconSize,
          height: LoginStyle.backIconSize,
        ),
        iconSize: LoginStyle.backIconSize,
        // ���� �� ���̴� ��ġ ���� ����(48)�� ���ּ� ���� ũ�⸦ 36���� �����.
        style: IconButton.styleFrom(
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        icon: const Icon(Icons.arrow_back, color: AppColors.textSecondary),
        onPressed: () => context.go(AppRoutes.onboarding),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // �Ǳ׸� ���� 250x49. �̹��� ������ �޶� ��׷����� �ʰ� contain ���.
        Image.asset(
          'assets/images/img_login_logo.png',
          width: LoginStyle.logoWidth,
          height: LoginStyle.logoHeight,
          fit: BoxFit.contain,
          alignment: Alignment.centerLeft,
          semanticLabel: 'Toggle me',
        ),
        const SizedBox(height: LoginStyle.logoToIntro),
        Text('������ ����ϰ� �߰��ϴ�\n������ ��ī�̺� ����', style: LoginStyle.intro),
      ],
    );
  }

  Widget _buildOptionsRow() {
    return Row(
      children: [
        // Spacer: �� ������ ä���� '���̵𡤺�й�ȣ ã��'�� ������ ������ �о����.
        const Spacer(),
        TextButton(
          onPressed: () => _showMessage('���̵𡤺�й�ȣ ã��� �غ� ���̿���.'),
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text('���̵𡤺�й�ȣ ã��', style: LoginStyle.findAccount),
        ),
      ],
    );
  }

  Widget _buildSocialSection() {
    return Column(
      children: [
        Center(child: Text('SNS ���� �α���', style: LoginStyle.sns)),
        const SizedBox(height: LoginStyle.snsToKakao),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 16,
          children: [
            for (final type in _visibleSocialTypes)
              SocialLoginButton(
                type: type,
                onPressed: () => _onSocialPressed(type),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildSignUpRow() {
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('������ �����Ű���?', style: LoginStyle.signUpQuestion),
          TextButton(
            onPressed: () => context.go(AppRoutes.signup),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text('ȸ������', style: LoginStyle.signUpLink),
          ),
        ],
      ),
    );
  }
}
