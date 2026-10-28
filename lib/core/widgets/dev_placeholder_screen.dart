import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/router/app_routes.dart';

class DevPlaceholderScreen extends StatelessWidget {
  const DevPlaceholderScreen({
    super.key,
    required this.title,
    required this.description,
  });

  final String title;
  final String description;

  static const Map<String, String> screens = {
    AppRoutes.onboarding: '온보딩',
    AppRoutes.login: '로그인',
    AppRoutes.signup: '회원가입',
    AppRoutes.room: '3D 방',
    AppRoutes.items: '아이템 목록',
    AppRoutes.itemCreate: '기록하기',
    AppRoutes.pinboard: '핀보드',
    AppRoutes.guestbook: '방명록',
    AppRoutes.shop: '아이템 상점',
    AppRoutes.calendar: '월별무드 캘린더',
    AppRoutes.social: '소셜',
    AppRoutes.mypage: '마이페이지',
    AppRoutes.notifications: '알림',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 24),

            Icon(
              Icons.construction_outlined,
              size: 56,
              color: Theme.of(context).colorScheme.primary,
            ),

            const SizedBox(height: 20),

            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium,
            ),

            const SizedBox(height: 12),

            Text(description, textAlign: TextAlign.center),

            const SizedBox(height: 12),

            const Text('현재 개발용 임시 화면입니다.', textAlign: TextAlign.center),

            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),

            Text('화면 이동 테스트', style: Theme.of(context).textTheme.titleMedium),

            const SizedBox(height: 12),

            ...screens.entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: OutlinedButton(
                  onPressed: () => context.go(entry.key),
                  child: Text(entry.value),
                ),
              ),
            ),

            const SizedBox(height: 12),

            OutlinedButton(
              onPressed: () => context.go('/unknown'),
              child: const Text('404 오류 화면 테스트'),
            ),
          ],
        ),
      ),
    );
  }
}
