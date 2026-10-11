import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../models/paper_settings.dart';
import '../../models/photo_item.dart';
import '../../models/photo_placement.dart';
import '../../models/polaroid_edits.dart';
import '../photo_editor/photo_render_service.dart';

class PdfPrintService {
  static double mm(double value) => value * PdfPageFormat.mm;

  static Future<Uint8List> render({
    required List<PhotoItem> photos,
    required PaperSettings settings,
    required LayoutResult layout,
  }) async {
    final document = pw.Document(compress: true);
    final byId = {for (final photo in photos) photo.id: photo};
    final images = <String, pw.MemoryImage>{};

    for (final page in layout.pages) {
      for (final p in page) {
        if (!images.containsKey(p.photoId)) {
          final photo = byId[p.photoId];
          if (photo != null) {
            images[p.photoId] = pw.MemoryImage(await PhotoRenderService.render(photo));
          }
        }
      }
    }

    for (final placements in layout.pages) {
      if (placements.isEmpty) continue;
      document.addPage(pw.Page(
        pageFormat: PdfPageFormat(mm(settings.widthMm), mm(settings.heightMm)),
        margin: pw.EdgeInsets.zero,
        build: (_) => pw.SizedBox(
          width: mm(settings.widthMm), height: mm(settings.heightMm),
          child: pw.Stack(children: [
          for (final p in placements)
            if (images.containsKey(p.photoId) && byId.containsKey(p.photoId))
              ..._photoWidgets(p, byId[p.photoId]!, images[p.photoId]!),
          if (settings.cutMarks)
            for (final p in placements) ..._cutMarks(p),
          ]),
        ),
      ));
    }
    return document.save();
  }

  /// Satu sumber posisi dalam satuan mm untuk image, frame, dan trim marks.
  static List<pw.Widget> _photoWidgets(PhotoPlacement p, PhotoItem photo,
      pw.MemoryImage image) {
    final size = photo.size;
    if (!size.isPolaroid) {
      return [pw.Positioned(
        left: mm(p.xMm), top: mm(p.yMm),
        child: pw.SizedBox(width: mm(p.widthMm), height: mm(p.heightMm),
          child: pw.Image(image, fit: pw.BoxFit.fill)),
      )];
    }

    final edits = photo.edits;
    final bgcolor = _pdfColor(edits.rgb);
    final ink = edits.dark ? PdfColors.white : PdfColors.blueGrey900;
    final captionVisible = size.captionHeightMm >= 7;
    final left = p.xMm;
    final top = p.yMm;
    final result = <pw.Widget>[
      pw.Positioned(left: mm(left), top: mm(top),
        child: pw.Container(width: mm(p.widthMm), height: mm(p.heightMm),
          color: bgcolor)),
      if (edits.frameStyle == FrameStyle.vintage)
        pw.Positioned(left: mm(left), top: mm(top),
          child: pw.Container(width: mm(p.widthMm), height: mm(p.heightMm),
            decoration: pw.BoxDecoration(border:
              pw.Border.all(color: PdfColors.brown300, width: .7)))),
      if (edits.frameStyle == FrameStyle.minimal)
        pw.Positioned(left: mm(left), top: mm(top),
          child: pw.Container(width: mm(p.widthMm), height: mm(p.heightMm),
            decoration: pw.BoxDecoration(border:
              pw.Border.all(color: edits.dark ? PdfColors.white : PdfColors.blueGrey300,
                width: .45)))),
      pw.Positioned(
        left: mm(left + size.windowLeftMm),
        top: mm(top + size.windowTopMm),
        child: pw.SizedBox(width: mm(size.windowWidthMm),
          height: mm(size.windowHeightMm),
          child: pw.Image(image, fit: pw.BoxFit.fill)),
      ),
      if (edits.frameStyle == FrameStyle.modern)
        pw.Positioned(
          left: mm(left + size.windowLeftMm),
          top: mm(top + size.windowTopMm),
          child: pw.Container(
            width: mm(size.windowWidthMm), height: mm(size.windowHeightMm),
            decoration: pw.BoxDecoration(border: pw.Border.all(
              color: edits.dark ? PdfColors.white : PdfColors.blueGrey400,
              width: .35))),
        ),
    ];

    if (captionVisible) {
      final caption = edits.caption.trim();
      final date = edits.showDate ? edits.date.trim() : '';
      final topText = top + size.windowTopMm + size.windowHeightMm + 1;
      if (caption.isNotEmpty) {
        result.add(pw.Positioned(
          left: mm(left + 2.5), top: mm(topText),
          child: pw.SizedBox(width: mm(size.widthMm - 5), height: mm(4.2),
            child: pw.Center(child: pw.Text(_printableText(caption), maxLines: 1,
              style: pw.TextStyle(color: ink,
                font: edits.font == CaptionFont.handwritten
                  ? pw.Font.courierOblique() : pw.Font.helvetica(),
                fontSize: mm(2.7))))),
        ));
      }
      if (date.isNotEmpty && size.captionHeightMm >= 10) {
        result.add(pw.Positioned(
          left: mm(left + 2.5),
          top: mm(topText + (caption.isEmpty ? 0 : 4.2)),
          child: pw.SizedBox(width: mm(size.widthMm - 5), height: mm(3.4),
            child: pw.Center(child: pw.Text(_printableText(date), maxLines: 1,
              style: pw.TextStyle(color: ink,
                font: pw.Font.helvetica(), fontSize: mm(1.9))))),
        ));
      }
    }

    if (edits.sticker != PolaroidSticker.none) {
      final stickerSize = (size.widthMm * .13).clamp(5.0, 11.0).toDouble();
      result.add(pw.Positioned(
        left: mm(left + size.widthMm - size.windowLeftMm - stickerSize - 1),
        top: mm(top + size.windowTopMm + 1),
        child: pw.SvgImage(svg: _stickerSvg(edits.sticker),
          width: mm(stickerSize), height: mm(stickerSize)),
      ));
    }
    return result;
  }

  // Font bawaan PDF hanya mencakup karakter Latin; ganti glif non-Latin
  // dengan tanda tanya agar ekspor tidak gagal tanpa font tambahan.
  static String _printableText(String text) => text.runes.map(
      (code) => (code >= 32 && code <= 255)
          ? String.fromCharCode(code) : '?').join();

  static PdfColor _pdfColor(int rgb) => PdfColor(
      ((rgb >> 16) & 255) / 255,
      ((rgb >> 8) & 255) / 255,
      (rgb & 255) / 255);

  static String _stickerSvg(PolaroidSticker sticker) {
    final body = switch (sticker) {
      PolaroidSticker.heart =>
        '<path d="M50 88 C20 66 6 51 6 31 C6 7 36 5 50 25 C64 5 94 7 94 31 C94 51 80 66 50 88Z" fill="#EE568A"/>',
      PolaroidSticker.star =>
        '<path d="M50 6 L62 36 L94 37 L69 57 L78 90 L50 72 L22 90 L31 57 L6 37 L38 36Z" fill="#F4B63F"/>',
      PolaroidSticker.smile =>
        '<circle cx="50" cy="50" r="44" fill="#459FD6"/><circle cx="34" cy="40" r="5" fill="white"/><circle cx="66" cy="40" r="5" fill="white"/><path d="M27 59 Q50 84 73 59" fill="none" stroke="white" stroke-width="7" stroke-linecap="round"/>',
      PolaroidSticker.none => '',
    };
    return '<svg xmlns="http://www.w3.org/2000/svg" width="100" height="100" viewBox="0 0 100 100">$body</svg>';
  }

  /// Empat tanda potong, masing-masing dua garis di luar bidang foto.
  /// Sengaja tidak menimpa permukaan foto.
  static List<pw.Widget> _cutMarks(PhotoPlacement p) {
    final marks = <pw.Widget>[];
    const extension = 1.7; // mm
    const gap = 0.2; // mm
    const width = 0.22; // points
    final x1 = p.xMm, x2 = p.xMm + p.widthMm;
    final y1 = p.yMm, y2 = p.yMm + p.heightMm;
    for (final x in [x1, x2]) {
      for (final y in [y1, y2]) {
        final signX = x == x1 ? -1.0 : 1.0;
        final signY = y == y1 ? -1.0 : 1.0;
        final hx = signX < 0 ? x - extension : x + gap;
        final hy = signY < 0 ? y - extension : y + gap;
        marks.add(pw.Positioned(
          left: mm(hx), top: mm(y) - width / 2,
          child: pw.Container(width: mm(extension - gap), height: width,
            color: PdfColors.blueGrey700),
        ));
        marks.add(pw.Positioned(
          left: mm(x) - width / 2, top: mm(hy),
          child: pw.Container(width: width, height: mm(extension - gap),
            color: PdfColors.blueGrey700),
        ));
      }
    }
    return marks;
  }

  static Future<bool> exportPdf(Uint8List bytes) async {
    final output = await FilePicker.saveFile(
      dialogTitle: 'Ekspor Layout Foto PDF',
      fileName: 'fotocetak-pro.pdf',
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      mimeType: 'application/pdf',
      bytes: bytes,
    );
    return output != null;
  }

  static Future<void> printPdf(Uint8List bytes) async {
    await Printing.layoutPdf(
      name: 'FotoCetak Pro',
      onLayout: (format) async => bytes,
    );
  }
}
