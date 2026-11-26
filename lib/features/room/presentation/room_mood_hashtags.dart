import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';

/// UI data, not a proposed backend response schema.
class RoomMoodHashtag {
  const RoomMoodHashtag({required this.categoryId, required this.text});
  final String categoryId;
  final String text;
}

/// Display only. Caller supplies category order and last valid analysis result.
class RoomMoodHashtags extends StatelessWidget {
  const RoomMoodHashtags({super.key, required this.tags});
  final List<RoomMoodHashtag> tags;
  @override
  Widget build(BuildContext context) {
    if (tags.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 44,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: tags.length > 5 ? 5 : tags.length,
        separatorBuilder: (_, _) => const SizedBox(width: 14),
        itemBuilder: (context, index) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AppColors.surfaceMuted),
            borderRadius: BorderRadius.circular(55),
          ),
          child: Text(
            '#${tags[index].text}',
            style: AppTextStyles.body2.copyWith(color: const Color(0xFF545454)),
          ),
        ),
      ),
    );
  }
}
