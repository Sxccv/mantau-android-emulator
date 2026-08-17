import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'services/notification_service.dart';
import 'state/app_state.dart';
import 'utils/formatters.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Diperlukan agar DateFormat('...', 'id_ID') tidak melempar galat.
  await initializeDateFormatting('id_ID', null);

  final appState = AppState();

  // Notifikasi sistem demo: ketukan membuka kejadian langsung, melewati
  // login dan onboarding (lihat AppState.bypassToEvent).
  final notifications = NotificationService(onTap: appState.bypassToEvent);

  // Cold start: aplikasi dihidupkan oleh ketukan notifikasi (proses mati).
  final launchEventId = await notifications.initialize();
  if (launchEventId != null) {
    appState.bypassToEvent(launchEventId);
  }

  runApp(
    ChangeNotifierProvider.value(
      value: appState,
      child: const MantauApp(),
    ),
  );

  // Beberapa detik setelah terbuka, kirim notifikasi "jatuh" yang hidup —
  // inilah yang tampil di layar kunci emulator saat demo. Jeda singkat
  // membuatnya terasa seperti peringatan sungguhan yang baru tiba.
  final event = appState.events.first; // ev-1, kejadian yang belum ditinjau
  Future.delayed(const Duration(seconds: 2), () {
    notifications.showFallAlert(
      eventId: event.id,
      title: 'Kemungkinan jatuh terdeteksi',
      body: '${event.cameraName} · ${Fmt.relative(event.detectedAt)} — '
          'ketuk untuk meninjau rekaman.',
    );
  });
}
