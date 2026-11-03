import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';

class GuestIntroScreen extends StatelessWidget {
  const GuestIntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF9EF),
      appBar: AppBar(
        title: const Text('비회원 이용 안내'),
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.info_outline_rounded,
                size: 64,
                color: Color(0xFFFF883F),
              ),
              const SizedBox(height: 24),
              const Text(
                '비회원으로 시작하기',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                '비회원은 OFF 모드로 서비스를 이용할 수 있습니다.\n'
                '회원 전용 기능은 로그인 후 사용할 수 있습니다.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, height: 1.6),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => context.go(AppRoutes.room),
                child: const Text('비회원으로 계속하기'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => context.go(AppRoutes.login),
                child: const Text('로그인하기'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
