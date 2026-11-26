import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toggle_me/app/theme/app_theme.dart';
import 'package:toggle_me/features/auth/data/token_storage.dart';
import 'package:toggle_me/features/guide/data/guide_progress_store.dart';
import 'package:toggle_me/features/guide/presentation/guide_book_icon.dart';
import 'package:toggle_me/features/guide/presentation/usage_guide_screen.dart';

Future<void> openGuide(
  WidgetTester tester, {
  Future<void> Function()? complete,
  String nickname = '테스터',
  double textScale = 1,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.lightTheme,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => showUsageGuide(context, onComplete: complete),
            child: const Text('가이드 열기'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('가이드 열기'));
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    await (FontLoader(
      'Pretendard',
    )..addFont(rootBundle.load('assets/fonts/PretendardVariable.ttf'))).load();
  });

  test('completion belongs to each account and survives logout', () async {
    FlutterSecureStorage.setMockInitialValues({
      'accessToken': 'a',
      'refreshToken': 'r',
    });
    final progress = GuideProgressStore();
    expect(await progress.hasCompleted(11), isFalse);
    await progress.complete(11);
    await TokenStorage().clearTokens();
    expect(await GuideProgressStore().hasCompleted(11), isTrue);
    expect(await progress.hasCompleted(22), isFalse);
  });

  testWidgets('five pages support previous, then finish once', (tester) async {
    var completed = 0;
    await openGuide(tester, complete: () async => completed++);
    expect(find.byTooltip('이전'), findsNothing);
    await tester.tap(find.text('다음'));
    await tester.pumpAndSettle();
    expect(find.text('가구를 모아 나만의 방을 꾸며보세요'), findsOneWidget);
    await tester.tap(find.byTooltip('이전'));
    await tester.pumpAndSettle();
    expect(find.text('좋아하는 것들로 채우는 나만의 공간'), findsOneWidget);
    for (var i = 0; i < 4; i++) {
      await tester.tap(find.text('다음'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
    expect(completed, 0);
    await tester.tap(find.text('내 방으로'));
    await tester.pumpAndSettle();
    expect(completed, 1);
    expect(find.text('가이드 열기'), findsOneWidget);
  });

  testWidgets('leaving an incomplete guide does not mark it completed', (
    tester,
  ) async {
    var completed = false;
    await openGuide(tester, complete: () async => completed = true);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(completed, isFalse);
  });

  testWidgets('completion failure stays on final page and can retry', (
    tester,
  ) async {
    var attempts = 0;
    await openGuide(
      tester,
      complete: () async {
        if (++attempts == 1) throw Exception('storage unavailable');
      },
    );
    for (var i = 0; i < 4; i++) {
      await tester.tap(find.text('다음'));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.text('내 방으로'));
    await tester.pumpAndSettle();
    expect(find.byType(UsageGuideScreen), findsOneWidget);
    expect(find.text('완료 정보를 저장하지 못했어요. 다시 시도해 주세요.'), findsOneWidget);
    await tester.tap(find.text('내 방으로'));
    await tester.pumpAndSettle();
    expect(attempts, 2);
    expect(find.byType(UsageGuideScreen), findsNothing);
  });

  testWidgets('pending completion blocks repeated taps and back', (
    tester,
  ) async {
    final pending = Completer<void>();
    var calls = 0;
    await openGuide(
      tester,
      complete: () {
        calls++;
        return pending.future;
      },
    );
    for (var i = 0; i < 4; i++) {
      await tester.tap(find.text('다음'));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.text('내 방으로'));
    await tester.pump();
    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNull);
    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(find.byType(UsageGuideScreen), findsOneWidget);
    expect(calls, 1);
    pending.complete();
    await tester.pumpAndSettle();
  });

  testWidgets('all pages fit a small screen with larger text', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await openGuide(tester, textScale: 1.4, nickname: '아주아주긴사용자닉네임테스트');
    for (var i = 0; i < 5; i++) {
      expect(tester.takeException(), isNull);
      final next = find.text(i == 4 ? '내 방으로' : '다음');
      await tester.ensureVisible(next);
      await tester.pumpAndSettle();
      if (i < 4) {
        await tester.tap(next);
        await tester.pumpAndSettle();
      }
    }
  });

  testWidgets('guide overlays the room at design size', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await openGuide(tester);
    final guideContext = tester.element(find.byType(UsageGuideScreen));
    final route = ModalRoute.of(guideContext)!;
    expect(route.opaque, isFalse);
    expect(route.barrierDismissible, isFalse);
    final card = find
        .descendant(
          of: find.byType(UsageGuideScreen),
          matching: find.byType(ClipRRect),
        )
        .first;
    expect(tester.getSize(card), const Size(344, 590));
    for (var i = 0; i < 4; i++) {
      await tester.tap(find.text('다음'));
      await tester.pumpAndSettle();
    }
    expect(find.text('OO님의 화면'), findsOneWidget);
  });

  testWidgets('book icon matches the 46px header controls', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Center(child: GuideBookIcon())),
    );
    expect(tester.getSize(find.byType(GuideBookIcon)), const Size(46, 46));
  });

  testWidgets('renders guide preview pages', (tester) async {
    if (!const bool.fromEnvironment('GUIDE_PREVIEW')) return;
    tester.view.physicalSize = const Size(363, 614);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await openGuide(tester);
    final directory = Directory('build/guide-preview')
      ..createSync(recursive: true);
    for (var i = 0; i < 5; i++) {
      expect(tester.takeException(), isNull);
      final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byType(RepaintBoundary).last,
      );
      await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 2);
        final bytes = (await image.toByteData(format: ui.ImageByteFormat.png))!;
        File('${directory.path}/page-${i + 1}.png')
            .writeAsBytesSync(bytes.buffer.asUint8List());
        image.dispose();
      });
      if (i < 4) {
        await tester.tap(find.text('다음'));
        await tester.pumpAndSettle();
      }
    }
  });
}
