import 'dart:io';
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';

import '../../models/photo_item.dart';
import '../../models/photo_size.dart';

class PhotoImportResult {
  final List<PhotoItem> photos;
  final List<String> errors;
  const PhotoImportResult(this.photos, this.errors);
}

class PhotoImportService {
  static Future<PhotoImportResult> pickPhotos() async {
    final selected = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'bmp', 'webp'],
    );
    final photos = <PhotoItem>[];
    final errors = <String>[];
    for (var index = 0; index < selected.length; index++) {
      final file = selected[index];
      final path = file.path;
      if (path == null || !File(path).existsSync()) {
        errors.add('${file.name}: berkas tidak ditemukan.');
        continue;
      }
      ui.ImmutableBuffer? buffer;
      ui.ImageDescriptor? descriptor;
      try {
        // Membaca metadata gambar tanpa melakukan decode piksel penuh.
        buffer = await ui.ImmutableBuffer.fromFilePath(path);
        descriptor = await ui.ImageDescriptor.encoded(buffer);
        photos.add(PhotoItem(
          id: '${DateTime.now().microsecondsSinceEpoch}_$index',
          path: path,
          name: file.name,
          widthPx: descriptor.width,
          heightPx: descriptor.height,
          size: PhotoSize.defaultSize,
        ));
      } catch (_) {
        errors.add('${file.name}: format tidak didukung atau rusak.');
      } finally {
        descriptor?.dispose();
        buffer?.dispose();
      }
    }
    return PhotoImportResult(photos, errors);
  }
}
