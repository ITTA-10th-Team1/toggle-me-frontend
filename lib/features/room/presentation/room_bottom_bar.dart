import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';

/// One continuous capsule with five independently accessible actions.
class RoomBottomBar extends StatelessWidget {
  const RoomBottomBar({
    super.key,
    this.onRecord,
    this.onGuestbook,
    this.onShop,
    this.onMood,
    this.onFriends,
  });

  final VoidCallback? onRecord;
  final VoidCallback? onGuestbook;
  final VoidCallback? onShop;
  final VoidCallback? onMood;
  final VoidCallback? onFriends;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: ColoredBox(
        color: AppColors.surfaceMuted,
        child: SizedBox(
          height: 52,
          child: LayoutBuilder(
            builder: (context, constraints) => Row(
              children: [
                SizedBox(
                  width: (constraints.maxWidth * 0.35).clamp(104.0, 112.0),
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: onRecord,
                    icon: const Icon(Icons.add, size: 20),
                    label: const Text('기록하기', style: AppTextStyles.buttonSmall),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      backgroundColor: AppColors.roomAccent,
                      foregroundColor: AppColors.textPrimary,
                      elevation: 0,
                      shape: const StadiumBorder(),
                    ),
                  ),
                ),
                _action('guestbook', '방명록', onGuestbook),
                _action('shop', '상점', onShop),
                _action('mood', '무드레포트', onMood),
                _action('friends', '친구목록', onFriends),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _action(String asset, String label, VoidCallback? onPressed) {
    return Expanded(
      child: IconButton(
        tooltip: label,
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 0, minHeight: 48),
        icon: SvgPicture.asset(
          'assets/room/icons/$asset.svg',
          width: 46,
          height: 46,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
