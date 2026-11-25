import '../../../core/network/api_client.dart';
import '../data/item_feed_model.dart';

class FeedRepository {
  FeedRepository(this._apiClient);

  final ApiClient _apiClient;

  /// �� ��� ��ü ��ȸ
  Future<List<ItemFeedModel>> getAllItems({
    String sort = 'LATEST',
    int? cursor,
    int? furnitureTypeId,
  }) async {
    final response = await _apiClient.dio.get(
      furnitureTypeId == null ? '/api/v1/items/all' : '/api/v1/items/feed',
      queryParameters: {
        'sort': sort,
        'furnitureTypeId': ?furnitureTypeId,
        if (cursor != null) 'cursor': cursor.toString(),
      },
    );

    final data = response.data as List<dynamic>;

    return data
        .map((item) => ItemFeedModel.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }
}
