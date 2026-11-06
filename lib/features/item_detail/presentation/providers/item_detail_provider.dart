import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../item/presentation/providers/item_upload_provider.dart';
import '../../data/item_detail_model.dart';
import '../../data/item_detail_repository.dart';

final itemDetailRepositoryProvider = Provider<ItemDetailRepository>((ref) {
  return ItemDetailRepository(ref.watch(apiClientProvider));
});

class ItemDetailState {
  const ItemDetailState({
    this.item,
    this.isLoading = false,
    this.isDeleting = false,
    this.errorMessage,
  });

  final ItemDetailModel? item;
  final bool isLoading;
  final bool isDeleting;
  final String? errorMessage;

  ItemDetailState copyWith({
    ItemDetailModel? item,
    bool? isLoading,
    bool? isDeleting,
    String? errorMessage,
    bool clearItem = false,
    bool clearError = false,
  }) {
    return ItemDetailState(
      item: clearItem ? null : item ?? this.item,
      isLoading: isLoading ?? this.isLoading,
      isDeleting: isDeleting ?? this.isDeleting,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

final itemDetailProvider =
    NotifierProvider<ItemDetailNotifier, ItemDetailState>(
  ItemDetailNotifier.new,
);

class ItemDetailNotifier extends Notifier<ItemDetailState> {
  int _requestId = 0;

  ItemDetailRepository get _repository =>
      ref.read(itemDetailRepositoryProvider);

  @override
  ItemDetailState build() => const ItemDetailState();

  Future<void> _ensureAccessToken() async {
    final token = await ref.read(tokenStorageProvider).getAccessToken();

    if (token == null || token.isEmpty) {
      throw Exception('로그인이 필요합니다.');
    }

    ref.read(apiClientProvider).setAccessToken(token);
  }

  /// 상세 화면 진입 시 최신 이미지 URL을 포함한 상세 정보를 다시 조회한다.
  Future<void> fetchDetail(int itemId) async {
    final requestId = ++_requestId;

    state = const ItemDetailState(isLoading: true);

    try {
      await _ensureAccessToken();
      final item = await _repository.getItem(itemId);

      if (requestId != _requestId) return;

      state = ItemDetailState(item: item);
    } catch (e) {
      if (requestId != _requestId) return;

      state = ItemDetailState(errorMessage: e.toString());
    }
  }

  /// 삭제 성공 여부를 반환한다.
  Future<bool> deleteItem(int itemId) async {
    if (state.isDeleting) return false;

    state = state.copyWith(isDeleting: true, clearError: true);

    try {
      await _ensureAccessToken();
      await _repository.deleteItem(itemId);

      // 진행 중인 상세 조회 응답이 삭제된 아이템을 다시 표시하지 않도록 무효화
      _requestId++;
      state = const ItemDetailState();
      return true;
    } catch (e) {
      state = state.copyWith(
        isDeleting: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }
}
