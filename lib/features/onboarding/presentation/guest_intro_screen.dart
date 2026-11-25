import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../app/theme/app_colors.dart';

class GuestIntroScreen extends StatelessWidget {
  const GuestIntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.guestBackground,
      appBar: AppBar(
        title: const Text('��ȸ�� �̿� �ȳ�'),
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
                color: AppColors.guestAccent,
              ),
              const SizedBox(height: 24),
              const Text(
                '��ȸ������ �����ϱ�',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                '��ȸ���� OFF ���� ���񽺸� �̿��� �� �ֽ��ϴ�.\n'
                'ȸ�� ���� ����� �α��� �� ����� �� �ֽ��ϴ�.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, height: 1.6),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => context.go('${AppRoutes.room}?guest=1'),
                child: const Text('��ȸ������ ����ϱ�'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => context.go(AppRoutes.login),
                child: const Text('�α����ϱ�'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
