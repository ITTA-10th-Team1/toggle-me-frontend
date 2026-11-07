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
    this.recommendations = const [],
    this.isLoadingRecommendations = false,
    this.recommendationError,
    this.hasLoadedRecommendations = false,
  });

  final ItemDetailModel? item;
  final bool isLoading;
  final bool isDeleting;
  final String? errorMessage;

  final List<ItemRecommendationModel> recommendations;
  final bool isLoadingRecommendations;
  final String? recommendationError;
  final bool hasLoadedRecommendations;

  ItemDetailState copyWith({
    ItemDetailModel? item,
    bool? isLoading,
    bool? isDeleting,
    String? errorMessage,
    bool clearItem = false,
    bool clearError = false,
    List<ItemRecommendationModel>? recommendations,
    bool? isLoadingRecommendations,
    String? recommendationError,
    bool clearRecommendationError = false,
    bool? hasLoadedRecommendations,
  }) {
    return ItemDetailState(
      item: clearItem ? null : item ?? this.item,
      isLoading: isLoading ?? this.isLoading,
      isDeleting: isDeleting ?? this.isDeleting,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      recommendations: recommendations ?? this.recommendations,
      isLoadingRecommendations:
          isLoadingRecommendations ?? this.isLoadingRecommendations,
      recommendationError: clearRecommendationError
          ? null
          : recommendationError ?? this.recommendationError,
      hasLoadedRecommendations:
          hasLoadedRecommendations ?? this.hasLoadedRecommendations,
    );
  }
}

final itemDetailProvider =
    NotifierProvider<ItemDetailNotifier, ItemDetailState>(
      ItemDetailNotifier.new,
    );

class ItemDetailNotifier extends Notifier<ItemDetailState> {
  int _requestId = 0;
  int _recommendationRequestId = 0;

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
    _recommendationRequestId++;

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

  /// 냉장고 기록 기반 AI 음식 추천
  Future<void> fetchRecommendations(int itemId) async {
    if (state.isLoadingRecommendations ||
        state.hasLoadedRecommendations ||
        state.isDeleting) {
      return;
    }

    final requestId = ++_recommendationRequestId;

    state = state.copyWith(
      isLoadingRecommendations: true,
      clearRecommendationError: true,
    );

    try {
      await _ensureAccessToken();
      final recommendations = await _repository.getRecommendations(itemId);

      if (requestId != _recommendationRequestId) return;

      state = state.copyWith(
        recommendations: recommendations,
        isLoadingRecommendations: false,
        hasLoadedRecommendations: true,
      );
    } catch (e) {
      if (requestId != _recommendationRequestId) return;

      state = state.copyWith(
        isLoadingRecommendations: false,
        recommendationError: e.toString(),
      );
    }
  }

  /// 삭제 성공 여부를 반환한다.
  Future<bool> deleteItem(int itemId) async {
    if (state.isDeleting || state.item?.id != itemId) {
      return false;
    }

    // 삭제 요청 시작 시점의 요청 ID 저장
    final requestId = _requestId;

    state = state.copyWith(isDeleting: true, clearError: true);

    try {
      await _ensureAccessToken();
      await _repository.deleteItem(itemId);

      // 다른 아이템으로 이동했다면 이전 응답 무시
      if (requestId != _requestId || state.item?.id != itemId) {
        return true;
      }

      // 진행 중인 상세 조회 및 추천 요청 무효화
      _requestId++;
      _recommendationRequestId++;

      state = const ItemDetailState();
      return true;
    } catch (e) {
      // 다른 아이템으로 이동했다면 이전 오류도 무시
      if (requestId != _requestId || state.item?.id != itemId) {
        return false;
      }

      state = state.copyWith(isDeleting: false, errorMessage: e.toString());

      return false;
    }
  }
}
