import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toggle_me/app/theme/app_theme.dart';
import 'package:toggle_me/core/widgets/room_mode_toggle.dart';
import 'package:toggle_me/core/widgets/app_button.dart';
import 'package:toggle_me/core/widgets/app_notice.dart';
import 'package:toggle_me/core/widgets/app_text_field.dart';
import 'package:toggle_me/features/auth/presentation/widgets/primary_button.dart';

void main() {
  testWidgets(
    'shared password field toggles visibility and retains its controller',
    (tester) async {
      final controller = TextEditingController(text: 'secret');
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppTextField(
              controller: controller,
              hintText: '비밀번호',
              icon: Icons.lock,
              isPassword: true,
            ),
          ),
        ),
      );
      expect(
        tester.widget<EditableText>(find.byType(EditableText)).obscureText,
        isTrue,
      );
      await tester.tap(find.byIcon(Icons.visibility_off_outlined));
      await tester.pump();
      expect(
        tester.widget<EditableText>(find.byType(EditableText)).obscureText,
        isFalse,
      );
      expect(controller.text, 'secret');
    },
  );
  testWidgets('shared toggle reports state without keeping its own copy', (
    tester,
  ) async {
    var enabled = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => RoomModeToggle(
              isOn: enabled,
              onChanged: (next) => setState(() => enabled = next),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byType(RoomModeToggle));
    await tester.pump(const Duration(milliseconds: 250));
    expect(enabled, isTrue);
    expect(
      tester.widget<RoomModeToggle>(find.byType(RoomModeToggle)).isOn,
      isTrue,
    );
    await tester.tap(find.byType(RoomModeToggle));
    await tester.pump(const Duration(milliseconds: 250));
    expect(enabled, isFalse);
  });
  testWidgets('saving and disabled toggles ignore repeated taps', (
    tester,
  ) async {
    var changes = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              RoomModeToggle(
                key: const Key('saving'),
                isOn: true,
                isLoading: true,
                onChanged: (_) => changes++,
              ),
              const RoomModeToggle(
                key: Key('disabled'),
                isOn: false,
                onChanged: null,
              ),
            ],
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('saving')));
    await tester.tap(find.byKey(const Key('saving')));
    await tester.tap(find.byKey(const Key('disabled')));
    await tester.pump();
    expect(changes, 0);
  });
  testWidgets('toggle supports keyboard activation', (tester) async {
    var changes = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RoomModeToggle(isOn: false, onChanged: (_) => changes++),
        ),
      ),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(changes, 1);
  });
  testWidgets(
    'login wrapper delegates to shared button and locks while loading',
    (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PrimaryButton(
              text: '로그인',
              isLoading: true,
              onPressed: () => taps++,
            ),
          ),
        ),
      );
      expect(find.byType(AppButton), findsOneWidget);
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();
      expect(taps, 0);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    },
  );
  testWidgets('new notices replace the queue and close immediately', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Column(
              children: [
                TextButton(
                  onPressed: () => showAppNotice(context, '첫 번째'),
                  child: const Text('첫 알림'),
                ),
                TextButton(
                  onPressed: () => showAppNotice(context, '두 번째'),
                  child: const Text('다음 알림'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('첫 알림'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('다음 알림'));
    await tester.pumpAndSettle();
    expect(find.text('첫 번째'), findsNothing);
    expect(find.text('두 번째'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
    expect(find.text('두 번째'), findsNothing);
    await tester.pump(const Duration(seconds: 3));
    expect(find.byType(SnackBar), findsNothing);
  });
}
