import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toggle_me/core/network/member_api.dart';
import 'package:toggle_me/features/auth/data/token_storage.dart';
import 'package:toggle_me/features/onboarding/data/automatic_member_profile.dart';
import 'package:toggle_me/features/room/data/room_repository.dart';
import 'package:toggle_me/features/room/domain/room_visibility.dart';

class _Tokens extends TokenStorage {
  String? access = 'account-a', refresh = 'refresh-a';
  bool switchOnNextRefreshRead = false;
  Future<void> Function()? afterSave;
  @override
  Future<String?> getAccessToken() async => access;
  @override
  Future<String?> getRefreshToken() async {
    final snapshot = refresh;
    if (switchOnNextRefreshRead) {
      switchOnNextRefreshRead = false;
      access = 'account-b';
      refresh = 'refresh-b';
    }
    return snapshot;
  }

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    access = accessToken;
    refresh = refreshToken;
    await afterSave?.call();
  }

  @override
  Future<void> clearTokens() async {
    access = null;
    refresh = null;
  }
}

class _Adapter implements HttpClientAdapter {
  _Adapter(this.reply);
  final FutureOr<(int, Object)> Function(RequestOptions) reply;
  final requests = <RequestOptions>[];
  @override
  Future<ResponseBody> fetch(
    RequestOptions o,
    Stream<Uint8List>? stream,
    Future<void>? cancel,
  ) async {
    requests.add(o);
    final (status, body) = await reply(o);
    return ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

MemberApi _client(_Tokens tokens, _Adapter adapter) => MemberApi(
  tokens: tokens,
  dio: Dio(BaseOptions(baseUrl: 'https://example.test'))
    ..httpClientAdapter = adapter,
);

void main() {
  test(
    'a switch during the last storage read never sends B Authorization',
    () async {
      final tokens = _Tokens();
      final adapter = _Adapter((o) => (200, {'profileCompleted': true}));
      final session = await _client(tokens, adapter).captureSession();
      tokens.switchOnNextRefreshRead = true;
      await expectLater(
        session.request(
          'PATCH',
          '/api/v1/members/me/profile',
          data: {'nickname': 'A'},
        ),
        throwsA(isA<MemberApiException>()),
      );
      expect(
        adapter.requests.single.headers['Authorization'],
        'Bearer account-a',
      );
      expect(
        adapter.requests.any(
          (r) => r.headers['Authorization'] == 'Bearer account-b',
        ),
        isFalse,
      );
    },
  );
  for (final phase in ['availability', 'profile', 'both']) {
    test(
      'automatic profile continues through same-account refresh: $phase',
      () async {
        final tokens = _Tokens();
        var rotations = 0, availability = 0, patches = 0;
        final rejected = <String>{};
        final adapter = _Adapter((o) {
          if (o.path.endsWith('/refresh')) {
            rotations++;
            return (
              200,
              {'accessToken': 'a-$rotations', 'refreshToken': 'r-$rotations'},
            );
          }
          final step = o.method == 'PATCH' ? 'profile' : 'availability';
          if ((phase == 'both' || phase == step) && rejected.add(step)) {
            return (401, {'code': 'UNAUTHORIZED'});
          }
          expect(o.headers['Authorization'], 'Bearer ${tokens.access}');
          if (step == 'profile') {
            patches++;
            return (200, {'profileCompleted': true});
          }
          availability++;
          return (200, {'available': true});
        });
        final session = await _client(tokens, adapter).captureSession();
        await AutomaticMemberProfile(session).save('nickname');
        expect(availability, 1);
        expect(patches, 1);
        expect(rotations, phase == 'both' ? 2 : 1);
      },
    );
  }
  test(
    'a captured session follows multiple verified rotations from other calls',
    () async {
      final tokens = _Tokens();
      var rotations = 0;
      final adapter = _Adapter(
        (o) => o.path.endsWith('/refresh')
            ? (
                200,
                {
                  'accessToken': 'a-${++rotations}',
                  'refreshToken': 'r-$rotations',
                },
              )
            : (200, {'available': true}),
      );
      final api = _client(tokens, adapter);
      final session = await api.captureSession();
      await api.refreshAccessToken('account-a');
      await api.refreshAccessToken('a-1');
      await session.request('GET', '/check');
      expect(adapter.requests.last.headers['Authorization'], 'Bearer a-2');
    },
  );
  test('session stays usable before and after a concurrent rotation', () async {
    final tokens = _Tokens();
    final started = Completer<void>(), finish = Completer<void>();
    final adapter = _Adapter((o) async {
      if (o.path.endsWith('/refresh')) {
        started.complete();
        await finish.future;
        return (200, {'accessToken': 'a-new', 'refreshToken': 'r-new'});
      }
      return (200, {'available': true});
    });
    final api = _client(tokens, adapter);
    final session = await api.captureSession();
    final rotation = api.refreshAccessToken('account-a');
    await started.future;
    // The ordinary operation can run while the old token is still valid.
    await session.request('GET', '/before');
    finish.complete();
    await rotation;
    await session.request('GET', '/after');
    expect(adapter.requests.last.headers['Authorization'], 'Bearer a-new');
  });
  test(
    'wait for the validated rotation while token storage has advanced',
    () async {
      final tokens = _Tokens();
      final saved = Completer<void>(), resume = Completer<void>();
      tokens.afterSave = () {
        saved.complete();
        return resume.future;
      };
      final adapter = _Adapter(
        (o) => o.path.endsWith('/refresh')
            ? (200, {'accessToken': 'a-new', 'refreshToken': 'r-new'})
            : (200, {}),
      );
      final api = _client(tokens, adapter);
      final session = await api.captureSession();
      final rotation = api.refreshAccessToken('account-a');
      await saved.future;
      final request = session.request('GET', '/after-refresh');
      await Future<void>.delayed(Duration.zero);
      expect(adapter.requests.length, 1);
      resume.complete();
      await rotation;
      await request;
      expect(adapter.requests.last.headers['Authorization'], 'Bearer a-new');
    },
  );
  test(
    'a slow 401 retries with the latest verified rotation of its own session',
    () async {
      final tokens = _Tokens();
      final pending = Completer<(int, Object)>(), started = Completer<void>();
      var rotations = 0, calls = 0;
      final adapter = _Adapter((o) {
        if (o.path.endsWith('/refresh')) {
          return (
            200,
            {'accessToken': 'a-${++rotations}', 'refreshToken': 'r-$rotations'},
          );
        }
        if (++calls == 1) {
          started.complete();
          return pending.future;
        }
        return (200, {});
      });
      final api = _client(tokens, adapter);
      final session = await api.captureSession();
      final request = session.request('GET', '/slow');
      await started.future;
      await api.refreshAccessToken('account-a');
      await api.refreshAccessToken('a-1');
      pending.complete((401, {'code': 'UNAUTHORIZED'}));
      await request;
      expect(rotations, 2);
      expect(adapter.requests.last.headers['Authorization'], 'Bearer a-2');
    },
  );
  for (final reason in ['logout', 'replacement', 'disposed']) {
    test('captured operation stops before sending after $reason', () async {
      final tokens = _Tokens();
      final adapter = _Adapter((o) => (200, {}));
      var active = true;
      final api = _client(tokens, adapter);
      final session = await api.captureSession(isActive: () => active);
      if (reason == 'logout') await tokens.clearTokens();
      if (reason == 'replacement') {
        tokens.access = 'account-b';
        tokens.refresh = 'refresh-b';
      }
      if (reason == 'disposed') active = false;
      await expectLater(
        session.request('PATCH', '/profile'),
        throwsA(isA<MemberApiException>()),
      );
      expect(adapter.requests, isEmpty);
    });
  }
  test(
    'account change during onboarding stops subsequent visibility save',
    () async {
      final tokens = _Tokens();
      final adapter = _Adapter((o) {
        tokens.access = 'account-b';
        tokens.refresh = 'refresh-b';
        return (200, {'roomId': 83});
      });
      final api = _client(tokens, adapter);
      final repo = RoomRepository(api);
      final session = await api.captureSession();
      await expectLater(
        repo.create([1, 2], RoomVisibility.socialOn, session: session),
        throwsA(isA<MemberApiException>()),
      );
      await expectLater(
        repo.visibility(83, RoomVisibility.socialOn, session: session),
        throwsA(isA<MemberApiException>()),
      );
      expect(adapter.requests.length, 1);
      expect(
        adapter.requests.single.headers['Authorization'],
        'Bearer account-a',
      );
    },
  );
  test(
    'profile operation never proceeds after switching at availability response',
    () async {
      final tokens = _Tokens();
      final adapter = _Adapter((o) {
        tokens.access = 'account-b';
        tokens.refresh = 'refresh-b';
        return (200, {'available': true});
      });
      final session = await _client(tokens, adapter).captureSession();
      await expectLater(
        AutomaticMemberProfile(session).save('A'),
        throwsA(isA<MemberApiException>()),
      );
      expect(adapter.requests.length, 1);
      expect(adapter.requests.single.method, 'GET');
    },
  );
}
