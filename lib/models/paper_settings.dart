enum PaperOrientation { portrait, landscape }

class PaperPreset {
  final String id;
  final String label;
  final double widthMm;
  final double heightMm;
  const PaperPreset(this.id, this.label, this.widthMm, this.heightMm);

  static const all = <PaperPreset>[
    PaperPreset('a4', 'A4 · 210 × 297 mm', 210, 297),
    PaperPreset('a5', 'A5 · 148 × 210 mm', 148, 210),
    PaperPreset('letter', 'Letter · 215,9 × 279,4 mm', 215.9, 279.4),
    PaperPreset('4r', '4R · 102 × 152 mm', 102, 152),
  ];

  static PaperPreset byId(String? id) => all.firstWhere(
    (element) => element.id == id,
    orElse: () => all.first,
  );
}

class PaperSettings {
  final PaperPreset paper;
  final PaperOrientation orientation;
  final double marginMm;
  final double gapMm;
  final bool cutMarks;

  const PaperSettings({
    this.paper = const PaperPreset('a4', 'A4 · 210 × 297 mm', 210, 297),
    this.orientation = PaperOrientation.portrait,
    this.marginMm = 5,
    this.gapMm = 3,
    this.cutMarks = true,
  });

  double get widthMm => orientation == PaperOrientation.portrait
      ? paper.widthMm : paper.heightMm;

  double get heightMm => orientation == PaperOrientation.portrait
      ? paper.heightMm : paper.widthMm;

  PaperSettings copyWith({
    PaperPreset? paper,
    PaperOrientation? orientation,
    double? marginMm,
    double? gapMm,
    bool? cutMarks,
  }) => PaperSettings(
    paper: paper ?? this.paper,
    orientation: orientation ?? this.orientation,
    marginMm: marginMm ?? this.marginMm,
    gapMm: gapMm ?? this.gapMm,
    cutMarks: cutMarks ?? this.cutMarks,
  );

  Map<String, dynamic> toJson() => {
    'paper': paper.id,
    'orientation': orientation.name,
    'marginMm': marginMm,
    'gapMm': gapMm,
    'cutMarks': cutMarks,
  };

  static PaperSettings fromJson(Map<String, dynamic> json) => PaperSettings(
    paper: PaperPreset.byId(json['paper'] as String?),
    orientation: json['orientation'] == 'landscape'
        ? PaperOrientation.landscape : PaperOrientation.portrait,
    marginMm: (json['marginMm'] as num?)?.toDouble() ?? 5,
    gapMm: (json['gapMm'] as num?)?.toDouble() ?? 3,
    cutMarks: json['cutMarks'] as bool? ?? true,
  );
}
