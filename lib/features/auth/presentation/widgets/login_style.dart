import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';

/// 로그인 화면 디자인 값 (이슈 #38, 피그마 '프론트 분들 수정사항 참고')
/// 피그마의 pt는 Flutter에서 같은 숫자로 써요. 자간 -2.5% = 글자 크기 × -0.025
abstract final class LoginStyle {
  // ───────── 색 (로그인 화면에서만 써서 AppColors에 넣지 않았어요) ─────────

  /// 입력창 힌트 글자
  static const hintColor = Color(0xFF6E6E6E);

  /// 'SNS 간편 로그인', '계정이 없으신가요?' 회색 글자
  static const grayText = Color(0xFF747474);

  // ───────── 크기 ─────────

  static const backIconSize = 36.0;
  static const logoWidth = 250.0;
  static const logoHeight = 49.0;
  static const kakaoButtonSize = 54.0;

  /// 아이디·비밀번호 입력창과 로그인 버튼 높이
  static const controlHeight = 53.0;

  /// 입력창 글자 한 줄 높이 (글자 18 기준)
  static const fieldLineHeight = 22.0;

  // ───────── 여백 ─────────

  static const backToLogo = 45.0;
  static const logoToIntro = 16.0;
  static const introToId = 48.0;
  static const idToPassword = 6.0;
  static const passwordToFind = 14.0;
  static const findToLogin = 20.0;
  static const loginToSns = 52.0;
  static const snsToKakao = 24.0;
  static const kakaoToSignUp = 59.0;

  // ───────── 글자 ─────────

  static TextStyle _style(
    double size,
    FontWeight weight, {
    Color color = AppColors.textPrimary,
    double? height,
  }) => TextStyle(
    fontSize: size,
    fontWeight: weight,
    letterSpacing: size * -0.025,
    color: color,
    height: height,
  );

  /// 소개 문구: Medium 18, #000000
  static final intro = _style(
    18,
    FontWeight.w500,
    color: AppColors.black,
    height: 1.4,
  );

  /// 입력한 글자 (줄 높이 고정: 입력창 높이 53 계산에 써요)
  static final fieldText = _style(
    18,
    FontWeight.w400,
    height: fieldLineHeight / 18,
  );

  /// 입력창 힌트: Regular 18, #6E6E6E
  static final fieldHint = _style(
    18,
    FontWeight.w400,
    color: hintColor,
    height: fieldLineHeight / 18,
  );

  /// '아이디·비밀번호 찾기': Medium 14
  static final findAccount = _style(14, FontWeight.w500);

  /// 로그인 버튼 글자: Medium 18
  /// 색은 넣지 않아요. 버튼이 켜졌을 때(흰 글자)·꺼졌을 때 색을 버튼이 정해요.
  static const loginButton = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    letterSpacing: 18 * -0.025,
  );

  /// 'SNS 간편 로그인': Regular 16, #747474
  static final sns = _style(16, FontWeight.w400, color: grayText);

  /// '계정이 없으신가요?': Regular 14, #747474
  static final signUpQuestion = _style(14, FontWeight.w400, color: grayText);

  /// '회원가입': 같은 크기, 굵게 (피그마 화면 기준)
  static final signUpLink = _style(14, FontWeight.w700);
}
