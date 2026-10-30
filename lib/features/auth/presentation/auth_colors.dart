import 'package:flutter/material.dart';

/// 로그인 화면에서만 임시로 쓰는 색상 모음.
///
/// 공통 테마(lib/app/theme/app_theme.dart)에는 아직 같은 색이 없어서 여기에 둬요.
/// 팀 공통 테마와 피그마 '컬러팔레트'가 확정되면 그 색으로 바꾸고 이 파일은 지워주세요.
class AuthColors {
  AuthColors._();

  static const Color primary = Color(0xFFF07B3F); // 주황 (기록하기 버튼 등)
  static const Color black = Color(0xFF1A1A1A); // 로그인 버튼
  static const Color fieldBackground = Color(0xFFF5F5F5); // 입력창 배경
  static const Color hint = Color(0xFF9E9E9E); // 입력창 안내 문구, 아이콘
  static const Color subText = Color(0xFF616161); // 보조 설명 글씨
  static const Color border = Color(0xFFE0E0E0); // 테두리

  // 소셜 로그인
  static const Color kakao = Color(0xFFFEE500);
  static const Color naver = Color(0xFF03C75A);
}
