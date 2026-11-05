import '../../../core/network/api_client.dart';
import '../data/item_feed_model.dart';

class FeedRepository {
  FeedRepository(this._apiClient);

  final ApiClient _apiClient;

  /// 내 기록 전체 조회
  Future<List<ItemFeedModel>> getAllItems({
    String sort = 'LATEST',
    int? cursor,
  }) async {
    final response = await _apiClient.dio.get(
      '/api/v1/items/all',
      queryParameters: {
        'sort': sort,
        if (cursor != null) 'cursor': cursor.toString(),
      },
    );

    final data = response.data as List<dynamic>;

    return data
        .map((item) => ItemFeedModel.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }
}
