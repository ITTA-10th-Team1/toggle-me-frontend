import '../../../core/network/api_client.dart';
import '../data/item_feed_model.dart';

class FeedRepository {
  FeedRepository(this._apiClient);

  final ApiClient _apiClient;

  /// 가구별 내 기록 조회
  Future<List<ItemFeedModel>> getAllItems({
    required int furnitureTypeId,
    String sort = 'LATEST',
    int? cursor,
  }) async {
    final response = await _apiClient.dio.get(
      '/api/v1/items/feed',
      queryParameters: {
        'furnitureTypeId': furnitureTypeId,
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
