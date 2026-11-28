import 'room_visibility.dart';

class RoomFurniture {
  RoomFurniture.fromJson(Map<String, dynamic> json)
    : typeId = (json['furnitureTypeId'] as num).toInt(),
      code = _sceneCode(json),
      hidden = json['hidden'] as bool,
      scene = {...json, 'furnitureTypeCode': _sceneCode(json)};
  // The server currently uses bookshelf for the desk model. Keep the alias
  // scoped to that model so a future real bookshelf stays distinct.
  static String _sceneCode(Map<String, dynamic> json) =>
      json['furnitureTypeCode'] == 'bookshelf' && json['objectNodeName'] == 'desk'
          ? 'desk'
          : json['furnitureTypeCode'] as String;

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
