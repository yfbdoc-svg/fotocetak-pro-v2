# Patch: Flutter Analyze gagal (FotoCetak Pro Tahap 4)

Paket ini memperbaiki output GitHub Actions `flutter analyze --no-fatal-infos`:

- `test/photo_edits_test.dart`: menghapus `const` dari objek `PhotoItem` yang menggunakan `PhotoSize.defaultSize` (getter non-const). Memperbaiki error `invalid_constant`.
- `lib/features/workspace/workspace_controller.dart`: menggunakan operator `?.` untuk kuantitas opsional.
- `lib/widgets/paper_preview.dart`: menggunakan `Matrix4.setEntry` dan `setTranslationRaw` untuk zoom terpusat tanpa API `translate/scale` yang deprecated.
- `lib/widgets/photo_list_panel.dart`: menggunakan wildcard `_` pada parameter callback yang tidak dipakai.

## Cara menerapkan melalui GitHub

1. Ekstrak ZIP paket ini.
2. Unggah **isi folder** `fotocetak_pro` ke akar repository lama, lalu commit perubahan; pastikan folder `.github/workflows` turut terunggah.
3. Di GitHub, buka Actions > Build FotoCetak Pro Windows dan jalankan ulang workflow **pada commit baru** (jangan hanya tekan Re-run jobs untuk commit lama).
4. Langkah berjalan berurutan: `flutter analyze --no-fatal-infos`, `flutter test`, kemudian `flutter build windows --release`.
5. Jika salah satu langkah gagal, kirimkan log langkah yang berwarna merah.

## Status verifikasi

Perubahan telah diverifikasi terhadap lokasi dan isi file paket asal; belum diuji di Flutter SDK/Windows lokal karena lingkungan ini tidak memiliki toolchain tersebut. Hasil GitHub Actions menentukan apakah build sepenuhnya berhasil.
