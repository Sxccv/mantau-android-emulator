import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

import '../../models/models.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/common.dart';

/// 3.2 — Peninjauan satu kejadian: video, penjelasan, dan kontak darurat.
class RecordingDetailScreen extends StatefulWidget {
  const RecordingDetailScreen({super.key, required this.eventId});

  final String eventId;

  @override
  State<RecordingDetailScreen> createState() => _RecordingDetailScreenState();
}

class _RecordingDetailScreenState extends State<RecordingDetailScreen> {
  VideoPlayerController? _controller;

  /// null = masih memuat, true = siap, false = gagal/ waktu habis.
  bool? _ready;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  Future<void> _initVideo() async {
    final controller =
        VideoPlayerController.asset('assets/video/fall_demo.mp4');
    _controller = controller;

    try {
      // Batas waktu penting: bila pipeline media bermasalah, initialize()
      // bisa menggantung selamanya dan pengguna hanya melihat kotak hitam
      // tanpa penjelasan. Lebih baik gagal dengan jujur.
      //
      // 10 detik: klip yang sehat siap jauh di bawah itu, sementara batas
      // yang lebih panjang berarti layar terpenting demo diam berputar
      // terlalu lama. Sengaja lebih longgar dari dulu (4 dtk) karena
      // ketukan notifikasi bisa menghidupkan aplikasi dari dingin — di
      // emulator, peluncuran dingin yang lambat gampang melewati 4 detik.
      await controller.initialize().timeout(const Duration(seconds: 10));
      controller.addListener(_onTick);
      if (!mounted) return;
      setState(() => _ready = true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _ready = false);
    }
  }

  void _onTick() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller?.removeListener(_onTick);
    _controller?.dispose();
    super.dispose();
  }

  void _togglePlay() {
    final c = _controller;
    if (c == null || _ready != true) return;

    if (c.value.isPlaying) {
      c.pause();
    } else {
      // Klip hanya ~6 detik; setelah selesai, putar ulang dari awal.
      if (c.value.position >= c.value.duration) c.seekTo(Duration.zero);
      c.play();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final event = state.eventById(widget.eventId);

    if (event == null) {
      return Scaffold(
        appBar: AppBar(leading: const BackButton()),
        body: const EmptyState(
          icon: Icons.error_outline,
          title: 'Rekaman tidak ditemukan',
          message: 'Kejadian ini sudah tidak tersedia.',
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: Text('${event.cameraName} · ${Fmt.time(event.detectedAt)}'),
        actions: [
          IconButton(
            tooltip: 'Unduh klip',
            icon: const Icon(Icons.download_outlined),
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Klip disimpan ke perangkat.')),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.page),
        children: [
          _VideoBox(
            controller: _controller,
            ready: _ready,
            onTogglePlay: _togglePlay,
            cameraName: event.cameraName,
          ),
          const SizedBox(height: AppSpacing.section),

          _Timeline(event: event),
          const SizedBox(height: AppSpacing.section),

          InfoBox(
            tone: InfoTone.yellow,
            child: Text.rich(
              TextSpan(
                children: [
                  const TextSpan(
                    text: 'Terdeteksi: ',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  TextSpan(text: event.summary),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.section),

          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Column(
              children: [
                DetailRow(label: 'Jenis kejadian', value: event.kind),
                const Divider(),
                DetailRow(
                  label: 'Terdeteksi pukul',
                  value: Fmt.time(event.detectedAt),
                ),
                const Divider(),
                DetailRow(
                  label: 'Tanggal',
                  value: Fmt.fullDate(event.detectedAt),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.section),

          const SectionLabel('Butuh bantuan?'),
          if (state.contacts.isEmpty)
            const InfoBox(
              child: Text(
                'Belum ada kontak darurat. Tambahkan dari Akun → Kontak darurat.',
              ),
            )
          else
            for (final c in state.contacts) ...[
              _ContactCallCard(
                contact: c,
                isPrimary: c == state.contacts.first,
                index: state.contacts.indexOf(c),
              ),
              const SizedBox(height: AppSpacing.gap),
            ],

          const SizedBox(height: 12),
          if (event.isUnresolved)
            Row(
              children: [
                Expanded(
                  child: SecondaryButton(
                    label: 'Aman, tutup',
                    onPressed: () {
                      context
                          .read<AppState>()
                          .resolveEvent(event.id, FallStatus.dismissed);
                      Navigator.of(context).pop();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: PrimaryButton(
                    label: 'Benar jatuh',
                    onPressed: () {
                      context
                          .read<AppState>()
                          .resolveEvent(event.id, FallStatus.confirmed);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Kejadian ditandai sebagai jatuh.'),
                        ),
                      );
                    },
                  ),
                ),
              ],
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.greenSoft,
                borderRadius: BorderRadius.circular(AppRadius.card),
              ),
              child: Text(
                event.status == FallStatus.confirmed
                    ? 'Sudah ditandai sebagai jatuh'
                    : 'Sudah ditinjau — ditandai aman',
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF15803D),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Kotak video 16:9 dengan lencana KEJADIAN dan penggeser waktu.
///
/// Seluruh angka waktu diambil dari `controller.value.duration` — klip demo
/// hanya berdurasi ~6 detik, jadi durasi tidak boleh ditulis tetap di kode.
class _VideoBox extends StatelessWidget {
  const _VideoBox({
    required this.controller,
    required this.ready,
    required this.onTogglePlay,
    required this.cameraName,
  });

  final VideoPlayerController? controller;
  final bool? ready;
  final VoidCallback onTogglePlay;
  final String cameraName;

  @override
  Widget build(BuildContext context) {
    final c = controller;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: ColoredBox(
          color: const Color(0xFF0B0F19),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (ready == true && c != null)
                // Klip aslinya hanya 320x180, jadi dipasang "contain" agar
                // tidak dipaksa membesar dan terlihat pecah.
                FittedBox(
                  fit: BoxFit.contain,
                  child: SizedBox(
                    width: c.value.size.width,
                    height: c.value.size.height,
                    child: VideoPlayer(c),
                  ),
                ),

              if (ready == null)
                const Center(
                  child: SizedBox(
                    width: 26,
                    height: 26,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      valueColor: AlwaysStoppedAnimation(Colors.white70),
                    ),
                  ),
                ),

              if (ready == false)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.videocam_off_outlined,
                          color: Colors.white54,
                          size: 32,
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Klip tidak dapat diputar di peramban ini',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white70, fontSize: 12.5),
                        ),
                      ],
                    ),
                  ),
                ),

              // Lencana KEJADIAN di kiri atas.
              Positioned(
                left: 10,
                top: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.red,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: const Text(
                    'KEJADIAN',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
              ),

              // Penunjuk waktu di kanan atas.
              if (ready == true && c != null)
                Positioned(
                  right: 10,
                  top: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      '${Fmt.duration(c.value.position)} / '
                      '${Fmt.duration(c.value.duration)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

              Positioned(
                left: 10,
                bottom: 10,
                child: Text(
                  cameraName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

              if (ready == true && c != null) ...[
                // Tombol putar besar hanya saat klip belum berjalan.
                if (!c.value.isPlaying)
                  Center(
                    child: GestureDetector(
                      onTap: onTogglePlay,
                      child: Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.92),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.play_arrow,
                          color: AppColors.orange,
                          size: 32,
                        ),
                      ),
                    ),
                  )
                else
                  GestureDetector(onTap: onTogglePlay),

                Positioned(
                  left: 8,
                  right: 8,
                  bottom: 30,
                  child: VideoProgressIndicator(
                    c,
                    allowScrubbing: true,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    colors: const VideoProgressColors(
                      playedColor: AppColors.orange,
                      bufferedColor: Colors.white24,
                      backgroundColor: Colors.white10,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// "Rentang waktu" — penanda menit di sekitar kejadian.
///
/// Ini penanda waktu bergaya, bukan cuplikan bingkai asli: klip 6 detik
/// beresolusi 320x180 tidak cukup untuk mengekstrak pratinjau yang berarti.
class _Timeline extends StatelessWidget {
  const _Timeline({required this.event});

  final FallEvent event;

  @override
  Widget build(BuildContext context) {
    final base = event.detectedAt;
    final marks = [
      base.subtract(const Duration(minutes: 4)),
      base.subtract(const Duration(minutes: 2)),
      base,
      base.add(const Duration(minutes: 2)),
      base.add(const Duration(minutes: 4)),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionLabel('Rentang waktu'),
        SizedBox(
          height: 62,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: marks.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, i) {
              final isEvent = i == 2;
              return Container(
                width: 70,
                decoration: BoxDecoration(
                  color: isEvent ? AppColors.orangeSoft : AppColors.blueSoft,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isEvent ? AppColors.orange : Colors.transparent,
                    width: 1.6,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isEvent ? Icons.warning_amber_rounded : Icons.bed_outlined,
                      size: 19,
                      color: isEvent ? AppColors.orange : AppColors.blueText,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      Fmt.time(marks[i]),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isEvent ? AppColors.orange : AppColors.blueText,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ContactCallCard extends StatelessWidget {
  const _ContactCallCard({
    required this.contact,
    required this.isPrimary,
    required this.index,
  });

  final EmergencyContact contact;
  final bool isPrimary;
  final int index;

  @override
  Widget build(BuildContext context) {
    final tint = AppColors.avatarTints[index % AppColors.avatarTints.length];

    return AppCard(
      border: isPrimary ? Border.all(color: AppColors.orange, width: 1.4) : null,
      child: Row(
        children: [
          CircleAvatar(
            radius: 21,
            backgroundColor: tint.withValues(alpha: 0.15),
            child: Text(
              contact.initials,
              style: TextStyle(
                color: tint,
                fontWeight: FontWeight.w800,
                fontSize: 13.5,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        contact.name,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isPrimary) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.orangeSoft,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Utama',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.orange,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  '${contact.phone} · ${contact.relation}',
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textMuted,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Menghubungi ${contact.name}...')),
            ),
            child: Container(
              width: 42,
              height: 42,
              decoration: const BoxDecoration(
                color: AppColors.green,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.call, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
