import 'photo_size.dart';
import 'photo_edits.dart';
import 'polaroid_edits.dart';

enum PhotoFit { cover, contain }

class PhotoItem {
  final String id;
  final String path;
  final String name;
  final int widthPx;
  final int heightPx;
  final PhotoSize size;
  final int quantity;
  final PhotoFit fit;
  final PolaroidEdits edits;
  final PhotoEdits photoEdits;

  const PhotoItem({
    required this.id,
    required this.path,
    required this.name,
    required this.widthPx,
    required this.heightPx,
    required this.size,
    this.quantity = 1,
    this.fit = PhotoFit.cover,
    this.edits = const PolaroidEdits(),
    this.photoEdits = const PhotoEdits(),
  });

  PhotoItem copyWith({PhotoSize? size, int? quantity, PhotoFit? fit,
      PolaroidEdits? edits, PhotoEdits? photoEdits}) => PhotoItem(
    id: id,
    path: path,
    name: name,
    widthPx: widthPx,
    heightPx: heightPx,
    size: size ?? this.size,
    quantity: quantity ?? this.quantity,
    fit: fit ?? this.fit,
    edits: edits ?? this.edits,
    photoEdits: photoEdits ?? this.photoEdits,
  );

  double get effectivePpi {
    // Hitung berdasarkan jendela gambar (bukan bingkai Polaroid).
    final x = widthPx / (size.windowWidthMm / 25.4);
    final y = heightPx / (size.windowHeightMm / 25.4);
    return x < y ? x : y;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'path': path,
    'name': name,
    'widthPx': widthPx,
    'heightPx': heightPx,
    'size': size.toJson(),
    'quantity': quantity,
    'fit': fit.name,
    'edits': edits.toJson(),
    'photoEdits': photoEdits.toJson(),
  };

  static PhotoItem fromJson(Map<String, dynamic> json) => PhotoItem(
    id: json['id'] as String,
    path: json['path'] as String,
    name: json['name'] as String,
    widthPx: (json['widthPx'] as num).toInt(),
    heightPx: (json['heightPx'] as num).toInt(),
    size: PhotoSize.fromJson(Map<String, dynamic>.from(json['size'] as Map)),
    quantity: (json['quantity'] as num?)?.toInt() ?? 1,
    fit: json['fit'] == 'contain' ? PhotoFit.contain : PhotoFit.cover,
    photoEdits: json['photoEdits'] is Map
        ? PhotoEdits.fromJson(Map<String, dynamic>.from(json['photoEdits'] as Map))
        : const PhotoEdits(),
    edits: json['edits'] is Map
        ? PolaroidEdits.fromJson(Map<String, dynamic>.from(json['edits'] as Map))
        : const PolaroidEdits(),
  );
}
