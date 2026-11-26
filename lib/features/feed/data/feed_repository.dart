import '../../../core/network/api_client.dart';
import '../data/item_feed_model.dart';

class FeedRepository {
  FeedRepository(this._apiClient);

  final ApiClient _apiClient;

  /// 가구별 또는 전체 내 기록 조회
  Future<List<ItemFeedModel>> getAllItems({
    int? furnitureTypeId,
    String sort = 'LATEST',
    int? cursor,
  }) async {
    final response = await _apiClient.dio.get(
      furnitureTypeId == null ? '/api/v1/items/all' : '/api/v1/items/feed',
      queryParameters: {
        if (furnitureTypeId != null) 'furnitureTypeId': furnitureTypeId,
        'sort': sort,
        if (cursor != null) 'cursor': cursor,
      },
    );

    final data = response.data as List<dynamic>;

    return data
        .map((item) => ItemFeedModel.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }
}
