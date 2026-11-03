import '../../room/domain/room_visibility.dart';

/// Carries the choice from the landing screen across login/profile screens.
/// Only the pending choice, never tokens or a fake room ID. In-memory only.
class RoomOnboardingDraft {
  RoomVisibility visibility = RoomVisibility.socialOn;
  void reset() => visibility = RoomVisibility.socialOn;
}

final roomOnboardingDraft = RoomOnboardingDraft();
