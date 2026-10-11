import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

import '../../models/paper_settings.dart';
import '../../models/photo_item.dart';
import '../../models/photo_size.dart';

class LoadedProject {
  final List<PhotoItem> photos;
  final PaperSettings settings;
  final List<String> missingFiles;
  final PhotoMode mode;
  const LoadedProject(this.photos, this.settings, this.missingFiles, this.mode);
}

class ProjectService {
  static Future<bool> save(
    List<PhotoItem> photos,
    PaperSettings settings,
    PhotoMode mode,
  ) async {
    final payload = <String, dynamic>{
      'app': 'FotoCetak Pro',
      'formatVersion': 2,
      'photoMode': mode.name,
      'settings': settings.toJson(),
      'photos': photos.map((p) => p.toJson()).toList(),
    };
    final contents = const JsonEncoder.withIndent('  ').convert(payload);
    final saved = await FilePicker.saveFile(
      dialogTitle: 'Simpan Proyek FotoCetak Pro',
      fileName: 'proyek-foto.fcp',
      type: FileType.custom,
      allowedExtensions: ['fcp'],
      mimeType: 'application/json',
      bytes: Uint8List.fromList(utf8.encode(contents)),
    );
    return saved != null;
  }

  static Future<LoadedProject?> open() async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['fcp', 'json'],
    );
    if (file?.path == null) return null;
    final decoded = jsonDecode(await File(file!.path!).readAsString());
    if (decoded is! Map || (decoded['formatVersion'] != 1 && decoded['formatVersion'] != 2)) {
      throw const FormatException('Format proyek belum didukung.');
    }
    final map = Map<String, dynamic>.from(decoded);
    final rawPhotos = (map['photos'] as List?) ?? [];
    final missing = <String>[];
    final photos = <PhotoItem>[];
    for (final raw in rawPhotos) {
      final photo = PhotoItem.fromJson(Map<String, dynamic>.from(raw as Map));
      if (await File(photo.path).exists()) {
        photos.add(photo);
      } else {
        missing.add(photo.path);
      }
    }
    return LoadedProject(
      photos,
      PaperSettings.fromJson(Map<String, dynamic>.from(map['settings'] as Map)),
      missing,
      map['photoMode'] == 'polaroid' ? PhotoMode.polaroid : PhotoMode.passport,
    );
  }
}
