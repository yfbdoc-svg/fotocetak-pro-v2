$ErrorActionPreference = 'Stop'
Write-Host 'Menyiapkan FotoCetak Pro untuk Windows...' -ForegroundColor Cyan
flutter doctor -v
flutter create --platforms=windows --project-name fotocetak_pro .
if ($LASTEXITCODE -ne 0) { throw 'Gagal membuat Windows runner.' }
flutter pub get
if ($LASTEXITCODE -ne 0) { throw 'Gagal mendapatkan dependensi.' }
flutter run -d windows
