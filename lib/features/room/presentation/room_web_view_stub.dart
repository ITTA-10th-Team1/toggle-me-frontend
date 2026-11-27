import 'package:flutter/widgets.dart';

class RoomWebView extends StatelessWidget {
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
  Widget build(BuildContext context) => const SizedBox.shrink();
}
