import 'dart:io';

import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../features/workspace/workspace_controller.dart';
import '../models/photo_item.dart';

class PhotoListPanel extends StatefulWidget {
  final WorkspaceController controller;
  final VoidCallback onAddPhotos;
  const PhotoListPanel({
    super.key,
    required this.controller,
    required this.onAddPhotos,
  });

  @override
  State<PhotoListPanel> createState() => _PhotoListPanelState();
}

class _PhotoListPanelState extends State<PhotoListPanel> {
  String sortBy = 'Terbaru';

  @override
  Widget build(BuildContext context) {
    final photos = [...widget.controller.photos];
    if (sortBy == 'Nama') {
      photos.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    } else {
      photos.sort((a, b) => b.id.compareTo(a.id));
    }
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 18, 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Daftar Foto (${photos.length})',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1B2C48),
                    ),
                  ),
                ),
                SizedBox(
                  width: 138,
                  child: DropdownButtonFormField<String>(
                    isExpanded: true,
                    initialValue: sortBy,
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Terbaru', child: Text('Terbaru', maxLines: 1, overflow: TextOverflow.ellipsis)),
                      DropdownMenuItem(value: 'Nama', child: Text('Nama', maxLines: 1, overflow: TextOverflow.ellipsis)),
                    ],
                    onChanged: (v) { if (v != null) setState(() => sortBy = v); },
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: photos.isEmpty
                ? _EmptyPanel(onAddPhotos: widget.onAddPhotos)
                : Scrollbar(
                    child: GridView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 18, 18, 18),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 16,
                        childAspectRatio: 0.69,
                      ),
                      itemCount: photos.length,
                      itemBuilder: (context, index) {
                        final photo = photos[index];
                        final selected = widget.controller.selectedPhoto?.id == photo.id;
                        return _PhotoCard(
                          photo: photo,
                          selected: selected,
                          onTap: () => widget.controller.selectPhoto(photo.id),
                          onDelete: () => widget.controller.removePhoto(photo.id),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _EmptyPanel extends StatelessWidget {
  final VoidCallback onAddPhotos;
  const _EmptyPanel({required this.onAddPhotos});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: const Color(0xFFEFF5FD),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(Icons.add_photo_alternate_outlined, size: 42, color: AppTheme.blue),
            ),
            const SizedBox(height: 18),
            const Text(
              'Belum ada foto',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tambahkan foto agar bisa ditata pada preview kertas. Anda bisa memilih beberapa file sekaligus.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppTheme.muted),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onAddPhotos,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Tambah Foto'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotoCard extends StatelessWidget {
  final PhotoItem photo;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  const _PhotoCard({
    required this.photo,
    required this.selected,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selected ? AppTheme.blue : const Color(0xFFD8E2EE),
                  width: selected ? 2 : 1,
                ),
                color: const Color(0xFFF7FAFE),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1B3A5A).withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Image.file(
                      File(photo.path),
                      fit: BoxFit.cover,
                      cacheWidth: 400,
                      errorBuilder: (_, _, _) => const ColoredBox(
                        color: Color(0xFFE8EEF5),
                        child: Center(child: Icon(Icons.broken_image_outlined)),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: selected ? AppTheme.blue : Colors.white,
                        borderRadius: BorderRadius.circular(7),
                        border: Border.all(
                          color: selected ? AppTheme.blue : const Color(0xFFD2DCE8),
                        ),
                      ),
                      child: Icon(
                        selected ? Icons.check_rounded : Icons.crop_square_rounded,
                        size: 16,
                        color: selected ? Colors.white : const Color(0xFF9BAABD),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  photo.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: Color(0xFF234164),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              PopupMenuButton<String>(
                tooltip: 'Opsi foto',
                onSelected: (value) {
                  if (value == 'hapus') onDelete();
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'hapus', child: Text('Hapus foto')),
                ],
                icon: const Icon(Icons.more_horiz_rounded, size: 18, color: AppTheme.muted),
              ),
            ],
          ),
          Text(
            '${photo.widthPx} × ${photo.heightPx} px',
            style: const TextStyle(fontSize: 10.5, color: AppTheme.muted),
          ),
        ],
      ),
    );
  }
}
