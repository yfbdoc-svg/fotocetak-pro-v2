class PhotoPlacement {
  final String photoId;
  final int pageIndex;
  final double xMm;
  final double yMm;
  final double widthMm;
  final double heightMm;

  const PhotoPlacement({
    required this.photoId,
    required this.pageIndex,
    required this.xMm,
    required this.yMm,
    required this.widthMm,
    required this.heightMm,
  });
}

class LayoutResult {
  final List<List<PhotoPlacement>> pages;
  final List<String> warnings;
  const LayoutResult(this.pages, this.warnings);

  int get pageCount => pages.every((page) => page.isEmpty) ? 0 : pages.length;
  int get placedCount => pages.fold<int>(0, (sum, page) => sum + page.length);
}
