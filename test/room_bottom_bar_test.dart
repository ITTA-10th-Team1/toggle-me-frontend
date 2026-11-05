import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toggle_me/features/room/presentation/room_bottom_bar.dart';

void main() {
  testWidgets('all five attached actions preserve their destinations', (
    tester,
  ) async {
    final actions = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.bottomCenter,
            child: SizedBox(
              width: 350,
              child: RoomBottomBar(
                onRecord: () => actions.add('record'),
                onGuestbook: () => actions.add('guestbook'),
                onShop: () => actions.add('shop'),
                onMood: () => actions.add('mood'),
                onFriends: () => actions.add('friends'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('기록하기'));
    for (final label in ['방명록', '상점', '무드레포트', '친구목록']) {
      await tester.tap(find.byTooltip(label));
    }
    expect(actions, ['record', 'guestbook', 'shop', 'mood', 'friends']);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'capsule fits a narrow phone and has no gap between action regions',
    (tester) async {
      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: RoomBottomBar(
                  onRecord: () {},
                  onGuestbook: () {},
                  onShop: () {},
                  onMood: () {},
                  onFriends: () {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final record = tester.getRect(find.byType(ElevatedButton));
      final guestbook = tester.getRect(find.byType(IconButton).first);
      expect(record.right, closeTo(guestbook.left, 0.01));
      expect(record.height, 52);
      expect(tester.takeException(), isNull);
    },
  );
}
