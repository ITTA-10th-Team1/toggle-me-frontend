import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import 'providers/feed_provider.dart';

class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    _scrollController.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(feedProvider.notifier).fetchInitial();

      if (mounted) {
        _loadMoreIfNeeded();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  // 스크롤이 하단에 가까워지면 다음 페이지 조회
  void _onScroll() {
    if (!_scrollController.hasClients) return;

    final position = _scrollController.position;

    if (position.maxScrollExtent - position.pixels <= 300) {
      _loadNextPage();
    }
  }

  Future<void> _loadNextPage() async {
    await ref.read(feedProvider.notifier).loadMore();

    if (mounted) {
      final state = ref.read(feedProvider);

      // 추가 조회에 실패했다면 자동으로 다음 페이지를 요청하지 않음
      if (state.errorMessage != null) return;

      _loadMoreIfNeeded();
    }
  }

  // 추가 조회 실패 후 버튼을 눌렀을 때만 재시도
  Future<void> _retryLoadMore() async {
    await ref.read(feedProvider.notifier).retryLoadMore();

    if (mounted) {
      final state = ref.read(feedProvider);

      // 재시도도 실패했다면 자동 추가 조회 중단
      if (state.errorMessage != null) return;

      _loadMoreIfNeeded();
    }
  }

  // 화면에 스크롤이 생기지 않을 정도로 데이터가 적으면 추가 조회
  void _loadMoreIfNeeded() {
    if (!_scrollController.hasClients) return;

    final position = _scrollController.position;
    final state = ref.read(feedProvider);

    if (position.maxScrollExtent <= 0 &&
        state.hasMore &&
        !state.isLoading &&
        !state.isLoadingMore &&
        state.errorMessage == null &&
        state.items.isNotEmpty) {
      _loadNextPage();
    }
  }

  // 정렬 메뉴 항목
  PopupMenuItem<String> _buildSortMenuItem(
    String value,
    FeedSort selectedSort,
  ) {
    final isSelected = selectedSort.label == value;

    return PopupMenuItem<String>(
      value: value,
      height: 40,
      padding: EdgeInsets.zero,
      child: SizedBox(
        width: 120,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.normal,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              if (isSelected)
                SvgPicture.asset(
                  'assets/images/img_common_check.svg',
                  width: 10,
                  height: 10,
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final feedState = ref.watch(feedProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // 상단 헤더
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: SizedBox(
                height: 48,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Center(
                      child: Text(
                        '취향 모아보기',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),

                    // 뒤로가기 버튼
                    Positioned(
                      left: 16,
                      child: GestureDetector(
                        onTap: () => context.pop(),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                            color: AppColors.darkIvory,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: SvgPicture.asset(
                              'assets/images/img_common_back.svg',
                              width: 20,
                              height: 20,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 정렬 버튼
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Theme(
                    data: Theme.of(context).copyWith(
                      splashFactory: NoSplash.splashFactory,
                      highlightColor: Colors.transparent,
                      hoverColor: Colors.transparent,
                      focusColor: Colors.transparent,
                    ),
                    child: PopupMenuButton<String>(
                      initialValue: feedState.sort.label,
                      position: PopupMenuPosition.under,
                      color: AppColors.darkIvory,
                      elevation: 0,
                      shadowColor: Colors.transparent,
                      surfaceTintColor: Colors.transparent,
                      offset: const Offset(0, 4),
                      constraints: const BoxConstraints(
                        minWidth: 120,
                        maxWidth: 120,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      onSelected: (value) {
                        final sort = value == '최신순'
                            ? FeedSort.latest
                            : FeedSort.oldest;

                        ref.read(feedProvider.notifier).changeSort(sort);
                      },
                      itemBuilder: (context) => [
                        _buildSortMenuItem('최신순', feedState.sort),
                        _buildSortMenuItem('오래된순', feedState.sort),
                      ],
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        color: AppColors.background,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              feedState.sort.label,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.normal,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.keyboard_arrow_down,
                              size: 18,
                              color: AppColors.textPrimary,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 아이템 목록
            Expanded(child: _buildFeedContent(feedState)),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedContent(FeedState state) {
    // 최초 로딩
    if (state.isLoading && state.items.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    // 최초 조회 실패
    if (state.errorMessage != null && state.items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '기록을 불러오지 못했어요.',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                ref.read(feedProvider.notifier).fetchInitial();
              },
              child: const Text('다시 시도'),
            ),
          ],
        ),
      );
    }

    // 등록된 아이템이 없는 경우
    if (state.items.isEmpty) {
      return const Center(
        child: Text(
          '아직 등록된 아이템이 없어요.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
      );
    }

    // 아이템 이미지 그리드
    return GridView.builder(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 5,
        mainAxisSpacing: 8,
        childAspectRatio: 0.78,
      ),
      itemCount:
          state.items.length +
          (state.isLoadingMore || state.errorMessage != null ? 1 : 0),
      itemBuilder: (context, index) {
        // 하단 로딩 / 추가 조회 실패
        if (index >= state.items.length) {
          if (state.isLoadingMore) {
            return const Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
                strokeWidth: 2,
              ),
            );
          }

          return Center(
            child: TextButton(
              onPressed: _retryLoadMore,
              child: const Text('다시 시도'),
            ),
          );
        }

        final item = state.items[index];

        return GestureDetector(
          onTap: () async {
            final deleted = await context.push<bool>('/items/${item.id}');

            if (deleted == true && mounted) {
              await ref.read(feedProvider.notifier).fetchInitial();
            }
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: Image.network(
              item.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: AppColors.darkIvory,
                  child: const Center(
                    child: Icon(
                      Icons.image_not_supported_outlined,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
