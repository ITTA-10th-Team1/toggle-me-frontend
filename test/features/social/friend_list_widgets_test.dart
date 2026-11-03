import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toggle_me/features/social/data/models/social_user.dart';
import 'package:toggle_me/features/social/presentation/widgets/friend_list_message.dart';
import 'package:toggle_me/features/social/presentation/widgets/friend_list_tile.dart';
import 'package:toggle_me/features/social/presentation/widgets/friend_search_bar.dart';
import 'package:toggle_me/features/social/presentation/widgets/profile_avatar.dart';

/// 위젯 하나만 화면에 올려 보는 도우미
Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  const user = SocialUser(memberId: 2, nickname: '토글러', handle: 'toggler_01');

  group('ProfileAvatar', () {
    testWidgets('사진 주소가 없으면 기본 이미지를 보여준다', (tester) async {
      await tester.pumpWidget(wrap(const ProfileAvatar(imageUrl: null)));

      expect(find.byIcon(Icons.person), findsOneWidget);
    });
  });

  group('FriendListTile', () {
    testWidgets('닉네임과 @아이디를 보여주고, 놀러가기를 누르면 onVisit을 부른다', (tester) async {
      var tapped = 0;
      await tester.pumpWidget(
        wrap(FriendListTile(user: user, onVisit: () => tapped++)),
      );

      expect(find.text('토글러'), findsOneWidget);
      expect(find.text('@toggler_01'), findsOneWidget);

      await tester.tap(find.text('놀러가기'));
      expect(tapped, 1);
    });

    testWidgets('isVisiting이면 로딩 표시가 나오고 눌리지 않는다', (tester) async {
      var tapped = 0;
      await tester.pumpWidget(
        wrap(
          FriendListTile(user: user, onVisit: () => tapped++, isVisiting: true),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.tap(find.byType(ElevatedButton));
      expect(tapped, 0);
    });
  });

  group('FriendSearchBar', () {
    testWidgets("글자를 입력하면 X 버튼이 생기고, 누르면 지운 뒤 onChanged('')", (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      final changes = <String>[];
      await tester.pumpWidget(
        wrap(FriendSearchBar(controller: controller, onChanged: changes.add)),
      );

      expect(find.text('아이디 검색'), findsOneWidget);
      expect(find.byIcon(Icons.cancel), findsNothing);

      await tester.enterText(find.byType(TextField), 'cat');
      await tester.pump();
      expect(changes.last, 'cat');
      expect(find.byIcon(Icons.cancel), findsOneWidget);

      await tester.tap(find.byIcon(Icons.cancel));
      await tester.pump();
      expect(controller.text, isEmpty);
      expect(changes.last, '');
      expect(find.byIcon(Icons.cancel), findsNothing);
    });
  });

  group('FriendListMessage', () {
    testWidgets('버튼 정보가 없으면 문구만 보여준다', (tester) async {
      await tester.pumpWidget(
        wrap(const FriendListMessage(message: '검색 결과가 없어요.')),
      );

      expect(find.text('검색 결과가 없어요.'), findsOneWidget);
      expect(find.byType(OutlinedButton), findsNothing);
    });

    testWidgets('[다시 시도]를 누르면 onAction을 부른다', (tester) async {
      var retried = 0;
      await tester.pumpWidget(
        wrap(
          FriendListMessage(
            message: '목록을 불러오지 못했어요.',
            actionLabel: '다시 시도',
            onAction: () => retried++,
          ),
        ),
      );

      await tester.tap(find.text('다시 시도'));
      expect(retried, 1);
    });
  });
}
