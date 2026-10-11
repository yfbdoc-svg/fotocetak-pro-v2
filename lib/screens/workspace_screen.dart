import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../features/photo_manager/photo_import_service.dart';
import '../features/print_engine/pdf_print_service.dart';
import '../features/project_storage/project_service.dart';
import '../features/workspace/workspace_controller.dart';
import '../widgets/paper_preview.dart';
import '../widgets/photo_list_panel.dart';
import '../widgets/print_settings_panel.dart';

class WorkspaceScreen extends StatefulWidget {
  const WorkspaceScreen({super.key});

  @override
  State<WorkspaceScreen> createState() => _WorkspaceScreenState();
}

class _WorkspaceScreenState extends State<WorkspaceScreen> {
  final WorkspaceController controller = WorkspaceController();
  bool busy = false;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _message(String text, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(text),
          backgroundColor: error ? const Color(0xFFB63F45) : AppTheme.dark,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  Future<void> _withBusy(Future<void> Function() action) async {
    if (busy) return;
    setState(() => busy = true);
    try {
      await action();
    } catch (error) {
      _message('Proses gagal: $error', error: true);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> importPhotos() => _withBusy(() async {
        final result = await PhotoImportService.pickPhotos();
        final before = controller.photos.length;
        controller.addPhotos(result.photos);
        final added = controller.photos.length - before;
        if (added > 0) {
          _message('$added foto berhasil dimasukkan.');
        }
        if (added == 0 && result.photos.isNotEmpty) {
          _message('Semua foto yang dipilih sudah ada di daftar.');
        }
        if (result.errors.isNotEmpty) {
          _message(result.errors.take(2).join(' '), error: true);
        }
      });

  Future<void> saveProject() => _withBusy(() async {
        final saved = await ProjectService.save(
          controller.photos,
          controller.settings,
          controller.mode,
        );
        if (saved) _message('Proyek berhasil disimpan.');
      });

  Future<void> openProject() => _withBusy(() async {
        final project = await ProjectService.open();
        if (project == null) return;
        controller.replaceProject(project.photos, project.settings, project.mode);
        _message('Proyek dibuka: ${project.photos.length} foto tersedia.');
        if (project.missingFiles.isNotEmpty) {
          _message(
            '${project.missingFiles.length} file foto tidak ditemukan di lokasi aslinya.',
            error: true,
          );
        }
      });

  Future<void> exportPdf() => _withBusy(() async {
        if (controller.layout.placedCount == 0) {
          _message('Belum ada foto yang dapat diekspor.', error: true);
          return;
        }
        final bytes = await PdfPrintService.render(
          photos: controller.photos,
          settings: controller.settings,
          layout: controller.layout,
        );
        final saved = await PdfPrintService.exportPdf(bytes);
        if (saved) _message('PDF siap cetak berhasil disimpan.');
      });

  Future<void> printPhotos() => _withBusy(() async {
        if (controller.layout.placedCount == 0) {
          _message('Belum ada foto yang dapat dicetak.', error: true);
          return;
        }
        final bytes = await PdfPrintService.render(
          photos: controller.photos,
          settings: controller.settings,
          layout: controller.layout,
        );
        await PdfPrintService.printPdf(bytes);
        _message('Dialog cetak telah dibuka. Pastikan skala cetak 100%.');
      });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          return Container(
            color: const Color(0xFFF2F6FB),
            child: Column(
              children: [
                _TopHeader(busy: busy),
                _Toolbar(
                  busy: busy,
                  onImport: importPhotos,
                  onOpen: openProject,
                  onSave: saveProject,
                  onExport: exportPdf,
                  onPrint: printPhotos,
                ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final width = math.max(1280.0, constraints.maxWidth);
                      final leftWidth = (width * .245).clamp(305.0, 415.0).toDouble();
                      final rightWidth = (width * .27).clamp(350.0, 440.0).toDouble();
                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SizedBox(
                          width: width,
                          height: constraints.maxHeight,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              SizedBox(
                                width: leftWidth,
                                child: PhotoListPanel(
                                  controller: controller,
                                  onAddPhotos: importPhotos,
                                ),
                              ),
                              const VerticalDivider(width: 1),
                              Expanded(
                                child: PaperPreview(controller: controller),
                              ),
                              const VerticalDivider(width: 1),
                              SizedBox(
                                width: rightWidth,
                                child: PrintSettingsPanel(
                                  controller: controller,
                                  busy: busy,
                                  onExportPdf: exportPdf,
                                  onPrint: printPhotos,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                _StatusBar(controller: controller),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _TopHeader extends StatelessWidget {
  final bool busy;
  const _TopHeader({required this.busy});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 22),
      decoration: const BoxDecoration(
        color: Color(0xFFF8FBFF),
        border: Border(bottom: BorderSide(color: AppTheme.border)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: const LinearGradient(
                colors: [Color(0xFF1A82F2), Color(0xFF0E63D8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Icon(Icons.photo_camera_rounded, color: Colors.white),
          ),
          const SizedBox(width: 14),
          const Text(
            'FotoCetak Pro',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
              color: Color(0xFF173157),
            ),
          ),
          const SizedBox(width: 18),
          Container(width: 1, height: 28, color: const Color(0xFFDCE5EF)),
          const SizedBox(width: 18),
          const Text(
            'Cetak Foto Lebih Mudah, Lebih Kreatif',
            style: TextStyle(
              fontSize: 13.5,
              color: AppTheme.muted,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: busy ? const Color(0xFFFFF7E1) : const Color(0xFFEAF7F0),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: busy ? const Color(0xFFF1D98D) : const Color(0xFFCFE7D9),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  busy ? Icons.sync_rounded : Icons.circle,
                  size: busy ? 14 : 10,
                  color: busy ? const Color(0xFFB58A0C) : AppTheme.green,
                ),
                const SizedBox(width: 8),
                Text(
                  busy ? 'Memproses...' : 'Siap Digunakan',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: busy ? const Color(0xFF8A6B00) : AppTheme.green,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            tooltip: 'Tentang aplikasi',
            onPressed: () => showAboutDialog(
              context: context,
              applicationName: 'FotoCetak Pro',
              applicationVersion: '0.4.1',
              children: const [
                Text(
                  'Workspace FotoCetak Pro disesuaikan agar lebih mendekati mockup final, '
                  'dengan preview besar, ruler/grid, garis potong, serta mode Pas Foto dan Polaroid.',
                ),
              ],
            ),
            icon: const Icon(Icons.help_outline_rounded, color: AppTheme.muted),
          ),
        ],
      ),
    );
  }
}

class _Toolbar extends StatelessWidget {
  final bool busy;
  final VoidCallback onImport;
  final VoidCallback onOpen;
  final VoidCallback onSave;
  final VoidCallback onExport;
  final VoidCallback onPrint;

  const _Toolbar({
    required this.busy,
    required this.onImport,
    required this.onOpen,
    required this.onSave,
    required this.onExport,
    required this.onPrint,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          FilledButton.icon(
            onPressed: busy ? null : onImport,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              backgroundColor: AppTheme.blue,
            ),
            icon: const Icon(Icons.add_rounded, size: 20),
            label: const Text('Tambah Foto'),
          ),
          const SizedBox(width: 12),
          _ToolbarButton(
            icon: Icons.folder_open_outlined,
            label: 'Buka Proyek',
            onTap: busy ? null : onOpen,
          ),
          const SizedBox(width: 10),
          _ToolbarButton(
            icon: Icons.save_outlined,
            label: 'Simpan Proyek',
            onTap: busy ? null : onSave,
          ),
          const Spacer(),
          _ToolbarButton(
            icon: Icons.picture_as_pdf_outlined,
            label: 'Ekspor PDF',
            onTap: busy ? null : onExport,
            foreground: const Color(0xFFDD3A32),
          ),
          const SizedBox(width: 10),
          FilledButton.icon(
            onPressed: busy ? null : onPrint,
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.blue,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            ),
            icon: const Icon(Icons.print_outlined, size: 20),
            label: const Text('Cetak Sekarang'),
          ),
        ],
      ),
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color? foreground;
  const _ToolbarButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18, color: foreground),
      label: Text(label, style: TextStyle(color: foreground)),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}

class _StatusBar extends StatelessWidget {
  final WorkspaceController controller;
  const _StatusBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    final pageCount = controller.layout.pageCount;
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppTheme.border)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded, size: 18, color: AppTheme.green),
          const SizedBox(width: 8),
          Text(
            '${controller.photos.length} foto  •  ${controller.totalCopies} cetakan  •  ${math.max(pageCount, 1)} halaman',
            style: const TextStyle(fontSize: 11.5, color: AppTheme.muted),
          ),
          const Spacer(),
          const Text(
            'FotoCetak Pro · v0.4.1',
            style: TextStyle(fontSize: 11, color: AppTheme.muted),
          ),
        ],
      ),
    );
  }
}
