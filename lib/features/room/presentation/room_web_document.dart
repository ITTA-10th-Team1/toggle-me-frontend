import 'dart:convert';

import 'room_camera_config.dart';
import 'room_weather_preview.dart';
import 'room_lighting_config.dart';

/// A real document is needed: scripts inserted with innerHTML do not execute.
String roomWebDocument(Uri base, String bridge) {
  String asset(String path) =>
      const HtmlEscape(HtmlEscapeMode.attribute)
          .convert(base.resolve('assets/$path').toString());
  final script = asset('packages/model_viewer_plus/assets/model-viewer.min.js');
  final model = asset('assets/models/toggleme_room.glb');
  return '''<!doctype html>
<html><head><meta name="viewport" content="width=device-width, initial-scale=1">
<style>html,body,model-viewer { width:100%;height:100%;margin:0;padding:0; }
body { overflow:hidden;background:#fffaf1; }
model-viewer { touch-action:none; }</style>
</head><body>
<model-viewer src="$model" loading="eager"
 camera-orbit="${RoomCameraConfig.orbit}"
 min-camera-orbit="${RoomCameraConfig.orbit}"
 max-camera-orbit="${RoomCameraConfig.orbit}"
 field-of-view="${RoomCameraConfig.fieldOfView}"
 min-field-of-view="${RoomCameraConfig.fieldOfView}"
 max-field-of-view="${RoomCameraConfig.fieldOfView}"
 environment-image="${RoomLightingConfig.environment}"
 exposure="${RoomLightingConfig.exposure}"
 shadow-intensity="${RoomLightingConfig.shadowIntensity}"
 shadow-softness="${RoomLightingConfig.shadowSoftness}"
 interaction-prompt="none" disable-pan disable-tap disable-zoom>
 <div slot="progress-bar"></div>
</model-viewer>
<script>
const send = (channel, value) => parent.postMessage(
  JSON.stringify({channel, value}), ${jsonEncode(base.origin)});
globalThis.RoomStatus = {postMessage: value => send('RoomStatus', value)};
globalThis.RoomFurniture = {postMessage: value => send('RoomFurniture', value)};
window.addEventListener('error', () => send('RoomStatus', 'error'));
window.addEventListener('unhandledrejection', () => send('RoomStatus', 'error'));
${roomWeatherPreview.replaceAll('</', r'<\/')}
${bridge.replaceAll('</', r'<\/')}
</script>
<script type="module" src="$script" onerror="RoomStatus.postMessage('error')"></script>
</body></html>''';
}
