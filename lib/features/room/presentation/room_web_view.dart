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
  });
  final String bridge;
  final ValueChanged<String> onStatus;
  final ValueChanged<String> onFurniture;

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
            (value == 'mirror' || value == 'fridge')) {
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
  Widget build(BuildContext context) => HtmlElementView.fromTagName(
    tagName: 'iframe',
    onElementCreated: (element) {
      final frame = element as web.HTMLIFrameElement;
      _frame = frame;
      frame.title = '3D room';
      frame.style
        ..border = '0'
        ..width = '100%'
        ..height = '100%'
        ..display = 'block';
      frame.srcdoc = roomWebDocument(Uri.base, widget.bridge).toJS;
    },
  );
}
