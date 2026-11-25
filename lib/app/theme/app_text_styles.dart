import 'package:flutter/material.dart';

abstract final class AppTextStyles {
  static const fontFamily = 'Pretendard';
  static const head1 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 1.36,
    letterSpacing: -0.6,
  );
  static const head2 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.30,
    letterSpacing: -0.5,
  );
  static const head3 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w500,
    height: 1.44,
    letterSpacing: -0.45,
  );
  static const body1 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 1.20,
    letterSpacing: -0.4,
  );
  static const body2 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.20,
    letterSpacing: -0.4,
  );
  static const caption = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.15,
    letterSpacing: -0.35,
  );
  static const button = TextStyle(fontSize: 15, fontWeight: FontWeight.w600);
  static const buttonSmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
  );
}
