/// Semua model data demo Mantau.
///
/// Aplikasi ini adalah demo: tidak ada backend, tidak ada serialisasi JSON.
/// Model dibuat sesederhana mungkin — cukup untuk menampung state di memori.
library;

/// Kamera CCTV yang terdaftar pada langganan pengguna.
class Camera {
  Camera({
    required this.id,
    required this.name,
    required this.address,
    required this.rtspUrl,
    required this.username,
    required this.password,
    this.isActive = true,
  });

  final String id;
  String name;
  String address;
  String rtspUrl;
  String username;
  String password;

  /// Saat false, kamera berhenti "memantau" dan spanduk status di Beranda berubah.
  bool isActive;
}

/// Tingkat keyakinan sebuah kejadian, dipakai untuk pelabelan di UI.
enum FallStatus {
  /// Belum ditinjau pengguna — inilah yang memunculkan titik merah.
  needsReview,

  /// Pengguna menandai "Aman, tutup".
  dismissed,

  /// Pengguna mengonfirmasi ini benar jatuh.
  confirmed,
}

/// Satu kejadian jatuh terdeteksi, lengkap dengan rekamannya.
class FallEvent {
  FallEvent({
    required this.id,
    required this.cameraName,
    required this.detectedAt,
    required this.summary,
    required this.kind,
    this.status = FallStatus.needsReview,
  });

  final String id;
  final String cameraName;
  final DateTime detectedAt;

  /// Penjelasan panjang yang muncul di kotak kuning pada halaman rekaman.
  final String summary;

  /// Ringkasan jenis kejadian, mis. "Jatuh + diam >5 mnt".
  final String kind;

  FallStatus status;

  bool get isUnresolved => status == FallStatus.needsReview;
}

/// Kontak yang dihubungi berurutan saat notifikasi tidak direspons.
class EmergencyContact {
  EmergencyContact({
    required this.id,
    required this.name,
    required this.phone,
    required this.relation,
  });

  final String id;
  String name;
  String phone;
  String relation;

  /// Inisial untuk avatar bulat, maksimal dua huruf.
  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts[1][0]).toUpperCase();
  }
}

/// Profil pengguna yang sedang masuk.
class UserProfile {
  UserProfile({
    required this.name,
    required this.email,
    required this.password,
  });

  String name;
  String email;
  String password;

  String get initial => name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();
}

/// Kartu pembayaran tersimpan (khusus tampilan — demo tidak memproses apa pun).
class PaymentCard {
  const PaymentCard({
    required this.brand,
    required this.last4,
    required this.expiry,
    required this.holder,
  });

  final String brand;
  final String last4;
  final String expiry;
  final String holder;
}

/// Satu baris riwayat tagihan.
class BillingEntry {
  const BillingEntry({
    required this.date,
    required this.amount,
    required this.description,
  });

  final DateTime date;
  final int amount;
  final String description;
}
