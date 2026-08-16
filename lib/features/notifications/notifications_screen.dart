import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/common.dart';
import '../shell/main_shell.dart';

/// 2.1 — Riwayat notifikasi 30 hari terakhir.
///
/// Kejadian yang belum ditinjau tampil sebagai kartu oranye besar; mengetuknya
/// langsung membuka halaman rekaman (3.2).
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final events = state.events;
    final active = events.where((e) => e.isUnresolved).toList();
    final past = events.where((e) => !e.isUnresolved).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifikasi'),
        automaticallyImplyLeading: false,
      ),
      body: events.isEmpty
          ? const EmptyState(
              icon: Icons.notifications_off_outlined,
              title: 'Belum ada notifikasi',
              message: 'Peringatan jatuh akan muncul di sini.',
            )
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.page),
              children: [
                if (active.isNotEmpty) ...[
                  const SectionLabel('Perlu perhatian'),
                  for (final e in active) ...[
                    _ActiveAlertCard(event: e),
                    const SizedBox(height: AppSpacing.gap),
                  ],
                  const SizedBox(height: 12),
                ],
                if (past.isNotEmpty) ...[
                  const SectionLabel('30 hari terakhir'),
                  for (final e in past) ...[
                    _PastNotificationTile(event: e),
                    const SizedBox(height: AppSpacing.gap),
                  ],
                ],
              ],
            ),
    );
  }
}

/// Kartu oranye besar sesuai layar 3 pada MVP_reference.png.
class _ActiveAlertCard extends StatelessWidget {
  const _ActiveAlertCard({required this.event});

  final FallEvent event;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => MainShell.of(context).openRecording(event.id),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 26),
        decoration: BoxDecoration(
          color: AppColors.orange,
          borderRadius: BorderRadius.circular(AppRadius.card),
          boxShadow: kCardShadow,
        ),
        child: Column(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.25),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.priority_high,
                color: Colors.white,
                size: 30,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Kemungkinan jatuh\nterdeteksi',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 21,
                height: 1.3,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '${event.cameraName} · ${Fmt.relative(event.detectedAt)} · '
              'terdeteksi otomatis dalam 3 detik',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.95),
                fontSize: 13,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: FilledButton(
                onPressed: () => MainShell.of(context).openRecording(event.id),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.orange,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.button),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                child: const Text('Lihat rekaman'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PastNotificationTile extends StatelessWidget {
  const _PastNotificationTile({required this.event});

  final FallEvent event;

  @override
  Widget build(BuildContext context) {
    final confirmed = event.status == FallStatus.confirmed;

    return AppCard(
      onTap: () => MainShell.of(context).openRecording(event.id),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: confirmed ? AppColors.orangeSoft : AppColors.background,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              confirmed ? Icons.warning_amber_rounded : Icons.check,
              size: 20,
              color: confirmed ? AppColors.orange : AppColors.textMuted,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.kind,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${event.cameraName} · ${Fmt.relative(event.detectedAt)}',
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Text(
            Fmt.time(event.detectedAt),
            style: const TextStyle(
              fontSize: 12.5,
              color: AppColors.textFaint,
            ),
          ),
        ],
      ),
    );
  }
}
