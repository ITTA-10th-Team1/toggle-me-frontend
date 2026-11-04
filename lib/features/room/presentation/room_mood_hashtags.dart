import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';

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
      height: 36,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: tags.length > 5 ? 5 : tags.length,
        separatorBuilder: (_, _) => const SizedBox(width: 7),
        itemBuilder: (context, index) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(55),
          ),
          child: Text(
            '#${tags[index].text}',
            style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
          ),
        ),
      ),
    );
  }
}
