import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:toggle_me/core/network/api_client.dart';
import 'package:toggle_me/core/network/image_upload_service.dart';
import 'package:toggle_me/core/network/member_api.dart';
import 'package:toggle_me/core/widgets/room_navigation.dart';
import 'package:toggle_me/features/auth/data/token_storage.dart';
import 'package:toggle_me/features/item/data/item_recommendation_storage.dart';
import 'package:toggle_me/features/item/data/item_repository.dart';
import 'package:toggle_me/features/item/model/item_model.dart';
import 'package:toggle_me/features/item/presentation/providers/item_upload_provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:toggle_me/features/room/data/room_repository.dart';
import 'package:toggle_me/features/onboarding/presentation/onboarding_screen.dart';
import 'package:toggle_me/features/onboarding/data/room_onboarding_draft.dart';

class _Tokens extends TokenStorage {
  String? access = 'old';
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

class _Adapter implements HttpClientAdapter {
  _Adapter(this.reply);
  final FutureOr<(int, Object?)> Function(RequestOptions) reply;
  final requests = <RequestOptions>[];
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? stream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final (status, body) = await reply(options);
    return ResponseBody.fromString(
      body == null ? '' : jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Dio _dio(_Adapter adapter) =>
    Dio(BaseOptions(baseUrl: 'https://api.example.test'))
      ..httpClientAdapter = adapter;

class _ItemRepository extends ItemRepository {
  _ItemRepository() : super(ApiClient());
  int creates = 0;
  @override
  Future<String> uploadImage(Uint8List imageBytes) async => 'image.jpg';
  @override
  Future<String> requestAnalysis(String imageKey, int furnitureTypeId) async =>
      '1';
  @override
  Future<ImageAnalysisStatus> pollAnalysis(
    String analysisId, {
    bool Function()? shouldContinue,
  }) async =>
      const ImageAnalysisStatus(status: 'COMPLETED', searchQueries: ['shirt']);
  @override
  Future<int> registerItem({
    required String imageKey,
    required int furnitureTypeId,
    required String memo,
    required String visibility,
    required List<String> tags,
  }) async {
    creates++;
    return 42;
  }
}

class _UnavailableStorage extends ItemRecommendationStorage {
  @override
  Future<void> saveSearchQueries(int itemId, List<String> queries) async =>
      throw StateError('Browser storage unavailable');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('session restore waits without flashing onboarding before room', (
    tester,
  ) async {
    FlutterSecureStorage.setMockInitialValues({});
    roomOnboardingDraft.reset();
    final reply = Completer<(int, Object?)>();
    final repo = RoomRepository(
      MemberApi(dio: _dio(_Adapter((_) => reply.future)), tokens: _Tokens()),
    );
    final router = GoRouter(
      initialLocation: '/onboarding',
      routes: [
        GoRoute(
          path: '/onboarding',
          builder: (_, _) =>
              OnboardingScreen(resumeSession: true, repository: repo),
        ),
        GoRoute(path: '/room', builder: (_, _) => const Text('restored room')),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('비회원으로 시작하기'), findsNothing);
    reply.complete((200, {'onboardingStep': 'DONE'}));
    await tester.pumpAndSettle();
    expect(find.text('restored room'), findsOneWidget);
    expect(find.text('비회원으로 시작하기'), findsNothing);
  });

  test(
    'old account requests are not replayed with a new account token',
    () async {
      final tokens = _Tokens();
      final adapter = _Adapter((_) async {
        tokens.access = 'another-account';
        tokens.refresh = 'another-refresh';
        return (401, {'code': 'UNAUTHORIZED'});
      });
      final session = MemberApi(dio: _dio(adapter), tokens: tokens);
      final api = ApiClient(
        dio: _dio(adapter),
        readAccessToken: session.accessToken,
        refreshAccessToken: session.refreshAccessToken,
      );
      await expectLater(
        api.dio.patch<dynamic>('/api/v1/items/42', data: {'memo': 'old'}),
        throwsA(isA<DioException>()),
      );
      expect(adapter.requests.length, 1);
      expect(tokens.access, 'another-account');
    },
  );

  test(
    'feed/detail/upload share one refresh for concurrent expired tokens',
    () async {
      final tokens = _Tokens();
      var rotations = 0;
      final adapter = _Adapter((options) async {
        if (options.path.endsWith('/refresh')) {
          rotations++;
          await Future<void>.delayed(const Duration(milliseconds: 10));
          return (200, {'accessToken': 'new', 'refreshToken': 'refresh-new'});
        }
        return options.headers['Authorization'] == 'Bearer old'
            ? (401, {'code': 'UNAUTHORIZED'})
            : (200, <String, dynamic>{});
      });
      final session = MemberApi(dio: _dio(adapter), tokens: tokens);
      final api = ApiClient(
        dio: _dio(adapter),
        readAccessToken: session.accessToken,
        refreshAccessToken: session.refreshAccessToken,
      );
      await Future.wait([
        api.dio.get<dynamic>('/api/v1/items/feed'),
        api.dio.get<dynamic>('/api/v1/items/42'),
        session.request('GET', '/api/v1/rooms'),
      ]);
      expect(rotations, 1);
      expect(tokens.access, 'new');
    },
  );

  test('refresh-only session can use item APIs after a reload', () async {
    final tokens = _Tokens()..access = null;
    final adapter = _Adapter(
      (options) => options.path.endsWith('/refresh')
          ? (200, {'accessToken': 'new', 'refreshToken': 'refresh-new'})
          : (200, <String, dynamic>{}),
    );
    final session = MemberApi(dio: _dio(adapter), tokens: tokens);
    final api = ApiClient(
      dio: _dio(adapter),
      readAccessToken: session.accessToken,
      refreshAccessToken: session.refreshAccessToken,
    );
    await api.dio.get<dynamic>('/api/v1/items/42');
    expect(adapter.requests.last.headers['Authorization'], 'Bearer new');
  });

  test('a second 401 does not refresh or replay indefinitely', () async {
    final tokens = _Tokens();
    var rotations = 0;
    var requests = 0;
    final adapter = _Adapter((options) {
      if (options.path.endsWith('/refresh')) {
        rotations++;
        return (200, {'accessToken': 'new', 'refreshToken': 'refresh-new'});
      }
      requests++;
      return (401, {'code': 'UNAUTHORIZED'});
    });
    final session = MemberApi(dio: _dio(adapter), tokens: tokens);
    final api = ApiClient(
      dio: _dio(adapter),
      readAccessToken: session.accessToken,
      refreshAccessToken: session.refreshAccessToken,
    );
    await expectLater(
      api.dio.get<dynamic>('/api/v1/items/42'),
      throwsA(isA<DioException>()),
    );
    expect(rotations, 1);
    expect(requests, 2);
  });

  test('S3 receives JPEG bytes with no API bearer token', () async {
    final presign = _Adapter(
      (options) => (
        200,
        {
          'uploadUrl': 'https://bucket.example.test/image.jpg',
          'imageKey': 'image.jpg',
          'headers': {'Content-Type': 'image/jpeg'},
          'expiresAt': '2030-01-01T00:00:00Z',
        },
      ),
    );
    final s3 = _Adapter((options) => (200, null));
    final service = ImageUploadService(
      ApiClient(dio: _dio(presign), accessToken: 'private-token'),
      uploadClientFactory: () => _dio(s3),
    );
    final image = img.Image(width: 12, height: 24);
    expect(
      await service.upload(Uint8List.fromList(img.encodePng(image))),
      'image.jpg',
    );
    final bytes = s3.requests.single.data as Uint8List;
    expect(bytes.take(2), [0xff, 0xd8]);
    expect(img.decodeImage(bytes)!.width, 12); // never enlarge small photos
    expect(s3.requests.single.headers['Authorization'], isNull);
    expect(
      (presign.requests.single.data as Map)['contentLength'],
      bytes.length,
    );
  });

  test('unsupported photos fail before requesting a presigned URL', () async {
    final adapter = _Adapter(
      (_) => throw StateError('Unexpected network request'),
    );
    final service = ImageUploadService(ApiClient(dio: _dio(adapter)));
    await expectLater(
      service.upload(Uint8List.fromList([1, 2, 3])),
      throwsA(isA<FormatException>()),
    );
    expect(adapter.requests, isEmpty);
  });

  test(
    'server save remains successful when browser recommendation storage fails',
    () async {
      final repo = _ItemRepository();
      final container = ProviderContainer(
        overrides: [
          itemRepositoryProvider.overrideWithValue(repo),
          itemRecommendationStorageProvider.overrideWithValue(
            _UnavailableStorage(),
          ),
        ],
      );
      final subscription = container.listen(itemUploadProvider, (_, _) {});
      addTearDown(() {
        subscription.close();
        container.dispose();
      });
      final notifier = container.read(itemUploadProvider.notifier);
      await notifier.setImage(
        XFile.fromData(Uint8List.fromList([1])),
        furnitureTypeId: 1,
      );
      expect(
        await notifier.submit(
          furnitureTypeId: 1,
          memo: '',
          visibility: 'PRIVATE',
        ),
        isTrue,
      );
      expect(repo.creates, 1);
      expect(container.read(itemUploadProvider).selectedImage, isNull);
    },
  );

  testWidgets('direct browser route can return to room without a pop target', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/direct',
      routes: [
        GoRoute(
          path: '/direct',
          builder: (context, _) => Scaffold(
            body: TextButton(
              onPressed: () => popOrGoRoom(context),
              child: const Text('back'),
            ),
          ),
        ),
        GoRoute(path: '/room', builder: (_, _) => const Text('room home')),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.tap(find.text('back'));
    await tester.pumpAndSettle();
    expect(find.text('room home'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
