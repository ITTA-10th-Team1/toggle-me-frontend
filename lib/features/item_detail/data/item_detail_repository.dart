import '../../../core/network/api_client.dart';
import 'item_detail_model.dart';

import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';

class ItemDetailRepository {
  ItemDetailRepository(this._apiClient);

  final ApiClient _apiClient;

  /// 아이템 상세 조회
  Future<ItemDetailModel> getItem(int itemId) async {
    final response = await _apiClient.dio.get('/api/v1/items/$itemId');

    return ItemDetailModel.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  /// 아이템 삭제
  /// 성공 시 서버가 204 No Content를 반환한다.
  Future<void> deleteItem(int itemId) async {
    await _apiClient.dio.delete('/api/v1/items/$itemId');
  }

  Future<List<ItemRecommendationModel>> getRecommendations(int itemId) async {
    debugPrint('========== AI 추천 API 요청 ==========');
    debugPrint('[AI 추천] itemId: $itemId');
    debugPrint('[AI 추천] method: POST');
    debugPrint('[AI 추천] path: /api/v1/items/$itemId/recommendations');

    try {
      final response = await _apiClient.dio.post(
        '/api/v1/items/$itemId/recommendations',
      );

      debugPrint('[AI 추천] statusCode: ${response.statusCode}');
      debugPrint('[AI 추천] response: ${response.data}');

      final data = response.data as List<dynamic>;

      final recommendations = data
          .map(
            (item) => ItemRecommendationModel.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList();

      debugPrint('[AI 추천] 파싱 성공: ${recommendations.length}개');

      return recommendations;
    } on DioException catch (e, stackTrace) {
      debugPrint('========== AI 추천 Dio 오류 ==========');
      debugPrint('[AI 추천] statusCode: ${e.response?.statusCode}');
      debugPrint('[AI 추천] responseData: ${e.response?.data}');
      debugPrint('[AI 추천] requestPath: ${e.requestOptions.path}');
      debugPrint('[AI 추천] requestMethod: ${e.requestOptions.method}');
      debugPrint('[AI 추천] message: ${e.message}');
      debugPrint('[AI 추천] stackTrace: $stackTrace');

      rethrow;
    } catch (e, stackTrace) {
      debugPrint('[AI 추천] 기타 오류: $e');
      debugPrint('[AI 추천] stackTrace: $stackTrace');

      rethrow;
    }
  }
}
