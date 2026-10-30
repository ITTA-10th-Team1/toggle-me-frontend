import 'package:flutter/material.dart';

import '../auth_colors.dart';

/// 카카오 / 네이버 / 구글 동그라미 버튼.
/// 카카오는 이미지 버튼, 네이버·구글은 이미지가 없어서 임시로 글자를 넣었어요.
/// 이미지를 받으면 카카오처럼 Image.asset(...)으로 바꾸면 돼요.
enum SocialType { kakao, naver, google }

class SocialLoginButton extends StatelessWidget {
  const SocialLoginButton({
    super.key,
    required this.type,
    required this.onPressed,
  });

  final SocialType type;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    // 카카오는 디자인 이미지(배경+아이콘 포함)를 그대로 써요. 피그마 기준 52x52.
    if (type == SocialType.kakao) {
      return InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: Image.asset(
          'assets/images/kakao_button.png',
          width: 52,
          height: 52,
          semanticLabel: '카카오 로그인',
        ),
      );
    }

    return InkWell(
      onTap: onPressed,
      customBorder: const CircleBorder(),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _backgroundColor,
          border: type == SocialType.google
              ? Border.all(color: AuthColors.border)
              : null,
        ),
        alignment: Alignment.center,
        child: _icon,
      ),
    );
  }

  Color get _backgroundColor {
    switch (type) {
      case SocialType.kakao:
        return AuthColors.kakao;
      case SocialType.naver:
        return AuthColors.naver;
      case SocialType.google:
        return Colors.white;
    }
  }

  Widget get _icon {
    switch (type) {
      case SocialType.kakao:
        return const Icon(Icons.chat_bubble, color: Colors.black87, size: 20);
      case SocialType.naver:
        return const Text(
          'N',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        );
      case SocialType.google:
        return const Text(
          'G',
          style: TextStyle(
            color: Color(0xFF4285F4),
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        );
    }
  }
}
