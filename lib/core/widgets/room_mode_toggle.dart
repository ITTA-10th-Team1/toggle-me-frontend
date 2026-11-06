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
                padding: const EdgeInsets.symmetric(
                  horizontal: 3.346,
                  vertical: 2.559,
                ),
                decoration: BoxDecoration(
                  color: isOn ? AppColors.white : AppColors.toggleOffTrack,
                  border: Border.all(
                    color: isOn
                        ? AppColors.toggleOnBorder
                        : AppColors.toggleOffBorder,
                    width: 0.573429,
                    strokeAlign: BorderSide.strokeAlignInside,
                  ),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: AnimatedAlign(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  alignment: isOn
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    width: 29.7354,
                    height: 29.7354,
                    decoration: BoxDecoration(
                      color: isOn
                          ? AppColors.toggleOn
                          : AppColors.toggleOffThumb,
                      shape: BoxShape.circle,
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x3B000000),
                          offset: Offset(-1.14686, 1.14686),
                          blurRadius: 4.12868,
                          spreadRadius: -1.14686,
                        ),
                      ],
                    ),
                    child: isLoading
                        ? Padding(
                            padding: EdgeInsets.all(6),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: isOn
                                  ? AppColors.white
                                  : AppColors.toggleOffTrack,
                            ),
                          )
                        : Center(
                            child: _WindowMark(
                              color: isOn
                                  ? AppColors.white
                                  : AppColors.toggleOffTrack,
                            ),
                          ),
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

/// Four rounded panes drawn as widgets, matching the designer's SVG geometry.
class _WindowMark extends StatelessWidget {
  const _WindowMark({required this.color});

  final Color color;

  Widget pane() => Container(
    width: 5.01271,
    height: 5.01271,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(0.420088),
    ),
  );

  Widget row() => Row(
    mainAxisSize: MainAxisSize.min,
    children: [pane(), const SizedBox(width: 0.76279), pane()],
  );

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [row(), const SizedBox(height: 0.54499), row()],
    ),
  );
}
