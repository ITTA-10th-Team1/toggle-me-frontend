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

  Future<List<ItemRecommendationModel>> getRecommendations(int itemId) async {
    final response = await _apiClient.dio.post(
      '/api/v1/items/$itemId/recommendations',
    );
    return (response.data as List<dynamic>)
        .map(
          (item) => ItemRecommendationModel.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
  }

  Future<ItemDetailModel> updateVisibility(
    int itemId,
    String visibility,
  ) async {
    final response = await _apiClient.dio.patch(
      '/api/v1/items/$itemId',
      data: {'visibility': visibility},
    );

    return ItemDetailModel.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  /// 아이템 메모를 수정한다.
  Future<ItemDetailModel> updateMemo(int itemId, String memo) async {
    final response = await _apiClient.dio.patch(
      '/api/v1/items/$itemId',
      data: {'memo': memo},
    );

    return ItemDetailModel.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }
}
