import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

/// Shared controlled toggle. Parent screens own state and API calls.
class RoomModeToggle extends StatelessWidget {
  const RoomModeToggle({
    super.key,
    required this.isOn,
    required this.onChanged,
    this.isLoading = false,
    this.semanticLabel = '방 공개 모드',
  });
  final bool isOn;
  final ValueChanged<bool>? onChanged;
  final bool isLoading;
  final String semanticLabel;
  @override
  Widget build(BuildContext context) {
    final enabled = onChanged != null && !isLoading;
    void change() => onChanged?.call(!isOn);
    return Semantics(
      label: semanticLabel,
      value: isLoading ? '저장 중' : (isOn ? '켜짐' : '꺼짐'),
      toggled: isOn,
      enabled: enabled,
      onTap: enabled ? change : null,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          excludeFromSemantics: true,
          borderRadius: BorderRadius.circular(30),
          onTap: enabled ? change : null,
          child: SizedBox(
            width: 60.86,
            height: 48,
            child: Center(
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
                  alignment: isOn
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: const BoxDecoration(
                      color: AppColors.white,
                      shape: BoxShape.circle,
                    ),
                    child: isLoading
                        ? const Padding(
                            padding: EdgeInsets.all(6),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.toggleOff,
                            ),
                          )
                        : null,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
