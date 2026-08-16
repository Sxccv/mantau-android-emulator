import '../models/models.dart';

/// Seluruh data dummy demo terkumpul di satu tempat.
///
/// Tanggal dihitung relatif terhadap saat aplikasi dijalankan, bukan tanggal
/// tetap, supaya label "3 hari lalu" tetap benar kapan pun demo dilakukan.
abstract class DemoData {
  /// Harga langganan per kamera per bulan.
  static const pricePerCamera = 150000;

  /// Batas kamera yang bisa dibeli pada demo ini.
  static const maxCameras = 10;

  static UserProfile user() => UserProfile(
        name: 'Andi Pratama',
        email: 'andi.pratama@gmail.com',
        password: 'demo1234',
      );

  /// Satu kamera sudah terpasang sejak awal, sesuai spesifikasi demo.
  static List<Camera> cameras() => [
        Camera(
          id: 'cam-1',
          name: 'Kamar Ibu',
          address: 'Jl. Melati No. 12, Bandung',
          rtspUrl: 'rtsp://192.168.1.42:554/stream1',
          username: 'admin',
          password: 'admin123',
        ),
      ];

  /// Satu kontak terisi; kontak kedua ditambahkan langsung saat demo agar
  /// fitur pengurutan benar-benar terlihat.
  static List<EmergencyContact> contacts() => [
        EmergencyContact(
          id: 'kontak-1',
          name: 'Budi Santoso',
          phone: '+62 812-3456-7890',
          relation: 'Anak',
        ),
      ];

  /// Tiga kejadian: satu belum ditinjau (memicu titik merah di Notifikasi dan
  /// menjadi tujuan lompatan 2.1 → 3.2), dua sudah ditutup sebagai riwayat.
  static List<FallEvent> events() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return [
      FallEvent(
        id: 'ev-1',
        cameraName: 'Kamar Ibu',
        detectedAt: today.add(const Duration(hours: 14, minutes: 32)),
        kind: 'Jatuh + diam >5 mnt',
        summary:
            'Jatuh diikuti posisi diam selama 6 menit. Klip disimpan otomatis '
            'untuk ditinjau keluarga.',
        status: FallStatus.needsReview,
      ),
      FallEvent(
        id: 'ev-2',
        cameraName: 'Kamar Ibu',
        detectedAt:
            today.subtract(const Duration(days: 3)).add(const Duration(hours: 9, minutes: 15)),
        kind: 'Jatuh ringan',
        summary:
            'Terpeleset di dekat tempat tidur, bangkit sendiri dalam 40 detik. '
            'Ditandai aman oleh keluarga.',
        status: FallStatus.dismissed,
      ),
      FallEvent(
        id: 'ev-3',
        cameraName: 'Kamar Ibu',
        detectedAt:
            today.subtract(const Duration(days: 7)).add(const Duration(hours: 20, minutes: 48)),
        kind: 'Gerakan mencurigakan',
        summary:
            'Sistem mendeteksi perubahan posisi mendadak. Setelah ditinjau, '
            'ternyata sedang mengambil barang di lantai.',
        status: FallStatus.dismissed,
      ),
    ];
  }

  /// Kartu contoh untuk pengujian dan sebagai acuan nilai di README.
  ///
  /// Aplikasi TIDAK memakai ini sebagai kartu bawaan — pengguna mengisinya
  /// sendiri saat berlangganan, supaya proses itu bisa diperagakan.
  static const sampleCard = PaymentCard(
    brand: 'Visa',
    last4: '4242',
    expiry: '09/28',
    holder: 'ANDI PRATAMA',
  );

  /// Riwayat tagihan tiga bulan sebelum bulan berjalan.
  ///
  /// Sengaja mulai dari bulan lalu: pembayaran langganan pertama terjadi hari
  /// ini, jadi bila daftar ini juga memuat bulan berjalan, layar tagihan akan
  /// terbaca seolah pengguna ditagih dua kali pada bulan yang sama.
  static List<BillingEntry> billing(int cameraCount) {
    final now = DateTime.now();
    return List.generate(3, (i) {
      final date = DateTime(now.year, now.month - (i + 1), 1);
      return BillingEntry(
        date: date,
        amount: pricePerCamera * cameraCount,
        description: 'Langganan $cameraCount kamera',
      );
    });
  }
}
