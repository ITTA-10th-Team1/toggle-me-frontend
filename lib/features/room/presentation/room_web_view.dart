import 'dart:convert';
import 'dart:js_interop';

import 'package:flutter/widgets.dart';
import 'package:web/web.dart' as web;

import 'room_web_document.dart';

class RoomWebView extends StatefulWidget {
  const RoomWebView({
    super.key,
    required this.bridge,
    required this.onStatus,
    required this.onFurniture,
    this.interactive = true,
  });
  final String bridge;
  final ValueChanged<String> onStatus;
  final ValueChanged<String> onFurniture;
  final bool interactive;

  @override
  State<RoomWebView> createState() => _RoomWebViewState();
}

class _RoomWebViewState extends State<RoomWebView> {
  web.HTMLIFrameElement? _frame;
  late final JSFunction _listener;

  @override
  void initState() {
    super.initState();
    _listener = ((web.MessageEvent event) {
      final frame = _frame;
      if (!mounted ||
          frame == null ||
          event.source != frame.contentWindow ||
          event.origin != web.window.location.origin) {
        return;
      }
      final raw = event.data;
      if (raw == null || !raw.isA<JSString>()) return;
      try {
        final data = jsonDecode((raw as JSString).toDart);
        if (data is! Map || data['value'] is! String) return;
        final value = data['value'] as String;
        if (data['channel'] == 'RoomStatus' &&
            (value == 'loaded' || value == 'error')) {
          widget.onStatus(value);
        }
        if (data['channel'] == 'RoomFurniture' &&
            (value == 'mirror' || value == 'fridge' || value == 'desk')) {
          widget.onFurniture(value);
        }
      } on FormatException {
        // Ignore unrelated messages, never interpret them as executable code.
      }
    }).toJS;
    web.window.addEventListener('message', _listener);
  }

  @override
  void dispose() {
    web.window.removeEventListener('message', _listener);
    _frame = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Browser iframe events do not bubble to Flutter overlays. Keep rendering
    // the room, but let the canvas receive taps while a dialog/sheet covers it.
    final pointerEvents =
        widget.interactive && (ModalRoute.isCurrentOf(context) ?? true)
        ? 'auto'
        : 'none';
    _frame?.style.pointerEvents = pointerEvents;
    return HtmlElementView.fromTagName(
      tagName: 'iframe',
      onElementCreated: (element) {
        final frame = element as web.HTMLIFrameElement;
        _frame = frame;
        frame.title = '3D room';
        frame.style
          ..border = '0'
          ..width = '100%'
          ..height = '100%'
          ..display = 'block'
          ..pointerEvents = pointerEvents;
        frame.srcdoc = roomWebDocument(Uri.base, widget.bridge).toJS;
      },
    );
  }
}
