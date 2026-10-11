import 'package:flutter/foundation.dart';

import '../../models/paper_settings.dart';
import '../../models/photo_item.dart';
import '../../models/photo_edits.dart';
import '../../models/photo_placement.dart';
import '../../models/photo_size.dart';
import '../../models/polaroid_edits.dart';
import '../layout_engine/layout_engine.dart';

class WorkspaceController extends ChangeNotifier {
  List<PhotoItem> _photos = [];
  PaperSettings _settings = const PaperSettings();
  PhotoMode _mode = PhotoMode.passport;
  String? _selectedPhotoId;
  int _pageIndex = 0;
  late LayoutResult _layout = LayoutEngine.compose(_photos, _settings);

  List<PhotoItem> get photos => List.unmodifiable(_photos);
  PaperSettings get settings => _settings;
  PhotoMode get mode => _mode;
  LayoutResult get layout => _layout;
  int get pageIndex => _pageIndex;
  int get totalCopies => _photos.fold(0, (total, photo) => total + photo.quantity);
  PhotoItem? get selectedPhoto => findPhoto(_selectedPhotoId ?? '');

  PhotoItem? findPhoto(String id) {
    for (final photo in _photos) {
      if (photo.id == id) return photo;
    }
    return null;
  }

  void addPhotos(Iterable<PhotoItem> photos) {
    final incoming = photos.toList();
    final seen = _photos.map((photo) => photo.path.toLowerCase()).toSet();
    final unique = incoming.where((photo) => seen.add(photo.path.toLowerCase()))
        .map((photo) => photo.copyWith(size: PhotoSize.defaultFor(_mode))).toList();
    if (unique.isEmpty) return;
    _photos = [..._photos, ...unique];
    _selectedPhotoId ??= unique.first.id;
    _refresh();
  }

  void replaceProject(List<PhotoItem> photos, PaperSettings settings, PhotoMode mode) {
    _photos = List.of(photos);
    _settings = settings;
    _mode = mode;
    _selectedPhotoId = photos.isEmpty ? null : photos.first.id;
    _pageIndex = 0;
    _refresh();
  }

  /// Satu mode aktif untuk seluruh proyek. Ukuran dari mode lain tidak boleh
  /// tercampur; editor mode lain menjadi tidak tersedia.
  void changeMode(PhotoMode mode) {
    if (mode == _mode) return;
    _mode = mode;
    final newSize = PhotoSize.defaultFor(mode);
    _photos = _photos.map((photo) => photo.copyWith(size: newSize)).toList();
    _pageIndex = 0;
    _refresh();
  }

  void selectPhoto(String? id) {
    _selectedPhotoId = id;
    notifyListeners();
  }

  void updatePhoto(String id, {PhotoSize? size, int? quantity,
      PhotoFit? fit, PolaroidEdits? edits, PhotoEdits? photoEdits}) {
    final index = _photos.indexWhere((item) => item.id == id);
    if (index == -1) return;
    // Ukuran dari mode non-aktif ditolak pada level controller, bukan hanya UI.
    if (size != null && size.mode != _mode) return;
    _photos = List.of(_photos);
    _photos[index] = _photos[index].copyWith(
      size: size,
      quantity: quantity?.clamp(1, 99).toInt(),
      fit: fit,
      edits: edits,
      photoEdits: photoEdits,
    );
    _refresh();
  }

  void updatePhotoEdits(String photoId, PhotoEdits edits) {
    updatePhoto(photoId, photoEdits: edits);
  }

  void updateEdits(String photoId, PolaroidEdits edits) {
    if (_mode != PhotoMode.polaroid) return;
    updatePhoto(photoId, edits: edits);
  }

  void removePhoto(String id) {
    _photos = _photos.where((photo) => photo.id != id).toList();
    if (_selectedPhotoId == id) {
      _selectedPhotoId = _photos.isEmpty ? null : _photos.first.id;
    }
    _refresh();
  }

  void clearPhotos() {
    _photos = [];
    _selectedPhotoId = null;
    _pageIndex = 0;
    _refresh();
  }

  void changePaper(PaperPreset preset) {
    _settings = _settings.copyWith(paper: preset);
    _refresh();
  }
  void changeOrientation(PaperOrientation orientation) {
    _settings = _settings.copyWith(orientation: orientation);
    _refresh();
  }
  void changeMargin(double margin) {
    _settings = _settings.copyWith(marginMm: margin);
    _refresh();
  }
  void changeGap(double gap) {
    _settings = _settings.copyWith(gapMm: gap);
    _refresh();
  }
  void changeCutMarks(bool enabled) {
    _settings = _settings.copyWith(cutMarks: enabled);
    _refresh();
  }
  void goToPage(int index) {
    _pageIndex = index.clamp(0, _layout.pages.length - 1).toInt();
    notifyListeners();
  }
  void regenerate() => _refresh();

  void _refresh() {
    _layout = LayoutEngine.compose(_photos, _settings);
    _pageIndex = _pageIndex.clamp(0, _layout.pages.length - 1).toInt();
    notifyListeners();
  }
}
