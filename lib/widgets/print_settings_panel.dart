import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../features/workspace/workspace_controller.dart';
import '../models/paper_settings.dart';
import '../models/photo_item.dart';
import '../models/photo_edits.dart';
import '../models/photo_size.dart';
import '../models/polaroid_edits.dart';

class PrintSettingsPanel extends StatelessWidget {
  final WorkspaceController controller;
  final bool busy;
  final VoidCallback onExportPdf;
  final VoidCallback onPrint;

  const PrintSettingsPanel({
    super.key,
    required this.controller,
    required this.busy,
    required this.onExportPdf,
    required this.onPrint,
  });

  @override
  Widget build(BuildContext context) {
    final selected = controller.selectedPhoto;
    final isPolaroid = controller.mode == PhotoMode.polaroid;
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          Container(
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Row(
              children: [
                const Icon(Icons.tune_rounded, color: AppTheme.blue, size: 22),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Pengaturan Cetak',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1A3154),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Refresh layout',
                  onPressed: controller.regenerate,
                  icon: const Icon(Icons.refresh_rounded, color: AppTheme.muted),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _ModeSegmentButton(
                          label: 'Pas Foto',
                          icon: Icons.badge_outlined,
                          selected: !isPolaroid,
                          onTap: () => controller.changeMode(PhotoMode.passport),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _ModeSegmentButton(
                          label: 'Polaroid',
                          icon: Icons.photo_outlined,
                          selected: isPolaroid,
                          onTap: () => controller.changeMode(PhotoMode.polaroid),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    isPolaroid
                        ? 'Mode Polaroid aktif • Pas Foto tidak tersedia.'
                        : 'Mode Pas Foto aktif • Polaroid tidak tersedia.',
                    style: const TextStyle(fontSize: 11, color: AppTheme.muted),
                  ),
                  const SizedBox(height: 16),
                  _SectionCard(
                    title: isPolaroid ? 'Pilih Ukuran Polaroid' : 'Pilih Ukuran Pas Foto',
                    child: isPolaroid
                        ? _PolaroidSizes(controller: controller, selected: selected)
                        : _PassportSizes(controller: controller, selected: selected),
                  ),
                  const SizedBox(height: 14),
                  _SectionCard(
                    title: 'Pengaturan Foto Terpilih',
                    child: selected == null
                        ? const Text(
                            'Pilih satu foto dari panel kiri atau preview agar pengaturan detailnya muncul di sini.',
                            style: TextStyle(fontSize: 12, color: AppTheme.muted),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      selected.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                  Text(
                                    '≈ ${selected.effectivePpi.toStringAsFixed(0)} PPI',
                                    style: const TextStyle(fontSize: 11, color: AppTheme.muted),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: _CounterCard(
                                      label: 'Jumlah',
                                      value: selected.quantity,
                                      onMinus: selected.quantity <= 1
                                          ? null
                                          : () => controller.updatePhoto(
                                                selected.id,
                                                quantity: selected.quantity - 1,
                                              ),
                                      onPlus: () => controller.updatePhoto(
                                        selected.id,
                                        quantity: selected.quantity + 1,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: _OptionCard(
                                      label: 'Tampilan Foto',
                                      child: DropdownButtonFormField<PhotoFit>(
                                        isExpanded: true,
                                        key: ValueKey('fit-${selected.id}-${selected.fit.name}'),
                                        initialValue: selected.fit,
                                        items: const [
                                          DropdownMenuItem(value: PhotoFit.cover, child: Text('Fill / Cover')),
                                          DropdownMenuItem(value: PhotoFit.contain, child: Text('Fit / Contain')),
                                        ],
                                        onChanged: (value) {
                                          if (value != null) {
                                            controller.updatePhoto(selected.id, fit: value);
                                          }
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (isPolaroid) ...[
                                const SizedBox(height: 12),
                                _PolaroidEditor(controller: controller, photo: selected),
                              ] else ...[
                                const SizedBox(height: 12),
                                _PassportEditor(controller: controller, photo: selected),
                              ],
                            ],
                          ),
                  ),
                  const SizedBox(height: 14),
                  _SectionCard(
                    title: 'Pengaturan Halaman',
                    child: _PaperControls(controller: controller),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: busy || controller.layout.placedCount == 0 ? null : onExportPdf,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    icon: const Icon(Icons.picture_as_pdf_outlined),
                    label: const Text('Ekspor PDF'),
                  ),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed: busy || controller.layout.placedCount == 0 ? null : onPrint,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      backgroundColor: AppTheme.green,
                    ),
                    icon: const Icon(Icons.print_rounded),
                    label: const Text('Cetak Sekarang'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeSegmentButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _ModeSegmentButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = selected ? AppTheme.blue : const Color(0xFFF2F5F9);
    final fg = selected ? Colors.white : const Color(0xFF99A9BD);
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        backgroundColor: bg,
        foregroundColor: fg,
        side: BorderSide(color: selected ? AppTheme.blue : const Color(0xFFE2E8F0)),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFDFEFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE3EAF3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Color(0xFF193152),
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _PassportSizes extends StatelessWidget {
  final WorkspaceController controller;
  final PhotoItem? selected;
  const _PassportSizes({required this.controller, required this.selected});

  @override
  Widget build(BuildContext context) {
    final sizes = PhotoSize.passportPresets;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final size in sizes)
          _SizeButton(
            label: size.label,
            active: selected?.size.id == size.id,
            onTap: selected == null ? null : () => controller.updatePhoto(selected!.id, size: size),
          ),
        _SizeButton(
          label: 'Lainnya...',
          active: false,
          onTap: selected == null ? null : () => _showCustomSizeDialog(context, controller, selected!),
        ),
      ],
    );
  }
}

Future<void> _showCustomSizeDialog(BuildContext context,
    WorkspaceController controller, PhotoItem photo) async {
  final widthController = TextEditingController(text: (photo.size.widthMm / 10).toStringAsFixed(1));
  final heightController = TextEditingController(text: (photo.size.heightMm / 10).toStringAsFixed(1));
  try {
    await showDialog<void>(context: context, builder: (dialogContext) => AlertDialog(
      title: const Text('Ukuran Pas Foto Khusus'),
      content: SizedBox(width: 320, child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: widthController, keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'Lebar (cm)')),
        const SizedBox(height: 12),
        TextField(controller: heightController, keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'Tinggi (cm)')),
        const SizedBox(height: 8),
        const Text('Masukkan ukuran 1–30 cm. Nilai berlaku untuk foto terpilih.',
          style: TextStyle(fontSize: 11, color: AppTheme.muted)),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Batal')),
        FilledButton(onPressed: () {
          final w = double.tryParse(widthController.text.replaceAll(',', '.'));
          final h = double.tryParse(heightController.text.replaceAll(',', '.'));
          if (w == null || h == null || w < 1 || h < 1 || w > 30 || h > 30) {
            ScaffoldMessenger.of(dialogContext).showSnackBar(
              const SnackBar(content: Text('Ukuran harus antara 1 sampai 30 cm.')));
            return;
          }
          controller.updatePhoto(photo.id, size: PhotoSize('custom_${w}x$h',
            'Khusus · $w × $h cm', w * 10, h * 10));
          Navigator.of(dialogContext).pop();
        }, child: const Text('Terapkan')),
      ],
    ));
  } finally {
    widthController.dispose();
    heightController.dispose();
  }
}

class _PolaroidSizes extends StatelessWidget {
  final WorkspaceController controller;
  final PhotoItem? selected;
  const _PolaroidSizes({required this.controller, required this.selected});

  @override
  Widget build(BuildContext context) {
    Widget btn(PhotoSize size, {String? labelOverride}) => _SizeButton(
          label: labelOverride ?? size.label,
          active: selected?.size.id == size.id,
          onTap: selected == null ? null : () => controller.updatePhoto(selected!.id, size: size),
        );

    final preset = PhotoSize.polaroidPresets;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Standar Kamera Asli', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            btn(preset[0], labelOverride: 'Standar\n(10,75 × 8,84 cm)'),
            btn(preset[1], labelOverride: 'Mini / Go\n(6,66 × 5,39 cm)'),
          ],
        ),
        const SizedBox(height: 12),
        const Text('Studio / Percetakan', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            btn(preset[2], labelOverride: 'Photo Card / 2R\n(6 × 9 cm)'),
            btn(preset[3], labelOverride: 'Photo Mini\n(5 × 7,5 cm)'),
            btn(preset[4], labelOverride: 'Square\n(9 × 9 cm)'),
            btn(preset[5], labelOverride: '3R\n(9 × 12,7 cm)'),
            btn(preset[6], labelOverride: '4R\n(10 × 15 cm)'),
          ],
        ),
      ],
    );
  }
}

class _SizeButton extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback? onTap;
  const _SizeButton({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 124,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
          backgroundColor: active ? const Color(0xFFEAF3FF) : Colors.white,
          foregroundColor: active ? AppTheme.blue : AppTheme.dark,
          side: BorderSide(color: active ? AppTheme.blue : const Color(0xFFDCE5EF)),
          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        ),
        child: Text(label, textAlign: TextAlign.center),
      ),
    );
  }
}

class _CounterCard extends StatelessWidget {
  final String label;
  final int value;
  final VoidCallback? onMinus;
  final VoidCallback? onPlus;
  const _CounterCard({
    required this.label,
    required this.value,
    required this.onMinus,
    required this.onPlus,
  });

  @override
  Widget build(BuildContext context) {
    return _OptionCard(
      label: label,
      child: Row(
        children: [
          IconButton(onPressed: onMinus, icon: const Icon(Icons.remove_circle_outline_rounded)),
          Expanded(
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
            ),
          ),
          IconButton(onPressed: onPlus, icon: const Icon(Icons.add_circle_outline_rounded)),
        ],
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  final String label;
  final Widget child;
  const _OptionCard({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _PassportEditor extends StatelessWidget {
  final WorkspaceController controller;
  final PhotoItem photo;
  const _PassportEditor({required this.controller, required this.photo});

  @override
  Widget build(BuildContext context) => _PhotoAdjustments(
    controller: controller,
    photo: photo,
    showBackground: true,
  );
}

/// Semua kontrol di bagian ini benar-benar memengaruhi foto yang dirender
/// di preview dan PDF. Tidak mengubah file sumber.
class _PhotoAdjustments extends StatelessWidget {
  final WorkspaceController controller;
  final PhotoItem photo;
  final bool showBackground;
  const _PhotoAdjustments({
    required this.controller,
    required this.photo,
    this.showBackground = false,
  });

  @override
  Widget build(BuildContext context) {
    final edits = photo.photoEdits;
    void update(PhotoEdits next) => controller.updatePhotoEdits(photo.id, next);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Expanded(child: Text('Edit & Crop Foto',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13))),
        TextButton.icon(
          onPressed: () => update(const PhotoEdits()),
          icon: const Icon(Icons.restart_alt_rounded, size: 17),
          label: const Text('Reset Foto'),
        ),
      ]),
      const SizedBox(height: 8),
      Row(children: [
        Expanded(child: OutlinedButton.icon(
          onPressed: () => update(edits.copyWith(
            quarterTurns: (edits.quarterTurns + 3) % 4)),
          icon: const Icon(Icons.rotate_left_rounded, size: 18),
          label: const Text('Putar Kiri'),
        )),
        const SizedBox(width: 7),
        Expanded(child: OutlinedButton.icon(
          onPressed: () => update(edits.copyWith(
            quarterTurns: (edits.quarterTurns + 1) % 4)),
          icon: const Icon(Icons.rotate_right_rounded, size: 18),
          label: const Text('Putar Kanan'),
        )),
      ]),
      const SizedBox(height: 8),
      SizedBox(width: double.infinity, child: OutlinedButton.icon(
        onPressed: () => update(edits.copyWith(
          flipHorizontal: !edits.flipHorizontal)),
        icon: Icon(edits.flipHorizontal
          ? Icons.flip : Icons.flip_camera_android_outlined, size: 18),
        label: Text(edits.flipHorizontal ? 'Mirror Aktif' : 'Mirror Horizontal'),
      )),
      const SizedBox(height: 10),
      _AdjustmentSlider(label: 'Zoom Crop', value: edits.zoom,
        min: 1, max: 3, divisions: 40,
        formatted: '${edits.zoom.toStringAsFixed(2)}×',
        onChanged: (v) => update(edits.copyWith(zoom: v))),
      _AdjustmentSlider(label: 'Posisi Horizontal', value: edits.focusX,
        min: 0, max: 1, divisions: 20,
        formatted: '${(edits.focusX * 100).round()}%',
        onChanged: (v) => update(edits.copyWith(focusX: v))),
      _AdjustmentSlider(label: 'Posisi Vertikal', value: edits.focusY,
        min: 0, max: 1, divisions: 20,
        formatted: '${(edits.focusY * 100).round()}%',
        onChanged: (v) => update(edits.copyWith(focusY: v))),
      const Divider(height: 20),
      _AdjustmentSlider(label: 'Kecerahan', value: edits.brightness,
        min: -80, max: 80, divisions: 80,
        formatted: edits.brightness.round().toString(),
        onChanged: (v) => update(edits.copyWith(brightness: v))),
      _AdjustmentSlider(label: 'Kontras', value: edits.contrast,
        min: -80, max: 80, divisions: 80,
        formatted: edits.contrast.round().toString(),
        onChanged: (v) => update(edits.copyWith(contrast: v))),
      _AdjustmentSlider(label: 'Saturasi', value: edits.saturation,
        min: -80, max: 80, divisions: 80,
        formatted: edits.saturation.round().toString(),
        onChanged: (v) => update(edits.copyWith(saturation: v))),
      if (showBackground) ...[
        const SizedBox(height: 10),
        const Text('Warna Ruang Kosong (Mode Fit)',
          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
        const SizedBox(height: 7),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final entry in PhotoEdits.palette.entries)
            Tooltip(message: entry.key, child: InkWell(
              onTap: () => update(edits.copyWith(paddingColor: entry.key)),
              customBorder: const CircleBorder(),
              child: Container(width: 31, height: 31,
                decoration: BoxDecoration(shape: BoxShape.circle,
                  color: Color(0xFF000000 | entry.value),
                  border: Border.all(
                    color: edits.paddingColor == entry.key
                      ? AppTheme.blue : const Color(0xFFCFD9E6),
                    width: edits.paddingColor == entry.key ? 3 : 1)),
                child: edits.paddingColor == entry.key
                  ? Icon(Icons.check, size: 17,
                      color: entry.key == 'black' ? Colors.white : AppTheme.blue)
                  : null),
            )),
        ]),
        const SizedBox(height: 8),
        const Text('Warna hanya mengisi area kosong ketika Fit/Contain dipilih. '
            'Penggantian latar belakang subjek secara otomatis belum tersedia.',
            style: TextStyle(fontSize: 10.5, color: AppTheme.muted)),
      ],
    ]);
  }
}

class _AdjustmentSlider extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final String formatted;
  final ValueChanged<double> onChanged;
  const _AdjustmentSlider({required this.label, required this.value,
    required this.min, required this.max, required this.divisions,
    required this.formatted, required this.onChanged});

  @override
  Widget build(BuildContext context) => Column(children: [
    Row(children: [
      Expanded(child: Text(label, style: const TextStyle(fontSize: 11.8,
        fontWeight: FontWeight.w600))),
      Text(formatted, style: const TextStyle(fontSize: 11, color: AppTheme.muted)),
    ]),
    Slider(value: value.clamp(min, max).toDouble(), min: min, max: max,
      divisions: divisions, onChanged: onChanged),
  ]);
}

class _PolaroidEditor extends StatefulWidget {
  final WorkspaceController controller;
  final PhotoItem photo;
  const _PolaroidEditor({required this.controller, required this.photo});

  @override
  State<_PolaroidEditor> createState() => _PolaroidEditorState();
}

class _PolaroidEditorState extends State<_PolaroidEditor> {
  int tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final edits = widget.photo.edits;
    void update(PolaroidEdits next) =>
        widget.controller.updateEdits(widget.photo.id, next);

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Expanded(child: Text('Edit Foto Polaroid',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800))),
        TextButton.icon(
          onPressed: () => update(const PolaroidEdits()),
          icon: const Icon(Icons.refresh_rounded, size: 16),
          label: const Text('Reset Frame'),
        ),
      ]),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(child: _EditorTab(label: 'Bingkai', active: tabIndex == 0,
          onTap: () => setState(() => tabIndex = 0))),
        const SizedBox(width: 6),
        Expanded(child: _EditorTab(label: 'Teks & Tanggal', active: tabIndex == 1,
          onTap: () => setState(() => tabIndex = 1))),
        const SizedBox(width: 6),
        Expanded(child: _EditorTab(label: 'Edit Foto', active: tabIndex == 2,
          onTap: () => setState(() => tabIndex = 2))),
      ]),
      const SizedBox(height: 12),
      if (tabIndex == 0) ...[
        const Text('Pilih Gaya Frame', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _FramePreviewBox(
              label: 'Klasik',
              active: edits.frameStyle == FrameStyle.classic,
              color: _frameColor(edits.frameColor),
              onTap: () => update(edits.copyWith(frameStyle: FrameStyle.classic)),
            ),
            _FramePreviewBox(
              label: 'Modern',
              active: edits.frameStyle == FrameStyle.modern,
              color: _frameColor(edits.frameColor),
              onTap: () => update(edits.copyWith(frameStyle: FrameStyle.modern)),
            ),
            _FramePreviewBox(
              label: 'Vintage',
              active: edits.frameStyle == FrameStyle.vintage,
              color: _frameColor(edits.frameColor),
              onTap: () => update(edits.copyWith(frameStyle: FrameStyle.vintage)),
            ),
            _FramePreviewBox(
              label: 'Minimalis',
              active: edits.frameStyle == FrameStyle.minimal,
              color: _frameColor(edits.frameColor),
              onTap: () => update(edits.copyWith(frameStyle: FrameStyle.minimal)),
            ),
          ],
        ),
        const SizedBox(height: 14),
        const Text('Warna Frame', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 8,
          children: [
            for (final entry in PolaroidEdits.colors.entries)
              InkWell(
                onTap: () => update(edits.copyWith(frameColor: entry.key)),
                borderRadius: BorderRadius.circular(30),
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: Color(0xFF000000 | entry.value),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: edits.frameColor == entry.key ? AppTheme.blue : const Color(0xFFDCE5EF),
                      width: edits.frameColor == entry.key ? 3 : 1,
                    ),
                  ),
                  child: edits.frameColor == entry.key
                      ? Icon(
                          Icons.check_rounded,
                          size: 18,
                          color: edits.dark ? Colors.white : AppTheme.blue,
                        )
                      : null,
                ),
              ),
          ],
        ),
        const SizedBox(height: 14),
      ],
      if (tabIndex == 1) ...[
        const Text('Teks Caption di Bawah Foto', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        TextFormField(
          key: ValueKey('caption-${widget.photo.id}'),
          initialValue: edits.caption,
          maxLength: 45,
          decoration: const InputDecoration(hintText: 'Tulis caption di sini...'),
          onChanged: (value) => update(edits.copyWith(caption: value)),
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<CaptionFont>(
          isExpanded: true,
          initialValue: edits.font,
          items: const [
            DropdownMenuItem(value: CaptionFont.simple, child: Text('Simple')),
            DropdownMenuItem(value: CaptionFont.handwritten, child: Text('Handwriting')),
          ],
          onChanged: (value) {
            if (value != null) update(edits.copyWith(font: value));
          },
        ),
        const SizedBox(height: 10),
        Material(
          color: Colors.transparent,
          child: SwitchListTile.adaptive(
          dense: true,
          contentPadding: EdgeInsets.zero,
          title: const Text('Tampilkan tanggal', style: TextStyle(fontSize: 12.2)),
          value: edits.showDate,
          onChanged: (value) => update(edits.copyWith(showDate: value)),
          ),
        ),
        if (edits.showDate)
          TextFormField(
            key: ValueKey('date-${widget.photo.id}'),
            initialValue: edits.date,
            maxLength: 20,
            decoration: const InputDecoration(hintText: '24/04/2025'),
            onChanged: (value) => update(edits.copyWith(date: value)),
          ),
        const SizedBox(height: 10),
        const Text('Tambahkan stiker', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _StickerButton(
              icon: Icons.block,
              active: edits.sticker == PolaroidSticker.none,
              onTap: () => update(edits.copyWith(sticker: PolaroidSticker.none)),
            ),
            _StickerButton(
              icon: Icons.favorite,
              active: edits.sticker == PolaroidSticker.heart,
              onTap: () => update(edits.copyWith(sticker: PolaroidSticker.heart)),
            ),
            _StickerButton(
              icon: Icons.star,
              active: edits.sticker == PolaroidSticker.star,
              onTap: () => update(edits.copyWith(sticker: PolaroidSticker.star)),
            ),
            _StickerButton(
              icon: Icons.sentiment_satisfied_alt,
              active: edits.sticker == PolaroidSticker.smile,
              onTap: () => update(edits.copyWith(sticker: PolaroidSticker.smile)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'Ukuran Square 9 × 9 cm memiliki ruang caption lebih sempit. Caption dan tanggal dapat dipangkas agar tetap rapi.',
          style: TextStyle(fontSize: 10.5, color: AppTheme.muted),
        ),
      ],
      if (tabIndex == 2)
        _PhotoAdjustments(controller: widget.controller, photo: widget.photo),
    ]);
  }

  Color _frameColor(String name) => Color(0xFF000000 |
      (PolaroidEdits.colors[name] ?? 0xFFFFFF));
}

class _EditorTab extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _EditorTab({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: active ? const Color(0xFFE9F3FF) : const Color(0xFFF6F8FB),
        border: Border.all(color: active ? AppTheme.blue : const Color(0xFFE3EAF3)),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: active ? AppTheme.blue : AppTheme.muted,
        ),
      ),
    ));
  }
}

class _FramePreviewBox extends StatelessWidget {
  final String label;
  final bool active;
  final Color color;
  final VoidCallback onTap;
  const _FramePreviewBox({
    required this.label,
    required this.active,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 78,
        child: Column(
          children: [
            Container(
              width: 78,
              height: 62,
              padding: const EdgeInsets.fromLTRB(10, 6, 10, 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: active ? AppTheme.blue : const Color(0xFFE2E8F0), width: active ? 2 : 1),
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(8, 8, 8, 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEDEFF4),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(label, style: TextStyle(fontSize: 11, color: active ? AppTheme.blue : AppTheme.dark)),
          ],
        ),
      ),
    );
  }
}

class _StickerButton extends StatelessWidget {
  final IconData icon;
  final bool active;
  final VoidCallback onTap;
  const _StickerButton({required this.icon, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: active ? AppTheme.blue : const Color(0xFFE2E8F0), width: active ? 2 : 1),
          color: active ? const Color(0xFFEAF3FF) : Colors.white,
        ),
        child: Icon(icon, size: 20, color: active ? AppTheme.blue : AppTheme.muted),
      ),
    );
  }
}

class _PaperControls extends StatelessWidget {
  final WorkspaceController controller;
  const _PaperControls({required this.controller});

  @override
  Widget build(BuildContext context) {
    final settings = controller.settings;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          isExpanded: true,
          key: ValueKey('paper-${settings.paper.id}'),
          initialValue: settings.paper.id,
          decoration: const InputDecoration(labelText: 'Ukuran Kertas'),
          items: [
            for (final paper in PaperPreset.all)
              DropdownMenuItem(value: paper.id, child: Text(paper.label, maxLines: 1, overflow: TextOverflow.ellipsis)),
          ],
          onChanged: (value) {
            if (value != null) controller.changePaper(PaperPreset.byId(value));
          },
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ChoiceChip(
                label: const Text('Potret'),
                selected: settings.orientation == PaperOrientation.portrait,
                onSelected: (_) => controller.changeOrientation(PaperOrientation.portrait),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ChoiceChip(
                label: const Text('Lanskap'),
                selected: settings.orientation == PaperOrientation.landscape,
                onSelected: (_) => controller.changeOrientation(PaperOrientation.landscape),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _SliderRow(
          title: 'Margin Kertas',
          value: settings.marginMm,
          min: 0,
          max: 20,
          onChanged: controller.changeMargin,
        ),
        _SliderRow(
          title: 'Jarak Foto',
          value: settings.gapMm,
          min: 0,
          max: 15,
          onChanged: controller.changeGap,
        ),
        Material(
          color: Colors.transparent,
          child: SwitchListTile.adaptive(
          dense: true,
          contentPadding: EdgeInsets.zero,
          title: const Text('Tampilkan garis potong', style: TextStyle(fontSize: 12.2)),
          subtitle: const Text('Berlaku pada preview dan PDF', style: TextStyle(fontSize: 10.5, color: AppTheme.muted)),
          value: settings.cutMarks,
          onChanged: controller.changeCutMarks,
          ),
        ),
      ],
    );
  }
}

class _SliderRow extends StatelessWidget {
  final String title;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;
  const _SliderRow({
    required this.title,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(title, style: const TextStyle(fontSize: 12.2, fontWeight: FontWeight.w700)),
            ),
            Text('${value.toStringAsFixed(0)} mm', style: const TextStyle(fontSize: 11.5, color: AppTheme.muted)),
          ],
        ),
        Slider(
          value: value.clamp(min, max).toDouble(),
          min: min,
          max: max,
          divisions: (max - min).round(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}
