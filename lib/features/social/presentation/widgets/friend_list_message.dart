import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';

/// 목록 대신 가운데에 보여주는 안내 문구 (정책 6, 8)
/// - 검색 결과 없음: FriendListMessage(message: '검색 결과가 없어요.')
/// - 불러오기 실패: actionLabel: '다시 시도', onAction을 주면 버튼이 생겨요.
class FriendListMessage extends StatelessWidget {
  const FriendListMessage({
    super.key,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final label = actionLabel;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            if (label != null && onAction != null) ...[
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: onAction,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textPrimary,
                  side: const BorderSide(color: AppColors.border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Text(label),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
