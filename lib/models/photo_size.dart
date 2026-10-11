enum PhotoMode { passport, polaroid }

/// Semua ukuran adalah lebar x tinggi ketika foto dalam orientasi potret.
/// Polaroid memiliki jendela foto tersendiri di dalam ukuran luar kertas.
class PhotoSize {
  final String id;
  final String label;
  final double widthMm;
  final double heightMm;
  final PhotoMode mode;
  final double? imageWidthMm;
  final double? imageHeightMm;

  const PhotoSize(this.id, this.label, this.widthMm, this.heightMm,
      {this.mode = PhotoMode.passport, this.imageWidthMm, this.imageHeightMm});

  bool get isPolaroid => mode == PhotoMode.polaroid;
  double get windowWidthMm => imageWidthMm ?? widthMm;
  double get windowHeightMm => imageHeightMm ?? heightMm;
  double get windowLeftMm => (widthMm - windowWidthMm) / 2;
  double get windowTopMm => isPolaroid
      ? ((heightMm - windowHeightMm) * 0.27).clamp(0.0, heightMm - windowHeightMm).toDouble()
      : 0;
  double get captionHeightMm => heightMm - windowTopMm - windowHeightMm;

  static const passportPresets = <PhotoSize>[
    PhotoSize('pas_2x3', '2 × 3 cm', 20, 30),
    PhotoSize('pas_3x4', '3 × 4 cm', 30, 40),
    PhotoSize('pas_4x6', '4 × 6 cm', 40, 60),
    PhotoSize('pas_3x5', '3 × 5 cm', 30, 50),
    PhotoSize('pas_5x7', '5 × 7 cm', 50, 70),
  ];

  // Angka standar pabrikan yang diberikan pengguna: total 8,84 x 10,75 cm,
  // jendela 7,68 x 7,89 cm; Go 5,39 x 6,66 cm, jendela 4,60 x 4,70 cm.
  static const polaroidPresets = <PhotoSize>[
    PhotoSize('pol_standard', 'Standar SX-70 / 600 / i-Type · 8,84 × 10,75 cm',
        88.4, 107.5, mode: PhotoMode.polaroid,
        imageWidthMm: 76.8, imageHeightMm: 78.9),
    PhotoSize('pol_go', 'Mini Polaroid Go · 5,39 × 6,66 cm',
        53.9, 66.6, mode: PhotoMode.polaroid,
        imageWidthMm: 46.0, imageHeightMm: 47.0),
    PhotoSize('pol_2r', 'Photo Card / 2R · 6 × 9 cm', 60, 90,
        mode: PhotoMode.polaroid, imageWidthMm: 45, imageHeightMm: 70),
    PhotoSize('pol_mini', 'Photo Mini · 5 × 7,5 cm', 50, 75,
        mode: PhotoMode.polaroid, imageWidthMm: 42, imageHeightMm: 56),
    PhotoSize('pol_square', 'Square · 9 × 9 cm', 90, 90,
        mode: PhotoMode.polaroid, imageWidthMm: 85, imageHeightMm: 85),
    PhotoSize('pol_3r', '3R · 9 × 12,7 cm', 90, 127,
        mode: PhotoMode.polaroid, imageWidthMm: 80, imageHeightMm: 99),
    PhotoSize('pol_4r', '4R · 10 × 15 cm', 100, 150,
        mode: PhotoMode.polaroid, imageWidthMm: 90, imageHeightMm: 120),
  ];

  // Ukuran cetak biasa dari tahap 1 tetap dapat dibaca dari proyek lama.
  static const legacy = <PhotoSize>[
    PhotoSize('2r', '2R · 6 × 9 cm', 60, 90),
    PhotoSize('3r', '3R · 8,9 × 12,7 cm', 89, 127),
    PhotoSize('4r', '4R · 10,2 × 15,2 cm', 102, 152),
    PhotoSize('5r', '5R · 12,7 × 17,8 cm', 127, 178),
    PhotoSize('6r', '6R · 15,2 × 20,3 cm', 152, 203),
    PhotoSize('8r', '8R · 20,3 × 25,4 cm', 203, 254),
  ];

  static const presets = <PhotoSize>[...passportPresets, ...polaroidPresets, ...legacy];
  static PhotoSize get defaultSize => passportPresets[1];
  static PhotoSize defaultFor(PhotoMode mode) =>
      mode == PhotoMode.passport ? defaultSize : polaroidPresets[2];
  static List<PhotoSize> forMode(PhotoMode mode) =>
      mode == PhotoMode.passport ? passportPresets : polaroidPresets;

  static PhotoSize byId(String? id) {
    for (final size in presets) {
      if (size.id == id) return size;
    }
    return defaultSize;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'widthMm': widthMm,
        'heightMm': heightMm,
        'mode': mode.name,
        'imageWidthMm': imageWidthMm,
        'imageHeightMm': imageHeightMm,
      };

  static PhotoSize fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String? ?? '';
    for (final preset in presets) {
      if (preset.id == id) return preset;
    }
    return PhotoSize(
      id.isEmpty ? 'custom' : id,
      json['label'] as String? ?? 'Ukuran Khusus',
      (json['widthMm'] as num).toDouble(),
      (json['heightMm'] as num).toDouble(),
      mode: json['mode'] == 'polaroid' ? PhotoMode.polaroid : PhotoMode.passport,
      imageWidthMm: (json['imageWidthMm'] as num?)?.toDouble(),
      imageHeightMm: (json['imageHeightMm'] as num?)?.toDouble(),
    );
  }
}
