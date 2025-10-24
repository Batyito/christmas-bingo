class EffectsSettings {
  final bool showSnow;
  final bool showTwinkles;
  final bool showBunnies;
  final bool showFloaters;
  final bool enableStampSound;

  const EffectsSettings({
    this.showSnow = true,
    this.showTwinkles = true,
    this.showBunnies = true,
    this.showFloaters = true,
    this.enableStampSound = true,
  });

  EffectsSettings copyWith({
    bool? showSnow,
    bool? showTwinkles,
    bool? showBunnies,
    bool? showFloaters,
    bool? enableStampSound,
  }) {
    return EffectsSettings(
      showSnow: showSnow ?? this.showSnow,
      showTwinkles: showTwinkles ?? this.showTwinkles,
      showBunnies: showBunnies ?? this.showBunnies,
      showFloaters: showFloaters ?? this.showFloaters,
      enableStampSound: enableStampSound ?? this.enableStampSound,
    );
  }
}
