import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme/app_colors.dart';
import 'signup_style.dart';

/// 회원가입 화면에서 쓰는 작은 부품들 (이슈 #44)
/// 제목, 설명 문구, 입력칸, 입력칸 안 버튼, 성별 선택 버튼

/// 제목 + 필수 표시(*). 입력칸 글자와 같은 위치에서 시작해요.
class SignupLabel extends StatelessWidget {
  const SignupLabel(this.text, {super.key, this.isRequired = true});

  final String text;
  final bool isRequired;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: SignupStyle.textInset),
      child: Text.rich(
        TextSpan(
          text: text,
          children: [
            if (isRequired)
              const TextSpan(
                text: ' *',
                style: TextStyle(color: SignupStyle.required),
              ),
          ],
        ),
        style: SignupStyle.label,
      ),
    );
  }
}

/// 입력칸 아래 설명 문구. 잘못 입력하면 색만 바꿔서 같은 자리에 보여줘요.
class SignupHelper extends StatelessWidget {
  const SignupHelper(this.text, {super.key, this.color});

  final String text;

  /// null이면 기본 회색
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: SignupStyle.textInset),
      child: Text(text, style: SignupStyle.helper.copyWith(color: color)),
    );
  }
}

/// 회원가입 입력칸: 높이 53, 양옆이 둥근 회색 칸
/// - [isPassword]: 글자를 가리고 오른쪽에 보이기/숨기기 눈 아이콘
/// - [trailing]: 오른쪽 끝에 붙는 버튼 (중복확인, 인증요청, 타이머+확인)
class SignupTextField extends StatefulWidget {
  const SignupTextField({
    super.key,
    required this.controller,
    required this.hintText,
    this.isPassword = false,
    this.enabled = true,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.trailing,
  });

  final TextEditingController controller;
  final String hintText;
  final bool isPassword;
  final bool enabled;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final Widget? trailing;

  @override
  State<SignupTextField> createState() => _SignupTextFieldState();
}

class _SignupTextFieldState extends State<SignupTextField> {
  bool _obscure = true; // 처음에는 비밀번호를 가려요.

  static const _iconSize = 20.0;

  @override
  Widget build(BuildContext context) {
    final hasEnd = widget.isPassword || widget.trailing != null;

    return Container(
      height: SignupStyle.controlHeight,
      decoration: BoxDecoration(
        color: SignupStyle.fieldBackground,
        borderRadius: BorderRadius.circular(SignupStyle.controlHeight / 2),
      ),
      child: Row(
        children: [
          const SizedBox(width: SignupStyle.textInset),
          Expanded(
            child: TextField(
              controller: widget.controller,
              enabled: widget.enabled,
              obscureText: widget.isPassword && _obscure,
              keyboardType: widget.keyboardType,
              textInputAction: widget.textInputAction,
              inputFormatters: widget.inputFormatters,
              autocorrect: false,
              enableSuggestions: false,
              // 줄 높이를 고정해서 글꼴이 달라도 칸 높이가 53으로 같아요.
              strutStyle: const StrutStyle(
                fontSize: 18,
                height: 22 / 18,
                forceStrutHeight: true,
              ),
              style: SignupStyle.fieldText.copyWith(
                color: widget.enabled ? null : SignupStyle.grayText,
              ),
              decoration: InputDecoration.collapsed(
                hintText: widget.hintText,
                hintStyle: SignupStyle.fieldHint,
              ),
            ),
          ),
          if (widget.isPassword)
            // 눈 아이콘 오른쪽 끝이 칸 끝에서 24가 되게 맞춰요.
            // (버튼 누르는 영역은 48이라 아이콘 바깥 14만큼 여유가 있어요.)
            Padding(
              padding: EdgeInsets.only(
                right: widget.trailing == null ? SignupStyle.textInset - 14 : 0,
              ),
              child: IconButton(
                tooltip: _obscure ? '비밀번호 보기' : '비밀번호 숨기기',
                icon: Icon(
                  _obscure
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: SignupStyle.grayText,
                  size: _iconSize,
                ),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
          if (widget.trailing != null) widget.trailing!,
          if (!hasEnd) const SizedBox(width: SignupStyle.textInset),
        ],
      ),
    );
  }
}

/// 입력칸 오른쪽 끝에 붙는 버튼 (중복확인, 인증요청, 확인)
/// - 기본: 흰 바탕 + 검정 테두리
/// - [filled]: 검정 바탕 + 흰 글자 (인증번호 확인)
class SignupInlineButton extends StatelessWidget {
  const SignupInlineButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.filled = false,
    this.isLoading = false,
  });

  final String label;

  /// null이면 비활성화 (흐리게, 안 눌림)
  final VoidCallback? onPressed;
  final bool filled;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !isLoading;
    final background = filled ? AppColors.authBlack : AppColors.white;
    final foreground = filled ? AppColors.white : AppColors.authBlack;

    return SizedBox(
      height: SignupStyle.controlHeight,
      child: OutlinedButton(
        onPressed: enabled ? onPressed : null,
        style: OutlinedButton.styleFrom(
          backgroundColor: background,
          foregroundColor: foreground,
          disabledBackgroundColor: background,
          disabledForegroundColor: foreground.withValues(alpha: 0.35),
          side: BorderSide(
            color: filled
                ? AppColors.authBlack
                : AppColors.authBlack.withValues(alpha: enabled ? 1 : 0.35),
          ),
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          minimumSize: const Size(0, SignupStyle.controlHeight),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          textStyle: SignupStyle.inlineButton,
        ),
        child: isLoading
            ? SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: foreground,
                ),
              )
            : Text(label),
      ),
    );
  }
}

/// 성별 같은 선택 버튼 (높이 53, 양옆 둥근 모양)
/// - 선택 안 함: 회색 바탕, 회색 글자
/// - 선택함: 흰 바탕, 검정 테두리, 검정 글자 (피그마 '선택했을 때')
class SignupChoiceButton extends StatelessWidget {
  const SignupChoiceButton({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? AppColors.white : SignupStyle.fieldBackground,
        shape: StadiumBorder(
          side: selected
              ? const BorderSide(color: AppColors.authBlack)
              : BorderSide.none,
        ),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: SizedBox(
            height: SignupStyle.controlHeight,
            child: Center(
              child: Text(
                label,
                style: SignupStyle.choice.copyWith(
                  color: selected ? AppColors.textPrimary : null,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
