import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import 'login_style.dart';

/// 회원가입 화면 디자인 값 (이슈 #44, 피그마 'Android_앱 내 회원가입')
/// 모든 입력칸·버튼 높이는 53, 자간 -2.5% = 글자 크기 × -0.025
abstract final class SignupStyle {
  // ───────── 색 ─────────

  /// 힌트·설명 문구·선택 안 한 버튼 글자: #6E6E6E
  static const grayText = LoginStyle.hintColor;

  /// 필수 입력 표시(*): #FF813B
  static const required = Color(0xFFFF813B);

  /// 인증 타이머 글자 (피그마의 주황색)
  static const timer = Color(0xFFFF813B);

  /// 입력칸·선택 안 한 버튼 배경
  static const fieldBackground = AppColors.fieldBackground;

  /// 잘못 입력했을 때 안내 글자
  // TODO(design): 오류·성공 안내 색은 피그마에 없어서 임시. 디자이너 확인 필요
  static const error = Colors.redAccent;

  /// 성공 안내 글자 (사용 가능한 아이디, 인증 완료)
  static const success = Color(0xFF2E9E5B);

  // ───────── 크기 ─────────

  /// 입력칸·버튼 높이
  static const controlHeight = LoginStyle.controlHeight;

  /// 상단 바 높이
  static const topBarHeight = 52.0;

  /// 화면 양옆 여백 (피그마 화면에서 잰 값)
  static const screenPadding = 12.0;

  /// 입력칸 안쪽 글자 시작 위치. 제목·설명 문구도 같은 위치에서 시작해요.
  /// (피그마: 타이틀을 입력칸의 맨 끝에 맞추지 않기)
  static const textInset = 24.0;

  /// 생년월일 펼친 목록 아래쪽 둥근 정도
  static const menuRadius = 15.0;

  // ───────── 여백 (피그마 표시 색) ─────────

  /// 상단 바 → 첫 제목 (주황 22)
  static const barToLabel = 22.0;

  /// 제목 → 입력칸 (빨강 8)
  static const labelToField = 8.0;

  /// 입력칸 → 설명 문구 (파랑 6)
  static const fieldToHelper = 6.0;

  /// 설명 문구(또는 입력칸) → 다음 제목 (보라 32)
  static const sectionGap = 32.0;

  /// 입력칸 → 입력칸 (초록 10)
  static const fieldToField = 10.0;

  /// 나란히 있는 버튼 사이 (검정 6)
  static const buttonGap = 6.0;

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

  /// 상단 바 '회원가입'
  static final title = _style(18, FontWeight.w600);

  /// 제목 (닉네임, 성별 …): Medium 18
  static final label = _style(18, FontWeight.w500);

  /// 설명 문구: Regular 14, #6E6E6E
  static final helper = _style(14, FontWeight.w400, color: grayText);

  /// 입력한 글자 (입력칸 높이를 맞추려고 줄 높이 고정)
  static final fieldText = LoginStyle.fieldText;

  /// 입력칸 힌트: Regular 18, #6E6E6E
  static final fieldHint = LoginStyle.fieldHint;

  /// 성별 버튼 글자: Regular 18
  static final choice = _style(18, FontWeight.w400, color: grayText);

  /// 생년월일 선택값·목록: Regular 18
  static final dropdown = _style(18, FontWeight.w400);

  /// 입력칸 안 작은 버튼 (중복확인, 인증요청, 확인)
  static final inlineButton = _style(16, FontWeight.w500);

  /// 인증 타이머
  static final timerText = _style(16, FontWeight.w500, color: timer);
}
