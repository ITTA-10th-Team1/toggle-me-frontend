import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../app/theme/app_colors.dart';

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
            builder: (context, constraints) => SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: constraints.maxWidth < 314 ? 314 : constraints.maxWidth,
                child: Row(
                  children: [
                    SizedBox(
                      width:
                          (constraints.maxWidth < 314
                              ? 314
                              : constraints.maxWidth) -
                          204,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: onRecord,

                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          backgroundColor: AppColors.roomAccent,
                          foregroundColor: AppColors.textPrimary,
                          elevation: 0,
                          shape: const StadiumBorder(),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add, size: 20),
                            SizedBox(width: 10),
                            Text(
                              '기록하기',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                letterSpacing: -0.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 5),
                    _action('guestbook', '방명록', onGuestbook),
                    const SizedBox(width: 5),
                    _action('shop', '상점', onShop),
                    const SizedBox(width: 5),
                    _action('mood', '무드레포트', onMood),
                    const SizedBox(width: 5),
                    _action('friends', '친구목록', onFriends),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _action(String asset, String label, VoidCallback? onPressed) {
    return SizedBox(
      width: 46,
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
