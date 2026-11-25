import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import 'login_style.dart';

/// Compatibility wrapper around the shared button; existing callers unchanged.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
  });
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  @override
  Widget build(BuildContext context) => AppButton(
    label: text,
    onPressed: onPressed,
    variant: AppButtonVariant.login,
    width: double.infinity,
    height: LoginStyle.controlHeight, // 이슈 #38: 53
    isLoading: isLoading,
    textStyle: LoginStyle.loginButton, // Medium 18, 자간 -2.5%
    backgroundColor: AppColors.loginButton,
    disabledBackgroundColor: AppColors.disabled,
  );
}
