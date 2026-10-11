import '../../models/paper_settings.dart';
import '../../models/photo_item.dart';
import '../../models/photo_placement.dart';

/// Mesin tata-letak dasar, deterministik, dalam satuan milimeter.
/// V1 memakai algoritma baris/shelf; optimasi MaxRects direncanakan untuk V2.
class LayoutEngine {
  static const double _epsilon = 0.00001;

  static LayoutResult compose(List<PhotoItem> photos, PaperSettings settings) {
    final pages = <List<PhotoPlacement>>[[]];
    final warnings = <String>[];
    final left = settings.marginMm;
    final top = settings.marginMm;
    final right = settings.widthMm - settings.marginMm;
    final bottom = settings.heightMm - settings.marginMm;
    double x = left;
    double y = top;
    double rowHeight = 0;
    int pageIndex = 0;

    if (right <= left || bottom <= top) {
      return LayoutResult(pages, ['Margin melebihi luas kertas.']);
    }

    for (final photo in photos) {
      final w = photo.size.widthMm;
      final h = photo.size.heightMm;
      if (w <= 0 || h <= 0 || w > right - left + _epsilon ||
          h > bottom - top + _epsilon) {
        warnings.add('${photo.name}: ukuran foto tidak muat pada kertas.');
        continue;
      }
      for (var i = 0; i < photo.quantity; i++) {
        if (x + w > right + _epsilon) {
          x = left;
          y += rowHeight + settings.gapMm;
          rowHeight = 0;
        }
        if (y + h > bottom + _epsilon) {
          pages.add([]);
          pageIndex++;
          x = left;
          y = top;
          rowHeight = 0;
        }
        pages[pageIndex].add(PhotoPlacement(
          photoId: photo.id,
          pageIndex: pageIndex,
          xMm: x,
          yMm: y,
          widthMm: w,
          heightMm: h,
        ));
        x += w + settings.gapMm;
        if (h > rowHeight) rowHeight = h;
      }
    }
    return LayoutResult(pages, warnings);
  }
}
