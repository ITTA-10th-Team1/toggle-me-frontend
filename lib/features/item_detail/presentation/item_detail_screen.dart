import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/app_notice.dart';
import '../../../core/widgets/room_mode_toggle.dart';
import 'providers/item_detail_provider.dart';
import '../data/item_detail_model.dart';

class ItemDetailScreen extends ConsumerStatefulWidget {
  const ItemDetailScreen({super.key, required this.itemId});

  final int itemId;

  @override
  ConsumerState<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends ConsumerState<ItemDetailScreen> {
  bool _isRecommendationExpanded = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(itemDetailProvider.notifier).fetchDetail(widget.itemId),
    );
  }

  Future<void> _deleteItem() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.background,
        title: const Text('아이템을 삭제할까요?'),
        content: const Text('삭제한 아이템은 다시 복구할 수 없어요.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text(
              '취소',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text(
              '삭제하기',
              style: TextStyle(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );

    if (shouldDelete != true || !mounted) return;

    final success = await ref
        .read(itemDetailProvider.notifier)
        .deleteItem(widget.itemId);

    if (!mounted) return;

    if (success) {
      context.pop(true);
    } else {
      final message = ref.read(itemDetailProvider).errorMessage ?? '삭제에 실패했어요.';
      showAppNotice(context, message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(itemDetailProvider);

    return PopScope(
      canPop: !state.isDeleting,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(state.isDeleting),
              Expanded(child: _buildBody(state)),
              if (state.item != null)
                Container(
                  color: AppColors.background,
                  child: _buildBottomButtons(state.isDeleting),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDeleting) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 8),
      child: Row(
        children: [
          const Spacer(),
          Material(
            color: AppColors.darkIvory,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: isDeleting ? null : () => context.pop(),
              child: SizedBox(
                width: 32,
                height: 32,
                child: Center(
                  child: SvgPicture.asset(
                    'assets/images/img_common_cancel.svg',
                    width: 18,
                    height: 18,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(ItemDetailState state) {
    if (state.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (state.item == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '아이템을 불러오지 못했어요.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => ref
                  .read(itemDetailProvider.notifier)
                  .fetchDetail(widget.itemId),
              child: const Text('다시 시도'),
            ),
          ],
        ),
      );
    }

    final item = state.item!;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildItemImage(item.imageUrl),
          const SizedBox(height: 18),
          _buildMemoSection(item.memo),
          const SizedBox(height: 18),
          _buildTagSection(item.tags),
          const SizedBox(height: 18),
          _buildVisibilitySection(item.isPublic),
          const SizedBox(height: 18),
          _buildRecommendationSection(item.furnitureTypeId, item.id, state),
        ],
      ),
    );
  }

  Widget _buildItemImage(String imageUrl) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(15),
      child: AspectRatio(
        aspectRatio: 326.6279296875 / 435.50390625,
        child: imageUrl.isEmpty
            ? _imagePlaceholder()
            : Image.network(
                imageUrl,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _imagePlaceholder(),
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return _imagePlaceholder(
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }

  Widget _imagePlaceholder({Widget? child}) {
    return Container(
      color: const Color(0xFFD9D9D9),
      child:
          child ??
          const Center(
            child: Icon(
              Icons.image_not_supported_outlined,
              color: AppColors.textHint,
              size: 32,
            ),
          ),
    );
  }

  Widget _buildMemoSection(String? memo) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('메모'),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 42),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            memo == null || memo.trim().isEmpty ? '작성된 메모가 없어요.' : memo,
            style: const TextStyle(
              fontSize: 12,
              height: 1.4,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTagSection(List<String> tags) {
    return Wrap(
      spacing: 7,
      runSpacing: 7,
      children: tags.isEmpty
          ? [_tagChip('#', enabled: false)]
          : tags.map((tag) => _tagChip('#$tag')).toList(),
    );
  }

  Widget _tagChip(String label, {bool enabled = true}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.darkIvory,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: enabled ? const Color(0xFF4B4540) : AppColors.textHint,
        ),
      ),
    );
  }

  Widget _buildVisibilitySection(bool isPublic) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '취향 공개 여부',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'On: 친구에게 공개  Off: 나만 보기',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          RoomModeToggle(isOn: isPublic, onChanged: null),
        ],
      ),
    );
  }

  Widget _buildRecommendationSection(
    int furnitureTypeId,
    int itemId,
    ItemDetailState state,
  ) {
    // 냉장고(furnitureTypeId: 2)만 AI 음식 추천 대상
    if (furnitureTypeId != 2) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () {
            final shouldExpand = !_isRecommendationExpanded;

            setState(() {
              _isRecommendationExpanded = shouldExpand;
            });

            if (shouldExpand) {
              ref
                  .read(itemDetailProvider.notifier)
                  .fetchRecommendations(itemId);
            }
          },
          child: Row(
            children: [
              const Text(
                'AI가 추천하는 음식',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                _isRecommendationExpanded
                    ? Icons.keyboard_arrow_up
                    : Icons.keyboard_arrow_down,
                size: 20,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
        if (_isRecommendationExpanded) ...[
          const SizedBox(height: 10),

          if (state.isLoadingRecommendations)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            )
          else if (state.recommendationError != null)
            Center(
              child: Column(
                children: [
                  const Text(
                    '음식 추천을 불러오지 못했어요.',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  TextButton(
                    onPressed: () => ref
                        .read(itemDetailProvider.notifier)
                        .fetchRecommendations(itemId),
                    child: const Text(
                      '다시 시도',
                      style: TextStyle(color: AppColors.primary),
                    ),
                  ),
                ],
              ),
            )
          else if (state.recommendations.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  '추천할 음식이 없어요.',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            )
          else
            SizedBox(
              height: 180,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: state.recommendations.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  return _buildRecommendationCard(state.recommendations[index]);
                },
              ),
            ),
        ],
      ],
    );
  }

  Widget _buildRecommendationCard(ItemRecommendationModel item) {
    return SizedBox(
      width: 108,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 108.66 / 144.876,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: item.imageUrl == null || item.imageUrl!.isEmpty
                  ? _imagePlaceholder()
                  : Image.network(
                      item.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _imagePlaceholder(),
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return _imagePlaceholder(
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: AppColors.primary,
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            item.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButtons(bool isDeleting) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: Row(
        children: [
          Expanded(
            flex: 10,
            child: OutlinedButton(
              onPressed: isDeleting ? null : _deleteItem,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(44),
                backgroundColor: AppColors.buttonSecondary,
                foregroundColor: AppColors.textSecondary,
                side: const BorderSide(color: AppColors.border, width: 0.7),
                shape: const StadiumBorder(),
              ),
              child: isDeleting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('삭제하기', style: TextStyle(fontSize: 12)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 13,
            child: ElevatedButton(
              onPressed: null,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(44),
                backgroundColor: AppColors.roomAccent,
                disabledBackgroundColor: AppColors.roomAccent,
                disabledForegroundColor: AppColors.black,
                foregroundColor: AppColors.black,
                shape: const StadiumBorder(),
                elevation: 0,
              ),
              child: const Text(
                '핀보드에 배치',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }
}
