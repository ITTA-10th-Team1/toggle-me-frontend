import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';

/// 동그란 프로필 사진 (화면설계서 4-1)
/// 사진 주소가 없거나, 불러오는 중이거나, 불러오기에 실패하면 기본 이미지를 보여줘요.
class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({super.key, required this.imageUrl, this.size = 48});

  final String? imageUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl;

    return ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: url == null
            ? _defaultImage()
            : Image.network(
                url,
                fit: BoxFit.cover,
                // 불러오는 동안에도 기본 이미지를 보여줘요.
                loadingBuilder: (context, child, progress) =>
                    progress == null ? child : _defaultImage(),
                // 인터넷 문제 등으로 실패하면 기본 이미지
                errorBuilder: (context, error, stackTrace) => _defaultImage(),
              ),
      ),
    );
  }

  // TODO(design): 디자이너 기본 프로필 이미지가 나오면 교체
  Widget _defaultImage() {
    return ColoredBox(
      color: AppColors.inputBackground,
      child: Icon(Icons.person, size: size * 0.6, color: AppColors.textHint),
    );
  }
}
