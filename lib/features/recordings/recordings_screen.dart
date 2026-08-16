import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/common.dart';
import 'recording_detail_screen.dart';

/// 3.1 — Riwayat rekaman kejadian, dapat disaring per tanggal.
class RecordingsScreen extends StatefulWidget {
  const RecordingsScreen({super.key});

  @override
  State<RecordingsScreen> createState() => _RecordingsScreenState();
}

class _RecordingsScreenState extends State<RecordingsScreen> {
  /// Sengaja mulai tanpa filter: kejadian demo berumur 3 dan 7 hari, sehingga
  /// menyaring "hari ini" secara bawaan akan membuat halaman tampak kosong.
  DateTime? _filterDate;

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _filterDate ?? now,
      firstDate: now.subtract(const Duration(days: 30)),
      lastDate: now,
      helpText: 'Pilih tanggal kejadian',
      cancelText: 'Batal',
      confirmText: 'Pilih',
    );
    if (picked != null) setState(() => _filterDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    final all = context.watch<AppState>().events;
    final events = _filterDate == null
        ? all
        : all.where((e) => Fmt.sameDay(e.detectedAt, _filterDate!)).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rekaman'),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.page,
              4,
              AppSpacing.page,
              12,
            ),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _pickDate,
                    borderRadius: BorderRadius.circular(AppRadius.field),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 13,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppRadius.field),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_outlined,
                            size: 17,
                            color: AppColors.textMuted,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            _filterDate == null
                                ? 'Semua tanggal'
                                : Fmt.fullDate(_filterDate!),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: _filterDate == null
                                  ? FontWeight.w500
                                  : FontWeight.w700,
                              color: _filterDate == null
                                  ? AppColors.textMuted
                                  : AppColors.text,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (_filterDate != null) ...[
                  const SizedBox(width: 10),
                  IconButton(
                    tooltip: 'Hapus filter',
                    onPressed: () => setState(() => _filterDate = null),
                    icon: const Icon(Icons.close),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.surface,
                      side: const BorderSide(color: AppColors.border),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: events.isEmpty
                ? EmptyState(
                    icon: Icons.videocam_off_outlined,
                    title: 'Tidak ada rekaman',
                    message: _filterDate == null
                        ? 'Rekaman kejadian akan muncul di sini.'
                        : 'Tidak ada kejadian pada '
                            '${Fmt.fullDate(_filterDate!)}.',
                    action: _filterDate == null
                        ? null
                        : SecondaryButton(
                            label: 'Tampilkan semua',
                            onPressed: () =>
                                setState(() => _filterDate = null),
                          ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.page,
                      0,
                      AppSpacing.page,
                      AppSpacing.page,
                    ),
                    itemCount: events.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.gap),
                    itemBuilder: (_, i) => _RecordingTile(event: events[i]),
                  ),
          ),
        ],
      ),
    );
  }
}

class _RecordingTile extends StatelessWidget {
  const _RecordingTile({required this.event});

  final FallEvent event;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => RecordingDetailScreen(eventId: event.id),
        ),
      ),
      child: Row(
        children: [
          // Pratinjau gelap dengan tombol putar, meniru kartu pada referensi.
          Container(
            width: 108,
            height: 84,
            color: const Color(0xFF111827),
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Icon(
                  Icons.bed_outlined,
                  color: Color(0xFF374151),
                  size: 34,
                ),
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.play_arrow,
                    color: AppColors.orange,
                    size: 19,
                  ),
                ),
                if (event.isUnresolved)
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.red,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'BARU',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 8.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 13),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${event.cameraName} · ${Fmt.time(event.detectedAt)}',
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    event.kind,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.textMuted,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    Fmt.shortDate(event.detectedAt),
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppColors.textFaint,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(right: 10),
            child: Icon(
              Icons.chevron_right,
              size: 20,
              color: AppColors.textFaint,
            ),
          ),
        ],
      ),
    );
  }
}
