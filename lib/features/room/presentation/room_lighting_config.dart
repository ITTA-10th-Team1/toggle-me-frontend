/// The third designer export has no embedded light.
/// Use normal viewer exposure with the existing studio environment.
abstract final class RoomLightingConfig {
  // The bundled legacy studio environment gives the two walls distinct shading.
  static const environment = 'legacy';
  static const exposure = 1.0;
  // Viewer shadows ground the whole room; they do not bake furniture shadows.
  static const shadowIntensity = 0.75;
  static const shadowSoftness = 1.0;
}
