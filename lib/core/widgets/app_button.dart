import 'package:flutter/material.dart';

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
              ? const Color(0xFF171717)
              : const Color(0x99FFFFFF),
          foregroundColor: const Color(0xFF171717),
          disabledBackgroundColor: const Color(0xFFE0E0E0),
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
          style: TextStyle(
            color: isLogin ? Colors.white : const Color(0xFF171717),
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
