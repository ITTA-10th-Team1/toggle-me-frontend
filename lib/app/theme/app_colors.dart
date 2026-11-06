import 'package:flutter/material.dart';

abstract final class AppColors {
  static const Color primary = Color(0xFFFF9638);

  static const Color textPrimary = Color(0xFF171717);
  static const Color textSecondary = Color(0xFF545454);
  static const Color black = Color(0xFF000000);
  static const Color white = Color(0xFFFFFFFF);

  static const Color background = Color(0xFFFFF9F0);
  static const Color uploadBackground = Color(0xFFFFE8DC);
  static const Color border = Color(0xFFD3D3D3);
  static const Color buttonSecondary = Color(0xFFF5F5F5);
  static const Color chipBackground = Color(0xFFF5F0E8);
  static const Color onboardingTextSecondary = Color(0xFF292929);

  static const Color disabled = Color(0xFFE0E0E0);

  static const Color guestButton = Color(0x99FFFFFF);
  static const Color loginButton = textPrimary;

  static const Color toggleOn = Color(0xFFFF813B);
  static const Color toggleOnBorder = Color(0xFF623015);
  static const Color toggleOffTrack = Color(0xFFA1ABB7);
  static const Color toggleOffThumb = Color(0xFF00152D);
  static const Color toggleOffBorder = Color(0xFF626A74);
  static const Color toggleOff = Color(0xFF777777);
  static const Color darkIvory = Color(0xFFF8F0E5);
  static const Color textHint = Color(0xFF9E9E9E);
  static const Color inputBackground = Color(0xFFF5F5F5);

  // Room
  static const Color roomBackground = Color(0xFFFFFAF1);
  static const Color surfaceMuted = Color(0xFFF8F0E5);
  static const Color textMuted = toggleOff;
  static const Color fieldBackground = Color(0xFFF5F5F5);
  static const Color hint = Color(0xFF9E9E9E);
  static const Color subText = Color(0xFF616161);

  // Screen-specific colors
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

  // 화면 배경 그라데이션 (친구 목록 등)
  static const Color backgroundGradientTop = Color(0xFFFFFBF6);
  static const Color backgroundGradientBottom = Color(0xFFFCE8DA);

  // 동그란 아이콘 버튼 배경 (뒤로가기 등)
  static const Color iconButtonBackground = Color(0xFFF3EEE6);

  // 연한 주황 버튼 배경 (놀러가기 등)
  static const Color primaryLight = Color(0xFFFCDCC6);
}
