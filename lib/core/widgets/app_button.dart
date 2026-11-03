import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';

enum AppButtonVariant { login, guest, primary }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    required this.variant,
    this.width = 207,
    this.height = 53,
    this.isLoading = false,
    this.backgroundColor,
    this.disabledBackgroundColor,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final double width;
  final double height;
  final bool isLoading;
  final Color? backgroundColor;
  final Color? disabledBackgroundColor;

  @override
  Widget build(BuildContext context) {
    final isLogin = variant == AppButtonVariant.login;

    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor:
              backgroundColor ??
              switch (variant) {
                AppButtonVariant.login => AppColors.loginButton,
                AppButtonVariant.guest => AppColors.guestButton,
                AppButtonVariant.primary => AppColors.primary,
              },
          foregroundColor: isLogin ? AppColors.white : AppColors.textPrimary,
          disabledBackgroundColor:
              disabledBackgroundColor ?? AppColors.disabled,
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(62),
          ),
        ),
        child: isLoading
            ? SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: isLogin ? AppColors.white : AppColors.textPrimary,
                ),
              )
            : Text(
                label,
                textAlign: TextAlign.center,
                style: AppTextStyles.button,
              ),
      ),
    );
  }
}
