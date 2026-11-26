import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/app_notice.dart';
import '../data/models/signup_request.dart';
import '../data/signup_service.dart';
import 'widgets/signup_account_step.dart';
import 'widgets/signup_profile_step.dart';
import 'widgets/signup_style.dart';

/// 회원가입 화면 (이슈 #44)
/// 경로 하나(AppRoutes.signup) 안에서 두 단계를 보여줘요.
/// - 1단계: 닉네임, 성별, 생년월일 → [다음]
/// - 2단계: 아이디, 비밀번호, 이메일 인증 → [가입 완료하기]
/// 뒤로가기: 2단계 → 1단계(입력값 유지), 1단계 → 로그인 화면
class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key, this.service});

  /// 테스트에서 가짜 서비스를 넣을 수 있어요. 없으면 FakeSignupService.
  final SignupService? service;

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  // TODO(api): 회원가입 API가 나오면 실제 서비스로 교체
  late final SignupService _service =
      widget.service ?? const FakeSignupService();

  int _step = 0;
  SignupProfile? _profile;

  void _goToAccountStep(SignupProfile profile) {
    setState(() {
      _profile = profile;
      _step = 1;
    });
  }

  void _onBack() {
    FocusScope.of(context).unfocus();
    if (_step == 1) {
      setState(() => _step = 0);
    } else {
      context.go(AppRoutes.login);
    }
  }

  Future<void> _signup(SignupAccount account) async {
    await _service.signup(SignupRequest(profile: _profile!, account: account));
    if (!mounted) return;
    // TODO(router): 가입 후 흐름은 팀 확인 후 연결
    //   1. 비회원 데이터가 있으면 회원 전환 팝업 (비회원 정책 10번)
    //   2. 사용자 상태별 이동 (프로필 미설정 / 방 미생성 / 방 생성 완료)
    //   지금은 로그인 화면으로 돌아가서 직접 로그인해요.
    showAppNotice(context, '회원가입이 완료됐어요. 로그인해 주세요.');
    context.go(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    // 안드로이드 뒤로가기 버튼도 화면의 ← 버튼과 똑같이 동작하게 해요.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _onBack();
      },
      child: Scaffold(
        backgroundColor: AppColors.white,
        body: SafeArea(
          child: Column(
            children: [
              _TopBar(onBack: _onBack),
              Expanded(
                // IndexedStack: 두 단계를 모두 살려둬서, 1단계로 돌아가도 입력값이 남아 있어요.
                child: IndexedStack(
                  index: _step,
                  children: [
                    SignupProfileStep(onNext: _goToAccountStep),
                    SignupAccountStep(service: _service, onSubmit: _signup),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 상단 바: 높이 52, 왼쪽 ←, 가운데 '회원가입'
class _TopBar extends StatelessWidget {
  const _TopBar({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: SignupStyle.topBarHeight,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 4),
              child: IconButton(
                tooltip: '뒤로가기',
                icon: const Icon(
                  Icons.arrow_back,
                  color: AppColors.textPrimary,
                  size: 28,
                ),
                onPressed: onBack,
              ),
            ),
          ),
          Text('회원가입', style: SignupStyle.title),
        ],
      ),
    );
  }
}
