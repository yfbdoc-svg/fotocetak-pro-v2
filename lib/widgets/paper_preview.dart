import 'dart:typed_data';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../features/workspace/workspace_controller.dart';
import '../features/photo_editor/photo_render_service.dart';
import '../models/photo_item.dart';
import '../models/photo_placement.dart';
import 'polaroid_face.dart';

class PaperPreview extends StatefulWidget {
  final WorkspaceController controller;
  const PaperPreview({super.key, required this.controller});

  @override
  State<PaperPreview> createState() => _PaperPreviewState();
}

class _PaperPreviewState extends State<PaperPreview> {
  double _zoom = 1.0;
  int _viewStyle = 0;
  Size _latestViewport = const Size(800, 680);
  final TransformationController _viewController = TransformationController();

  @override
  void dispose() {
    _viewController.dispose();
    super.dispose();
  }

  void _changeZoom(double zoom, Size viewport) {
    final next = zoom.clamp(.6, 2.5).toDouble();
    final cx = viewport.width / 2;
    final cy = viewport.height / 2;
    // Zoom di sekitar pusat viewport tanpa API Matrix4 yang deprecated.
    final matrix = Matrix4.identity();
    matrix.setEntry(0, 0, next);
    matrix.setEntry(1, 1, next);
    matrix.setTranslationRaw(cx * (1 - next), cy * (1 - next), 0);
    _viewController.value = matrix;
    setState(() => _zoom = next);
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final settings = controller.settings;
    final pageCount = math.max(controller.layout.pageCount, 1);
    final pageIndex = controller.pageIndex.clamp(0, pageCount - 1);
    final placements = controller.layout.pages.isEmpty
        ? const <PhotoPlacement>[]
        : controller.layout.pages[pageIndex];
    final selectedId = controller.selectedPhoto?.id;
    final photosById = {for (final p in controller.photos) p.id: p};
    final widthMm = settings.widthMm;
    final heightMm = settings.heightMm;

    return Container(
      color: const Color(0xFFF5F8FC),
      child: Column(
        children: [
          Container(
            height: 64,
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Row(
              children: [
                const Icon(Icons.description_outlined, color: AppTheme.blue, size: 22),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Pratinjau Kertas',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1A3154),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F7FB),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFDCE5EF)),
                  ),
                  child: Text(
                    '${settings.paper.label.split('·').first.trim()} (${widthMm.toStringAsFixed(0)} × ${heightMm.toStringAsFixed(0)} mm)',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, viewport) {
                _latestViewport = Size(viewport.maxWidth, viewport.maxHeight);
                final availableW = math.max(180.0, viewport.maxWidth - 76);
                final availableH = math.max(180.0, viewport.maxHeight - 58);
                final unit = math.min(availableW / widthMm, availableH / heightMm);
                final paperW = widthMm * unit;
                final paperH = heightMm * unit;
                const rulerSpace = 32.0;

                return Stack(
                  children: [
                    if (_viewStyle == 0)
                      Positioned.fill(child: CustomPaint(painter: _WorkspaceGridPainter())),
                    InteractiveViewer(
                      transformationController: _viewController,
                      constrained: true,
                      minScale: 0.6,
                      maxScale: 2.5,
                      boundaryMargin: const EdgeInsets.all(600),
                      onInteractionEnd: (_) {
                        final zoomNow = _viewController.value.getMaxScaleOnAxis();
                        if (mounted) setState(() => _zoom = zoomNow);
                      },
                      child: Center(
                        child: SizedBox(
                        width: paperW + rulerSpace,
                        height: paperH + rulerSpace,
                        child: Stack(
                          children: [
                            Positioned(
                              left: rulerSpace,
                              top: 0,
                              width: paperW,
                              height: rulerSpace,
                              child: CustomPaint(
                                painter: _RulerPainter(horizontal: true, unit: unit, lengthMm: widthMm),
                              ),
                            ),
                            Positioned(
                              left: 0,
                              top: rulerSpace,
                              width: rulerSpace,
                              height: paperH,
                              child: CustomPaint(
                                painter: _RulerPainter(horizontal: false, unit: unit, lengthMm: heightMm),
                              ),
                            ),
                            Positioned(
                              left: rulerSpace,
                              top: rulerSpace,
                              width: paperW,
                              height: paperH,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(2),
                                  border: Border.all(color: const Color(0xFFCFD9E5), width: 1.3),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF173A5B).withValues(alpha: 0.12),
                                      blurRadius: 22,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: Stack(
                                  children: [
                                    Positioned.fill(
                                      child: _viewStyle != 0 ? const SizedBox.shrink() : CustomPaint(
                                        painter: _PaperInnerGridPainter(unit: unit),
                                      ),
                                    ),
                                    Positioned(
                                      left: settings.marginMm * unit,
                                      top: settings.marginMm * unit,
                                      width: math.max(0, (widthMm - (2 * settings.marginMm)) * unit),
                                      height: math.max(0, (heightMm - (2 * settings.marginMm)) * unit),
                                      child: IgnorePointer(
                                        child: Container(
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                              color: const Color(0xFFD4DEE9),
                                              width: 1,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    for (final placement in placements)
                                      if (photosById.containsKey(placement.photoId))
                                        Positioned(
                                          left: placement.xMm * unit,
                                          top: placement.yMm * unit,
                                          width: placement.widthMm * unit,
                                          height: placement.heightMm * unit,
                                          child: _PlacementTile(
                                            photo: photosById[placement.photoId]!,
                                            selected: selectedId == placement.photoId,
                                            onTap: () => controller.selectPhoto(placement.photoId),
                                          ),
                                        ),
                                    if (settings.cutMarks)
                                      Positioned.fill(
                                        child: IgnorePointer(
                                          child: CustomPaint(
                                            painter: _CutLinePainter(placements: placements, unit: unit),
                                          ),
                                        ),
                                      ),
                                    if (controller.photos.isEmpty)
                                      const Center(
                                        child: _EmptyPreview(),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    ),
                  ],
                );
              },
            ),
          ),
          LayoutBuilder(builder: (context, footer) {
            final compact = footer.maxWidth < 760;
            return Container(
            height: 62,
            color: Colors.white,
            padding: EdgeInsets.symmetric(horizontal: compact ? 5 : 16),
            child: Row(
              children: [
                OutlinedButton.icon(
                  onPressed: () => _changeZoom(1, _latestViewport),
                  icon: const Icon(Icons.fit_screen_rounded, size: 17),
                  label: Text(compact ? 'Fit' : 'Fit ke Layar'),
                ),
                SizedBox(width: compact ? 2 : 14),
                IconButton(
                  onPressed: () => _changeZoom(_zoom - .1, _latestViewport),
                  icon: const Icon(Icons.remove_circle_outline_rounded),
                ),
                SizedBox(
                  width: compact ? 90 : 160,
                  child: Slider(
                    value: _zoom.clamp(.6, 2.5).toDouble(),
                    min: 0.6,
                    max: 2.5,
                    divisions: 18,
                    onChanged: (value) => _changeZoom(value, _latestViewport),
                  ),
                ),
                IconButton(
                  onPressed: () => _changeZoom(_zoom + .1, _latestViewport),
                  icon: const Icon(Icons.add_circle_outline_rounded),
                ),
                SizedBox(
                  width: compact ? 44 : 60,
                  child: Text(
                    '${(_zoom * 100).round()}%',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: pageIndex == 0 ? null : () => controller.goToPage(pageIndex - 1),
                  icon: const Icon(Icons.chevron_left_rounded),
                ),
                Text(
                  '${pageIndex + 1} / $pageCount',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
                IconButton(
                  onPressed: pageIndex >= pageCount - 1 ? null : () => controller.goToPage(pageIndex + 1),
                  icon: const Icon(Icons.chevron_right_rounded),
                ),
                if (!compact) const SizedBox(width: 18),
                if (!compact) _ViewModeBox(icon: Icons.grid_view_rounded, active: _viewStyle == 0, onTap: () => setState(() => _viewStyle = 0)),
                if (!compact) const SizedBox(width: 8),
                if (!compact) _ViewModeBox(icon: Icons.view_comfy_alt_outlined, active: _viewStyle == 1, onTap: () => setState(() => _viewStyle = 1)),
                if (!compact) const SizedBox(width: 8),
                if (!compact) _ViewModeBox(icon: Icons.view_headline_rounded, active: _viewStyle == 2, onTap: () => setState(() => _viewStyle = 2)),
              ],
            ),
          );
          }),
        ],
      ),
    );
  }
}

class _PlacementTile extends StatelessWidget {
  final PhotoItem photo;
  final bool selected;
  final VoidCallback onTap;
  const _PlacementTile({
    required this.photo,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: selected ? const Color(0xFF4A88E9) : const Color(0xFFA9BBCF),
            width: selected ? 1.8 : 1.1,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
        ),
        child: ClipRect(
          child: photo.size.isPolaroid
              ? PolaroidFace(photo: photo)
              : FutureBuilder<Uint8List>(
                  future: PhotoRenderService.render(photo, ppi: 160),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return const ColoredBox(
                        color: Color(0xFFE7EEF7),
                        child: Center(child: Icon(Icons.broken_image_outlined)),
                      );
                    }
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                    }
                    return Image.memory(
                      snapshot.data!,
                      gaplessPlayback: true,
                      fit: BoxFit.fill,
                      filterQuality: FilterQuality.high,
                    );
                  },
                ),
        ),
      ),
    );
  }
}

class _EmptyPreview extends StatelessWidget {
  const _EmptyPreview();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: const [
        Icon(Icons.add_photo_alternate_outlined, size: 48, color: Color(0xFF9DAEC4)),
        SizedBox(height: 10),
        Text(
          'Belum ada foto untuk dipratinjau',
          style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.muted),
        ),
      ],
    );
  }
}

class _ViewModeBox extends StatelessWidget {
  final IconData icon;
  final bool active;
  final VoidCallback onTap;
  const _ViewModeBox({required this.icon, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: active ? const Color(0xFFE9F3FF) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: active ? AppTheme.blue : const Color(0xFFDCE5EF)),
      ),
      child: Icon(icon, size: 18, color: active ? AppTheme.blue : const Color(0xFF7A8CA4)),
    ));
  }
}

class _WorkspaceGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawColor(const Color(0xFFF1F6FB), BlendMode.src);
    final line = Paint()..color = const Color(0xFFE0E8F1)..strokeWidth = .8;
    for (double x = 0; x < size.width; x += 26) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), line);
    }
    for (double y = 0; y < size.height; y += 26) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), line);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PaperInnerGridPainter extends CustomPainter {
  final double unit;
  const _PaperInnerGridPainter({required this.unit});

  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()..color = const Color(0xFFF3F5F8)..strokeWidth = .6;
    final step = math.max(8.0, unit * 5);
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), line);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), line);
    }
  }

  @override
  bool shouldRepaint(covariant _PaperInnerGridPainter oldDelegate) => oldDelegate.unit != unit;
}

class _RulerPainter extends CustomPainter {
  final bool horizontal;
  final double unit;
  final double lengthMm;
  const _RulerPainter({
    required this.horizontal,
    required this.unit,
    required this.lengthMm,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()..color = const Color(0xFFEFF4FA);
    canvas.drawRect(Offset.zero & size, bg);
    final border = Paint()..color = const Color(0xFFD3DDEA)..strokeWidth = 1;
    if (horizontal) {
      canvas.drawLine(Offset(0, size.height - .5), Offset(size.width, size.height - .5), border);
    } else {
      canvas.drawLine(Offset(size.width - .5, 0), Offset(size.width - .5, size.height), border);
    }
    final tick = Paint()..color = const Color(0xFF91A4BB)..strokeWidth = 1;
    final textStyle = const TextStyle(fontSize: 9, color: Color(0xFF6C8097));
    for (int mm = 0; mm <= lengthMm.floor(); mm += 5) {
      final pos = mm * unit;
      if (horizontal) {
        final big = mm % 50 == 0;
        final h = big ? 16.0 : 9.0;
        canvas.drawLine(Offset(pos, size.height), Offset(pos, size.height - h), tick);
        if (big) {
          final tp = TextPainter(
            text: TextSpan(text: '$mm', style: textStyle),
            textDirection: TextDirection.ltr,
          )..layout();
          tp.paint(canvas, Offset(pos - (tp.width / 2), 2));
        }
      } else {
        final big = mm % 50 == 0;
        final w = big ? 16.0 : 9.0;
        canvas.drawLine(Offset(size.width, pos), Offset(size.width - w, pos), tick);
        if (big) {
          final tp = TextPainter(
            text: TextSpan(text: '$mm', style: textStyle),
            textDirection: TextDirection.ltr,
          )..layout();
          tp.paint(canvas, Offset(2, pos - (tp.height / 2)));
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _RulerPainter oldDelegate) {
    return oldDelegate.unit != unit ||
        oldDelegate.lengthMm != lengthMm ||
        oldDelegate.horizontal != horizontal;
  }
}

class _CutLinePainter extends CustomPainter {
  final List<PhotoPlacement> placements;
  final double unit;
  const _CutLinePainter({required this.placements, required this.unit});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF55677D)
      ..strokeWidth = 1;
    final extension = math.max(7.0, unit * 1.8);
    final gap = math.max(2.0, unit * 0.3);

    for (final placement in placements) {
      final left = placement.xMm * unit;
      final top = placement.yMm * unit;
      final right = left + placement.widthMm * unit;
      final bottom = top + placement.heightMm * unit;

      for (final x in [left, right]) {
        for (final y in [top, bottom]) {
          final toLeft = x == left;
          final toTop = y == top;
          canvas.drawLine(
            Offset(toLeft ? x - extension : x + gap, y),
            Offset(toLeft ? x - gap : x + extension, y),
            paint,
          );
          canvas.drawLine(
            Offset(x, toTop ? y - extension : y + gap),
            Offset(x, toTop ? y - gap : y + extension),
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CutLinePainter oldDelegate) {
    return oldDelegate.unit != unit || oldDelegate.placements != placements;
  }
}
