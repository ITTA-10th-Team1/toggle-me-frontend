class ItemFeedModel {
  const ItemFeedModel({
    required this.id,
    required this.furnitureTypeId,
    required this.recordedOn,
    required this.imageUrl,
    this.memo,
    required this.visibility,
    required this.tags,
    required this.createdAt,
  });

  final int id;
  final int furnitureTypeId;
  final String recordedOn;
  final String imageUrl;
  final String? memo;
  final String visibility;
  final List<String> tags;
  final DateTime createdAt;

  factory ItemFeedModel.fromJson(Map<String, dynamic> json) {
    return ItemFeedModel(
      id: (json['id'] as num).toInt(),
      furnitureTypeId: (json['furnitureTypeId'] as num).toInt(),
      recordedOn: json['recordedOn'] as String,
      imageUrl: json['imageUrl'] as String,
      memo: json['memo'] as String?,
      visibility: json['visibility'] as String,
      tags: (json['tags'] as List<dynamic>? ?? [])
          .map((tag) => tag.toString())
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
