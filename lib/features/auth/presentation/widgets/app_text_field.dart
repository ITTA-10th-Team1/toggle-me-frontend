import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../auth_colors.dart';

/// 회색 둥근 배경 + 왼쪽 아이콘이 있는 입력창.
/// isPassword: true 로 주면 오른쪽에 눈 아이콘(보이기/숨기기)이 생겨요.
class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.icon,
    this.isPassword = false,
    this.validator,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
  });

  final TextEditingController controller;
  final String hintText;
  final IconData icon;
  final bool isPassword;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;

  /// 입력할 수 있는 글자를 제한할 때 사용해요. (예: 소문자·숫자만)
  final List<TextInputFormatter>? inputFormatters;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    );

    return TextFormField(
      controller: widget.controller,
      obscureText: widget.isPassword && _obscure,
      validator: widget.validator,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      inputFormatters: widget.inputFormatters,
      // 키보드 자동 수정·추천 단어가 글자를 멋대로 바꾸지 않게 꺼둬요.
      autocorrect: false,
      enableSuggestions: false,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        hintText: widget.hintText,
        hintStyle: const TextStyle(color: AuthColors.hint, fontSize: 14),
        prefixIcon: Icon(widget.icon, color: AuthColors.hint, size: 20),
        suffixIcon: widget.isPassword
            ? IconButton(
                icon: Icon(
                  _obscure
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: AuthColors.hint,
                  size: 20,
                ),
                onPressed: () => setState(() => _obscure = !_obscure),
              )
            : null,
        filled: true,
        fillColor: AuthColors.fieldBackground,
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
        border: border,
        enabledBorder: border,
        focusedBorder: border.copyWith(
          borderSide: const BorderSide(color: AuthColors.primary),
        ),
      ),
    );
  }
}
