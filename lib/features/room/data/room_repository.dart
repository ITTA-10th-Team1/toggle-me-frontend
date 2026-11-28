import '../../../core/network/member_api.dart';
import '../domain/room_data.dart';
import '../domain/room_visibility.dart';

class RoomRepository {
  RoomRepository(this.api);
  final MemberApi api;

  Future<Map<String, dynamic>> me({MemberApiSession? session}) async =>
      Map<String, dynamic>.from(
        await _request('GET', '/api/v1/members/me', session: session) as Map,
      );

  Future<dynamic> _request(
    String method,
    String path, {
    Object? data,
    MemberApiSession? session,
  }) => session == null
      ? api.request(method, path, data: data)
      : session.request(method, path, data: data);

  Future<List<Map<String, dynamic>>> list(
    String path, {
    MemberApiSession? session,
  }) async => (await _request('GET', path, session: session) as List)
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

  Future<RoomVisibility> visibility(
    int roomId,
    RoomVisibility value, {
    MemberApiSession? session,
  }) async {
    final result = await _request(
      'PATCH',
      '/api/v1/rooms/$roomId/visibility',
      data: {'visibility': value.wireValue},
      session: session,
    );
    return RoomVisibility.parse(result['visibility'] as String);
  }

  Future<int> create(
    List<int> variants,
    RoomVisibility visibility, {
    MemberApiSession? session,
  }) async {
    final body = await _request(
      'POST',
      '/api/v1/members/onboarding',
      data: {
        'furnitureVariantIds': variants,
        'visibility': visibility.wireValue,
      },
      session: session,
    );
    return (body['roomId'] as num).toInt();
  }
}
