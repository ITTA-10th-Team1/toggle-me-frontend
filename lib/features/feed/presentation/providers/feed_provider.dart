import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../item/presentation/providers/item_upload_provider.dart';
import '../../data/feed_repository.dart';
import '../../data/item_feed_model.dart';

// 정렬 방식
enum FeedSort { latest, oldest }

extension FeedSortExtension on FeedSort {
  String get apiValue {
    switch (this) {
      case FeedSort.latest:
        return 'LATEST';
      case FeedSort.oldest:
        return 'OLDEST';
    }
  }

  String get label {
    switch (this) {
      case FeedSort.latest:
        return '최신순';
      case FeedSort.oldest:
        return '오래된순';
    }
  }
}

// FeedRepository Provider
final feedRepositoryProvider = Provider<FeedRepository>((ref) {
  return FeedRepository(ref.watch(apiClientProvider));
});

// 피드 상태
class FeedState {
  const FeedState({
    this.items = const [],
    this.sort = FeedSort.latest,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.errorMessage,
  });

  final List<ItemFeedModel> items;
  final FeedSort sort;

  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;

  final String? errorMessage;

  FeedState copyWith({
    List<ItemFeedModel>? items,
    FeedSort? sort,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    String? errorMessage,
    bool clearError = false,
  }) {
    return FeedState(
      items: items ?? this.items,
      sort: sort ?? this.sort,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

// 피드 Provider
final feedProvider = NotifierProvider<FeedNotifier, FeedState>(
  FeedNotifier.new,
);

class FeedNotifier extends Notifier<FeedState> {
  late FeedRepository _repository;

  @override
  FeedState build() {
    _repository = ref.read(feedRepositoryProvider);
    return const FeedState();
  }

  /// 인증 토큰 적용
  /// 인증 토큰 적용
  Future<void> _ensureAccessToken() async {
    final tokenStorage = ref.read(tokenStorageProvider);
    final token = await tokenStorage.getAccessToken();

    if (token == null || token.isEmpty) {
      throw Exception('로그인이 필요합니다.');
    }

    ref.read(apiClientProvider).setAccessToken(token);
  }

  /// 최초 조회 및 새로고침
  Future<void> fetchInitial() async {
    if (state.isLoading) return;

    final currentSort = state.sort;

    state = state.copyWith(
      items: [],
      isLoading: true,
      isLoadingMore: false,
      hasMore: true,
      clearError: true,
    );

    try {
      await _ensureAccessToken();

      final items = await _repository.getAllItems(sort: currentSort.apiValue);

      state = state.copyWith(
        items: items,
        isLoading: false,
        hasMore: items.isNotEmpty,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  /// 다음 페이지 조회
  Future<void> loadMore() async {
    if (state.isLoading ||
        state.isLoadingMore ||
        !state.hasMore ||
        state.items.isEmpty) {
      return;
    }

    // 현재 목록의 마지막 아이템 ID를 cursor로 사용
    final cursor = state.items.last.id;

    state = state.copyWith(isLoadingMore: true, clearError: true);

    try {
      await _ensureAccessToken();

      final newItems = await _repository.getAllItems(
        sort: state.sort.apiValue,
        cursor: cursor,
      );

      if (newItems.isEmpty) {
        state = state.copyWith(isLoadingMore: false, hasMore: false);
        return;
      }

      state = state.copyWith(
        items: [...state.items, ...newItems],
        isLoadingMore: false,
        hasMore: true,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false, errorMessage: e.toString());
    }
  }

  /// 정렬 변경
  Future<void> changeSort(FeedSort sort) async {
    if (state.sort == sort) return;

    state = state.copyWith(sort: sort);

    await fetchInitial();
  }
}
