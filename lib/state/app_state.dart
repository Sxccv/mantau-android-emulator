import 'package:flutter/foundation.dart';

import '../data/demo_data.dart';
import '../models/models.dart';

/// Satu-satunya sumber kebenaran untuk seluruh aplikasi demo.
///
/// Semua state disimpan di memori saja — tidak ada penyimpanan permanen.
/// Ini disengaja: keluar akun harus mengulang alur login → onboarding → beranda
/// setiap kali dijalankan, supaya demo bisa diputar berkali-kali.
class AppState extends ChangeNotifier {
  UserProfile _user = DemoData.user();
  List<Camera> _cameras = DemoData.cameras();
  List<EmergencyContact> _contacts = DemoData.contacts();
  List<FallEvent> _events = DemoData.events();

  /// Kosong sampai pengguna benar-benar berlangganan dan membayar.
  List<BillingEntry> _billing = [];

  /// Kartu tersimpan. Null sampai pengguna mengetiknya sendiri.
  ///
  /// Sengaja tidak diisi di awal: mengisi kartu adalah bagian dari demo, jadi
  /// keluar akun harus mengosongkannya lagi.
  PaymentCard? _paymentCard;

  bool _loggedIn = false;
  bool _onboarded = false;

  /// Kuota yang berlaku sekarang.
  int _cameraQuota = 1;

  /// Penurunan paket yang dijadwalkan, null bila tidak ada.
  ///
  /// Naik paket berlaku seketika setelah dibayar; turun paket baru berlaku
  /// pada awal periode tagihan berikutnya — itulah sebabnya keduanya tidak
  /// bisa diwakili satu setter yang sama.
  int? _pendingQuota;
  DateTime? _pendingEffectiveAt;

  /// Pengaturan di 4.5 — khusus tampilan, tidak memengaruhi perilaku lain.
  bool notificationsEnabled = true;
  bool soundEnabled = true;
  bool autoRecordEnabled = true;

  /// Id kejadian yang harus langsung dibuka begitu MainShell terpasang.
  ///
  /// Diisi saat notifikasi sistem diketuk (deep link demo). MainShell
  /// mendengarkan notifier ini dan memanggil `openRecording` begitu nilai
  /// terisi — satu mekanisme untuk cold start maupun warm tap.
  final ValueNotifier<String?> deepLinkEventId = ValueNotifier<String?>(null);

  UserProfile get user => _user;
  List<Camera> get cameras => List.unmodifiable(_cameras);
  List<EmergencyContact> get contacts => List.unmodifiable(_contacts);
  List<BillingEntry> get billing => List.unmodifiable(_billing);
  PaymentCard? get paymentCard => _paymentCard;
  bool get hasPaymentCard => _paymentCard != null;
  bool get loggedIn => _loggedIn;
  bool get onboarded => _onboarded;
  int get cameraQuota => _cameraQuota;

  int? get pendingQuota => _pendingQuota;
  DateTime? get pendingEffectiveAt => _pendingEffectiveAt;
  bool get hasPendingChange => _pendingQuota != null;

  /// Kejadian terbaru lebih dulu — dipakai Notifikasi maupun Rekaman.
  List<FallEvent> get events {
    final sorted = [..._events]..sort((a, b) => b.detectedAt.compareTo(a.detectedAt));
    return List.unmodifiable(sorted);
  }

  int get unresolvedCount => _events.where((e) => e.isUnresolved).length;
  bool get hasUnresolved => unresolvedCount > 0;

  bool get atCameraLimit => _cameras.length >= _cameraQuota;
  bool get allCamerasActive => _cameras.isNotEmpty && _cameras.every((c) => c.isActive);

  int get monthlyCost => _cameraQuota * DemoData.pricePerCamera;

  // --- Autentikasi ---------------------------------------------------------

  /// Demo: kredensial apa pun diterima. Salah ketik di atas panggung tidak
  /// boleh menghentikan presentasi.
  void login({String? email}) {
    if (email != null && email.trim().isNotEmpty) {
      _user.email = email.trim();
    }
    _loggedIn = true;
    notifyListeners();
  }

  /// Mengembalikan seluruh state ke kondisi awal supaya demo bisa diulang.
  void logout() {
    _loggedIn = false;
    _onboarded = false;
    _cameraQuota = 1;
    // Tanpa ini, demo babak kedua dimulai di tengah perubahan langganan.
    _pendingQuota = null;
    _pendingEffectiveAt = null;
    _user = DemoData.user();
    _cameras = DemoData.cameras();
    _contacts = DemoData.contacts();
    _events = DemoData.events();
    _billing = [];
    // Inilah yang membuat demo bisa diulang: kartu harus kosong lagi setiap
    // kali masuk, supaya pengisiannya bisa diperagakan dari awal.
    _paymentCard = null;
    notificationsEnabled = true;
    soundEnabled = true;
    autoRecordEnabled = true;
    notifyListeners();
  }

  /// Berlangganan pertama kali. Hanya dipanggil setelah pembayaran berhasil.
  void subscribe(int quota, PaymentCard card) {
    _cameraQuota = quota.clamp(1, DemoData.maxCameras);
    _onboarded = true;
    _paymentCard = card;

    // Pembayaran hari ini di paling atas, disusul riwayat bulan-bulan lalu.
    _billing = [
      BillingEntry(
        date: DateTime.now(),
        amount: _cameraQuota * DemoData.pricePerCamera,
        description: 'Langganan $_cameraQuota kamera',
      ),
      ...DemoData.billing(_cameraQuota),
    ];

    notifyListeners();
  }

  void savePaymentCard(PaymentCard card) {
    _paymentCard = card;
    notifyListeners();
  }

  // --- Kamera --------------------------------------------------------------

  void addCamera(Camera camera) {
    _cameras = [..._cameras, camera];
    notifyListeners();
  }

  void removeCamera(String id) {
    _cameras = _cameras.where((c) => c.id != id).toList();
    notifyListeners();
  }

  void toggleCamera(String id, bool active) {
    for (final c in _cameras) {
      if (c.id == id) c.isActive = active;
    }
    notifyListeners();
  }

  // --- Langganan -----------------------------------------------------------

  /// Biaya menaikkan paket ke [quota]: selisih kamera × harga bulanan penuh.
  int upgradeCostTo(int quota) =>
      ((quota - _cameraQuota).clamp(0, DemoData.maxCameras)) *
      DemoData.pricePerCamera;

  /// Menaikkan paket. Hanya dipanggil setelah pembayaran berhasil.
  ///
  /// Dibaca Beranda sebagai penyebut pada "x/y", jadi 4.4 dan 1.3 tetap sinkron.
  void applyUpgrade(int quota) {
    final next = quota.clamp(1, DemoData.maxCameras);
    if (next <= _cameraQuota) return;

    final added = next - _cameraQuota;
    _cameraQuota = next;

    // Penting: naik paket membatalkan penurunan yang terjadwal. Tanpa ini,
    // pengguna membayar kamera tambahan hari ini lalu diam-diam turun bulan
    // depan — kejutan terburuk yang bisa muncul saat demo berlangsung.
    _pendingQuota = null;
    _pendingEffectiveAt = null;

    _billing = [
      BillingEntry(
        date: DateTime.now(),
        amount: added * DemoData.pricePerCamera,
        description: 'Tambahan $added kamera',
      ),
      ..._billing,
    ];

    notifyListeners();
  }

  /// Menjadwalkan penurunan paket mulai awal bulan depan. Tanpa pembayaran.
  void scheduleDowngrade(int quota) {
    final next = quota.clamp(1, DemoData.maxCameras);
    if (next >= _cameraQuota) return;
    if (!canDowngradeTo(next)) return;

    final now = DateTime.now();
    // Dart menggulung bulan ke-13 menjadi Januari tahun berikutnya.
    _pendingEffectiveAt = DateTime(now.year, now.month + 1, 1);
    _pendingQuota = next;
    notifyListeners();
  }

  void cancelPendingDowngrade() {
    _pendingQuota = null;
    _pendingEffectiveAt = null;
    notifyListeners();
  }

  /// Paket tidak boleh turun di bawah jumlah kamera yang benar-benar terpasang;
  /// kalau tidak, bulan depan aplikasi harus memaksa menghapus kamera.
  bool canDowngradeTo(int quota) => quota >= _cameras.length;

  // --- Kontak darurat ------------------------------------------------------

  void addContact(EmergencyContact contact) {
    _contacts = [..._contacts, contact];
    notifyListeners();
  }

  void updateContact(String id, {String? name, String? phone, String? relation}) {
    for (final c in _contacts) {
      if (c.id != id) continue;
      if (name != null) c.name = name;
      if (phone != null) c.phone = phone;
      if (relation != null) c.relation = relation;
    }
    notifyListeners();
  }

  void removeContact(String id) {
    _contacts = _contacts.where((c) => c.id != id).toList();
    notifyListeners();
  }

  /// Urutan daftar menentukan siapa dihubungi lebih dulu, jadi memindahkan
  /// kontak benar-benar mengubah arti — bukan sekadar tampilan.
  void reorderContacts(int oldIndex, int newIndex) {
    final list = [..._contacts];
    if (newIndex > oldIndex) newIndex -= 1;
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);
    _contacts = list;
    notifyListeners();
  }

  // --- Kejadian ------------------------------------------------------------

  FallEvent? eventById(String id) {
    for (final e in _events) {
      if (e.id == id) return e;
    }
    return null;
  }

  void resolveEvent(String id, FallStatus status) {
    for (final e in _events) {
      if (e.id == id) e.status = status;
    }
    notifyListeners();
  }

  // --- Profil --------------------------------------------------------------

  void updateUser({String? name, String? email, String? password}) {
    if (name != null && name.trim().isNotEmpty) _user.name = name.trim();
    if (email != null && email.trim().isNotEmpty) _user.email = email.trim();
    if (password != null && password.isNotEmpty) _user.password = password;
    notifyListeners();
  }

  void setSetting({bool? notifications, bool? sound, bool? autoRecord}) {
    if (notifications != null) notificationsEnabled = notifications;
    if (sound != null) soundEnabled = sound;
    if (autoRecord != null) autoRecordEnabled = autoRecord;
    notifyListeners();
  }

  // --- Deep link notifikasi (demo) ---------------------------------------

  /// Memasuki demo langsung dari notifikasi sistem: melewati login dan
  /// onboarding lalu membuka kejadian [eventId] begitu shell siap.
  ///
  /// Dipanggil saat notifikasi diketuk, baik proses aplikasi baru dihidupkan
  /// oleh ketukan itu (cold start) maupun sudah berjalan (warm tap). Ini
  /// sengaja mengabaikan gerbang login/onboarding supaya ketukan mendarat
  /// tepat di halaman rekaman — sesuai kebutuhan demo.
  void bypassToEvent(String eventId) {
    _loggedIn = true;
    _onboarded = true;
    deepLinkEventId.value = eventId;
    notifyListeners();
  }

  @override
  void dispose() {
    deepLinkEventId.dispose();
    super.dispose();
  }
}
