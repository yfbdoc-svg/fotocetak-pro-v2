/// Perubahan foto non-destruktif. Angka disimpan di proyek dan dipakai ulang
/// oleh tampilan serta ekspor PDF melalui PhotoRenderService.
class PhotoEdits {
  final int quarterTurns;
  final bool flipHorizontal;
  final double brightness;
  final double contrast;
  final double saturation;
  final double focusX;
  final double focusY;
  final double zoom;
  final String paddingColor;

  const PhotoEdits({
    this.quarterTurns = 0,
    this.flipHorizontal = false,
    this.brightness = 0,
    this.contrast = 0,
    this.saturation = 0,
    this.focusX = .5,
    this.focusY = .5,
    this.zoom = 1,
    this.paddingColor = 'white',
  });

  static const palette = <String, int>{
    'white': 0xFFFFFF,
    'gray': 0xE5E7EB,
    'red': 0xFFE14A53,
    'blue': 0xFF51B5E5,
    'pink': 0xFFF1A5CE,
    'black': 0xFF2F343C,
  };

  int get backgroundRgb => palette[paddingColor] ?? 0xFFFFFF;

  PhotoEdits copyWith({
    int? quarterTurns,
    bool? flipHorizontal,
    double? brightness,
    double? contrast,
    double? saturation,
    double? focusX,
    double? focusY,
    double? zoom,
    String? paddingColor,
  }) => PhotoEdits(
    quarterTurns: quarterTurns ?? this.quarterTurns,
    flipHorizontal: flipHorizontal ?? this.flipHorizontal,
    brightness: brightness ?? this.brightness,
    contrast: contrast ?? this.contrast,
    saturation: saturation ?? this.saturation,
    focusX: focusX ?? this.focusX,
    focusY: focusY ?? this.focusY,
    zoom: zoom ?? this.zoom,
    paddingColor: paddingColor ?? this.paddingColor,
  );

  Map<String, dynamic> toJson() => {
    'quarterTurns': quarterTurns,
    'flipHorizontal': flipHorizontal,
    'brightness': brightness,
    'contrast': contrast,
    'saturation': saturation,
    'focusX': focusX,
    'focusY': focusY,
    'zoom': zoom,
    'paddingColor': paddingColor,
  };

  static PhotoEdits fromJson(Map<String, dynamic> json) => PhotoEdits(
    quarterTurns: ((json['quarterTurns'] as num?)?.toInt() ?? 0) % 4,
    flipHorizontal: json['flipHorizontal'] == true,
    brightness: ((json['brightness'] as num?)?.toDouble() ?? 0).clamp(-100, 100).toDouble(),
    contrast: ((json['contrast'] as num?)?.toDouble() ?? 0).clamp(-100, 100).toDouble(),
    saturation: ((json['saturation'] as num?)?.toDouble() ?? 0).clamp(-100, 100).toDouble(),
    focusX: ((json['focusX'] as num?)?.toDouble() ?? .5).clamp(0, 1).toDouble(),
    focusY: ((json['focusY'] as num?)?.toDouble() ?? .5).clamp(0, 1).toDouble(),
    zoom: ((json['zoom'] as num?)?.toDouble() ?? 1).clamp(1, 3).toDouble(),
    paddingColor: palette.containsKey(json['paddingColor'])
        ? json['paddingColor'] as String : 'white',
  );
}
