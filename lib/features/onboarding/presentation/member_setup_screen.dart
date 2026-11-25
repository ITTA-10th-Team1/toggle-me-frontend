import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/network/member_api.dart';
import '../../../core/widgets/app_notice.dart';
import '../../../core/widgets/room_mode_toggle.dart';
import '../../room/data/room_repository.dart';
import '../../room/domain/room_visibility.dart';
import '../data/room_onboarding_draft.dart';

/// Profile and first-room submission. The walkthrough can be added separately.
class MemberSetupScreen extends StatefulWidget {
  const MemberSetupScreen({super.key, this.repository});
  final RoomRepository? repository;
  @override
  State<MemberSetupScreen> createState() => _MemberSetupScreenState();
}

class _MemberSetupScreenState extends State<MemberSetupScreen> {
  late final repo = widget.repository ?? RoomRepository(memberApi);
  final nickname = TextEditingController();
  final handle = TextEditingController();
  final selected = <int, int>{};
  List<Map<String, dynamic>> types = [];
  bool loading = true, saving = false, needsProfile = true;
  String? error;
  RoomVisibility visibility = roomOnboardingDraft.visibility;

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void dispose() {
    nickname.dispose();
    handle.dispose();
    super.dispose();
  }

  Future<void> load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      await roomOnboardingDraft.restore();
      visibility = roomOnboardingDraft.visibility;
      final me = await repo.me();
      final all = await repo.list('/api/v1/furniture-types');
      final supported = all
          .where((e) => e['code'] == 'mirror' || e['code'] == 'fridge')
          .toList();
      final choices = <int, int>{};
      for (final type in supported) {
        final variants = await repo.list(
          '/api/v1/furniture-types/${type['id']}/variants',
        );
        if (variants.length != 1) {
          throw const MemberApiException(
            'DESIGN_SELECTION',
            '�⺻ ���� �������� Ȯ������ ���߾��.',
          );
        }
        choices[(type['id'] as num).toInt()] = (variants.single['id'] as num)
            .toInt();
      }
      if (supported.length != 2) {
        throw const MemberApiException(
          'FURNITURE_MISSING',
          '�ſ����� ������ Ȯ������ ���߾��.',
        );
      }
      if (!mounted) return;
      setState(() {
        needsProfile = me['profileCompleted'] != true;
        nickname.text = me['nickname'] as String? ?? '';
        types = supported;
        selected
          ..clear()
          ..addAll(choices);
        loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          error = '$e';
          loading = false;
        });
      }
    }
  }

  Future<void> submit() async {
    if (saving) return;
    setState(() => saving = true);
    try {
      if (needsProfile) {
        final available = await repo.api.request(
          'GET',
          Uri(
            path: '/api/v1/members/handle-availability',
            queryParameters: {'handle': handle.text.trim()},
          ).toString(),
        );
        if (available['available'] != true) {
          final reason = available['reason'];
          throw MemberApiException('HANDLE_UNAVAILABLE', switch (reason) {
            'DUPLICATED' => '�̹� ��� ���� ID����.',
            'RESERVED' => '����� �� ���� ID����.',
            _ => 'ID�� ���� �ҹ��ڡ����ڡ����� 3~20�ڷ� �Է��� �ּ���.',
          });
        }
        await repo.api.request(
          'PATCH',
          '/api/v1/members/me/profile',
          data: {
            'nickname': nickname.text.trim(),
            'handle': handle.text.trim(),
          },
        );
        if (!mounted) return;
        setState(() => needsProfile = false);
      }
      final id = await repo.create(selected.values.toList(), visibility);
      // Existing/temporarily auto-created rooms ignore onboarding visibility.
      // Explicitly save the user's current choice after a successful submission.
      await repo.visibility(id, visibility);
      await roomOnboardingDraft.clear();
      if (mounted) context.go(AppRoutes.room);
    } catch (e) {
      if (mounted) showAppNotice(context, '$e');
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('�� �� �����ϱ�')),
    body: loading
        ? const Center(child: CircularProgressIndicator())
        : error != null
        ? Center(
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
          )
        : SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                if (needsProfile) ...[
                  TextField(
                    controller: nickname,
                    enabled: !saving,
                    maxLength: 30,
                    decoration: const InputDecoration(labelText: '�г���'),
                  ),
                  TextField(
                    controller: handle,
                    enabled: !saving,
                    maxLength: 20,
                    decoration: const InputDecoration(
                      labelText: '���� ID',
                      helperText: '���� �ҹ��ڡ����ڡ����� 3~20��',
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                const Text('�ſ�� ������� ���� �����ؿ�.'),
                for (final type in types)
                  ListTile(
                    leading: const Icon(Icons.check_circle_outline),
                    title: Text(type['name'] as String),
                  ),
                Row(
                  children: [
                    const Expanded(child: Text('�� ����')),
                    RoomModeToggle(
                      isOn: visibility.isPublic,
                      onChanged: saving
                          ? null
                          : (on) => setState(() {
                              visibility = on
                                  ? RoomVisibility.socialOn
                                  : RoomVisibility.socialOff;
                              roomOnboardingDraft.visibility = visibility;
                            }),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: saving ? null : submit,
                  child: Text(saving ? '���� �ߡ�' : '�Ϸ�'),
                ),
              ],
            ),
          ),
  );
}
