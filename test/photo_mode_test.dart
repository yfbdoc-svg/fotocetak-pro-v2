import 'package:flutter_test/flutter_test.dart';
import 'package:fotocetak_pro/features/workspace/workspace_controller.dart';
import 'package:fotocetak_pro/models/photo_item.dart';
import 'package:fotocetak_pro/models/photo_size.dart';
import 'package:fotocetak_pro/models/polaroid_edits.dart';

void main() {
  PhotoItem sample() => PhotoItem(id: '1', path: 'not-real.jpg',
    name: 'not-real.jpg', widthPx: 1200, heightPx: 1600,
    size: PhotoSize.defaultSize);

  test('pilihan Pas Foto dan Polaroid tidak boleh bercampur', () {
    final controller = WorkspaceController();
    controller.addPhotos([sample()]);
    expect(controller.mode, PhotoMode.passport);
    expect(controller.photos.single.size.id, 'pas_3x4');
    controller.updatePhoto('1', size: PhotoSize.polaroidPresets.first);
    expect(controller.photos.single.size.id, 'pas_3x4');

    controller.changeMode(PhotoMode.polaroid);
    expect(controller.photos.single.size.id, 'pol_2r');
    controller.updatePhoto('1', size: PhotoSize.passportPresets.first);
    expect(controller.photos.single.size.id, 'pol_2r');
    controller.updatePhoto('1', size: PhotoSize.polaroidPresets.first);
    expect(controller.photos.single.size.id, 'pol_standard');
    controller.changeMode(PhotoMode.passport);
    expect(controller.photos.single.size.id, 'pas_3x4');
    controller.dispose();
  });

  test('semua preset Polaroid sesuai ukuran yang diminta', () {
    final pol = PhotoSize.polaroidPresets;
    expect(pol.length, 7);
    expect(pol[0].widthMm, 88.4);
    expect(pol[0].heightMm, 107.5);
    expect(pol[0].windowWidthMm, 76.8);
    expect(pol[0].windowHeightMm, 78.9);
    expect(pol[1].widthMm, 53.9);
    expect(pol[1].windowHeightMm, 47.0);
    expect(pol[2].widthMm, 60);
    expect(pol[3].heightMm, 75);
    expect(pol[4].heightMm, 90);
    expect(pol[5].heightMm, 127);
    expect(pol[6].heightMm, 150);
  });

  test('edit Polaroid disimpan tanpa merusak data sumber', () {
    final edits = const PolaroidEdits().copyWith(
      frameColor: 'pink', caption: 'Best Day', date: '10/10/2026',
      showDate: true, sticker: PolaroidSticker.heart);
    final restored = PolaroidEdits.fromJson(edits.toJson());
    expect(restored.frameColor, 'pink');
    expect(restored.caption, 'Best Day');
    expect(restored.sticker, PolaroidSticker.heart);
    expect(restored.showDate, isTrue);
  });
}
