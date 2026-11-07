import '../../../core/network/api_client.dart';
import 'item_detail_model.dart';

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

  /// 냉장고 기록 기반 AI 음식 추천
  Future<List<ItemRecommendationModel>> getRecommendations(int itemId) async {
    final response = await _apiClient.dio.post(
      '/api/v1/items/$itemId/recommendations',
    );

    final data = response.data as List<dynamic>;

    return data
        .map(
          (item) => ItemRecommendationModel.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
  }
}
