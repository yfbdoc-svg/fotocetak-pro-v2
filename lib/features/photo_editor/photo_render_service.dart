import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import '../../models/photo_item.dart';

/// Renderer tunggal untuk pratinjau dan PDF Pas Foto.
/// Semua efek bersifat non-destruktif. File sumber tidak pernah ditulis ulang.
///
/// Warna latar hanya mengisi area kosong mode FIT, bukan otomatis menghapus
/// latar belakang subjek. Penggantian background subjek membutuhkan segmentasi.
class PhotoRenderService {
  static final Map<String, Future<Uint8List>> _memo = {};

  static Future<Uint8List> render(PhotoItem photo, {int ppi = 300}) {
    final edits = photo.photoEdits;
    final key = [
      photo.path,
      ppi,
      photo.size.id,
      photo.size.widthMm,
      photo.size.heightMm,
      photo.fit.name,
      edits.quarterTurns,
      edits.flipHorizontal,
      edits.brightness,
      edits.contrast,
      edits.saturation,
      edits.zoom,
      edits.focusX,
      edits.focusY,
      edits.paddingColor,
    ].join('|');
    if (_memo.length > 48) _memo.clear();
    return _memo.putIfAbsent(key, () async {
      try {
        return await _render(photo, ppi: ppi);
      } catch (_) {
        _memo.remove(key);
        rethrow;
      }
    });
  }

  static Future<Uint8List> _render(PhotoItem photo, {required int ppi}) async {
    final mmW = photo.size.windowWidthMm;
    final mmH = photo.size.windowHeightMm;
    final outputW = (mmW / 25.4 * ppi).round().clamp(1, 3200).toInt();
    final outputH = (mmH / 25.4 * ppi).round().clamp(1, 3200).toInt();

    final sourceBytes = await File(photo.path).readAsBytes();
    final codec = await ui.instantiateImageCodec(
      sourceBytes,
      targetWidth: math.min(photo.widthPx, 3500),
    );
    try {
      final frame = await codec.getNextFrame();
      final source = frame.image;
      try {
        final edits = photo.photoEdits;
        final recorder = ui.PictureRecorder();
        final canvas = ui.Canvas(recorder);
        final canvasW = outputW.toDouble();
        final canvasH = outputH.toDouble();
        final outputRect = ui.Rect.fromLTWH(0, 0, canvasW, canvasH);
        final rgb = edits.backgroundRgb;
        canvas.drawRect(
          outputRect,
          ui.Paint()..color = ui.Color(0xFF000000 | rgb),
        );
        canvas.save();
        canvas.clipRect(outputRect);
        final sourceW = source.width.toDouble();
        final sourceH = source.height.toDouble();
        final turns = edits.quarterTurns % 4;
        final rotatedW = turns.isOdd ? sourceH : sourceW;
        final rotatedH = turns.isOdd ? sourceW : sourceH;
        final fit = photo.fit == PhotoFit.cover
            ? math.max(canvasW / rotatedW, canvasH / rotatedH)
            : math.min(canvasW / rotatedW, canvasH / rotatedH);
        final scale = fit * edits.zoom;
        final usedW = rotatedW * scale;
        final usedH = rotatedH * scale;
        final overflowX = math.max(0.0, usedW - canvasW);
        final overflowY = math.max(0.0, usedH - canvasH);
        final dx = canvasW / 2 - (edits.focusX - .5) * overflowX;
        final dy = canvasH / 2 - (edits.focusY - .5) * overflowY;

        canvas.translate(dx, dy);
        if (edits.flipHorizontal) canvas.scale(-1, 1);
        canvas.rotate(turns * math.pi / 2);
        final sourceRect = ui.Rect.fromLTWH(0, 0, sourceW, sourceH);
        final destRect = ui.Rect.fromCenter(
          center: ui.Offset.zero,
          width: sourceW * scale,
          height: sourceH * scale,
        );
        canvas.drawImageRect(
          source,
          sourceRect,
          destRect,
          ui.Paint()
            ..isAntiAlias = true
            ..filterQuality = ui.FilterQuality.high
            ..colorFilter = ui.ColorFilter.matrix(_matrix(
              brightness: edits.brightness,
              contrast: edits.contrast,
              saturation: edits.saturation,
            )),
        );
        canvas.restore();
        final picture = recorder.endRecording();
        try {
          final rendered = await picture.toImage(outputW, outputH);
          try {
            final bytes = await rendered.toByteData(format: ui.ImageByteFormat.png);
            if (bytes == null) throw StateError('Gagal membuat preview foto.');
            return bytes.buffer.asUint8List();
          } finally {
            rendered.dispose();
          }
        } finally {
          picture.dispose();
        }
      } finally {
        source.dispose();
      }
    } finally {
      codec.dispose();
    }
  }

  static List<double> _matrix({
    required double brightness,
    required double contrast,
    required double saturation,
  }) {
    final s = 1 + saturation / 100;
    final c = 1 + contrast / 100;
    final offset = 128 * (1 - c) + brightness * 1.65;
    const r = .213, g = .715, b = .072;
    final r0 = (1 - s) * r;
    final g0 = (1 - s) * g;
    final b0 = (1 - s) * b;
    return [
      (r0 + s) * c, g0 * c, b0 * c, 0, offset,
      r0 * c, (g0 + s) * c, b0 * c, 0, offset,
      r0 * c, g0 * c, (b0 + s) * c, 0, offset,
      0, 0, 0, 1, 0,
    ];
  }
}
