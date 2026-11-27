import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../app/theme/app_gradients.dart';
import '../data/room_onboarding_draft.dart';
import '../../room/domain/room_visibility.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/room_mode_toggle.dart';
import '../../../core/network/member_api.dart';
import '../../../core/widgets/app_notice.dart';
import '../../room/data/room_repository.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({
    super.key,
    this.roomDraft,
    this.resumeSession = false,
    this.repository,
  });

  final RoomOnboardingDraft? roomDraft;
  final bool resumeSession;
  final RoomRepository? repository;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late bool _isOn;
  bool _resuming = false;
  bool _redirecting = false;
  RoomOnboardingDraft get _draft => widget.roomDraft ?? roomOnboardingDraft;

  @override
  void initState() {
    super.initState();
    _isOn = _draft.visibility.isPublic;
    _resuming = widget.resumeSession;
    if (widget.resumeSession) _resume();
  }

  Future<void> _resume() async {
    final repo = widget.repository ?? RoomRepository(memberApi);
    try {
      await _draft.restore();
      if (!mounted) return;
      setState(() => _isOn = _draft.visibility.isPublic);
      if (!await repo.api.hasSession) return;
      final me = await repo.me();
      if (!mounted ||
          GoRouter.of(context).routeInformationProvider.value.uri.path !=
              AppRoutes.onboarding) {
        return;
      }
      _redirecting = true;
      context.go(
        me['onboardingStep'] == 'DONE' ? AppRoutes.room : AppRoutes.memberSetup,
      );
    } catch (_) {
      // Offline sessions can retry through login; never erase stored room data.
    } finally {
      if (mounted && !_redirecting) setState(() => _resuming = false);
    }
  }

  void _changeRoomMode(bool value) {
    setState(() {
      _isOn = value;
      _draft.visibility = value
          ? RoomVisibility.socialOn
          : RoomVisibility.socialOff;
    });
  }

  Future<void> _goToLogin() async {
    try {
      await _draft.persist();
      if (mounted) context.go(AppRoutes.login);
    } catch (_) {
      if (mounted) showAppNotice(context, '공개 설정을 저장하지 못했어요. 다시 시도해 주세요.');
    }
  }

  void _goToGuestIntro() {
    context.go(AppRoutes.guestIntro);
  }

  @override
  Widget build(BuildContext context) {
    if (_resuming) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.onboarding),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final screenHeight = math.max(constraints.maxHeight, 680.0);

              return SingleChildScrollView(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: SizedBox(
                      height: screenHeight,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 12),

                            _buildHeader(),

                            Expanded(child: _buildRoomImage()),

                            _buildDescription(),

                            const SizedBox(height: 42),

                            _buildButtons(),

                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Image.asset(
          'assets/images/onboarding_logo.png',
          width: 120.26,
          height: 23.6,
          fit: BoxFit.contain,
        ),

        RoomModeToggle(isOn: _isOn, onChanged: _changeRoomMode),
      ],
    );
  }

  Widget _buildRoomImage() {
    return Center(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final imageSize = math.min(
            constraints.maxWidth,
            constraints.maxHeight,
          );

          return SizedBox(
            width: imageSize,
            height: imageSize,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  'assets/images/onboarding_room_on.png',
                  fit: BoxFit.contain,
                ),

                if (!_isOn)
                  Container(
                    alignment: Alignment.center,
                    color: Colors.black.withValues(alpha: 0.18),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.roomOffOverlay,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'OFF',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDescription() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '취향을 모으는 가장 나다운 방법',
          style: AppTextStyles.head1.copyWith(color: AppColors.textPrimary),
        ),

        const SizedBox(height: 12),

        Text(
          '점점 잊혀가는 나의 취향을\n'
          '나만의 방에 하나씩 기록해두세요',
          style: AppTextStyles.body2.copyWith(
            color: AppColors.onboardingTextSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildButtons() {
    return Column(
      children: [
        AppButton(
          label: '비회원으로 시작하기',
          variant: AppButtonVariant.guest,
          width: double.infinity,
          height: 53,
          textStyle: AppTextStyles.head3.copyWith(fontWeight: FontWeight.w400),
          onPressed: _goToGuestIntro,
        ),

        const SizedBox(height: 8),

        AppButton(
          label: '로그인',
          variant: AppButtonVariant.login,
          width: double.infinity,
          height: 53,
          textStyle: AppTextStyles.head3.copyWith(fontWeight: FontWeight.w400),
          onPressed: _goToLogin,
        ),
      ],
    );
  }
}
