import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:toggle_me/core/network/member_api.dart';
import 'package:toggle_me/features/auth/data/token_storage.dart';
import 'package:toggle_me/features/item/presentation/item_upload_screen.dart';
import 'package:toggle_me/features/item/presentation/providers/item_upload_provider.dart';
import 'package:toggle_me/features/room/data/room_repository.dart';
import 'package:toggle_me/features/room/domain/room_data.dart';

class _Tokens extends TokenStorage {
  @override
  Future<String?> getAccessToken() async => 'test-access';
  @override
  Future<String?> getRefreshToken() async => 'test-refresh';
}

class _RoomRepo extends RoomRepository {
  _RoomRepo({this.empty = false}) : super(MemberApi(tokens: _Tokens()));
  final bool empty;
  @override
  Future<List<Map<String, dynamic>>> list(
    String path, {
    MemberApiSession? session,
  }) async {
    expect(path, '/api/v1/rooms');
    return empty
        ? []
        : [
            {'id': 83},
          ];
  }

  @override
  Future<List<RoomFurniture>> furnitureForRoom(
    int id, {
    MemberApiSession? session,
  }) async {
    expect(id, 83);
    return [
      RoomFurniture.fromJson({
        'furnitureTypeId': 71,
        'furnitureTypeCode': 'mirror',
        'hidden': false,
      }),
      RoomFurniture.fromJson({
        'furnitureTypeId': 82,
        'furnitureTypeCode': 'fridge',
        'hidden': true,
      }),
      RoomFurniture.fromJson({
        'furnitureTypeId': 103,
        'furnitureTypeCode': 'bookshelf',
        'objectNodeName': 'desk',
        'hidden': false,
      }),
    ];
  }
}

class _Upload extends ItemUploadNotifier {
  int? submittedId;
  String? submittedVisibility;
  void ready() {
    final bytes = File('assets/room/raster/profile.png').readAsBytesSync();
    state = ItemUploadState(
      selectedImage: XFile.fromData(bytes, name: 'test.png'),
      selectedImageBytes: bytes,
      imageKey: 'test/image.png',
    );
  }

  @override
  Future<bool> submit({
    required int furnitureTypeId,
    required String memo,
    required String visibility,
  }) async {
    submittedId = furnitureTypeId;
    submittedVisibility = visibility;
    return false;
  }
}

Future<void> selectDesk(WidgetTester tester, String name) async {
  await tester.scrollUntilVisible(
    find.text(name),
    150,
    scrollable: find.descendant(
      of: find.byType(ListView),
      matching: find.byType(Scrollable),
    ),
  );
  await tester.tap(find.text(name));
  await tester.pumpAndSettle();
}

void main() {
  test('server bookshelf desk normalizes placement while preserving actual ID', () {
    final item = RoomFurniture.fromJson({
      'furnitureTypeId': 3, 'furnitureTypeCode': 'bookshelf',
      'objectNodeName': 'desk', 'hidden': false, 'variantId': 4,
    });
    expect(item.code, 'desk');
    expect(item.scene['furnitureTypeCode'], 'desk');
    expect(item.typeId, 3);
    expect(item.scene['variantId'], 4);
    expect(item.hidden, false);
    final shelf = RoomFurniture.fromJson({
      'furnitureTypeId': 9, 'furnitureTypeCode': 'bookshelf',
      'objectNodeName': 'shelf', 'hidden': true,
    });
    expect(shelf.code, 'bookshelf');
    expect(shelf.hidden, true);
  });
  test(
    'recording catalog uses actual placed IDs and excludes hidden furniture',
    () async {
      final c = ProviderContainer.test(
        overrides: [
          recordingRoomRepositoryProvider.overrideWithValue(_RoomRepo()),
        ],
      );
      expect(await c.read(recordingFurnitureProvider.future), {
        'mirror': 71,
        'desk': 103,
      });
    },
  );
  test('no room does not invent recording IDs', () async {
    final c = ProviderContainer.test(
      overrides: [
        recordingRoomRepositoryProvider.overrideWithValue(
          _RoomRepo(empty: true),
        ),
      ],
    );
    expect(await c.read(recordingFurnitureProvider.future), isEmpty);
  });
  for (final choice in {'거울': 71, '냉장고': 82, '책상': 103}.entries) {
    testWidgets(
      'record submission uses server furniture ID for ${choice.key}',
      (tester) async {
        final upload = _Upload();
        final c = ProviderContainer.test(
          overrides: [
            recordingFurnitureProvider.overrideWith(
              (ref) async => {'mirror': 71, 'fridge': 82, 'desk': 103},
            ),
            itemUploadProvider.overrideWith(() => upload),
          ],
        );
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: c,
            child: const MaterialApp(home: ItemUploadScreen()),
          ),
        );
        await tester.pumpAndSettle();
        await selectDesk(tester, choice.key);
        c.read(itemUploadProvider.notifier);
        upload.ready();
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('기록하기'));
        await tester.tap(find.text('기록하기'));
        await tester.pumpAndSettle();
        expect(upload.submittedId, choice.value);
        expect(upload.submittedVisibility, 'PUBLIC');
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets(
    'unregistered desk stays visible as a category but cannot submit a fake ID',
    (tester) async {
      final upload = _Upload();
      final c = ProviderContainer.test(
        overrides: [
          recordingFurnitureProvider.overrideWith(
            (ref) async => {'mirror': 71, 'fridge': 82},
          ),
          itemUploadProvider.overrideWith(() => upload),
        ],
      );
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: c,
          child: const MaterialApp(home: ItemUploadScreen()),
        ),
      );
      await tester.pumpAndSettle();
      await selectDesk(tester, '책상');
      expect(find.text('책상은 아직 방에 배치되지 않았어요.'), findsOneWidget);
      expect(upload.submittedId, isNull);
    },
  );
  test('desk model preserves original mirror/fridge placements and groups all desk parts', () {
    final bytes = File('assets/models/toggleme_room.glb').readAsBytesSync();
    final size = bytes.buffer.asByteData().getUint32(12, Endian.little);
    final glb = jsonDecode(utf8.decode(bytes.sublist(20, 20 + size))) as Map;
    final nodes = glb['nodes'] as List;
    Map node(String name) =>
        nodes.cast<Map>().firstWhere((n) => n['name'] == name);
    final layout = jsonDecode(
      File('docs/desk-backend-layout.json').readAsStringSync(),
    ) as Map;
    for (final name in ['stand', 'body']) {
      final expected = layout['preservedNodes'][name];
      expect(node(name)['translation'], expected['translation']);
      expect(node(name)['rotation'], expected['rotation']);
      expect(node(name)['scale'] ?? [1, 1, 1], expected['scale']);
    }
    expect(node('stand')['translation'], [
      -1.3948961734771728,
      0.38799723982810974,
      1.667795181274414,
    ]);
    expect(node('body')['translation'], [
      1.1741273403167725,
      1.186818853020668,
      -1.438000932456924,
    ]);
    final children = (node('desk')['children'] as List)
        .map((i) => nodes[i]['name'])
        .toSet();
    expect(children, {'Chair assembly', 'Desk assembly', 'Desk assembly.001'});
  });
}
