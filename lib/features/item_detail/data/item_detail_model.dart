class ItemDetailModel {
  const ItemDetailModel({
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

  bool get isPublic => visibility.toUpperCase() == 'PUBLIC';

  factory ItemDetailModel.fromJson(Map<String, dynamic> json) {
    return ItemDetailModel(
      id: (json['id'] as num).toInt(),
      furnitureTypeId: (json['furnitureTypeId'] as num).toInt(),
      recordedOn: json['recordedOn']?.toString() ?? '',
      imageUrl: json['imageUrl']?.toString() ?? '',
      memo: json['memo']?.toString(),
      visibility: json['visibility']?.toString() ?? 'PRIVATE',
      tags: (json['tags'] as List<dynamic>? ?? [])
          .map((tag) => tag.toString())
          .toList(),
      createdAt: DateTime.parse(json['createdAt'].toString()),
    );
  }
}
