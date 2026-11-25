import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/network/member_api.dart';
import '../../../core/widgets/app_notice.dart';
import '../data/room_repository.dart';
import '../domain/room_data.dart';
import '../domain/room_visibility.dart';
import 'room_mood_hashtags.dart';
import 'room_screen.dart';
import '../../guide/data/guide_progress_store.dart';
import '../../guide/presentation/usage_guide_screen.dart';
import '../../social/presentation/widgets/share_taste_dialog.dart';

class MemberRoomScreen extends StatefulWidget {
  const MemberRoomScreen({super.key, this.repository, this.guideProgress});
  final RoomRepository? repository;
  final GuideProgressStore? guideProgress;
  @override
  State<MemberRoomScreen> createState() => _MemberRoomScreenState();
}

class _MemberRoomScreenState extends State<MemberRoomScreen> {
  late final repo = widget.repository ?? RoomRepository(memberApi);
  RoomData? room;
  String? error;
  bool loading = true;
  bool leaving = false;
  int generation = 0;
  late final guideProgress = widget.guideProgress ?? GuideProgressStore();
  bool guideChecked = false;
  bool guideOpen = false;
  int? memberId;
  String nickname = 'OO';

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final request = ++generation;
    setState(() {
      loading = true;
      error = null;
    });
    try {
      if (!await repo.api.hasSession) {
        if (mounted) context.go(AppRoutes.login);
        return;
      }
      final me = await repo.me();
      memberId = (me['memberId'] as num).toInt();
      nickname = me['nickname'] as String? ?? 'OO';
      if (me['onboardingStep'] != 'DONE') {
        if (mounted) context.go(AppRoutes.memberSetup);
        return;
      }
      final data = await repo.load();
      if (!mounted || request != generation) return;
      if (data == null) {
        context.go(AppRoutes.memberSetup);
        return;
      }
      setState(() {
        room = data;
        loading = false;
      });
      if (!guideChecked) {
        guideChecked = true;
        final completed = await guideProgress.hasCompleted(memberId!);
        if (!mounted || completed || request != generation) return;
        await WidgetsBinding.instance.endOfFrame;
        if (mounted && ModalRoute.of(context)?.isCurrent == true) {
          await showGuide();
        }
      }
    } catch (e) {
      if (!mounted || request != generation) return;
      if (e is MemberApiException &&
          ['UNAUTHORIZED', 'INVALID_REFRESH_TOKEN'].contains(e.code)) {
        context.go(AppRoutes.login);
      } else {
        setState(() {
          error = '$e';
          loading = false;
        });
      }
    }
  }

  Future<void> open(String path) async {
    await context.push(path);
    if (mounted && !leaving) await load();
  }

  Future<void> showGuide() async {
    if (guideOpen || leaving || memberId == null) return;
    guideOpen = true;
    final account = memberId!;
    try {
      await showUsageGuide(
        context,
        onComplete: () => guideProgress.complete(account),
      );
    } finally {
      guideOpen = false;
    }
  }

  Future<void> logout() async {
    if (leaving) return;
    leaving = true;
    generation++;
    try {
      await repo.api.logout();
    } catch (_) {
      if (mounted) showAppNotice(context, '��⿡���� �α׾ƿ��߾��. ���� ������ Ȯ������ ���߾��.');
    }
    if (mounted) context.go(AppRoutes.login);
  }

  Future<RoomVisibility> saveVisibility(RoomVisibility value) async {
    try {
      return await repo.visibility(room!.id, value);
    } on MemberApiException catch (e) {
      if (mounted &&
          ['UNAUTHORIZED', 'INVALID_REFRESH_TOKEN'].contains(e.code)) {
        context.go(AppRoutes.login);
      }
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(error!, textAlign: TextAlign.center),
              TextButton(onPressed: load, child: const Text('�ٽ� �õ�')),
              TextButton(
                onPressed: () => context.go(AppRoutes.login),
                child: const Text('�α����ϱ�'),
              ),
            ],
          ),
        ),
      );
    }
    final data = room!;
    return RoomScreen(
      key: ValueKey('${data.id}-$generation'),
      furniture: data.furniture,
      initialVisibility: data.visibility,
      moodHashtags: data.tags
          .map(
            (tag) => RoomMoodHashtag(
              categoryId:
                  data.furniture
                      .where((e) => e.typeId == tag['furnitureTypeId'])
                      .firstOrNull
                      ?.code ??
                  '',
              text: tag['name'] as String,
            ),
          )
          .toList(),
      onVisibilityChanged: saveVisibility,
      onFurnitureTap: (code) {
        final furniture = data.furniture.firstWhere(
          (e) => e.code == code && !e.hidden,
        );
        open(
          Uri(
            path: AppRoutes.items,
            queryParameters: {'furnitureTypeId': '${furniture.typeId}'},
          ).toString(),
        );
      },
      onLogout: logout,
      onProfile: () => open(AppRoutes.mypage),
      onGuide: showGuide,
      onRecord: () => open(AppRoutes.itemCreate),
      onGuestbook: () => open(AppRoutes.guestbook),
      onShop: () => open(AppRoutes.shop),
      onMood: () => open(AppRoutes.calendar),
      onShare: () => showShareTasteDialog(
        context,
        tags: data.tags.map((tag) => tag['name'] as String).toList(),
        nickname: nickname,
      ),
    );
  }
}
