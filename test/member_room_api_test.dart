import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:toggle_me/features/onboarding/presentation/member_setup_screen.dart';
import 'package:toggle_me/features/onboarding/data/room_onboarding_draft.dart';
import 'package:toggle_me/core/network/member_api.dart';
import 'package:toggle_me/features/auth/data/token_storage.dart';
import 'package:toggle_me/features/feed/data/feed_repository.dart';
import 'package:toggle_me/core/network/api_client.dart';
import 'package:toggle_me/features/room/data/room_repository.dart';
import 'package:toggle_me/features/room/domain/room_visibility.dart';

class MemoryTokens extends TokenStorage {
  String? access = 'expired';
  String? refresh = 'refresh-old';
  @override
  Future<String?> getAccessToken() async => access;
  @override
  Future<String?> getRefreshToken() async => refresh;
  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    access = accessToken;
    refresh = refreshToken;
  }

  @override
  Future<void> clearTokens() async {
    access = null;
    refresh = null;
  }
}

class Adapter implements HttpClientAdapter {
  Adapter(this.handle);
  final FutureOr<(int, Object?)> Function(RequestOptions) handle;
  final requests = <RequestOptions>[];
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? stream,
    Future<void>? cancel,
  ) async {
    requests.add(options);
    final (status, body) = await handle(options);
    return ResponseBody.fromString(
      status == 204 ? '' : jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

MemberApi client(Adapter adapter, MemoryTokens tokens) => MemberApi(
  dio: Dio(BaseOptions(baseUrl: 'https://example.test'))
    ..httpClientAdapter = adapter,
  tokens: tokens,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final failVisibility in [false, true]) {
    testWidgets(
      'setup ${failVisibility ? 'retains screen on failed save' : 'saves selected visibility before entering room'}',
      (tester) async {
        FlutterSecureStorage.setMockInitialValues({
          'pendingRoomVisibility': 'SOCIAL_OFF',
        });
        roomOnboardingDraft.reset();
        final save = Completer<(int, Object?)>();
        var creates = 0;
        final adapter = Adapter((o) async {
          switch (o.path) {
            case '/api/v1/members/me':
              return (200, {'profileCompleted': true});
            case '/api/v1/furniture-types':
              return (
                200,
                [
                  {'id': 11, 'code': 'mirror', 'name': '거울'},
                  {'id': 22, 'code': 'fridge', 'name': '냉장고'},
                ],
              );
            case '/api/v1/furniture-types/11/variants':
              return (
                200,
                [
                  {'id': 101},
                ],
              );
            case '/api/v1/furniture-types/22/variants':
              return (
                200,
                [
                  {'id': 202},
                ],
              );
            case '/api/v1/members/onboarding':
              creates++;
              expect(o.data, {
                'furnitureVariantIds': [101, 202],
                'visibility': 'SOCIAL_OFF',
              });
              return save.future;
            case '/api/v1/rooms/83/visibility':
              expect(o.data, {'visibility': 'SOCIAL_OFF'});
              return failVisibility
                  ? (
                      500,
                      {'code': 'INTERNAL_SERVER_ERROR', 'message': '설정 저장 실패'},
                    )
                  : (200, {'visibility': 'SOCIAL_OFF'});
          }
          return (404, {'code': 'RESOURCE_NOT_FOUND'});
        });
        final router = GoRouter(
          initialLocation: '/setup',
          routes: [
            GoRoute(
              path: '/setup',
              builder: (_, _) => MemberSetupScreen(
                repository: RoomRepository(client(adapter, MemoryTokens())),
              ),
            ),
            GoRoute(
              path: '/room',
              builder: (_, _) => const Scaffold(body: Text('saved-room')),
            ),
          ],
        );
        addTearDown(router.dispose);
        await tester.pumpWidget(MaterialApp.router(routerConfig: router));
        await tester.pumpAndSettle();
        await tester.tap(find.text('완료'));
        await tester.pumpAndSettle();
        expect(find.text('저장 중…'), findsOneWidget);
        await tester.tap(find.byType(FilledButton));
        await tester.pump();
        expect(creates, 1);
        save.complete((200, {'roomId': 83}));
        await tester.pumpAndSettle();
        expect(
          find.text('saved-room'),
          failVisibility ? findsNothing : findsOneWidget,
        );
        if (failVisibility) {
          expect(find.text('설정 저장 실패'), findsOneWidget);
          expect(find.text('완료'), findsOneWidget);
        }
      },
    );
  }
  test(
    'concurrent 401 responses rotate once and replay with the new token',
    () async {
      var rotations = 0;
      final tokens = MemoryTokens();
      final adapter = Adapter((o) async {
        if (o.path.endsWith('/refresh')) {
          rotations++;
          await Future<void>.delayed(const Duration(milliseconds: 20));
          return (200, {'accessToken': 'fresh', 'refreshToken': 'refresh-new'});
        }
        if (o.headers['Authorization'] == 'Bearer expired') {
          return (401, {'code': 'UNAUTHORIZED'});
        }
        return (200, []);
      });
      final api = client(adapter, tokens);
      await Future.wait([api.request('GET', '/a'), api.request('GET', '/b')]);
      expect(rotations, 1);
      expect(tokens.refresh, 'refresh-new');
      expect(
        adapter.requests
            .where((o) => o.headers['Authorization'] == 'Bearer fresh')
            .length,
        2,
      );
    },
  );

  test('invalid refresh clears the session and does not loop', () async {
    final tokens = MemoryTokens();
    final adapter = Adapter(
      (o) => (
        401,
        {
          'code': o.path.endsWith('/refresh')
              ? 'INVALID_REFRESH_TOKEN'
              : 'UNAUTHORIZED',
          'message': '다시 로그인',
        },
      ),
    );
    await expectLater(
      client(adapter, tokens).request('GET', '/a'),
      throwsA(isA<MemberApiException>()),
    );
    expect(tokens.access, isNull);
    expect(adapter.requests.length, 2);
  });

  test(
    'temporary refresh failure retains stored credentials for retry',
    () async {
      final tokens = MemoryTokens();
      final adapter = Adapter(
        (o) => o.path.endsWith('/refresh')
            ? (503, {'code': 'INTERNAL_SERVER_ERROR'})
            : (401, {'code': 'UNAUTHORIZED'}),
      );
      await expectLater(
        client(adapter, tokens).request('GET', '/a'),
        throwsA(isA<MemberApiException>()),
      );
      expect(tokens.refresh, 'refresh-old');
    },
  );

  test(
    'logout after refresh sends the rotated refresh token then clears storage',
    () async {
      final tokens = MemoryTokens();
      final adapter = Adapter((o) {
        if (o.path.endsWith('/refresh')) {
          return (200, {'accessToken': 'fresh', 'refreshToken': 'refresh-new'});
        }
        if (o.headers['Authorization'] == 'Bearer expired') {
          return (401, {'code': 'UNAUTHORIZED'});
        }
        expect(o.data['refreshToken'], 'refresh-new');
        return (204, null);
      });
      await client(adapter, tokens).logout();
      expect(tokens.refresh, isNull);
    },
  );

  test('an in-flight refresh never restores a replaced session', () async {
    final tokens = MemoryTokens();
    final started = Completer<void>();
    final release = Completer<void>();
    final adapter = Adapter((o) async {
      if (o.path.endsWith('/refresh')) {
        started.complete();
        await release.future;
        return (200, {'accessToken': 'stale', 'refreshToken': 'stale-refresh'});
      }
      return (401, {'code': 'UNAUTHORIZED'});
    });
    final request = client(adapter, tokens).request('GET', '/a');
    final expectation = expectLater(
      request,
      throwsA(isA<MemberApiException>()),
    );
    await started.future;
    tokens.access = 'other-account';
    tokens.refresh = 'other-refresh';
    release.complete();
    await expectation;
    expect(tokens.access, 'other-account');
  });

  test('room uses returned room and floor IDs, preserves hidden furniture and empty tags', () async {
    final tokens = MemoryTokens();
    final adapter = Adapter(
      (o) => switch (o.path) {
        '/api/v1/rooms' => (
          200,
          [
            {'id': 83, 'visibility': 'SOCIAL_OFF'},
          ],
        ),
        '/api/v1/rooms/83/floors' => (
          200,
          [
            {'id': 91, 'floorNumber': 1},
          ],
        ),
        '/api/v1/rooms/83/floors/91/furniture' => (
          200,
          [
            {
              'furnitureTypeId': 12,
              'furnitureTypeCode': 'fridge',
              'hidden': true,
              'objectNodeName': 'body',
              'position': {'x': 1, 'y': 2, 'z': 3},
              'scale': {'x': 1, 'y': 1, 'z': 1},
            },
          ],
        ),
        '/api/v1/rooms/83/tags' => (200, []),
        _ => (404, {'code': 'RESOURCE_NOT_FOUND'}),
      },
    );
    final room = (await RoomRepository(client(adapter, tokens)).load())!;
    expect(room.id, 83);
    expect(room.visibility, RoomVisibility.socialOff);
    expect(room.furniture.single.hidden, isTrue);
    expect(room.tags, isEmpty);
    expect(room.furniture.single.scene['position'], {'x': 1, 'y': 2, 'z': 3});
  });

  test(
    'missing room remains empty rather than displaying a demo room',
    () async {
      final adapter = Adapter((o) => (200, []));
      expect(
        await RoomRepository(client(adapter, MemoryTokens())).load(),
        isNull,
      );
      expect(adapter.requests.length, 1);
    },
  );

  test('onboarding posts variant IDs and explicit visibility; failed toggle propagates', () async {
    final adapter = Adapter((o) {
      if (o.method == 'POST') {
        expect(o.data, {
          'furnitureVariantIds': [107, 209],
          'visibility': 'SOCIAL_OFF',
        });
        return (200, {'roomId': 83});
      }
      return (
        500,
        {'code': 'INTERNAL_SERVER_ERROR', 'message': '저장 실패', 'errors': []},
      );
    });
    final repo = RoomRepository(client(adapter, MemoryTokens()));
    expect(await repo.create([107, 209], RoomVisibility.socialOff), 83);
    await expectLater(
      repo.visibility(83, RoomVisibility.socialOn),
      throwsA(isA<MemberApiException>()),
    );
  });

  test('furniture feed requests its actual type ID, while full feed stays separate', () async {
    final adapter = Adapter((o) => (200, []));
    final api = ApiClient();
    api.dio.options.baseUrl = 'https://example.test';
    api.dio.httpClientAdapter = adapter;
    final repo = FeedRepository(api);
    await repo.getAllItems(furnitureTypeId: 42, sort: 'OLDEST', cursor: 11);
    expect(adapter.requests.last.path, '/api/v1/items/feed');
    expect(adapter.requests.last.uri.queryParameters, {
      'sort': 'OLDEST',
      'furnitureTypeId': '42',
      'cursor': '11',
    });
    await repo.getAllItems();
    expect(adapter.requests.last.path, '/api/v1/items/all');
  });
}
