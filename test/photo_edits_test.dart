import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:fotocetak_pro/features/photo_editor/photo_render_service.dart';
import 'package:fotocetak_pro/features/workspace/workspace_controller.dart';
import 'package:fotocetak_pro/models/photo_edits.dart';
import 'package:fotocetak_pro/models/photo_item.dart';
import 'package:fotocetak_pro/models/photo_size.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('pengaturan editor tersimpan dan bisa dibuka ulang', () {
    const first = PhotoEdits(
      quarterTurns: 3,
      flipHorizontal: true,
      brightness: 22,
      contrast: -11,
      saturation: 14,
      zoom: 1.7,
      focusX: .25,
      focusY: .8,
      paddingColor: 'blue',
    );
    final restored = PhotoEdits.fromJson(first.toJson());
    expect(restored.quarterTurns, 3);
    expect(restored.flipHorizontal, isTrue);
    expect(restored.brightness, 22);
    expect(restored.contrast, -11);
    expect(restored.saturation, 14);
    expect(restored.zoom, 1.7);
    expect(restored.focusX, .25);
    expect(restored.focusY, .8);
    expect(restored.paddingColor, 'blue');
  });

  test('controller menyimpan perubahan foto tanpa mengubah foto asli', () {
    final controller = WorkspaceController();
    controller.addPhotos([
      PhotoItem(
        id: '1', path: 'example.jpg', name: 'example.jpg',
        widthPx: 1600, heightPx: 2000, size: PhotoSize.defaultSize,
      ),
    ]);
    final modified = controller.photos.first.photoEdits.copyWith(
      quarterTurns: 1, brightness: 15,
    );
    controller.updatePhotoEdits('1', modified);
    expect(controller.photos.first.photoEdits.quarterTurns, 1);
    expect(controller.photos.first.photoEdits.brightness, 15);
    final json = controller.photos.first.toJson();
    final restored = PhotoItem.fromJson(json);
    expect(restored.photoEdits.quarterTurns, 1);
    expect(restored.photoEdits.brightness, 15);
    controller.dispose();
  });

  // File IO dan codec Flutter adalah operasi asynchronous nyata. Di dalam
  // testWidgets, FakeAsync dapat membuatnya menggantung tanpa runAsync().
  testWidgets('renderer menghasilkan PNG dan tidak mengubah file sumber', (tester) async {
    await tester.runAsync(() async {
      const tinyPng =
          'iVBORw0KGgoAAAANSUhEUgAAAAIAAAACCAIAAAD91JpzAAAAFklEQVR4nGOs3/GQgYGBiYGBgYGBAQAY6AIcHOpqHwAAAABJRU5ErkJggg==';
      final temp = await Directory.systemTemp.createTemp('fotocetak_render_test_');
      try {
        final file = File('${temp.path}/fixture.png');
        final original = base64Decode(tinyPng);
        await file.writeAsBytes(original);
        final photo = PhotoItem(
          id: '1',
          path: file.path,
          name: 'fixture.png',
          widthPx: 2,
          heightPx: 2,
          size: PhotoSize.passportPresets[1],
          photoEdits: const PhotoEdits(
            quarterTurns: 1,
            flipHorizontal: true,
            brightness: 10,
            contrast: 20,
            zoom: 1.2,
          ),
        );
        // Timeout terbatas agar kegagalan codec terlihat jelas di GitHub Actions.
        final result = await PhotoRenderService.render(photo, ppi: 72)
            .timeout(const Duration(seconds: 45));
        expect(result.take(8), equals([137, 80, 78, 71, 13, 10, 26, 10]));
        expect(await file.readAsBytes(), original);
      } finally {
        await temp.delete(recursive: true);
      }
    });
  });
}
