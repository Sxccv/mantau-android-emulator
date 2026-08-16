import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../profile/membership_screen.dart';
import '../shell/main_shell.dart';
import 'add_camera_screen.dart';

/// 1.3 — Beranda: daftar kamera terhubung dan status pemantauan.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  /// Saat kuota penuh, tombol tambah tidak dimatikan begitu saja — ia membuka
  /// ajakan meningkatkan paket, sehingga batasan itu sendiri bisa didemokan.
  void _onAddCamera(BuildContext context) {
    final state = context.read<AppState>();

    if (!state.atCameraLimit) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const AddCameraScreen()),
      );
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _UpgradePrompt(quota: state.cameraQuota),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final cameras = state.cameras;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Kepala halaman: logo + avatar, sesuai referensi.
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.page,
                12,
                AppSpacing.page,
                12,
              ),
              child: Row(
                children: [
                  const BrandLogo(height: 28),
                  const Spacer(),
                  GestureDetector(
                    onTap: () =>
                        MainShell.of(context).goToTab(MainShellState.tabAkun),
                    child: CircleAvatar(
                      radius: 17,
                      backgroundColor: AppColors.blueSoft,
                      child: Text(
                        state.user.initial,
                        style: const TextStyle(
                          color: AppColors.blueText,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.page,
                  0,
                  AppSpacing.page,
                  AppSpacing.page,
                ),
                children: [
                  _StatusBanner(
                    allActive: state.allCamerasActive,
                    hasCameras: cameras.isNotEmpty,
                  ),
                  const SizedBox(height: AppSpacing.section),

                  SectionLabel(
                    'Kamera terhubung',
                    trailing: Text(
                      '${cameras.length}/${state.cameraQuota}',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.orange,
                      ),
                    ),
                  ),

                  for (var i = 0; i < cameras.length; i++) ...[
                    _CameraCard(camera: cameras[i], index: i),
                    const SizedBox(height: AppSpacing.gap),
                  ],

                  if (cameras.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Text(
                        'Belum ada kamera terhubung.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                    ),

                  const SizedBox(height: 4),
                  _AddCameraButton(
                    atLimit: state.atCameraLimit,
                    onTap: () => _onAddCamera(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.allActive, required this.hasCameras});

  final bool allActive;
  final bool hasCameras;

  @override
  Widget build(BuildContext context) {
    final ok = allActive && hasCameras;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      decoration: BoxDecoration(
        color: ok ? AppColors.green : AppColors.textMuted,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Row(
        children: [
          Icon(
            ok ? Icons.check_circle : Icons.pause_circle_filled,
            color: Colors.white,
            size: 19,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              ok
                  ? 'Semua kamera aktif memantau'
                  : hasCameras
                      ? 'Sebagian kamera dijeda'
                      : 'Belum ada kamera dipantau',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CameraCard extends StatelessWidget {
  const _CameraCard({required this.camera, required this.index});

  final Camera camera;
  final int index;

  @override
  Widget build(BuildContext context) {
    final tint = AppColors.cameraTiles[index % AppColors.cameraTiles.length];

    return AppCard(
      onTap: () => _showDetail(context),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: tint,
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(Icons.videocam, color: Colors.white, size: 25),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  camera.name,
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: camera.isActive
                            ? AppColors.green
                            : AppColors.textFaint,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      camera.isActive ? 'Live · memantau' : 'Dijeda',
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Switch(
            value: camera.isActive,
            activeThumbColor: Colors.white,
            activeTrackColor: AppColors.orange,
            onChanged: (v) =>
                context.read<AppState>().toggleCamera(camera.id, v),
          ),
        ],
      ),
    );
  }

  void _showDetail(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _CameraDetailSheet(camera: camera),
    );
  }
}

class _CameraDetailSheet extends StatelessWidget {
  const _CameraDetailSheet({required this.camera});

  final Camera camera;

  @override
  Widget build(BuildContext context) {
    return _SheetShell(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            camera.name,
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 14),
          DetailRow(label: 'Alamat', value: camera.address),
          const Divider(),
          DetailRow(label: 'RTSP URL', value: camera.rtspUrl),
          const Divider(),
          DetailRow(label: 'Username', value: camera.username),
          const Divider(),
          DetailRow(
            label: 'Status',
            value: camera.isActive ? 'Aktif memantau' : 'Dijeda',
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: SecondaryButton(
                  label: 'Tutup',
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: PrimaryButton(
                  label: 'Hapus kamera',
                  onPressed: () {
                    context.read<AppState>().removeCamera(camera.id);
                    Navigator.of(context).pop();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _UpgradePrompt extends StatelessWidget {
  const _UpgradePrompt({required this.quota});

  final int quota;

  @override
  Widget build(BuildContext context) {
    return _SheetShell(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.orangeSoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.lock_outline, color: AppColors.orange),
          ),
          const SizedBox(height: 14),
          const Text(
            'Batas kamera tercapai',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            'Paket Anda saat ini mencakup $quota kamera dan semuanya sudah '
            'terpakai. Tingkatkan paket untuk menghubungkan kamera baru.',
            style: const TextStyle(
              fontSize: 13.5,
              height: 1.5,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 20),
          PrimaryButton(
            label: 'Tingkatkan paket',
            icon: Icons.arrow_upward,
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const MembershipScreen()),
              );
            },
          ),
          const SizedBox(height: 10),
          SecondaryButton(
            label: 'Nanti saja',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}

/// Pembungkus seragam untuk semua bottom sheet di aplikasi.
class _SheetShell extends StatelessWidget {
  const _SheetShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 18),
            child,
          ],
        ),
      ),
    );
  }
}

class _AddCameraButton extends StatelessWidget {
  const _AddCameraButton({required this.atLimit, required this.onTap});

  final bool atLimit;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: DottedBorderBox(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              atLimit ? Icons.lock_outline : Icons.add,
              size: 19,
              color: AppColors.orange,
            ),
            const SizedBox(width: 8),
            Text(
              atLimit ? 'Batas paket tercapai' : 'Hubungkan kamera baru',
              style: const TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
                color: AppColors.orange,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Kotak bergaris putus-putus oranye seperti tombol tambah pada referensi.
class DottedBorderBox extends StatelessWidget {
  const DottedBorderBox({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedBorderPainter(),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: AppColors.orangeSoft.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        child: child,
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.orange.withValues(alpha: 0.55)
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;

    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(AppRadius.card),
    );

    // Menggambar garis putus-putus dengan menyusuri kontur kotak membulat.
    final path = Path()..addRRect(rrect);
    const dash = 6.0;
    const gap = 4.0;

    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = (distance + dash).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance = next + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
