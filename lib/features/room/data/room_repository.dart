import '../../../core/network/member_api.dart';
import '../domain/room_data.dart';
import '../domain/room_visibility.dart';

class RoomRepository {
  RoomRepository(this.api);
  final MemberApi api;

  Future<Map<String, dynamic>> me() async => Map<String, dynamic>.from(
    await api.request('GET', '/api/v1/members/me') as Map,
  );

  Future<List<Map<String, dynamic>>> list(String path) async =>
      (await api.request('GET', path) as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

  Future<RoomData?> load() async {
    final rooms = await list('/api/v1/rooms');
    if (rooms.isEmpty) return null;
    final room = rooms.first;
    final id = (room['id'] as num).toInt();
    final floors = await list('/api/v1/rooms/$id/floors');
    final floor = floors.where((e) => e['floorNumber'] == 1).firstOrNull;
    if (floor == null) {
      throw const MemberApiException('FLOOR_MISSING', '방의 1층 정보를 찾지 못했어요.');
    }
    final furniture = await list(
      '/api/v1/rooms/$id/floors/${floor['id']}/furniture',
    );
    final tags = await list('/api/v1/rooms/$id/tags');
    return RoomData(
      id: id,
      visibility: RoomVisibility.parse(room['visibility'] as String),
      furniture: furniture.map(RoomFurniture.fromJson).toList(),
      tags: tags,
    );
  }

  Future<RoomVisibility> visibility(int roomId, RoomVisibility value) async {
    final result = await api.request(
      'PATCH',
      '/api/v1/rooms/$roomId/visibility',
      data: {'visibility': value.wireValue},
    );
    return RoomVisibility.parse(result['visibility'] as String);
  }

  Future<int> create(List<int> variants, RoomVisibility visibility) async {
    final body = await api.request(
      'POST',
      '/api/v1/members/onboarding',
      data: {
        'furnitureVariantIds': variants,
        'visibility': visibility.wireValue,
      },
    );
    return (body['roomId'] as num).toInt();
  }
}
