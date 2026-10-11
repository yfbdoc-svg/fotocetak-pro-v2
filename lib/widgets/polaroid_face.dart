import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../models/photo_item.dart';
import '../features/photo_editor/photo_render_service.dart';
import '../models/polaroid_edits.dart';

/// Digambar proporsional terhadap milimeter agar tampilan bingkai dan crop
/// mirip dengan geometri dokumen PDF (ukuran fisik tetap milimeter).
class PolaroidFace extends StatelessWidget {
  final PhotoItem photo;
  const PolaroidFace({super.key, required this.photo});

  @override
  Widget build(BuildContext context) {
    final size = photo.size;
    if (!size.isPolaroid) {
      return _RenderedPhoto(photo: photo);
    }
    final edits = photo.edits;
    final rgb = edits.rgb;
    final frame = Color(0xFF000000 | rgb);
    final ink = edits.dark ? Colors.white : const Color(0xFF283342);
    final canCaption = size.captionHeightMm >= 7;
    return LayoutBuilder(builder: (context, constraints) {
      final unit = constraints.maxWidth / size.widthMm;
      final textHeight = (size.captionHeightMm - 1) * unit;
      return Stack(children: [
        Positioned.fill(child: ColoredBox(color: frame)),
        if (edits.frameStyle == FrameStyle.vintage)
          Positioned.fill(child: Container(decoration: BoxDecoration(
            border: Border.all(color: const Color(0x558D673C), width: 1.2)))),
        if (edits.frameStyle == FrameStyle.minimal)
          Positioned.fill(child: IgnorePointer(child: Container(
            decoration: BoxDecoration(border: Border.all(
              color: edits.dark ? Colors.white54 : const Color(0xFFB3BBC4),
              width: 1,
            )),
          ))),
        Positioned(
          left: size.windowLeftMm * unit,
          top: size.windowTopMm * unit,
          width: size.windowWidthMm * unit,
          height: size.windowHeightMm * unit,
          child: Container(
            clipBehavior: Clip.hardEdge,
            decoration: BoxDecoration(
              border: edits.frameStyle == FrameStyle.modern
                ? Border.all(color: edits.dark ? Colors.white70 : Colors.black26, width: 1)
                : null,
            ),
            child: _RenderedPhoto(photo: photo),
          ),
        ),
        if (canCaption && (edits.caption.trim().isNotEmpty ||
            (edits.showDate && edits.date.trim().isNotEmpty)))
          Positioned(
            left: 2.5 * unit, right: 2.5 * unit,
            top: (size.windowTopMm + size.windowHeightMm + 1) * unit,
            height: textHeight.clamp(0.0, constraints.maxHeight).toDouble(),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              if (edits.caption.trim().isNotEmpty)
                Flexible(child: FittedBox(fit: BoxFit.scaleDown,
                  child: Text(edits.caption, maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: ink, fontWeight: FontWeight.w600,
                      fontFamily: edits.font == CaptionFont.handwritten
                          ? 'Segoe Print' : 'Segoe UI',
                      fontStyle: edits.font == CaptionFont.handwritten
                          ? FontStyle.italic : FontStyle.normal,
                      fontSize: (3.0 * unit).clamp(8.0, 22.0).toDouble(),
                    )))),
              if (edits.showDate && edits.date.trim().isNotEmpty)
                Flexible(child: FittedBox(fit: BoxFit.scaleDown,
                  child: Text(edits.date, maxLines: 1, style: TextStyle(
                    color: ink.withValues(alpha: 0.8),
                    fontSize: (2.0 * unit).clamp(7.0, 14.0).toDouble())))),
            ]),
          ),
        if (edits.sticker != PolaroidSticker.none)
          Positioned(
            right: (size.windowLeftMm + 1) * unit,
            top: (size.windowTopMm + 1) * unit,
            child: Icon(_stickerIcon(edits.sticker),
              color: _stickerColor(edits.sticker),
              size: (size.widthMm * unit * 0.13).clamp(9.0, 27.0).toDouble()),
          ),
      ]);
    });
  }

  static IconData _stickerIcon(PolaroidSticker sticker) => switch (sticker) {
    PolaroidSticker.heart => Icons.favorite,
    PolaroidSticker.star => Icons.star,
    PolaroidSticker.smile => Icons.sentiment_satisfied_alt,
    PolaroidSticker.none => Icons.circle_outlined,
  };
  static Color _stickerColor(PolaroidSticker sticker) => switch (sticker) {
    PolaroidSticker.heart => const Color(0xFFEE568A),
    PolaroidSticker.star => const Color(0xFFF4B63F),
    PolaroidSticker.smile => const Color(0xFF459FD6),
    PolaroidSticker.none => Colors.transparent,
  };
}

class _RenderedPhoto extends StatelessWidget {
  final PhotoItem photo;
  const _RenderedPhoto({required this.photo});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List>(
      future: PhotoRenderService.render(photo, ppi: 160),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const ColoredBox(
            color: Color(0xFFE7E9EE),
            child: Center(child: Icon(Icons.broken_image_outlined, size: 19)),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        }
        return Image.memory(
          snapshot.data!,
          fit: BoxFit.fill,
          filterQuality: FilterQuality.high,
          gaplessPlayback: true,
        );
      },
    );
  }
}
