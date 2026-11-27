import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toggle_me/features/social/data/taste_share_service.dart';
import 'package:toggle_me/features/social/presentation/widgets/share_taste_dialog.dart';

/// 실제로 카카오톡을 열거나 복사하지 않고, 무엇을 요청받았는지만 기록하는 가짜
class _FakeShareService implements TasteShareService {
  final kakaoShared = <TasteShareContent>[];
  final copied = <TasteShareContent>[];
  Object? kakaoError;

  @override
  Future<void> shareToKakaoTalk(TasteShareContent content) async {
    if (kakaoError != null) throw kakaoError!;
    kakaoShared.add(content);
  }

  @override
  Future<void> copyLink(TasteShareContent content) async {
    copied.add(content);
  }
}

/// 버튼 하나를 눌러 공유하기 팝업을 여는 테스트용 화면
Future<void> _openDialog(
  WidgetTester tester, {
  required List<String> tags,
  String? nickname,
  TasteShareService? service,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => showShareTasteDialog(
              context,
              tags: tags,
              nickname: nickname,
              service: service ?? _FakeShareService(),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

/// 공유할 수 있는 최소 태그 5개
const _fiveTags = ['데님', '빵', '빈티지', '캠핑', '재즈'];

/// 팝업(Dialog) 크기
Size _dialogSize(WidgetTester tester) => tester.getSize(find.byType(Dialog));

Future<void> _chooseOption(WidgetTester tester, String label) async {
  await tester.tap(find.text('공유하기'));
  await tester.pumpAndSettle();
  await tester.tap(find.text(label));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('내 태그 5개와 [공유하기] [내 방으로] 버튼이 보이고, 설명 문구는 없다', (tester) async {
    await _openDialog(tester, tags: _fiveTags);

    for (final tag in _fiveTags) {
      expect(find.text('#$tag'), findsOneWidget);
    }
    expect(find.text('공유하기'), findsOneWidget);
    expect(find.text('내 방으로'), findsOneWidget);
    expect(find.text('친구와 취향을 공유해요'), findsNothing);
  });

  testWidgets('[공유하기]와 [내 방으로]는 같은 줄에 있다', (tester) async {
    await _openDialog(tester, tags: ['데님']);

    final share = tester.getCenter(find.text('공유하기'));
    final home = tester.getCenter(find.text('내 방으로'));
    expect(share.dy, home.dy);
    expect(share.dx, lessThan(home.dx));
  });

  testWidgets('닉네임이 있으면 OO님의 취향, 없으면 나의 취향', (tester) async {
    await _openDialog(tester, tags: ['데님'], nickname: '토글러');
    expect(find.text('토글러님의 취향'), findsOneWidget);

    await tester.tap(find.text('내 방으로'));
    await tester.pumpAndSettle();

    await _openDialog(tester, tags: ['데님']);
    expect(find.text('나의 취향'), findsOneWidget);
  });

  testWidgets('태그는 최대 5개까지만 보인다', (tester) async {
    await _openDialog(tester, tags: ['a', 'b', 'c', 'd', 'e', 'f']);

    expect(find.text('#e'), findsOneWidget);
    expect(find.text('#f'), findsNothing);
  });

  for (final count in [0, 4]) {
    testWidgets('태그가 $count개면 "부족해요" 안내가 보이고 [공유하기]가 꺼진다', (tester) async {
      await _openDialog(tester, tags: _fiveTags.take(count).toList());

      expect(find.text('아직 태그가 부족해서 볼 수 없어요.'), findsOneWidget);
      expect(find.text('태그가 5개 모이면 공유할 수 있어요.'), findsOneWidget);
      expect(find.textContaining('#'), findsNothing); // 태그는 안 보여줌
      final button = tester.widget<ElevatedButton>(
        find.ancestor(
          of: find.text('공유하기'),
          matching: find.byType(ElevatedButton),
        ),
      );
      expect(button.onPressed, isNull);
    });
  }

  testWidgets('팝업 크기는 태그 수와 안내 문구에 상관없이 같다', (tester) async {
    final sizes = <Size>[];
    for (final tags in [
      <String>[],
      ['데님'],
      _fiveTags,
      [..._fiveTags, '추가'],
    ]) {
      await _openDialog(tester, tags: tags);
      sizes.add(_dialogSize(tester));
      await tester.tap(find.text('내 방으로'));
      await tester.pumpAndSettle();
    }
    expect(sizes.toSet(), hasLength(1));

    // 결과 문구가 나타나도 크기가 그대로
    await _openDialog(tester, tags: _fiveTags);
    await _chooseOption(tester, '취향 내용 복사');
    expect(find.text('취향 내용을 복사했어요.'), findsOneWidget);
    expect(_dialogSize(tester), sizes.first);
  });

  testWidgets('[공유하기]를 누르면 카카오톡·취향 내용 복사 두 가지만 나온다', (tester) async {
    await _openDialog(tester, tags: _fiveTags);
    await tester.tap(find.text('공유하기'));
    await tester.pumpAndSettle();

    expect(find.text('카카오톡으로 공유하기'), findsOneWidget);
    expect(find.text('취향 내용 복사'), findsOneWidget);
    expect(find.byType(ListTile), findsNWidgets(2));
  });

  testWidgets('카카오톡으로 공유하기 → 모든 태그를 담아 공유를 요청한다', (tester) async {
    final service = _FakeShareService();
    await _openDialog(
      tester,
      tags: ['a', 'b', 'c', 'd', 'e', 'f'],
      service: service,
    );

    await _chooseOption(tester, '카카오톡으로 공유하기');

    expect(service.kakaoShared, hasLength(1));
    // 카드에는 5개만 보여도 공유는 전부 해요.
    expect(service.kakaoShared.single.hashtagLine, '#a #b #c #d #e #f');
    expect(service.kakaoShared.single.title, '나의 취향');
  });

  testWidgets('카카오톡 공유에 실패하면 안내 문구가 보인다', (tester) async {
    final service = _FakeShareService()..kakaoError = Exception('fail');
    await _openDialog(tester, tags: _fiveTags, service: service);

    await _chooseOption(tester, '카카오톡으로 공유하기');

    expect(find.text('카카오톡으로 공유하지 못했어요. 다시 시도해 주세요.'), findsOneWidget);
  });

  testWidgets('취향 내용 복사 → 복사를 요청하고 "취향 내용을 복사했어요."', (tester) async {
    final service = _FakeShareService();
    await _openDialog(tester, tags: _fiveTags, service: service);

    await _chooseOption(tester, '취향 내용 복사');

    expect(service.copied.single.hashtagLine, '#데님 #빵 #빈티지 #캠핑 #재즈');
    expect(find.text('취향 내용을 복사했어요.'), findsOneWidget);
  });

  testWidgets('선택 창을 그냥 닫으면 아무것도 하지 않는다', (tester) async {
    final service = _FakeShareService();
    await _openDialog(tester, tags: _fiveTags, service: service);
    await tester.tap(find.text('공유하기'));
    await tester.pumpAndSettle();

    // 선택 창 바깥(위쪽)을 눌러 닫기
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    expect(service.kakaoShared, isEmpty);
    expect(service.copied, isEmpty);
    expect(find.text('내 방으로'), findsOneWidget); // 팝업은 그대로
  });

  testWidgets('[내 방으로]는 팝업을 닫는다', (tester) async {
    await _openDialog(tester, tags: ['데님']);
    await tester.tap(find.text('내 방으로'));
    await tester.pumpAndSettle();

    expect(find.text('내 방으로'), findsNothing);
  });

  test('공유 글: 제목, 해시태그 한 줄 (링크 설정이 없으면 링크 줄은 빠짐)', () {
    const content = TasteShareContent(title: '나의 취향', tags: ['데님', '빵']);
    expect(content.text, '나의 취향\n#데님 #빵');
  });

  group('스티커 태그 (#47)', () {
    // 실제 휴대폰(Pixel 9) 크기로 확인해요.
    setUp(() {
      final binding = TestWidgetsFlutterBinding.instance;
      binding.platformDispatcher.views.first.physicalSize = const Size(
        412,
        915,
      );
      binding.platformDispatcher.views.first.devicePixelRatio = 1;
    });
    tearDown(() {
      TestWidgetsFlutterBinding.instance.platformDispatcher.views.first
          .resetPhysicalSize();
      TestWidgetsFlutterBinding.instance.platformDispatcher.views.first
          .resetDevicePixelRatio();
    });

    /// 태그 카드 (높이 240인 흰 칸)
    Rect cardRect(WidgetTester tester) => tester.getRect(
      find.ancestor(
        of: find.text('나의 취향'),
        matching: find.byWidgetPredicate(
          (w) =>
              w is Container &&
              w.constraints?.maxHeight == ShareTasteDialog.cardHeight,
        ),
      ),
    );

    double fontSizeOf(WidgetTester tester, String text) =>
        tester.widget<Text>(find.text(text)).style!.fontSize!;

    /// 태그를 감싼 기울기(Transform.rotate)의 각도
    double angleOf(WidgetTester tester, String text) {
      final transform = tester.widget<Transform>(
        find
            .ancestor(of: find.text(text), matching: find.byType(Transform))
            .first,
      );
      final m = transform.transform;
      return math.atan2(m.entry(1, 0), m.entry(0, 0)) * 180 / math.pi;
    }

    testWidgets('첫 번째 태그는 크게, 나머지 4개는 작게 보인다', (tester) async {
      await _openDialog(tester, tags: _fiveTags);

      expect(fontSizeOf(tester, '#데님'), 22);
      for (final tag in _fiveTags.skip(1)) {
        expect(fontSizeOf(tester, '#$tag'), 15);
      }
    });

    testWidgets('태그마다 기울어져 있고, 열 때마다 각도가 같다', (tester) async {
      await _openDialog(tester, tags: _fiveTags);
      final first = [for (final t in _fiveTags) angleOf(tester, '#$t')];

      for (final angle in first) {
        expect(angle.abs(), greaterThan(1)); // 모두 기울어짐
      }

      await tester.tap(find.text('내 방으로'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      final second = [for (final t in _fiveTags) angleOf(tester, '#$t')];
      expect(second, first);
    });

    testWidgets('작은 태그가 큰 태그와 살짝 겹친다', (tester) async {
      await _openDialog(tester, tags: _fiveTags);

      /// 태그 스티커(배경 칸) 영역
      Rect chip(String tag) => tester.getRect(
        find
            .ancestor(of: find.text(tag), matching: find.byType(Container))
            .first,
      );
      final main = chip('#데님');
      // 휴대폰 화면에서는 귀퉁이 4개 모두 큰 태그에 살짝 걸쳐요.
      for (final t in _fiveTags.skip(1)) {
        expect(chip('#$t').overlaps(main), isTrue, reason: t);
      }
    });

    testWidgets('아주 긴 태그도 카드 밖으로 넘치지 않는다', (tester) async {
      const longTags = [
        '미드센추리모던인테리어',
        '재즈플레이리스트모음집',
        '빈티지카메라수집',
        '주말캠핑과차박여행',
        '홈카페레시피연구',
      ];
      await _openDialog(tester, tags: longTags);

      expect(tester.takeException(), isNull); // 넘침 오류 없음
      final card = cardRect(tester);
      for (final tag in longTags) {
        final chip = tester.getRect(find.text('#$tag'));
        expect(chip.left, greaterThanOrEqualTo(card.left), reason: tag);
        expect(chip.right, lessThanOrEqualTo(card.right), reason: tag);
        expect(chip.bottom, lessThanOrEqualTo(card.bottom), reason: tag);
      }
    });
  });
}
