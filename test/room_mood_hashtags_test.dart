import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toggle_me/features/room/presentation/room_mood_hashtags.dart';
import 'package:toggle_me/features/room/presentation/room_presentation_config.dart';

void main() {
  testWidgets('presentation shows denim and bread, without navigation', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: RoomMoodHashtags(tags: RoomPresentationConfig.moodHashtags),
        ),
      ),
    );
    expect(find.text('#데님'), findsOneWidget);
    expect(find.text('#빵'), findsOneWidget);
    expect(find.text('#거울'), findsNothing);
    expect(find.text('#냉장고'), findsNothing);
    expect(find.byType(InkWell), findsNothing);
    await tester.tap(find.text('#데님'));
    await tester.pump();
    expect(find.text('#빵'), findsOneWidget);
  });
  testWidgets('empty real result does not fall back to presentation tags', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: RoomMoodHashtags(tags: [])),
      ),
    );
    expect(find.text('#데님'), findsNothing);
    expect(find.text('#빵'), findsNothing);
    expect(find.byType(ListView), findsNothing);
  });
  testWidgets('a supplied result replaces fixture text', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: RoomMoodHashtags(
            tags: [RoomMoodHashtag(categoryId: 'mirror', text: '빈티지')],
          ),
        ),
      ),
    );
    expect(find.text('#빈티지'), findsOneWidget);
    expect(find.text('#데님'), findsNothing);
  });
}
