enum RoomVisibility {
  socialOn('SOCIAL_ON'),
  socialOff('SOCIAL_OFF');

  const RoomVisibility(this.wireValue);
  final String wireValue;
  bool get isPublic => this == socialOn;
  static RoomVisibility parse(String value) => switch (value) {
    'SOCIAL_ON' => socialOn,
    'SOCIAL_OFF' => socialOff,
    _ => throw FormatException('Unknown room visibility: $value'),
  };
}
