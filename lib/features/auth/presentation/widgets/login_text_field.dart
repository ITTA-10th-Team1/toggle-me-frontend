import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme/app_colors.dart';
import 'login_style.dart';

/// 로그인 화면 전용 입력창 (이슈 #38 디자인 수정사항)
/// - 높이 53, 로그인 버튼처럼 양옆이 둥근 모양
/// - 안쪽 좌우 여백 24 (왼쪽 아이콘, 오른쪽 눈 아이콘까지)
/// - 힌트 Regular 18, #6E6E6E, 자간 -2.5%
/// 팀 공통 AppTextField(lib/core)는 건드리지 않으려고 따로 만들었어요.
class LoginTextField extends StatefulWidget {
  const LoginTextField({
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

  static const height = 53.0;
  static const horizontalPadding = 24.0;

  final TextEditingController controller;
  final String hintText;
  final IconData icon;

  /// true면 글자를 가리고, 오른쪽에 보이기/숨기기 눈 아이콘이 생겨요.
  final bool isPassword;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;

  @override
  State<LoginTextField> createState() => _LoginTextFieldState();
}

class _LoginTextFieldState extends State<LoginTextField> {
  bool _obscure = true; // 화면설계서 5-1: 최초 진입 시 숨김

  static const _iconSize = 20.0;

  /// 한 줄 높이 22 (글자 18). 소수점이 생기면 화면에서 반올림돼 높이가 어긋나서 정수로 맞췄어요.
  static const _lineHeight = LoginStyle.fieldLineHeight;
  static const _verticalPadding = (LoginTextField.height - _lineHeight) / 2;

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(LoginTextField.height / 2),
      borderSide: BorderSide.none,
    );

    return TextFormField(
      controller: widget.controller,
      obscureText: widget.isPassword && _obscure,
      validator: widget.validator,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      inputFormatters: widget.inputFormatters,
      autocorrect: false,
      enableSuggestions: false,
      textAlignVertical: TextAlignVertical.center,
      strutStyle: const StrutStyle(
        fontSize: 18,
        height: LoginStyle.fieldLineHeight / 18,
        forceStrutHeight: true,
      ),
      style: LoginStyle.fieldText,
      decoration: InputDecoration(
        hintText: widget.hintText,
        hintStyle: LoginStyle.fieldHint,
        // 왼쪽 아이콘: 칸 끝에서 24 떨어진 곳에 놓아요.
        prefixIcon: Padding(
          padding: const EdgeInsets.only(
            left: LoginTextField.horizontalPadding,
            right: 12,
          ),
          child: Icon(widget.icon, color: AppColors.hint, size: _iconSize),
        ),
        prefixIconConstraints: const BoxConstraints(),
        // 오른쪽 눈 아이콘: 아이콘 오른쪽 끝이 칸 끝에서 24가 되게 맞춰요.
        // (버튼 누르는 영역은 48이라 아이콘 바깥 14만큼 여유가 있어요.)
        suffixIcon: widget.isPassword
            ? Padding(
                padding: const EdgeInsets.only(
                  right: LoginTextField.horizontalPadding - 14,
                ),
                child: IconButton(
                  tooltip: _obscure ? '비밀번호 보기' : '비밀번호 숨기기',
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: AppColors.hint,
                    size: _iconSize,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              )
            : null,
        suffixIconConstraints: const BoxConstraints(),
        filled: true,
        fillColor: AppColors.fieldBackground,
        isDense: true,
        // 칸 높이 53 = 글자 줄 높이(22) + 위아래 여백(15.5씩).
        // 줄 높이를 strutStyle로 고정해서, 글꼴이 달라도 높이가 53으로 같아요.
        contentPadding: const EdgeInsets.fromLTRB(
          0,
          _verticalPadding,
          LoginTextField.horizontalPadding,
          _verticalPadding,
        ),
        border: border,
        enabledBorder: border,
        focusedBorder: border.copyWith(
          borderSide: const BorderSide(color: AppColors.primary),
        ),
        errorBorder: border.copyWith(
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        focusedErrorBorder: border.copyWith(
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
      ),
    );
  }
}
