import 'dart:async';
import 'dart:typed_data';

import '../../../core/network/api_client.dart';
import '../../../core/network/image_upload_service.dart';
import '../model/item_model.dart';

class ItemRepository {
  ItemRepository(this._apiClient)
    : _imageUploadService = ImageUploadService(_apiClient);

  final ApiClient _apiClient;
  final ImageUploadService _imageUploadService;

  /// 이미지 업로드 후 imageKey 반환
  Future<String> uploadImage(Uint8List imageBytes) {
    return _imageUploadService.upload(imageBytes);
  }

  /// AI 분석 요청
  Future<String> requestAnalysis(String imageKey, int furnitureTypeId) async {
    final payload = {'imageKey': imageKey, 'furnitureTypeId': furnitureTypeId};

    final response = await _apiClient.dio.post(
      '/api/v1/images/analysis',
      data: payload,
    );

    final result = ImageAnalysisResult.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );

    return result.analysisId;
  }

  /// AI 분석 결과 조회
  Future<ImageAnalysisStatus> getAnalysisResult(String analysisId) async {
    final response = await _apiClient.dio.get(
      '/api/v1/images/analysis/$analysisId',
    );

    return ImageAnalysisStatus.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  /// AI 분석이 완료될 때까지 최대 60초 대기
  Future<ImageAnalysisStatus> pollAnalysis(
    String analysisId, {
    bool Function()? shouldContinue,
  }) async {
    final stopwatch = Stopwatch()..start();

    const limit = Duration(seconds: 60);
    while (stopwatch.elapsed < limit) {
      if (shouldContinue != null && !shouldContinue()) {
        return const ImageAnalysisStatus(status: 'FAILED');
      }
      try {
        final result = await getAnalysisResult(analysisId)
            .timeout(limit - stopwatch.elapsed);
        if (result.status == 'COMPLETED' || result.status == 'FAILED') {
          return result;
        }
      } on TimeoutException {
        break;
      }
      if (shouldContinue != null && !shouldContinue()) break;
      await Future<void>.delayed(const Duration(seconds: 2));
    }

    return const ImageAnalysisStatus(status: 'FAILED');
  }

  /// 공통 아이템 등록
  Future<int> registerItem({
    required String imageKey,
    required int furnitureTypeId,
    required String memo,
    required String visibility,
    required List<String> tags,
  }) async {
    // 태그 앞뒤의 공백과 # 제거, 소문자 변환, 중복 제거
    final normalizedTags = <String>[];
    final seenTags = <String>{};

    for (final tag in tags) {
      final normalized = tag
          .trim()
          .replaceAll(RegExp(r'^#+|#+$'), '')
          .trim()
          .toLowerCase();

      if (normalized.isNotEmpty && seenTags.add(normalized)) {
        normalizedTags.add(normalized);
      }
    }

    if (normalizedTags.length > 3) {
      throw ArgumentError('태그는 최대 3개까지 선택할 수 있습니다.');
    }

    final response = await _apiClient.dio.post(
      '/api/v1/items',
      data: {
        'imageKey': imageKey,
        'furnitureTypeId': furnitureTypeId,
        'memo': memo,
        'visibility': visibility,
        'tags': normalizedTags,
      },
    );

    final data = Map<String, dynamic>.from(response.data as Map);
    return (data['id'] as num).toInt();
  }
}
