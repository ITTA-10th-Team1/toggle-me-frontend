import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../data/models/social_user.dart';
import 'profile_avatar.dart';

/// 친구 목록 카드 한 장: 프로필 사진 + 닉네임 + @아이디 + 놀러가기 버튼 (화면설계서 4, 5번)
/// isVisiting이 true면 버튼에 로딩 표시가 나오고 눌리지 않아요. (중복 클릭 방지)
class FriendListTile extends StatelessWidget {
  const FriendListTile({
    super.key,
    required this.user,
    required this.onVisit,
    this.isVisiting = false,
  });

  final SocialUser user;
  final VoidCallback? onVisit;
  final bool isVisiting;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          ProfileAvatar(imageUrl: user.profileImageUrl, size: 60),
          const SizedBox(width: 16),
          // 닉네임과 아이디는 남는 공간을 다 쓰고, 길면 '...'으로 줄여요.
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.nickname,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '@${user.handle}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppColors.textHint,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _VisitButton(onPressed: onVisit, isLoading: isVisiting),
        ],
      ),
    );
  }
}

/// 놀러가기 버튼: 연한 살구색 배경 + 주황 테두리
class _VisitButton extends StatelessWidget {
  const _VisitButton({required this.onPressed, required this.isLoading});

  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 110,
      height: 44,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryLight,
          foregroundColor: AppColors.textPrimary,
          // 로딩 중(눌리지 않는 상태)에도 같은 색을 유지해서 깜빡이지 않게 해요.
          disabledBackgroundColor: AppColors.primaryLight,
          elevation: 0,
          padding: EdgeInsets.zero,
          side: const BorderSide(color: AppColors.primary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
              )
            : const Text('놀러가기', style: TextStyle(fontSize: 15)),
      ),
    );
  }
}
