import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';

/// 친구 목록 검색창 (화면설계서 3번): 흰색 알약 모양 + 옅은 테두리
/// 글자가 바뀔 때마다 onChanged를 불러요. 0.3초 기다리는 처리(debounce)는 화면에서 해요.
/// 글자가 있으면 오른쪽에 X 버튼이 생기고, 누르면 지운 뒤 onChanged('')를 불러요.
class FriendSearchBar extends StatelessWidget {
  const FriendSearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(22),
      borderSide: const BorderSide(color: AppColors.border),
    );

    return TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      autocorrect: false,
      enableSuggestions: false,
      style: const TextStyle(fontSize: 15),
      decoration: InputDecoration(
        hintText: '아이디 검색',
        hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 15),
        prefixIcon: const Icon(
          Icons.search,
          color: AppColors.textHint,
          size: 22,
        ),
        // 글자가 있을 때만 X 버튼을 보여줘요.
        // ValueListenableBuilder: controller 글자가 바뀌면 이 부분만 다시 그려요.
        suffixIcon: ValueListenableBuilder<TextEditingValue>(
          valueListenable: controller,
          builder: (context, value, child) {
            if (value.text.isEmpty) return const SizedBox.shrink();
            return IconButton(
              tooltip: '검색어 지우기',
              icon: const Icon(
                Icons.cancel,
                color: AppColors.textHint,
                size: 20,
              ),
              onPressed: () {
                controller.clear();
                onChanged('');
              },
            );
          },
        ),
        filled: true,
        fillColor: AppColors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        border: border,
        enabledBorder: border,
        focusedBorder: border.copyWith(
          borderSide: const BorderSide(color: AppColors.primary),
        ),
      ),
    );
  }
}
