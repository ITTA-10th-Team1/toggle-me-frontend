import 'dart:async';
import 'dart:io';

import '../../../core/network/api_client.dart';
import '../../../core/network/image_upload_service.dart';
import '../model/item_model.dart';

class ItemRepository {
  ItemRepository(this._apiClient)
    : _imageUploadService = ImageUploadService(_apiClient);

  final ApiClient _apiClient;
  final ImageUploadService _imageUploadService;

  /// 이미지 업로드 후 imageKey 반환
  Future<String> uploadImage(File image) {
    return _imageUploadService.upload(image);
  }

  /// AI 분석 요청
  Future<String> requestAnalysis(String imageKey) async {
    final response = await _apiClient.dio.post(
      '/api/v1/images/analysis',
      data: {'imageKey': imageKey},
    );

    final result = ImageAnalysisResult.fromJson(
      Map<String, dynamic>.from(response.data),
    );

    return result.analysisId;
  }

  /// AI 분석 결과 조회
  Future<List<String>> getAnalysisResult(String analysisId) async {
    final response = await _apiClient.dio.get(
      '/api/v1/images/analysis/$analysisId',
    );

    final result = ImageAnalysisStatus.fromJson(
      Map<String, dynamic>.from(response.data),
    );

    switch (result.status) {
      case 'COMPLETED':
        return result.tags;

      case 'FAILED':
        return [];

      case 'PENDING':
        return [];

      default:
        throw Exception('알 수 없는 AI 분석 상태입니다.');
    }
  }

  /// AI 분석이 완료될 때까지 최대 60초 대기
  Future<List<String>> pollAnalysis(
    String analysisId, {
    bool Function()? shouldContinue,
  }) async {
    final stopwatch = Stopwatch()..start();

    while (stopwatch.elapsed < const Duration(seconds: 60)) {
      if (shouldContinue != null && !shouldContinue()) {
        return [];
      }

      await Future.delayed(const Duration(seconds: 2));

      if (shouldContinue != null && !shouldContinue()) {
        return [];
      }

      try {
        final response = await _apiClient.dio.get(
          '/api/v1/images/analysis/$analysisId',
        );

        final result = ImageAnalysisStatus.fromJson(
          Map<String, dynamic>.from(response.data),
        );

        if (result.status == 'COMPLETED') {
          return result.tags;
        }

        if (result.status == 'FAILED') {
          return [];
        }
      } catch (_) {
        // 일시적인 분석 조회 오류는 다음 주기에 재시도
      }
    }

    return [];
  }

  /// 냉장고 사진 등록
  Future<void> registerFridgeFood({required String imageKey}) async {
    final now = DateTime.now();

    final recordedOn =
        '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';

    await _apiClient.dio.post(
      '/api/v1/fridge/foods',
      data: {
        'imageKey': imageKey,
        'recordedOn': recordedOn,
        'visibility': 'PRIVATE',
      },
    );
  }
}
