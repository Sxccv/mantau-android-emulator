import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Menangani notifikasi sistem demo: kanal, izin, kirim, dan ketukan.
///
/// Notifikasi diketuk -> [onTap] dipanggil dengan payload (id kejadian),
/// baik proses aplikasi masih hidup (warm) maupun baru dihidupkan oleh
/// ketukan itu sendiri (cold start — lewat [initialize]).
class NotificationService {
  NotificationService({required this.onTap});

  /// Dipanggil saat notifikasi diketuk, payload = id kejadian (mis. `ev-1`).
  final ValueChanged<String> onTap;

  static const _channelId = 'mantau_alerts';
  static const _channelName = 'Peringatan jatuh';
  static const _channelDescription =
      'Peringatan saat sistem mendeteksi kemungkinan jatuh.';
  static const _icon = 'ic_stat_mantau';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  /// Menyiapkan plugin, membuat kanal, meminta izin notifikasi, lalu
  /// mengembalikan payload bila aplikasi dibuka lewat ketukan notifikasi
  /// (cold start). Mengembalikan null pada peluncuran biasa.
  Future<String?> initialize() async {
    const settings = InitializationSettings(
      android: AndroidInitializationSettings(_icon),
      iOS: DarwinInitializationSettings(),
    );
    await _plugin.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload != null && payload.isNotEmpty) onTap(payload);
      },
    );

    final android = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await android?.createNotificationChannel(
      const AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDescription,
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      ),
    );

    // Android 13+ (API 33+): izin runtime wajib sebelum notifikasi tampil.
    // Bila sudah diizinkan lebih dulu lewat adb (lihat README), dialog izin
    // tidak muncul dan demo berjalan mulus tanpa ketukan tambahan.
    await android?.requestNotificationsPermission();

    final launch = await _plugin.getNotificationAppLaunchDetails();
    return launch?.notificationResponse?.payload;
  }

  /// Memunculkan notifikasi jatuh untuk [eventId] pada kanal demo.
  ///
  /// Id notifikasi dibuat tetap (1): memunculkan ulang akan menggantikan
  /// notifikasi lama, jadi demo bisa diulang tanpa menumpuk notifikasi.
  Future<void> showFallAlert({
    required String eventId,
    required String title,
    required String body,
  }) async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        icon: _icon,
        importance: Importance.max,
        priority: Priority.high,
        category: AndroidNotificationCategory.alarm,
      ),
    );
    await _plugin.show(
      id: 1,
      title: title,
      body: body,
      notificationDetails: details,
      payload: eventId,
    );
  }
}
