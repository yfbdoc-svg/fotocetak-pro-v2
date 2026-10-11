/// Edit non-destruktif. Digunakan oleh pratinjau dan eksport PDF.
enum FrameStyle { classic, modern, vintage, minimal }
enum CaptionFont { simple, handwritten }
enum PolaroidSticker { none, heart, star, smile }

class PolaroidEdits {
  final String frameColor;
  final FrameStyle frameStyle;
  final String caption;
  final CaptionFont font;
  final bool showDate;
  final String date;
  final PolaroidSticker sticker;

  const PolaroidEdits({
    this.frameColor = 'white',
    this.frameStyle = FrameStyle.classic,
    this.caption = '',
    this.font = CaptionFont.handwritten,
    this.showDate = false,
    this.date = '',
    this.sticker = PolaroidSticker.none,
  });

  static const colors = <String, int>{
    'white': 0xFFFFFF,
    'cream': 0xFFF3E8D3,
    'pink': 0xFFFFDBE8,
    'sky': 0xFFDCEEFF,
    'black': 0xFF262933,
    'mint': 0xFFDAF0E3,
    'beige': 0xFFF0E1C9,
    'sage': 0xFFD7EABE,
    'lavender': 0xFFDDCAF3,
  };

  int get rgb => colors[frameColor] ?? 0xFFFFFF;
  bool get dark => frameColor == 'black';

  PolaroidEdits copyWith({
    String? frameColor,
    FrameStyle? frameStyle,
    String? caption,
    CaptionFont? font,
    bool? showDate,
    String? date,
    PolaroidSticker? sticker,
  }) => PolaroidEdits(
    frameColor: frameColor ?? this.frameColor,
    frameStyle: frameStyle ?? this.frameStyle,
    caption: caption ?? this.caption,
    font: font ?? this.font,
    showDate: showDate ?? this.showDate,
    date: date ?? this.date,
    sticker: sticker ?? this.sticker,
  );

  Map<String, dynamic> toJson() => {
    'frameColor': frameColor,
    'frameStyle': frameStyle.name,
    'caption': caption,
    'font': font.name,
    'showDate': showDate,
    'date': date,
    'sticker': sticker.name,
  };

  static PolaroidEdits fromJson(Map<String, dynamic> json) {
    T readEnum<T extends Enum>(List<T> values, String? name, T fallback) {
      for (final value in values) {
        if (value.name == name) return value;
      }
      return fallback;
    }
    final colorId = json['frameColor'] as String? ?? 'white';
    return PolaroidEdits(
      frameColor: colors.containsKey(colorId) ? colorId : 'white',
      frameStyle: readEnum(FrameStyle.values, json['frameStyle'] as String?, FrameStyle.classic),
      caption: json['caption'] as String? ?? '',
      font: readEnum(CaptionFont.values, json['font'] as String?, CaptionFont.handwritten),
      showDate: json['showDate'] as bool? ?? false,
      date: json['date'] as String? ?? '',
      sticker: readEnum(PolaroidSticker.values, json['sticker'] as String?, PolaroidSticker.none),
    );
  }
}
