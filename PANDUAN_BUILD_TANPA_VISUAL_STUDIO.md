# Build FotoCetak Pro v0.4.0 melalui GitHub Actions

Tidak perlu instal Visual Studio/VS Code ataupun C++ di laptop. Gunakan browser dan akun GitHub.

## Unggah

1. Download file `FotoCetak_Pro_Tahap4_EditorAktif_GitHub.zip` dan ekstrak.
2. Buka repo GitHub lama `fotocetak-pro` atau buat repo baru melalui https://github.com/new dan pilih **Private**.
3. Pilih **Add file → Upload files**, unggah semua **isi** folder `fotocetak_pro`. Jangan unggah ZIP mentah dan jangan menyisakan satu lapis folder `fotocetak_pro` di root repository.
4. Pastikan `.github/workflows/build-windows.yml`, `pubspec.yaml`, dan folder `lib`, `test` terlihat di root repo. Commit ke branch `main`.

## Bangun dan unduh

5. Buka **Actions → Build FotoCetak Pro Windows**.
6. Jika belum berjalan otomatis, pilih **Run workflow → main → Run workflow**.
7. Tunggu selesai. Jika merah, buka step `Periksa masalah kode`, `Uji dasar aplikasi`, atau `Build aplikasi EXE versi Release`, lalu salin error.
8. Jika hijau, pilih run yang selesai → bagian **Artifacts** → download `FotoCetakPro-Windows-x64`.
9. Ekstrak semua berkas hasil download dan jalankan `fotocetak_pro.exe`. Jangan pindahkan hanya file EXE.

## Catatan

- Hasil build berjalan offline di Windows 10/11 64-bit sesuai dukungan Flutter.
- Output memerlukan folder `data/`, `flutter_windows.dll`, serta DLL pendukung.
- Saat uji cetak pilih skala 100%, jangan Fit to Page, dan ukur cetakan Pas Foto 3×4 cm dengan penggaris.
- Penggantian background otomatis dan manajemen warna ICC masih belum dikerjakan.
- Paket source ini **belum diverifikasi berhasil di GitHub Actions** pada sesi pembuatan. Gunakan log Actions untuk validasi.
