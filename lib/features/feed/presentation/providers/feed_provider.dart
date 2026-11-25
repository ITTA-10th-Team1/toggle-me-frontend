import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../item/presentation/providers/item_upload_provider.dart';
import '../../data/feed_repository.dart';
import '../../data/item_feed_model.dart';

// ���� ���
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
        return '�ֽż�';
      case FeedSort.oldest:
        return '�����ȼ�';
    }
  }
}

// FeedRepository Provider
final feedRepositoryProvider = Provider<FeedRepository>((ref) {
  return FeedRepository(ref.watch(apiClientProvider));
});

// �ǵ� ����
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

// �ǵ� Provider
final feedProvider = NotifierProvider<FeedNotifier, FeedState>(
  FeedNotifier.new,
);

class FeedNotifier extends Notifier<FeedState> {
  late FeedRepository _repository;

  // ���� �ֱٿ� ������ ��û�� �����ϱ� ���� ��ȣ
  int _requestId = 0;
  int? _furnitureTypeId;

  @override
  FeedState build() {
    _repository = ref.read(feedRepositoryProvider);
    return const FeedState();
  }

  /// ���� ��ū ����
  Future<void> _ensureAccessToken() async {
    final tokenStorage = ref.read(tokenStorageProvider);
    final token = await tokenStorage.getAccessToken();

    if (token == null || token.isEmpty) {
      throw Exception('�α����� �ʿ��մϴ�.');
    }

    ref.read(apiClientProvider).setAccessToken(token);
  }

  /// ���� ��ȸ �� ���ΰ�ħ
  Future<void> fetchInitial({
    int? furnitureTypeId,
    bool changeCategory = false,
  }) async {
    if (changeCategory) _furnitureTypeId = furnitureTypeId;
    // �� ��û ��ȣ �߱�
    final requestId = ++_requestId;
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

      final items = await _repository.getAllItems(
        sort: currentSort.apiValue,
        furnitureTypeId: _furnitureTypeId,
      );

      // �� �ֽ� ��û�� ���۵ƴٸ� ���� ���� ����
      if (requestId != _requestId) return;

      state = state.copyWith(
        items: items,
        isLoading: false,
        hasMore: items.isNotEmpty,
        clearError: true,
      );
    } catch (e) {
      if (requestId != _requestId) return;

      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  /// ���� ������ ��ȸ
  Future<void> loadMore() async {
    if (state.isLoading ||
        state.isLoadingMore ||
        !state.hasMore ||
        state.items.isEmpty ||
        state.errorMessage != null) {
      return;
    }

    // ���� ��û ��ȣ�� ���� ��� ����
    final requestId = _requestId;
    final currentSort = state.sort;

    // ���� ����� ������ ������ ID�� cursor�� ���
    final cursor = state.items.last.id;

    state = state.copyWith(isLoadingMore: true);

    try {
      await _ensureAccessToken();

      final newItems = await _repository.getAllItems(
        sort: currentSort.apiValue,
        cursor: cursor,
        furnitureTypeId: _furnitureTypeId,
      );

      // ���� ���� ������ ���� ��û�� ��ȿȭ�ƴٸ� ���� ����
      if (requestId != _requestId) return;

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
      if (requestId != _requestId) return;

      state = state.copyWith(isLoadingMore: false, errorMessage: e.toString());
    }
  }

  /// �߰� ��ȸ ���� �� ����ڰ� �ٽ� �õ�
  Future<void> retryLoadMore() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) {
      return;
    }

    state = state.copyWith(clearError: true);

    await loadMore();
  }

  /// ���� ����
  Future<void> changeSort(FeedSort sort) async {
    if (state.sort == sort) return;

    // ������ ���� ������ �� ���ο� ���� ��ȸ ����
    state = state.copyWith(sort: sort);

    await fetchInitial();
  }
}
