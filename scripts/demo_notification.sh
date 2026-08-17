#!/usr/bin/env bash
# Demo notifikasi layar kunci Mantau — satu perintah untuk semuanya.
#
#   1. (opsional) menyalakan emulator
#   2. menunggu emulator selesai boot
#   3. memasang APK debug bila tersedia
#   4. mengizinkan notifikasi lewat adb (menghindari dialog izin saat demo)
#   5. meluncurkan aplikasi -> notifikasi "Kemungkinan jatuh terdeteksi"
#      muncul ±2 detik kemudian
#
# Pemakaian:
#   bash scripts/demo_notification.sh            # emulator sudah menyala
#   bash scripts/demo_notification.sh --launch   # jalankan emulator dulu
set -euo pipefail

EMULATOR_ID="Medium_Phone_API_36.1"
APP_ID="id.mantau.demo"
APK="build/app/outputs/flutter-apk/app-debug.apk"

# Lokasi Android SDK. Variabel lingkungan boleh kosong — pakai nilai bawaan
# yang aman (${VAR:-} tidak memicu "unbound variable" walau VAR tidak terisi).
SDK="${ANDROID_SDK_ROOT:-${ANDROID_HOME:-}}"
if [[ -z "$SDK" ]]; then
  SDK="${LOCALAPPDATA:-}/Android/Sdk"
fi

# Cari adb: variabel ADB eksplisit, lalu PATH, lalu lokasi SDK yang umum.
if [[ -n "${ADB:-}" ]]; then
  ADB_BIN="$ADB"
elif command -v adb >/dev/null 2>&1; then
  ADB_BIN="adb"
elif [[ -n "$SDK" && -e "$SDK/platform-tools/adb.exe" ]]; then
  ADB_BIN="$SDK/platform-tools/adb.exe"
else
  echo "adb tidak ditemukan." >&2
  echo "Set ADB=/path/ke/adb.exe atau ANDROID_SDK_ROOT=/path/ke/Sdk." >&2
  exit 1
fi

if [[ "${1:-}" == "--launch" ]]; then
  if ! command -v flutter >/dev/null 2>&1; then
    echo "flutter tidak ditemukan di PATH." >&2
    exit 1
  fi
  echo "==> Meluncurkan emulator $EMULATOR_ID..."
  flutter emulators --launch "$EMULATOR_ID"
fi

echo "==> Menunggu perangkat..."
"$ADB_BIN" wait-for-device
until [[ "$("$ADB_BIN" shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" == "1" ]]; do
  sleep 1
done
echo "==> Emulator selesai boot."

if [[ -f "$APK" ]]; then
  echo "==> Memasang APK debug..."
  "$ADB_BIN" install -r "$APK"
else
  echo "!! APK debug tidak ditemukan ($APK)." >&2
  echo "   Jalankan dulu: flutter build apk --debug" >&2
fi

echo "==> Mengizinkan notifikasi (POST_NOTIFICATIONS)..."
"$ADB_BIN" shell pm grant "$APP_ID" android.permission.POST_NOTIFICATIONS || \
  echo "    (gagal — pastikan APK sudah terpasang, atau lewati saja)"

echo "==> Meluncurkan Mantau..."
"$ADB_BIN" shell am start -n "$APP_ID/.MainActivity"

echo ""
echo "==> Selesai. Notifikasi 'Kemungkinan jatuh terdeteksi' muncul ±2 detik lagi."
echo "    Kunci layar emulator, lalu ketuk notifikasinya untuk langsung membuka"
echo "    rekaman — login dan onboarding dilewati."
