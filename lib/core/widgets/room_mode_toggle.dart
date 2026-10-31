import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

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
      toggled: isOn,
      child: GestureDetector(
        onTap: () => onChanged(!isOn),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          width: 60.86,
          height: 36,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isOn ? AppColors.toggleOn : AppColors.toggleOff,
            borderRadius: BorderRadius.circular(30),
          ),
          child: AnimatedAlign(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            alignment: isOn ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                color: AppColors.white,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
