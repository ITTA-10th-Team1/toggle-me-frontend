import '../../../../core/network/request_error_message.dart';

import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/item_repository.dart';
import '../../data/item_recommendation_storage.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/member_api.dart';
import '../../../auth/data/token_storage.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  final client = ApiClient(
    readAccessToken: memberApi.accessToken,
    refreshAccessToken: memberApi.refreshAccessToken,
  );

  ref.onDispose(() => client.dio.close());

  return client;
});

final itemRepositoryProvider = Provider<ItemRepository>((ref) {
  return ItemRepository(ref.watch(apiClientProvider));
});

final tokenStorageProvider = Provider<TokenStorage>((ref) {
  return TokenStorage();
});

final itemRecommendationStorageProvider = Provider<ItemRecommendationStorage>(
  (ref) => ItemRecommendationStorage(),
);

class ItemUploadState {
  const ItemUploadState({
    this.selectedImage,
    this.selectedImageBytes,
    this.imageKey,
    this.isUploading = false,
    this.isGeneratingTags = false,
    this.isSubmitting = false,
    this.recommendedTags = const [],
    this.recommendedSearchQueries = const [],
    this.selectedTags = const {},
    this.errorMessage,
  });

  final XFile? selectedImage;
  final Uint8List? selectedImageBytes;
  final String? imageKey;
  final bool isUploading;
  final bool isGeneratingTags;
  final bool isSubmitting;
  final List<String> recommendedTags;
  final List<String> recommendedSearchQueries;
  final Set<String> selectedTags;
  final String? errorMessage;

  ItemUploadState copyWith({
    XFile? selectedImage,
    Uint8List? selectedImageBytes,
    String? imageKey,
    bool? isUploading,
    bool? isGeneratingTags,
    bool? isSubmitting,
    List<String>? recommendedTags,
    List<String>? recommendedSearchQueries,
    Set<String>? selectedTags,
    String? errorMessage,
    bool clearImage = false,
    bool clearImageKey = false,
    bool clearError = false,
  }) {
    return ItemUploadState(
      selectedImage: clearImage ? null : selectedImage ?? this.selectedImage,
      selectedImageBytes: clearImage
          ? null
          : selectedImageBytes ?? this.selectedImageBytes,
      imageKey: clearImageKey ? null : imageKey ?? this.imageKey,
      isUploading: isUploading ?? this.isUploading,
      isGeneratingTags: isGeneratingTags ?? this.isGeneratingTags,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      recommendedTags: recommendedTags ?? this.recommendedTags,
      recommendedSearchQueries:
          recommendedSearchQueries ?? this.recommendedSearchQueries,
      selectedTags: selectedTags ?? this.selectedTags,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

final itemUploadProvider =
    NotifierProvider.autoDispose<ItemUploadNotifier, ItemUploadState>(
      ItemUploadNotifier.new,
    );

class ItemUploadNotifier extends Notifier<ItemUploadState> {
  int _operationId = 0;

  ItemRepository get _repository => ref.read(itemRepositoryProvider);

  @override
  ItemUploadState build() {
    ref.onDispose(() => _operationId++);
    return const ItemUploadState();
  }

  /// 사진 선택 또는 교체
  Future<void> setImage(XFile image, {required int furnitureTypeId}) async {
    if (state.isSubmitting) return;

    _operationId++;
    final operationId = _operationId;

    state = ItemUploadState(selectedImage: image, isUploading: true);

    try {
      // 이미지 바이트 읽기
      final imageBytes = await image.readAsBytes();

      if (!ref.mounted || operationId != _operationId) return;

      state = state.copyWith(selectedImageBytes: imageBytes);

      // 1. S3 이미지 업로드
      final imageKey = await _repository.uploadImage(imageBytes);

      if (!ref.mounted || operationId != _operationId) return;

      state = state.copyWith(
        imageKey: imageKey,
        isUploading: false,
        isGeneratingTags: true,
      );

      // 2. AI 분석 요청
      final analysisId = await _repository.requestAnalysis(
        imageKey,
        furnitureTypeId,
      );

      if (!ref.mounted || operationId != _operationId) return;

      // 3. AI 분석 결과 조회
      final analysisResult = await _repository.pollAnalysis(
        analysisId,
        shouldContinue: () => operationId == _operationId,
      );

      if (!ref.mounted || operationId != _operationId) return;

      state = state.copyWith(
        isGeneratingTags: false,
        recommendedTags: analysisResult.tags,
        recommendedSearchQueries: analysisResult.searchQueries,
        selectedTags: {},
        errorMessage: analysisResult.status == 'COMPLETED'
            ? null
            : 'AI 분석을 완료하지 못했어요. 사진은 그대로 기록할 수 있어요.',
      );
    } catch (e) {
      if (!ref.mounted || operationId != _operationId) return;

      state = state.copyWith(
        isUploading: false,
        isGeneratingTags: false,
        errorMessage: requestErrorMessage(e),
      );
    }
  }

  /// 사진 삭제
  void removeImage() {
    if (state.isSubmitting) return;

    _operationId++;
    state = const ItemUploadState();
  }

  /// 태그 선택
  void toggleTag(String tag) {
    if (state.isSubmitting) return;

    final selected = Set<String>.from(state.selectedTags);

    if (selected.contains(tag)) {
      selected.remove(tag);
    } else {
      if (selected.length >= 3) return;
      selected.add(tag);
    }

    state = state.copyWith(selectedTags: selected);
  }

  /// 공통 아이템 등록
  Future<bool> submit({
    required int furnitureTypeId,
    required String memo,
    required String visibility,
  }) async {
    if (state.isSubmitting || state.isGeneratingTags) {
      return false;
    }

    final imageKey = state.imageKey;

    if (imageKey == null || state.isUploading) {
      state = state.copyWith(errorMessage: '사진 업로드가 완료되지 않았습니다.');
      return false;
    }

    state = state.copyWith(isSubmitting: true, clearError: true);

    try {
      // 1. 아이템 등록 후 생성된 ID 받기
      final itemId = await _repository.registerItem(
        imageKey: imageKey,
        furnitureTypeId: furnitureTypeId,
        memo: memo,
        visibility: visibility,
        tags: state.selectedTags.toList(),
      );

      // 2. 거울인 경우 AI 검색어를 아이템 ID와 연결해 저장
      if (ref.mounted && state.recommendedSearchQueries.isNotEmpty) {
        try {
          await ref
              .read(itemRecommendationStorageProvider)
              .saveSearchQueries(itemId, state.recommendedSearchQueries);
        } catch (_) {
          // The server already saved the item. A browser storage failure must
          // not report failure and encourage a duplicate POST on retry.
        }
      }

      if (ref.mounted) state = const ItemUploadState();
      return true;
    } catch (e) {
      if (ref.mounted) {
        state = state.copyWith(
          isSubmitting: false,
          errorMessage: requestErrorMessage(e),
        );
      }

      rethrow;
    }
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}
