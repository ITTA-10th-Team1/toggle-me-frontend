import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import 'providers/feed_provider.dart';

class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key, this.furnitureTypeId});
  final int? furnitureTypeId;

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
      if (!mounted) return;
      await ref
          .read(feedProvider.notifier)
          .fetchInitial(
            furnitureTypeId: widget.furnitureTypeId,
            changeCategory: true,
          );

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

  // ��ũ���� �ϴܿ� ��������� ���� ������ ��ȸ
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

      // �߰� ��ȸ�� �����ߴٸ� �ڵ����� ���� �������� ��û���� ����
      if (state.errorMessage != null) return;

      _loadMoreIfNeeded();
    }
  }

  // �߰� ��ȸ ���� �� ��ư�� ������ ���� ��õ�
  Future<void> _retryLoadMore() async {
    await ref.read(feedProvider.notifier).retryLoadMore();

    if (mounted) {
      final state = ref.read(feedProvider);

      // ��õ��� �����ߴٸ� �ڵ� �߰� ��ȸ �ߴ�
      if (state.errorMessage != null) return;

      _loadMoreIfNeeded();
    }
  }

  // ȭ�鿡 ��ũ���� ������ ���� ������ �����Ͱ� ������ �߰� ��ȸ
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

  // ���� �޴� �׸�
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
                  fontFamily: 'Pretendard',
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  height: 1,
                  letterSpacing: -0.35,
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
            // ��� ���
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: SizedBox(
                height: 48,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Center(
                      child: Text(
                        '���� ��ƺ���',
                        style: TextStyle(
                          fontFamily: 'Pretendard',
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          height: 26 / 20,
                          letterSpacing: -0.5,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),

                    // �ڷΰ��� ��ư
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

            // ���� ��ư
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
                        final sort = value == '�ֽż�'
                            ? FeedSort.latest
                            : FeedSort.oldest;

                        ref.read(feedProvider.notifier).changeSort(sort);
                      },
                      itemBuilder: (context) => [
                        _buildSortMenuItem('�ֽż�', feedState.sort),
                        _buildSortMenuItem('�����ȼ�', feedState.sort),
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
                                fontFamily: 'Pretendard',
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                height: 1,
                                letterSpacing: -0.35,
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

            // ������ ���
            Expanded(child: _buildFeedContent(feedState)),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedContent(FeedState state) {
    // ���� �ε�
    if (state.isLoading && state.items.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    // ���� ��ȸ ����
    if (state.errorMessage != null && state.items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '����� �ҷ����� ���߾��.',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                ref.read(feedProvider.notifier).fetchInitial();
              },
              child: const Text('�ٽ� �õ�'),
            ),
          ],
        ),
      );
    }

    // ��ϵ� �������� ���� ���
    if (state.items.isEmpty) {
      return const Center(
        child: Text(
          '���� ��ϵ� �������� �����.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
      );
    }

    // ������ �̹��� �׸���
    return GridView.builder(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
        // �ϴ� �ε� / �߰� ��ȸ ����
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
              child: const Text('�ٽ� �õ�'),
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
