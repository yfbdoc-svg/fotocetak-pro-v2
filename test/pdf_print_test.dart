import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:fotocetak_pro/features/layout_engine/layout_engine.dart';
import 'package:fotocetak_pro/features/print_engine/pdf_print_service.dart';
import 'package:fotocetak_pro/models/paper_settings.dart';
import 'package:fotocetak_pro/models/photo_item.dart';
import 'package:fotocetak_pro/models/photo_size.dart';
import 'package:fotocetak_pro/models/polaroid_edits.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('PDF mode Pas Foto dan Polaroid berhasil di-render', () async {
    // PNG kecil yang sudah dikodekan untuk test; tidak ada foto pribadi.
    const base64Png = 'iVBORw0KGgoAAAANSUhEUgAAAAIAAAACCAIAAAD91JpzAAAAFklEQVR4nGOs3/GQgYGBiYGBgYGBAQAY6AIcHOpqHwAAAABJRU5ErkJggg==';
    final dir = await Directory.systemTemp.createTemp('fcp_pdf_test_');
    addTearDown(() async => dir.delete(recursive: true));
    final file = File('${dir.path}/test.png');
    await file.writeAsBytes(base64Decode(base64Png));
    for (final size in [PhotoSize.passportPresets[1],
        PhotoSize.polaroidPresets[2]]) {
      final photo = PhotoItem(id: 'test', path: file.path, name: 'test.png',
        widthPx: 1, heightPx: 1, size: size,
        edits: const PolaroidEdits(caption: 'Hello',
          sticker: PolaroidSticker.heart));
      const paper = PaperSettings();
      final layout = LayoutEngine.compose([photo], paper);
      final bytes = await PdfPrintService.render(
        photos: [photo], settings: paper, layout: layout);
      expect(bytes.length, greaterThan(500));
      expect(ascii.decode(bytes.sublist(0, 5)), '%PDF-');
    }
  });
}
