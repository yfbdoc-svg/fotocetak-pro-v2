import 'package:flutter_test/flutter_test.dart';
import 'package:fotocetak_pro/features/layout_engine/layout_engine.dart';
import 'package:fotocetak_pro/models/paper_settings.dart';
import 'package:fotocetak_pro/models/photo_item.dart';
import 'package:fotocetak_pro/models/photo_size.dart';

void main() {
  PhotoItem sample({String id = 'a', int count = 1, PhotoSize? size}) => PhotoItem(
    id: id,
    path: 'test.jpg',
    name: 'test.jpg',
    widthPx: 1200,
    heightPx: 1600,
    size: size ?? PhotoSize.defaultSize,
    quantity: count,
  );

  test('tata-letak mempertahankan jumlah cetakan dan area margin', () {
    final paper = const PaperSettings(marginMm: 5, gapMm: 3);
    final result = LayoutEngine.compose([sample(count: 35)], paper);
    expect(result.placedCount, 35);
    expect(result.warnings, isEmpty);
    for (final page in result.pages) {
      for (final p in page) {
        expect(p.xMm, greaterThanOrEqualTo(paper.marginMm));
        expect(p.yMm, greaterThanOrEqualTo(paper.marginMm));
        expect(p.xMm + p.widthMm,
            lessThanOrEqualTo(paper.widthMm - paper.marginMm + 0.00001));
        expect(p.yMm + p.heightMm,
            lessThanOrEqualTo(paper.heightMm - paper.marginMm + 0.00001));
      }
    }
  });

  test('foto terlalu besar diberi peringatan tanpa keluar halaman', () {
    const small = PaperSettings(paper: PaperPreset('small', 'Kecil', 50, 50));
    final result = LayoutEngine.compose([sample(size: PhotoSize.presets[5])], small);
    expect(result.placedCount, 0);
    expect(result.warnings, isNotEmpty);
  });

  test('pengaturan orientasi mengubah dimensi kertas', () {
    const landscape = PaperSettings(orientation: PaperOrientation.landscape);
    expect(landscape.widthMm, 297);
    expect(landscape.heightMm, 210);
  });
}
