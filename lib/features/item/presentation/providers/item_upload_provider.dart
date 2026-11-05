import 'dart:io';

import 'package:dio/dio.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/item_repository.dart';
import '../../../../core/network/api_client.dart';
import '../../../auth/data/token_storage.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  final client = ApiClient();

  ref.onDispose(() => client.dio.close());

  return client;
});

final itemRepositoryProvider = Provider<ItemRepository>((ref) {
  return ItemRepository(ref.watch(apiClientProvider));
});

final tokenStorageProvider = Provider<TokenStorage>((ref) {
  return TokenStorage();
});

class ItemUploadState {
  const ItemUploadState({
    this.selectedImage,
    this.imageKey,
    this.isUploading = false,
    this.isGeneratingTags = false,
    this.isSubmitting = false,
    this.recommendedTags = const [],
    this.selectedTags = const {},
    this.errorMessage,
  });

  final File? selectedImage;
  final String? imageKey;
  final bool isUploading;
  final bool isGeneratingTags;
  final bool isSubmitting;
  final List<String> recommendedTags;
  final Set<String> selectedTags;
  final String? errorMessage;

  ItemUploadState copyWith({
    File? selectedImage,
    String? imageKey,
    bool? isUploading,
    bool? isGeneratingTags,
    bool? isSubmitting,
    List<String>? recommendedTags,
    Set<String>? selectedTags,
    String? errorMessage,
    bool clearImage = false,
    bool clearImageKey = false,
    bool clearError = false,
  }) {
    return ItemUploadState(
      selectedImage: clearImage ? null : selectedImage ?? this.selectedImage,
      imageKey: clearImageKey ? null : imageKey ?? this.imageKey,
      isUploading: isUploading ?? this.isUploading,
      isGeneratingTags: isGeneratingTags ?? this.isGeneratingTags,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      recommendedTags: recommendedTags ?? this.recommendedTags,
      selectedTags: selectedTags ?? this.selectedTags,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

final itemUploadProvider =
    NotifierProvider<ItemUploadNotifier, ItemUploadState>(
      ItemUploadNotifier.new,
    );

class ItemUploadNotifier extends Notifier<ItemUploadState> {
  int _operationId = 0;

  ItemRepository get _repository => ref.read(itemRepositoryProvider);

  @override
  ItemUploadState build() {
    return const ItemUploadState();
  }

  Future<void> _ensureAccessToken() async {
    final token = await ref.read(tokenStorageProvider).getAccessToken();

    if (token == null || token.isEmpty) {
      throw Exception('로그인이 필요합니다.');
    }

    ref.read(apiClientProvider).setAccessToken(token);
  }

  /// 사진 선택 또는 교체
  Future<void> setImage(File image) async {
    if (state.isSubmitting) return;

    _operationId++;
    final operationId = _operationId;

    state = ItemUploadState(selectedImage: image, isUploading: true);

    try {
      await _ensureAccessToken();
      // 1. S3 이미지 업로드
      final imageKey = await _repository.uploadImage(image);

      if (operationId != _operationId) return;

      state = state.copyWith(
        imageKey: imageKey,
        isUploading: false,
        isGeneratingTags: true,
      );

      // 2. AI 분석 요청
      final analysisId = await _repository.requestAnalysis(imageKey);

      if (operationId != _operationId) return;

      // 3. AI 분석 결과 조회
      final tags = await _repository.pollAnalysis(
        analysisId,
        shouldContinue: () => operationId == _operationId,
      );

      if (operationId != _operationId) return;

      state = state.copyWith(
        isGeneratingTags: false,
        recommendedTags: tags,
        selectedTags: {},
      );
    } catch (e) {
      if (operationId != _operationId) return;

      state = state.copyWith(
        isUploading: false,
        isGeneratingTags: false,
        errorMessage: e.toString(),
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
  Future<void> submit({
    required int furnitureTypeId,
    required String memo,
    required String visibility,
  }) async {
    if (state.isSubmitting) return;

    final imageKey = state.imageKey;

    if (imageKey == null || state.isUploading) {
      state = state.copyWith(errorMessage: '사진 업로드가 완료되지 않았습니다.');
      return;
    }

    state = state.copyWith(isSubmitting: true, clearError: true);

    try {
      // 서비스 accessToken 설정
      await _ensureAccessToken();

      await _repository.registerItem(
        imageKey: imageKey,
        furnitureTypeId: furnitureTypeId,
        memo: memo,
        visibility: visibility,
        tags: state.selectedTags.toList(),
      );

      state = const ItemUploadState();
    } catch (e) {
      if (e is DioException) {
        print('실패한 API 주소: ${e.requestOptions.uri}');
        print('HTTP 메서드: ${e.requestOptions.method}');
        print('서버 응답: ${e.response?.data}');
      }

      print('아이템 기록 실패 원인: $e');

      state = state.copyWith(isSubmitting: false, errorMessage: e.toString());
      rethrow;
    }
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}
