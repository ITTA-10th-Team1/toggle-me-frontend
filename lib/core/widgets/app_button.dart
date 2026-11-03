import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

enum AppButtonVariant { login, guest }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    required this.variant,
    this.width = 207,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final double width;

  @override
  Widget build(BuildContext context) {
    final isLogin = variant == AppButtonVariant.login;

    return SizedBox(
      width: width,
      height: 53,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isLogin
              ? AppColors.loginButton
              : AppColors.guestButton,
          foregroundColor: isLogin ? AppColors.white : AppColors.textPrimary,
          disabledBackgroundColor: AppColors.disabled,
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(62),
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
