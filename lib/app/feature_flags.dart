/// Feature flags for gating modular capabilities across the application.
abstract final class FeatureFlags {
  FeatureFlags._();

  /// Whether premium tier features are unlocked.
  static const bool premiumEnabled = false;

  /// Whether sound playback is enabled.
  static const bool soundEnabled = false;

  /// Whether the AI adaptive engine for question difficulty is enabled.
  static const bool adaptiveEngineEnabled = false;

  /// Whether the AI coach guidance feature is enabled.
  static const bool coachEnabled = false;

  /// Whether specialized exam packs are enabled.
  static const bool examPacksEnabled = false;
}
