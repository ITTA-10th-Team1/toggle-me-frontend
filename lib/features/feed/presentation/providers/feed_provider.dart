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

  // 가장 최근에 시작한 요청을 구분하기 위한 번호
  int _requestId = 0;

  // 현재 선택된 가구 ID
  int? _furnitureTypeId;

  // 서버 원본 목록의 마지막 ID
  int? _nextCursor;

  @override
  FeedState build() {
    _repository = ref.read(feedRepositoryProvider);
    return const FeedState();
  }

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
  Future<void> fetchInitial({int? furnitureTypeId}) async {
    if (furnitureTypeId != null) {
      _furnitureTypeId = furnitureTypeId;
    }

    // 새 요청 번호 발급
    final requestId = ++_requestId;
    final currentSort = state.sort;
    final selectedFurnitureTypeId = _furnitureTypeId;

    _nextCursor = null;

    state = state.copyWith(
      items: [],
      isLoading: true,
      isLoadingMore: false,
      hasMore: true,
      clearError: true,
    );

    if (selectedFurnitureTypeId == null) {
      state = state.copyWith(
        isLoading: false,
        hasMore: false,
        errorMessage: '가구를 선택해 주세요.',
      );
      return;
    }

    try {
      await _ensureAccessToken();

      final items = await _repository.getAllItems(
        furnitureTypeId: selectedFurnitureTypeId,
        sort: currentSort.apiValue,
      );

      if (requestId != _requestId) return;

      _nextCursor = items.isEmpty ? null : items.last.id;

      state = state.copyWith(
        items: items,
        isLoading: false,
        hasMore: items.length == 20,
        clearError: true,
      );
    } catch (e) {
      if (requestId != _requestId) return;

      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  /// 다음 페이지 조회
  Future<void> loadMore() async {
    if (state.isLoading ||
        state.isLoadingMore ||
        !state.hasMore ||
        state.errorMessage != null) {
      return;
    }

    final selectedFurnitureTypeId = _furnitureTypeId;

    if (selectedFurnitureTypeId == null) return;

    // 현재 요청 번호와 정렬 방식 저장
    final requestId = _requestId;
    final currentSort = state.sort;

    // 서버 원본 목록의 마지막 ID를 cursor로 사용
    final cursor = _nextCursor;

    if (cursor == null) return;

    state = state.copyWith(isLoadingMore: true);

    try {
      await _ensureAccessToken();

      final items = await _repository.getAllItems(
        furnitureTypeId: selectedFurnitureTypeId,
        sort: currentSort.apiValue,
        cursor: cursor,
      );

      // 정렬 변경 등으로 이전 요청이 무효화됐다면 응답 무시
      if (requestId != _requestId) return;

      if (items.isEmpty) {
        _nextCursor = null;

        state = state.copyWith(isLoadingMore: false, hasMore: false);
        return;
      }

      // 서버 원본 목록 기준으로 cursor 갱신
      _nextCursor = items.last.id;

      state = state.copyWith(
        items: [...state.items, ...items],
        isLoadingMore: false,
        hasMore: items.length == 20,
      );
    } catch (e) {
      if (requestId != _requestId) return;

      state = state.copyWith(isLoadingMore: false, errorMessage: e.toString());
    }
  }

  /// 추가 조회 실패 시 사용자가 다시 시도
  Future<void> retryLoadMore() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) {
      return;
    }

    state = state.copyWith(clearError: true);

    await loadMore();
  }

  /// 정렬 변경
  Future<void> changeSort(FeedSort sort) async {
    if (state.sort == sort) return;

    // 정렬을 먼저 변경한 뒤 새로운 최초 조회 시작
    state = state.copyWith(sort: sort);

    // cursor를 초기화하고 첫 페이지부터 다시 조회
    await fetchInitial();
  }
}
