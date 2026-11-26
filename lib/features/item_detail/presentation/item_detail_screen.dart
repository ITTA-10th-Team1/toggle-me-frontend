import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/app_notice.dart';
import '../../../core/widgets/room_mode_toggle.dart';
import 'providers/item_detail_provider.dart';
import '../data/item_detail_model.dart';

import 'package:url_launcher/url_launcher.dart';

class ItemDetailScreen extends ConsumerStatefulWidget {
  const ItemDetailScreen({super.key, required this.itemId});

  final int itemId;

  @override
  ConsumerState<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends ConsumerState<ItemDetailScreen> {
  bool _isRecommendationExpanded = false;
  final TextEditingController _memoController = TextEditingController();
  String? _lastLoadedMemo;
  bool _allowPop = false;

  bool get _hasUnsavedMemo => _memoController.text != (_lastLoadedMemo ?? '');

  @override
  void dispose() {
    _memoController.dispose();
    super.dispose();
  }

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

  Future<void> _handleExit() async {
    final state = ref.read(itemDetailProvider);

    if (state.isDeleting) return;

    if (state.isUpdatingMemo || state.isUpdatingVisibility) {
      showAppNotice(context, '작업이 완료된 후 이동해 주세요.');
      return;
    }

    if (!_hasUnsavedMemo) {
      context.pop();
      return;
    }

    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.background,
        title: const Text('저장하지 않은 메모가 있어요.'),
        content: const Text('변경한 메모를 저장하지 않고 나가시겠어요?'),
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
              '나가기',
              style: TextStyle(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );

    if (shouldExit != true || !mounted) return;

    setState(() {
      _allowPop = true;
    });

    await Future<void>.delayed(Duration.zero);

    if (mounted) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(itemDetailProvider);

    return PopScope(
      canPop:
          !state.isDeleting &&
          !state.isUpdatingMemo &&
          !state.isUpdatingVisibility &&
          (!_hasUnsavedMemo || _allowPop),
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleExit();
      },
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
              onTap: isDeleting ? null : _handleExit,
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
      padding: const EdgeInsets.fromLTRB(20, 8, 10, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildItemImage(item.imageUrl),
          const SizedBox(height: 18),
          _buildMemoSection(item.memo),
          const SizedBox(height: 18),
          _buildTagSection(item.tags),
          const SizedBox(height: 18),
          _buildVisibilitySection(state),
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
    // 서버에서 메모가 새로 로드되거나 수정된 경우에만 입력값 갱신
    if (_lastLoadedMemo != memo) {
      _memoController.text = memo ?? '';
      _lastLoadedMemo = memo;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('메모'),
        const SizedBox(height: 10),
        TextField(
          controller: _memoController,
          maxLines: 1,
          textInputAction: TextInputAction.done,
          style: const TextStyle(
            fontFamily: 'Pretendard',
            fontSize: 16,
            fontWeight: FontWeight.w400,
            letterSpacing: -0.4,
            color: Color(0xFF000000),
          ),
          decoration: InputDecoration(
            hintText: '오늘 발견한 취향에 대해 자유롭게 적어보세요',
            hintStyle: const TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 16,
              fontWeight: FontWeight.w400,
              letterSpacing: -0.4,
              color: Color(0xFF545454),
            ),
            filled: true,
            fillColor: AppColors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 15,
              vertical: 17,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: AppColors.darkIvory,
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: AppColors.darkIvory,
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: AppColors.darkIvory,
                width: 1,
              ),
            ),
          ),
          enabled:
              !ref.watch(itemDetailProvider).isUpdatingMemo &&
              !ref.watch(itemDetailProvider).isUpdatingVisibility &&
              !ref.watch(itemDetailProvider).isDeleting,
          onChanged: (_) {
            setState(() {});
          },
          onSubmitted: (_) => _saveMemo(),
        ),
      ],
    );
  }

  Future<void> _saveMemo() async {
    if (!_hasUnsavedMemo) return;

    final success = await ref
        .read(itemDetailProvider.notifier)
        .updateMemo(widget.itemId, _memoController.text);

    if (!mounted) return;

    if (success) {
      final savedMemo = ref.read(itemDetailProvider).item?.memo ?? '';

      _memoController.text = savedMemo;
      _lastLoadedMemo = savedMemo;

      showAppNotice(context, '메모가 수정되었어요.');
    } else {
      showAppNotice(context, '메모 수정에 실패했어요. 다시 시도해 주세요.');
    }

    setState(() {});
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
          fontFamily: 'Pretendard',
          fontSize: 16,
          fontWeight: FontWeight.w400,
          height: 20 / 16,
          letterSpacing: -0.4,
          color: enabled ? const Color(0xFF4B4540) : AppColors.textHint,
        ),
      ),
    );
  }

  Widget _buildVisibilitySection(ItemDetailState state) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: AppColors.darkIvory, width: 1),
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
                    fontFamily: 'Pretendard',
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.5,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'On: 친구에게 공개  Off: 나만 보기',
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    height: 18 / 14,
                    letterSpacing: -0.35,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          RoomModeToggle(
            isOn: state.item?.isPublic ?? false,
            onChanged:
                state.isUpdatingVisibility ||
                    state.isUpdatingMemo ||
                    state.isDeleting
                ? null
                : (value) async {
                    final success = await ref
                        .read(itemDetailProvider.notifier)
                        .updateVisibility(widget.itemId, value);

                    if (!mounted) return;

                    if (!success) {
                      showAppNotice(context, '공개 여부 변경에 실패했어요. 다시 시도해 주세요.');
                    }
                  },
          ),
        ],
      ),
    );
  }

  /// 네이버 쇼핑 검색 페이지 열기
  Future<void> _openShoppingSearch(String query) async {
    final uri = Uri.https('search.shopping.naver.com', 'search/all', {
      'query': query,
    });

    final success = await launchUrl(uri, mode: LaunchMode.externalApplication);

    if (!success && mounted) {
      showAppNotice(context, '쇼핑 검색 페이지를 열지 못했어요.');
    }
  }

  /// 거울 AI 추천 검색어
  Widget _buildMirrorSearchSection(List<String> searchQueries) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () {
            setState(() {
              _isRecommendationExpanded = !_isRecommendationExpanded;
            });
          },
          child: Row(
            children: [
              const Text(
                'AI 추천 상품',
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
          if (searchQueries.isEmpty)
            const Text(
              '추천 검색어가 없어요.',
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: searchQueries.map((query) {
                return InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => _openShoppingSearch(query),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 13,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.darkIvory,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          query,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 5),
                        const Icon(
                          Icons.open_in_new,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ],
    );
  }

  Widget _buildRecommendationSection(
    int furnitureTypeId,
    int itemId,
    ItemDetailState state,
  ) {
    // 거울(furnitureTypeId: 1)
    if (furnitureTypeId == 1) {
      return _buildMirrorSearchSection(state.searchQueries);
    }

    // 냉장고(furnitureTypeId: 2)
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
        fontFamily: 'Pretendard',
        fontSize: 20,
        fontWeight: FontWeight.w500,
        letterSpacing: -0.5,
        color: AppColors.textPrimary,
      ),
    );
  }
}
