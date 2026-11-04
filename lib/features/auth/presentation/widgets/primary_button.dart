import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';

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
    height: 52,
    isLoading: isLoading,
    backgroundColor: AppColors.loginButton,
    disabledBackgroundColor: AppColors.disabled,
  );
}
