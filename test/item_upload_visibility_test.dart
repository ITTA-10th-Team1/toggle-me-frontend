import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toggle_me/core/widgets/room_mode_toggle.dart';
import 'package:toggle_me/features/item/presentation/item_upload_screen.dart';

void main() {
  testWidgets('new record defaults to public and can still be made private', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: ItemUploadScreen())),
    );
    final toggle = find.byType(RoomModeToggle);
    await tester.ensureVisible(toggle);
    await tester.pumpAndSettle();
    expect(tester.widget<RoomModeToggle>(toggle).isOn, isTrue);
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    expect(tester.widget<RoomModeToggle>(toggle).isOn, isFalse);
  });
}
