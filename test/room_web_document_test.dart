import 'package:flutter_test/flutter_test.dart';
import 'package:toggle_me/features/room/presentation/room_web_document.dart';
import 'package:toggle_me/features/room/presentation/room_scene_bridge.dart';

void main() {
  test(
    'web room resolves model and matching bundled viewer below app base',
    () {
      final html = roomWebDocument(
        Uri.parse('https://example.com/app/#/room'),
        roomSceneBridge,
      );
      expect(
        html,
        contains(
          'https://example.com/app/assets/assets/models/toggleme_room.glb',
        ),
      );
      expect(
        html,
        contains(
          'https://example.com/app/assets/packages/model_viewer_plus/assets/model-viewer.min.js',
        ),
      );
      expect(html, contains('type="module"'));
      expect(html, contains('slot="progress-bar"'));
      expect(html, contains("globalThis.RoomStatus ="));
      expect(html, contains("globalThis.RoomFurniture ="));
      expect(html, contains(roomSceneBridge));
      expect(html, contains('"https://example.com"'));
    },
  );
}
