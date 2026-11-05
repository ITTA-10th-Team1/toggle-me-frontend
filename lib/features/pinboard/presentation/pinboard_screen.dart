import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../app/theme/app_colors.dart';

class PinboardScreen extends StatelessWidget {
  const PinboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 핀보드 배경
          Image.asset(
            'assets/images/img_pinboard_background.png',
            fit: BoxFit.cover,
          ),

          SafeArea(
            child: Stack(
              children: [
                // 뒤로가기 버튼
                Positioned(
                  top: 12,
                  left: 16,
                  child: GestureDetector(
                    onTap: () => context.pop(),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: AppColors.iconButtonBackground,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: SvgPicture.asset(
                          'assets/images/img_common_back.svg',
                          width: 24,
                          height: 24,
                        ),
                      ),
                    ),
                  ),
                ),

                // 핀보드 꾸미기 버튼
                Positioned(
                  top: 12,
                  right: 16,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: AppColors.iconButtonBackground,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: SvgPicture.asset(
                        'assets/images/img_pinboard_fin.svg',
                        width: 24,
                        height: 24,
                      ),
                    ),
                  ),
                ),

                // 피드 목록 이동 버튼
                Positioned(
                  top: 64,
                  right: 16,
                  child: GestureDetector(
                    onTap: () => context.push(AppRoutes.items),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: AppColors.iconButtonBackground,
                        shape: BoxShape.circle,
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _MenuLine(),
                          SizedBox(height: 4),
                          _MenuLine(),
                          SizedBox(height: 4),
                          _MenuLine(),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuLine extends StatelessWidget {
  const _MenuLine();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 17,
      height: 2,
      decoration: BoxDecoration(
        color: AppColors.textPrimary,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
