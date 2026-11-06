import '../../core/widgets/app_notice.dart';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/dev_placeholder_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/item/presentation/item_upload_screen.dart';
import '../../features/onboarding/presentation/guest_intro_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/room/presentation/room_screen.dart';
import '../../features/room/presentation/room_presentation_config.dart';
import '../../features/social/presentation/friend_list_screen.dart';
import '../../features/pinboard/presentation/pinboard_screen.dart';
import '../../features/feed/presentation/feed_screen.dart';
import '../../features/item_detail/presentation/item_detail_screen.dart';
import 'app_routes.dart';

final GoRouter appRouter = GoRouter(
  // Keep normal startup; presentation may opt in with ROOM_DEMO_ENTRY.
  initialLocation: const bool.fromEnvironment('ROOM_DEMO_ENTRY')
      ? AppRoutes.room
      : AppRoutes.onboarding,

  routes: [
    GoRoute(
      path: AppRoutes.onboarding,
      builder: (context, state) => const OnboardingScreen(),
    ),

    GoRoute(
      path: AppRoutes.guestIntro,
      builder: (context, state) => const GuestIntroScreen(),
    ),

    GoRoute(
      path: AppRoutes.login,
      builder: (context, state) => const LoginScreen(),
    ),

    GoRoute(
      path: AppRoutes.signup,
      builder: (context, state) => const DevPlaceholderScreen(
        title: '회원가입',
        description: '회원가입 화면 준비 중',
      ),
    ),

    // 실제 메인 3D 방 화면
    GoRoute(
      path: AppRoutes.room,
      builder: (context, state) => RoomScreen(
        moodHashtags: RoomPresentationConfig.moodHashtags,
        onFurnitureTap: (category) => context.push(
          Uri(
            path: AppRoutes.pinboard,
            queryParameters: {'category': category},
          ).toString(),
        ),
        onProfile: () => context.push(AppRoutes.mypage),
        onNotifications: () => context.push(AppRoutes.notifications),
        onRecord: () => context.push(AppRoutes.itemCreate),
        onGuestbook: () => context.push(AppRoutes.guestbook),
        onShop: () => context.push(AppRoutes.shop),
        onMood: () => context.push(AppRoutes.calendar),
        onFriends: () => context.push(AppRoutes.social),
        onCategory: (category) {
          showAppNotice(context, '$category 기능은 준비 중입니다.');
        },
      ),
    ),

    GoRoute(
      path: AppRoutes.items,
      builder: (context, state) => const FeedScreen(),
    ),

    GoRoute(
      path: AppRoutes.itemCreate,
      builder: (context, state) => const ItemUploadScreen(),
    ),

    GoRoute(
      path: AppRoutes.itemDetail,
      builder: (context, state) {
        final itemId = int.parse(state.pathParameters['itemId']!);

        return ItemDetailScreen(itemId: itemId);
      },
    ),

    GoRoute(
      path: AppRoutes.pinboard,
      builder: (context, state) => const PinboardScreen(),
    ),

    GoRoute(
      path: AppRoutes.guestbook,
      builder: (context, state) =>
          const DevPlaceholderScreen(title: '방명록', description: '방명록 화면 준비 중'),
    ),

    GoRoute(
      path: AppRoutes.shop,
      builder: (context, state) => const DevPlaceholderScreen(
        title: '아이템 상점',
        description: '아이템 상점 화면 준비 중',
      ),
    ),

    GoRoute(
      path: AppRoutes.calendar,
      builder: (context, state) => const DevPlaceholderScreen(
        title: '월별무드 캘린더',
        description: '캘린더 화면 준비 중',
      ),
    ),

    GoRoute(
      path: AppRoutes.social,
      builder: (context, state) => const FriendListScreen(),
    ),

    GoRoute(
      path: AppRoutes.mypage,
      builder: (context, state) => const DevPlaceholderScreen(
        title: '마이페이지',
        description: '마이페이지 화면 준비 중',
      ),
    ),

    GoRoute(
      path: AppRoutes.notifications,
      builder: (context, state) =>
          const DevPlaceholderScreen(title: '알림', description: '알림 화면 준비 중'),
    ),
  ],

  errorBuilder: (context, state) => Scaffold(
    appBar: AppBar(title: const Text('오류')),
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 64),
            const SizedBox(height: 16),
            const Text('404 - 페이지를 찾을 수 없습니다.', textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go(AppRoutes.room),
              child: const Text('3D 방으로 돌아가기'),
            ),
          ],
        ),
      ),
    ),
  ),
);
