import 'room_visibility.dart';

class RoomFurniture {
  RoomFurniture.fromJson(Map<String, dynamic> json)
    : typeId = (json['furnitureTypeId'] as num).toInt(),
      code = json['furnitureTypeCode'] as String,
      hidden = json['hidden'] as bool,
      scene = Map<String, dynamic>.from(json);
  final int typeId;
  final String code;
  final bool hidden;
  final Map<String, dynamic> scene;
}

class RoomData {
  const RoomData({
    required this.id,
    required this.visibility,
    required this.furniture,
    required this.tags,
  });
  final int id;
  final RoomVisibility visibility;
  final List<RoomFurniture> furniture;
  final List<Map<String, dynamic>> tags;
}
