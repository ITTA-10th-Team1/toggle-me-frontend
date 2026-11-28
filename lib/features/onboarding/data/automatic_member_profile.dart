import 'dart:math';

import '../../../core/network/member_api.dart';

/// Completes the existing profile API without asking for an input screen.
class AutomaticMemberProfile {
  AutomaticMemberProfile(this.api);
  final MemberApiSession api;

  Future<void> save(String nickname) async {
    const alphabet = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random.secure();
    for (var attempt = 0; attempt < 5; attempt++) {
      await api.ensureActive();
      // user_ is reserved by the server. tm_ + 12 characters fits its 3–20 rule.
      final handle =
          'tm_${List.generate(12, (_) => alphabet[random.nextInt(alphabet.length)]).join()}';
      final available = await api.request(
        'GET',
        Uri(
          path: '/api/v1/members/handle-availability',
          queryParameters: {'handle': handle},
        ).toString(),
      );
      await api.ensureActive();
      if (available['available'] != true) {
        if (available['reason'] == 'DUPLICATED') continue;
        throw const MemberApiException(
          'HANDLE_UNAVAILABLE',
          '기본 프로필을 준비하지 못했어요. 다시 시도해 주세요.',
        );
      }
      try {
        await api.request(
          'PATCH',
          '/api/v1/members/me/profile',
          data: {
            'handle': handle,
            'nickname': nickname.trim().isEmpty ? '토글러' : nickname.trim(),
          },
        );
        await api.ensureActive();
        return;
      } on MemberApiException catch (e) {
        if (e.code != 'HANDLE_ALREADY_EXISTS') rethrow;
      }
    }
    throw const MemberApiException(
      'HANDLE_UNAVAILABLE',
      '고유 ID를 준비하지 못했어요. 다시 시도해 주세요.',
    );
  }
}
