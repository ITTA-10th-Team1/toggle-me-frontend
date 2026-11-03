import 'package:flutter/material.dart';

abstract final class AppColors {
  static const Color primary = Color(0xFFFF9638);

  static const Color textPrimary = Color(0xFF171717);
  static const Color white = Color(0xFFFFFFFF);
  static const Color disabled = Color(0xFFE0E0E0);

  static const Color guestButton = Color(0x99FFFFFF);
  static const Color loginButton = textPrimary;

  static const Color toggleOn = primary;
  static const Color toggleOff = Color(0xFF777777);
  static const Color roomBackground = Color(0xFFFFFAF1);
  static const Color surfaceMuted = Color(0xFFF8F0E5);
  static const Color textMuted = toggleOff;
  static const Color textSecondary = Color(0xFF616161);
  static const Color onboardingTextSecondary = Color(0xFF292929);
  static const Color textHint = hint;
  static const Color inputBackground = fieldBackground;
  static const Color fieldBackground = Color(0xFFF5F5F5);
  static const Color hint = Color(0xFF9E9E9E);
  static const Color subText = Color(0xFF616161);
  static const Color border = disabled;
  // Current screen-specific shades; retain until design confirms one palette.
  static const Color roomAccent = Color(0xFFFF813B);
  static const Color authAccent = Color(0xFFF07B3F);
  static const Color authBlack = Color(0xFF1A1A1A);
  static const Color authDisabled = Color(0x991A1A1A);
  static const Color guestBackground = Color(0xFFFFF9EF);
  static const Color guestAccent = Color(0xFFFF883F);
  static const Color kakao = Color(0xFFFEE500);
  static const Color naver = Color(0xFF03C75A);
  static const Color google = Color(0xFF4285F4);
  static const Color onboardingTop = Color(0xFFFFFDF0);
  static const Color onboardingUpper = Color(0xFFFFF4B3);
  static const Color onboardingLower = Color(0xFFFFD58E);
  static const Color onboardingBottom = Color(0xFFFFA06E);
  static const Color roomOffOverlay = Color(0xCC171717);
}
