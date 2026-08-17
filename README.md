# Mantau Aplikasi Demo (versi Android)

> Ini salinan khusus **Android** dari `triathlon-mobile`. Kode aplikasinya sama;
> yang berbeda hanya konfigurasi Android. Karena keduanya salinan terpisah,
> **perubahan di satu proyek tidak ikut ke proyek lainnya** — kalau ada
> perbaikan yang perlu ada di dua-duanya, terapkan dua kali.

Hub seluler untuk layanan langganan deteksi jatuh berbasis CCTV. Aplikasi
mengelola kamera terdaftar, memberi peringatan saat pipeline computer vision
mendeteksi jatuh, lalu membantu pengguna meninjau rekaman dan menghubungi
kontak darurat secepat mungkin.

> **Ini aplikasi demo.** Tidak ada backend, tidak ada jaringan, tidak ada
> autentikasi sungguhan. Semua data bersifat dummy dan hanya disimpan di
> memori. Klip peringatan adalah satu video kaleng berdurasi ~6 detik yang
> dipakai ulang untuk semua kejadian. Sambungan ke `mantau-prototype`
> (pipeline CV + backend) berada di luar cakupan versi ini.

---

## Kebutuhan

| Kebutuhan | Versi |
|---|---|
| Flutter | **3.35.7** atau lebih baru (Dart `^3.9.2`) |
| JDK | **17** — wajib untuk Android Gradle Plugin 8.9 |
| Android SDK | platform-tools + salah satu emulator/perangkat Android |
| Gradle | 8.12, otomatis diunduh oleh wrapper |

Batas Dart `^3.9.2` cukup ketat: Flutter yang lebih lama akan gagal di
`flutter pub get`. Periksa dengan `flutter --version` lalu `flutter doctor`
sebelum melangkah.

Berkas `android/local.properties` **tidak ikut ke repositori** (berisi jalur SDK
yang khas per mesin) dan dibuat ulang otomatis oleh Flutter. Begitu pula
`gradlew`, `gradlew.bat`, dan `gradle-wrapper.jar` — Flutter menaruhnya kembali
sendiri saat pertama kali membangun. Jadi tidak ada yang perlu disalin manual.

## Menjalankan di emulator Android

```bash
git clone <url-repositori>
cd mantau-android
flutter pub get
```

Siapkan emulator. Nama AVD **berbeda di tiap mesin**, jadi lihat dulu daftarnya:

```bash
flutter emulators
flutter emulators --launch <id-emulator-anda>
```

Kalau daftarnya kosong, buat satu lewat Android Studio (Device Manager) atau:

```bash
flutter emulators --create --name mantau_demo
```

Setelah emulator menyala:

```bash
flutter devices        # pastikan perangkatnya terbaca
flutter run -d android
```

`-d android` memilih perangkat Android yang tersedia, jadi tidak perlu menebak
id seperti `emulator-5554`.

Build pertama menjalankan Gradle dari nol dan bisa memakan **5–10 menit**;
build berikutnya jauh lebih cepat.

Kalau ingin memasang APK-nya langsung tanpa `flutter run`:

```bash
flutter build apk --debug
adb install -r build/app/outputs/flutter-apk/app-debug.apk
```

`adb` sering tidak otomatis masuk PATH. Lokasinya:

- Windows — `%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe`
- macOS/Linux — `~/Android/Sdk/platform-tools/adb`

Sudah diuji pada **Medium Phone API 36.1 (Android 16)**. Identitas aplikasinya:

| Item | Nilai |
|---|---|
| Application ID | `id.mantau.demo` |
| Nama di peluncur | Mantau |
| Ikon peluncur | glif lensa dari logo, di atas oranye merek |

Aplikasi memakai seluruh layar perangkat; bingkai ponsel yang dipakai versi web
otomatis tidak aktif karena lebar layar sudah di bawah ambangnya.

Menjalankan pengujian alur demo:

```bash
flutter test
```

### Impeller dimatikan — jangan dihidupkan lagi tanpa mengecek

`android/app/src/main/AndroidManifest.xml` mematikan Impeller
(`io.flutter.embedding.android.EnableImpeller` = `false`) sehingga aplikasi
memakai Skia.

Ini bukan pilihan gaya. Dengan Impeller aktif di emulator, sebagian teks
**hilang sama sekali padahal tetap memakan ruang tata letak** — paling terlihat
pada judul "Pilih paket langganan" dan paragraf di bawahnya, yang tampil sebagai
area kosong. Layar yang sama tampil normal di web, jadi penyebabnya ada pada
perenderan di GPU tiruan emulator, bukan pada kode aplikasi.

Kalau nanti dicoba di perangkat asli, Impeller boleh dinyalakan kembali —
tetapi periksa dulu layar pemilihan paket sebelum menyimpulkan aman.

---

## Data demo

### Akun masuk

| Kolom | Nilai |
|---|---|
| Email | `andi.pratama@gmail.com` |
| Kata sandi | `demo1234` |

Kedua kolom sudah terisi otomatis. **Kredensial apa pun diterima** asal tidak
kosong, dan tombol Google/Apple langsung masuk — salah ketik saat presentasi
tidak akan menggagalkan demo.

### Kartu pembayaran demo

Langganan pertama **wajib dibayar**, dan di layar pembayaran itulah kartu diisi
untuk pertama kali. Kartu **sengaja dibiarkan kosong setiap kali masuk**, supaya
proses pengisiannya bisa diperagakan. Isi dengan nilai berikut:

| Kolom | Nilai |
|---|---|
| Nomor kartu | `4242 4242 4242 4242` |
| Nama pemegang kartu | `ANDI PRATAMA` |
| Masa berlaku | `09/28` |
| CVV | `123` |

> Semua angka di atas adalah **data uji**, bukan kartu sungguhan — `4242…`
> adalah nomor kartu percobaan yang dikenal luas. Aplikasi ini tidak memproses
> pembayaran apa pun dan tidak mengirim data ke mana pun; kartu hanya disimpan
> di memori dan hilang saat keluar akun.

Merek kartu diturunkan dari digit pertama (`4` → Visa, `5` → Mastercard,
`3` → Amex), jadi nomor lain juga bisa dipakai. Validasinya memeriksa panjang
dan format saja — **tanpa pemeriksaan Luhn** — supaya nomor apa pun yang masuk
akal tetap diterima saat presentasi.

Setelah tersimpan, kartu muncul di **Akun → Metode pembayaran** dan otomatis
dipakai saat menaikkan paket, lengkap dengan tombol **Ganti kartu**.

### Kamera bawaan

Satu kamera sudah terpasang saat aplikasi dibuka.

| Kolom | Nilai |
|---|---|
| Nama kamera | `Kamar Ibu` |
| Alamat | `Jl. Melati No. 12, Bandung` |
| RTSP URL | `rtsp://192.168.1.42:554/stream1` |
| Username | `admin` |
| Password | `admin123` |

### Kamera untuk diketik saat demo

Pakai nilai ini saat memperagakan layar **Tambah kamera**:

| Kolom | Nilai |
|---|---|
| Nama kamera | `Ruang Tengah` |
| Alamat | `Jl. Melati No. 12, Bandung` |
| RTSP URL | `rtsp://192.168.1.43:554/stream1` |
| Username | `admin` |
| Password | `cctv2024` |

Tombol **Uji koneksi** memalsukan pemeriksaan ~1,5 detik lalu menampilkan
"Koneksi berhasil diuji — gambar diterima". Tidak ada CCTV yang dihubungi.

### Kontak darurat

Terisi satu kontak:

| Nama | Telepon | Hubungan |
|---|---|---|
| Budi Santoso | `+62 812-3456-7890` | Anak |

Kontak kedua untuk **ditambahkan langsung saat demo**, supaya fitur pengurutan
benar-benar terlihat:

| Nama | Telepon | Hubungan |
|---|---|---|
| Sri Rahayu | `+62 813-2211-9087` | Menantu |

### Kejadian

Tiga kejadian, semuanya memakai klip `fall_demo.mp4` yang sama:

| Kejadian | Waktu | Status |
|---|---|---|
| Jatuh + diam >5 mnt | Hari ini, 14:32 | **Belum ditinjau** — memicu titik merah |
| Jatuh ringan | 3 hari lalu, 09:15 | Sudah ditutup |
| Gerakan mencurigakan | 7 hari lalu, 20:48 | Sudah ditutup |

Tanggal dihitung relatif terhadap saat aplikasi dijalankan, jadi label
"3 hari lalu" selalu akurat kapan pun demo dilakukan.

> Spesifikasi awal menyebut "2 rekaman lama". Di sini ada **3 entri** karena
> kejadian dari notifikasi aktif juga perlu punya rekaman yang bisa dibuka —
> tanpa itu, lompatan dari Notifikasi akan mendarat di halaman kosong.

### Harga dan aturan langganan

**Rp150.000 per kamera per bulan.** Maksimal **10 kamera** pada demo ini.
Kuota yang dipilih saat onboarding mengikat: ia menjadi penyebut "x/y" di
Beranda dan batas penambahan kamera.

Langganan pertama ditagih **satu bulan penuh** (`jumlah kamera × Rp150.000`)
lewat layar pembayaran. Sesudah itu, naik dan turun paket sengaja berperilaku
berbeda:

| Arah | Biaya | Kapan berlaku |
|---|---|---|
| **Naik paket** | Selisih kamera × Rp150.000, dibayar di layar pembayaran | **Seketika** setelah pembayaran berhasil |
| **Turun paket** | Gratis | **Awal bulan berikutnya** |

Contoh: dari 2 ke 5 kamera dikenai 3 × Rp150.000 = **Rp450.000**. Tagihan
bulanan berikutnya lalu menyesuaikan paket baru.

Beberapa perilaku yang sengaja dijaga:

- Kuota **hanya berubah setelah pembayaran berhasil** — berlaku untuk langganan
  pertama maupun peningkatan paket. Menekan Batal atau kembali dari layar
  pembayaran tidak mengubah apa pun.
- Naik paket **membatalkan penurunan yang terjadwal**. Tanpa ini pengguna
  membayar kamera tambahan hari ini lalu diam-diam turun bulan depan.
- Paket **tidak bisa turun di bawah jumlah kamera yang terpasang**. Hapus
  kamera dulu; tombolnya dinonaktifkan dengan penjelasan.
- Pembayaran yang berhasil **muncul di riwayat tagihan** pada
  Akun → Metode pembayaran.

> Penurunan paket dijadwalkan tetapi **tidak pernah benar-benar diterapkan
> selama demo** — tanggal berlakunya bulan depan sedangkan demo berjalan hari
> ini. Panel kuning "Penurunan paket terjadwal" beserta tombol Batalkan
> itulah wujud fiturnya; tidak ada simulasi pergantian bulan.

### Pembayaran (khusus tampilan)

Kartu tersimpan `Visa •••• 4829`, a.n. ANDI PRATAMA, berlaku `09/28`, beserta
riwayat tagihan tiga bulan terakhir. Halaman pembayaran dan pengaturan bersifat
tampilan saja.

---

## Demo notifikasi layar kunci

Aplikasi mengirim **notifikasi sistem sungguhan** beberapa detik setelah
dibuka — ditangani `lib/services/notification_service.dart` memakai
`flutter_local_notifications`. Notifikasi tampil di laci maupun layar kunci
emulator, dan mengetuknya membuka aplikasi **langsung ke halaman rekaman**
kejadian yang belum ditinjau (`ev-1`), lengkap dengan video, rentang waktu,
dan kontak darurat. Login dan onboarding **sengaja dilewati** demi kelancaran
demo (lihat `AppState.bypassToEvent`).

### Cara menjalankan (dari nol)

1. **Bangun APK debug** — cukup sekali; ulangi bila kode berubah:

   ```bash
   flutter build apk --debug
   ```

2. **Jalankan skrip demo** — menyalakan emulator (bila `--launch`), menunggu
   selesai boot, memasang APK, mengizinkan notifikasi lewat adb, lalu membuka
   aplikasi:

   ```bash
   bash scripts/demo_notification.sh --launch
   ```

   (Tanpa `--launch`, skrip memakai emulator yang sudah menyala.)

3. **Kunci layar** emulator (tombol daya di panel samping) — notifikasi
   **"Kemungkinan jatuh terdeteksi"** sudah menunggu di layar kunci.

4. **Ketuk notifikasi** → aplikasi terbuka langsung di halaman rekaman
   kejadian (video berjalan, kontak darurat terlihat). Tanpa login, tanpa
   onboarding.

Notifikasi dikirim ulang setiap kali aplikasi dibuka dengan id tetap, jadi
notifikasi lama diganti — tidak menumpuk di laci. Aplikasi perlu dijalankan
sekali dulu sebelum notifikasi bisa ada (langkah 2 di atas melakukannya).

### Cara manual (tanpa skrip)

Bila skrip tidak bisa dipakai — mis. adb tidak ditemukan dan pesan di
terminal menyuruh mengisi `ADB` atau `ANDROID_SDK_ROOT` — jalankan langkahnya
satu per satu:

```bash
flutter build apk --debug
flutter emulators --launch Medium_Phone_API_36.1   # bila emulator belum nyala
adb install -r build/app/outputs/flutter-apk/app-debug.apk
adb shell pm grant id.mantau.demo android.permission.POST_NOTIFICATIONS
adb shell am start -n id.mantau.demo/.MainActivity
```

`adb` sering tidak otomatis masuk PATH; lokasinya:
`%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe`.

### Catatan

- Saat **pertama kali** aplikasi dibuka, sistem menampilkan dialog izin
  notifikasi — tekan **Izinkan**. Perintah `pm grant` di atas (atau skrip)
  mengizinkan lebih dulu, sehingga dialog tidak muncul sama sekali.
- Ketukan dari layar kunci maupun laci memakai jalur yang sama, termasuk saat
  aplikasi dihidupkan dari dingin oleh ketukan itu sendiri.

---

## Urutan peragaan yang disarankan

1. **Masuk** — biarkan kolom terisi, tekan `Masuk`.
2. **Pilih paket** — biarkan di **1 kamera** untuk memperagakan batas kuota,
   lalu tekan **Lanjut ke pembayaran**.
3. **Pembayaran pertama** — formulir kartu terbuka **kosong**. Isi dengan data
   kartu demo di atas, lalu tekan **Bayar Rp150.000** → **Pembayaran berhasil**
   → **Selesai**. Langganan baru jadi setelah langkah ini; menekan Batal
   mengembalikan ke pemilihan paket tanpa mengubah apa pun.
4. **Beranda** — perhatikan spanduk hijau dan hitungan `1/1`. Tekan
   `Batas paket tercapai` → muncul ajakan **Tingkatkan paket**.
5. **Akun → Paket langganan** — naikkan stepper ke **3 kamera**, lalu tekan
   **Tingkatkan · Rp300.000**.
6. **Pembayaran** — kali ini kartu tadi **sudah terisi**, tidak perlu diketik
   ulang (ada tombol **Ganti kartu** bila ingin diganti). Rinciannya: 2 kamera
   tambahan × Rp150.000. Tekan **Bayar** → **Selesai**.
7. **Beranda** — hitungan kini `1/3` dan tombol tambah aktif kembali.
   Paket naik seketika karena sudah dibayar.
8. **Tambah kamera** — isi dengan data "Ruang Tengah" di atas, tekan
   **Uji koneksi**, lalu **Simpan kamera**. Kamera langsung muncul.
9. **Akun → Metode pembayaran** — kartu yang tadi diketik tersimpan di sini,
   dan kedua pembayaran sudah tercatat di **Riwayat tagihan** paling atas.
   Tekan **Ganti kartu** untuk memperagakan penggantian.
10. **Akun → Paket langganan** — turunkan stepper ke **2 kamera** dan tekan
    **Jadwalkan penurunan**. Muncul panel kuning: paket baru turun awal bulan
    depan, dan kuota hari ini **tetap 3**. Tekan **Batalkan** untuk mengurungkan.
11. **Notifikasi** — titik merah pada tab, kartu oranye peringatan jatuh.
12. Tekan **Lihat rekaman** — langsung melompat ke halaman rekaman lengkap
    dengan video, rentang waktu, penjelasan, dan kontak darurat. Tekan tombol
    putar; klipnya benar-benar berjalan dan penunjuk waktu bergerak
    `0:00 → 0:06`.
13. **Rekaman** — terbuka tanpa filter berisi 3 kejadian; coba saring per
    tanggal, lalu hapus filter.
14. **Akun → Kontak darurat** — tambahkan "Sri Rahayu", lalu **geser** untuk
    mengubah urutan; lencana `Utama` ikut berpindah.
15. **Akun → Keluar** — kembali ke layar masuk. Kartu ikut terhapus, jadi
    seluruh alur termasuk pengisian kartu siap didemokan lagi dari awal.

---

## Catatan penting soal pemutaran video

Klip `assets/video/fall_demo.mp4` berdurasi **6,08 detik, 320×180, H.264**.
Semua angka waktu di pemutar diambil dari `controller.value.duration`, bukan
ditulis tetap, jadi tampilan selalu jujur mengikuti klip yang sebenarnya.
Karena resolusinya rendah, video sengaja tidak pernah ditampilkan layar penuh.

**Sudah diverifikasi berjalan di emulator ini.** Klipnya termuat, bingkai
pertama tampil, tombol putar berfungsi, penunjuk waktu bergerak dari `0:00`
ke `0:06`, dan penggeser oranye ikut maju.

Ini justru kelebihan versi Android. Pada versi web, di mesin yang dipakai selama
pengembangan, Chrome sama sekali gagal memuat video apa pun — MP4 maupun WebM,
lewat HTTP maupun `blob:`, bahkan di pemutar bawaan Chrome. Berkas dan kode
aplikasinya sudah dipastikan sehat, jadi penyebabnya ada pada proses media
Chrome di lingkungan tersebut. Di Android tidak ada masalah itu: pemutarannya
ditangani `video_player_android` secara native.

Pemutar tetap diberi batas waktu 10 detik beserta pesan yang jelas, supaya
seandainya inisialisasi gagal di perangkat lain, demo tidak menggantung pada
kotak hitam tanpa penjelasan. Batas ini sengaja lebih longgar dari 4 detik
karena ketukan notifikasi dapat menghidupkan aplikasi dari dingin, dan
peluncuran dingin yang lambat di emulator bisa melewati 4 detik.

---

## Struktur proyek

```
lib/
  main.dart              titik masuk, provider, pemuatan locale id_ID
  app.dart               MaterialApp, tema, gerbang login → onboarding → shell
  theme/app_theme.dart   token warna dan ThemeData
  state/app_state.dart   SATU ChangeNotifier untuk seluruh state aplikasi
  models/models.dart     Camera, FallEvent, EmergencyContact, UserProfile, dll
  data/demo_data.dart    seluruh data dummy terkumpul di satu tempat
  utils/formatters.dart  format rupiah, tanggal, dan durasi berbahasa Indonesia
  services/              notifikasi sistem demo (flutter_local_notifications)
  widgets/               komponen bersama + PhoneFrame untuk tampilan web
  features/
    auth/                1.1 masuk
    onboarding/          1.2 pilih paket
    shell/               bilah bawah + Navigator bersarang per tab
    home/                1.3 beranda, 1.4 tambah kamera
    notifications/       2.1 notifikasi
    recordings/          3.1 riwayat, 3.2 detail + pemutar
    profile/             4.1–4.5 akun, kontak, paket, checkout, formulir kartu,
                         pembayaran, pengaturan
test/
  demo_flow_test.dart    35 uji: state, sinkronisasi kuota, siklus langganan,
                         pengisian kartu, alur pembayaran, lompatan notifikasi
```

Logo aplikasi ada di `assets/images/mantau_logo.png` dan dipakai lewat widget
`BrandLogo`. Berkas itu adalah **wordmark** — kata "Mantau" sudah termasuk di
dalam gambar, jadi jangan menaruh teks "Mantau" di sebelahnya. Ikon tab peramban
dibuat dari glif lensa pada logo tersebut.

### Keputusan rancangan

- **Satu `AppState`.** Kuota onboarding, Beranda, dan halaman paket membaca
  nilai yang sama, jadi "sinkron dengan homepage" berlaku otomatis. Notifikasi
  dan Rekaman juga memakai satu daftar kejadian yang sama.
- **Dua arah, dua metode.** Naik dan turun paket tidak lagi bisa diwakili satu
  setter: `applyUpgrade` dipanggil hanya setelah pembayaran berhasil, sementara
  `scheduleDowngrade` hanya menyimpan niat beserta tanggal berlakunya.
- **Riwayat tagihan hidup di state**, bukan dihitung ulang dari kuota. Kalau
  tidak, pembayaran yang baru saja dilakukan tidak akan meninggalkan jejak
  di mana pun. Riwayat palsu sengaja dimulai dari **bulan lalu**, supaya
  pembayaran hari ini tidak terbaca sebagai tagihan ganda di bulan yang sama.
- **Kartu tidak punya nilai bawaan.** Satu-satunya jalan mengisinya adalah lewat
  layar pembayaran, dan keluar akun menghapusnya lagi — itulah yang membuat
  pengisian kartu bisa diperagakan berulang kali.
- **Formulir kartu dipakai bersama** oleh layar pembayaran dan halaman
  Metode pembayaran (`card_form.dart`), jadi aturan validasi dan cara
  menurunkan merek kartu hanya ditulis sekali.
- **Tanpa penyimpanan permanen.** Keluar akun mengembalikan seluruh state ke
  awal supaya alur login → onboarding → beranda bisa diperagakan berulang kali.
  Menyimpan status "sudah onboarding" justru membuat demo hanya bisa sekali.
- **Navigator bersarang per tab**, sehingga halaman detail terbuka di dalam tab
  dan bilah bawah tetap terlihat — sesuai layar 4 dan 5 pada `MVP_reference.png`.
- **Penurunan paket dikunci** bila jumlah kamera terpasang melebihi kuota baru,
  agar Beranda tidak pernah menampilkan angka mustahil seperti `3/2`.
