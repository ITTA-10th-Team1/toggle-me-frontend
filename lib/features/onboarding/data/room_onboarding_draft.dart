import '../../room/domain/room_visibility.dart';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Carries the choice from the landing screen across login/profile screens.
/// Only the pending choice, never tokens or a fake room ID.
class RoomOnboardingDraft {
  static const _key = 'pendingRoomVisibility';
  final _storage = const FlutterSecureStorage();
  RoomVisibility visibility = RoomVisibility.socialOn;
  void reset() => visibility = RoomVisibility.socialOn;
  Future<void> persist() =>
      _storage.write(key: _key, value: visibility.wireValue);
  Future<void> restore() async {
    final saved = await _storage.read(key: _key);
    if (saved != null) visibility = RoomVisibility.parse(saved);
  }

  Future<void> clear() async {
    await _storage.delete(key: _key);
    reset();
  }
}

final roomOnboardingDraft = RoomOnboardingDraft();
