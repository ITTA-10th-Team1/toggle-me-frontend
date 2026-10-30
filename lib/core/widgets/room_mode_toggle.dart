import 'package:flutter/material.dart';

class RoomModeToggle extends StatelessWidget {
  const RoomModeToggle({
    super.key,
    required this.isOn,
    required this.onChanged,
  });

  final bool isOn;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '방 공개 모드',
      value: isOn ? '켜짐' : '꺼짐',
      button: true,
      child: GestureDetector(
        onTap: () => onChanged(!isOn),
        child: Image.asset(
          isOn
              ? 'assets/images/room_toggle_on.png'
              : 'assets/images/room_toggle_off.png',
          width: 60.86,
          height: 36,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
