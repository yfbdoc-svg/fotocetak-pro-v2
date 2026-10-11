# FotoCetak Pro v0.4.1 — Flutter Windows

**Paket source code, bukan EXE jadi.** Didesain untuk build di GitHub Actions agar laptop tidak memerlukan Visual Studio dan C++ Build Tools.

## Patch v0.4.1 untuk kegagalan GitHub Actions

- SwitchListTile diberi pembungkus Material lokal untuk mengatasi assertion ListTile pada widget test.
- Dropdown foto, kertas, crop, dan font menggunakan isExpanded dan ellipsis untuk mencegah RenderFlex overflow.
- Pengujian photo renderer memakai tester.runAsync() agar operasi IO/codec native tidak menggantung pada FakeAsync.
- Ada tes tampilan pada lebar jendela 1440 dan 1280 px.
- Perubahan ini tidak menghapus fungsi foto dan tidak menonaktifkan pengujian.

## Yang berubah dari Tahap 3

### Workspace
- Tampilan tiga panel lebih adaptif: ukuran panel disesuaikan berdasarkan lebar monitor, bukan lebar minimum tetap 1460 px.
- Toolbar tambah foto, buka/simpan proyek, PDF, dan cetak.
- Panel thumbnail 3 kolom dengan pengurutan **Terbaru / Nama** dan pilihan foto.
- Preview kertas dengan garis tepi, latar grid, penggaris (ruler), margin, dan tanda potong tiap item foto.
- Zoom **60%–250%** dengan pan melalui mouse/trackpad. **Fit ke Layar** kembali ke ukuran yang menampilkan seluruh kertas. Tiga tombol tampilan mengontrol grid workspace/preview sederhana.

### Editor Pas Foto / Polaroid yang berfungsi
- Hanya satu mode proyek yang aktif pada satu waktu: **Pas Foto** atau **Polaroid**. Saat ganti mode, ukuran foto mengikuti default mode baru, tetapi file asli dan kuantitas tidak berubah.
- **Pas Foto**: preset 2×3, 3×4, 4×6, 3×5, 5×7 cm, ditambah dialog **Lainnya...** untuk ukuran 1–30 cm.
- **Polaroid**: 7 preset sesuai spesifikasi sebelumnya, termasuk jendela foto kamera asli dan ukuran studio.
- Per foto: jumlah cetak, **Fit / Fill**, zoom crop, posisi crop horizontal/vertikal, rotasi 90°, mirror horizontal, kecerahan, kontras, saturasi, dan reset.
- Semua koreksi foto disimpan non-destruktif di file proyek `.fcp`. Preview dan hasil PDF memakai renderer gambar yang sama (preview 160 PPI agar ringan, PDF target 300 PPI).
- Panel editor Polaroid kini memakai tab interaktif **Bingkai**, **Teks & Tanggal**, **Edit Foto**.
- Pilih gaya bingkai, warna bingkai, caption, tanggal manual, font, dan stiker. Frame, caption, stiker serta edit foto muncul dalam PDF.
- PDF dan dialog cetak tersedia. Gunakan mode cetak **100% / Actual Size**.

## Batasan yang perlu diketahui

1. Pilihan warna latar Pas Foto **hanya mengisi ruang kosong ketika Fit/Contain**, bukan menghapus atau mengganti background yang berada di belakang subjek. Fitur penghapusan background otomatis memerlukan segmentasi dan **belum tersedia**.
2. Gaya font Handwriting pada layar dapat berbeda dengan PDF karena font PDF bawaan menggunakan pengganti Courier Oblique. Sebaiknya uji cetak.
3. Pengaturan warna foto sederhana, **belum sistem color management berbasis ICC**.
4. Algoritma penyusunan masih berbasis baris/shelf, belum optimasi MaxRects serta belum mendukung drag item manual dalam kertas.
5. Frame Polaroid adalah desain cetak yang meniru tampilan Polaroid, bukan film Polaroid asli. Untuk cetak standar kamera, ukuran area gambar dan ukuran luar memakai data yang disepakati.
6. Warna profil printer, *borderless overscan*, dan scaling printer dapat menyebabkan hasil cetak tidak identik dengan ukuran pada layar. **Wajib uji penggaris 3×4 cm dan skala 100%.**
7. Mode Pas Foto/Polaroid tidak dicampur dalam satu proyek. Berganti mode mengubah ukuran setiap foto ke default mode yang dipilih.
8. Proyek menyimpan jalur absolut file asli. Jika foto dipindahkan/diubah namanya, buka proyek lama mungkin kehilangan referensi.

## Build tanpa Visual Studio (GitHub Actions)

1. Ekstrak paket ZIP ini.
2. Buat repository **Private** (bisa juga gunakan repository lama) di GitHub.
3. Upload **isi folder `fotocetak_pro`** langsung ke root repository: `pubspec.yaml` dan `.github/workflows/build-windows.yml` harus berada pada root, bukan di subfolder.
4. Pilih **Actions → Build FotoCetak Pro Windows → Run workflow**. Push ke branch `main` juga dapat menjalankan build otomatis.
5. Workflow menginstal Flutter pada Windows runner, membuat target Windows, menjalankan formatter, `flutter analyze`, `flutter test`, lalu `flutter build windows --release`.
6. Setelah job hijau, buka **Artifacts**, unduh `FotoCetakPro-Windows-x64`.
7. Ekstrak seluruh artifact lalu buka `fotocetak_pro.exe`. **DLL dan folder `data` harus tetap bersamanya.**

> **Status validasi:** Source telah diperiksa struktur berkas dan keseimbangan sintaks, dan tes telah ditulis, tetapi **belum dikompilasi/dijalankan pada Windows di sesi ini** karena Flutter SDK dan Visual Studio toolchain tidak tersedia di container penyusun. Konfirmasi pertama diperoleh dari hasil Actions. Jika gagal, kirim error job yang merah untuk koreksi.

## Struktur inti

```text
fotocetak_pro/
├── .github/workflows/build-windows.yml
├── lib/
│   ├── models/photo_edits.dart
│   ├── features/photo_editor/photo_render_service.dart
│   ├── features/workspace/workspace_controller.dart
│   ├── features/print_engine/pdf_print_service.dart
│   ├── widgets/paper_preview.dart
│   ├── widgets/print_settings_panel.dart
│   ├── widgets/photo_list_panel.dart
│   ├── widgets/polaroid_face.dart
│   └── screens/workspace_screen.dart
├── test/
├── pubspec.yaml
└── PANDUAN_BUILD_TANPA_VISUAL_STUDIO.md
```
