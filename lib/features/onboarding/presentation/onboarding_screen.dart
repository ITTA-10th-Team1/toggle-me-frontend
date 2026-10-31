import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/room_mode_toggle.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  bool _isOn = true;

  void _changeRoomMode(bool value) {
    setState(() {
      _isOn = value;
    });
  }

  void _goToLogin() {
    context.go(AppRoutes.login);
  }

  void _goToGuestIntro() {
    context.go(AppRoutes.guestIntro);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFFFDF0),
              Color(0xFFFFF4B3),
              Color(0xFFFFD58E),
              Color(0xFFFFA06E),
            ],
            stops: [0.0, 0.32, 0.68, 1.0],
          ),
        ),
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

                            const SizedBox(height: 32),

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
                        color: const Color(0xCC171717),
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
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '취향을 모으는 가장 나다운 방법',
          style: TextStyle(
            color: Color(0xFF171717),
            fontSize: 23,
            fontWeight: FontWeight.w800,
            letterSpacing: -1.0,
          ),
        ),

        SizedBox(height: 12),

        Text(
          '점점 잊혀가는 나의 취향을\n'
          '나만의 방에 하나씩 기록해두세요',
          style: TextStyle(
            color: Color(0xFF292929),
            fontSize: 15,
            fontWeight: FontWeight.w500,
            height: 1.45,
            letterSpacing: -0.3,
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
          onPressed: _goToGuestIntro,
        ),

        const SizedBox(height: 8),

        AppButton(
          label: '로그인',
          variant: AppButtonVariant.login,
          width: double.infinity,
          onPressed: _goToLogin,
        ),
      ],
    );
  }
}
