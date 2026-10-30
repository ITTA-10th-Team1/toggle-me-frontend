import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../data/auth_service.dart';
import 'auth_colors.dart';
import 'widgets/app_text_field.dart';
import 'widgets/primary_button.dart';
import 'widgets/social_login_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // ACC-01: MVP에서는 카카오만 보여줘요.
  // 네이버·구글 버튼 코드는 그대로 있어서, MVP 이후 이 목록에 추가하면 다시 보여요.
  static const _visibleSocialTypes = [SocialType.kakao];

  final _formKey = GlobalKey<FormState>();
  final _idController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();

  bool _isLoading = false;

  // 화면설계서 8번: 아이디와 비밀번호가 모두 입력돼야 로그인 버튼 활성화
  bool get _canLogin =>
      _idController.text.trim().isNotEmpty &&
      _passwordController.text.isNotEmpty;

  @override
  void initState() {
    super.initState();
    // 글자를 입력할 때마다 화면을 다시 그려서 버튼 활성화 여부를 갱신해요.
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

  // ───────── 동작 ─────────

  Future<void> _onLoginPressed() async {
    FocusScope.of(context).unfocus(); // 키보드 내리기
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await _authService.login(
        id: _idController.text.trim(),
        password: _passwordController.text,
      );
      if (!mounted) return;
      // TODO(router): 프로필 설정/튜토리얼 경로 추가 후 상태별 분기
      // 지금은 임시로 온보딩으로 보내요.
      context.go(AppRoutes.onboarding);
    } catch (e) {
      _showMessage(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _onSocialPressed(SocialType type) async {
    try {
      switch (type) {
        case SocialType.kakao:
          await _authService.loginWithKakao();
        case SocialType.naver:
          await _authService.loginWithNaver();
        case SocialType.google:
          await _authService.loginWithGoogle();
      }
    } on UnimplementedError catch (e) {
      _showMessage(e.message ?? '준비 중이에요.');
    } catch (e) {
      _showMessage('로그인 중 문제가 생겼어요.');
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  // ───────── 입력 검사 ─────────

  String? _validateId(String? value) {
    if (value == null || value.trim().isEmpty) return '아이디를 입력해주세요.';
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return '비밀번호를 입력해주세요.';
    return null;
  }

  // ───────── 화면 ─────────

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
                const SizedBox(height: 24),
                _buildHeader(),
                const SizedBox(height: 40),
                AppTextField(
                  controller: _idController,
                  hintText: '아이디 입력',
                  icon: Icons.person_outline,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: _validateId,
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: _passwordController,
                  hintText: '비밀번호 입력',
                  icon: Icons.lock_outline,
                  isPassword: true,
                  textInputAction: TextInputAction.done,
                  validator: _validatePassword,
                ),
                const SizedBox(height: 8),
                _buildOptionsRow(),
                const SizedBox(height: 20),
                PrimaryButton(
                  text: '로그인',
                  isLoading: _isLoading,
                  // null을 넘기면 버튼이 비활성화(회색, 안 눌림)돼요.
                  onPressed: _canLogin ? _onLoginPressed : null,
                ),
                const SizedBox(height: 48),
                _buildSocialSection(),
                const SizedBox(height: 48),
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
        padding: EdgeInsets.zero,
        alignment: Alignment.centerLeft,
        icon: const Icon(Icons.arrow_back, color: AuthColors.subText),
        onPressed: () => context.go(AppRoutes.onboarding),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 피그마 기준 250x50. 이미지 비율이 달라도 찌그러지지 않게 contain 사용.
        Image.asset(
          'assets/images/logo.png',
          width: 250,
          height: 50,
          fit: BoxFit.contain,
          alignment: Alignment.centerLeft,
          semanticLabel: 'Toggle me',
        ),
        const SizedBox(height: 12),
        const Text(
          '취향을 기록하고 발견하는\n공간형 아카이빙 서비스',
          style: TextStyle(
            fontSize: 13,
            height: 1.5,
            color: AuthColors.subText,
          ),
        ),
      ],
    );
  }

  Widget _buildOptionsRow() {
    return Row(
      children: [
        // Spacer: 빈 공간을 채워서 '아이디·비밀번호 찾기'를 오른쪽 끝으로 밀어줘요.
        const Spacer(),
        TextButton(
          onPressed: () => _showMessage('아이디·비밀번호 찾기는 준비 중이에요.'),
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text(
            '아이디·비밀번호 찾기',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AuthColors.black,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSocialSection() {
    return Column(
      children: [
        const Center(
          child: Text(
            'SNS 간편 로그인',
            style: TextStyle(fontSize: 12, color: AuthColors.hint),
          ),
        ),
        const SizedBox(height: 16),
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
          const Text(
            '계정이 없으신가요?',
            style: TextStyle(fontSize: 12, color: AuthColors.hint),
          ),
          TextButton(
            onPressed: () => context.go(AppRoutes.signup),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              '회원가입',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AuthColors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
