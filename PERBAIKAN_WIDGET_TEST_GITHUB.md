# Perbaikan GitHub Actions v0.4.1

## Gejala

- Assertion `ListTile background color or ink splashes may be invisible`
- RenderFlex overflow pada dropdown foto dan dropdown kertas
- `photo_edits_test.dart` menunggu selama 10 menit lalu timeout

## Perubahan

1. `lib/widgets/print_settings_panel.dart`: `SwitchListTile.adaptive` berada di dalam `Material(color: Colors.transparent)`. Dropdown memiliki `isExpanded: true` dan teks ukuran kertas memakai `TextOverflow.ellipsis`.
2. `lib/widgets/photo_list_panel.dart`: dropdown pengurutan menjadi lebar tetap 138 px, tanpa floating label di dalam kolom sempit, dan `isExpanded: true`.
3. `test/photo_edits_test.dart`: operasi File IO dan raster native dijalankan di `tester.runAsync`, bukan FakeAsync; render diberi timeout 45 detik agar failure terdiagnosis tanpa menunggu 10 menit. File sumber dibandingkan byte-per-byte seperti pengujian semula.
4. `test/widget_test.dart`: smoke test pada lebar 1440 dan 1280 px untuk menangkap assertion widget.

## Cara menjalankan build GitHub Actions

- Ganti file proyek yang ada dengan isi `fotocetak_pro` pada ZIP ini; lokasi `.github/workflows/build-windows.yml` tetap di root repo.
- Commit ke branch `main`, pilih **Actions** → **Build FotoCetak Pro Windows**.
- Periksa langkah **Uji dasar aplikasi**, lalu **Build aplikasi EXE versi Release**.

**Validasi:** Pemeriksaan struktur dan pemeriksaan statis terhadap patch berhasil dilakukan, tetapi Flutter SDK tidak tersedia pada lingkungan penyusunan, sehingga `flutter test` dan kompilasi Windows belum dieksekusi di sini.
