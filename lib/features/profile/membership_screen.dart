import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/demo_data.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/common.dart';
import 'checkout_screen.dart';

/// 4.4 — Kelola paket langganan.
///
/// Kuota di sini adalah kuota yang sama yang dibaca Beranda, jadi perubahan
/// paket langsung terlihat pada hitungan "x/y".
///
/// Dua arah, dua perilaku: naik paket butuh pembayaran dan berlaku seketika,
/// turun paket gratis tetapi baru berlaku awal bulan depan.
class MembershipScreen extends StatefulWidget {
  const MembershipScreen({super.key});

  @override
  State<MembershipScreen> createState() => _MembershipScreenState();
}

class _MembershipScreenState extends State<MembershipScreen> {
  int? _target;

  Future<void> _upgrade(int target) async {
    final state = context.read<AppState>();

    final paid = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => CheckoutScreen(
          currentQuota: state.cameraQuota,
          targetQuota: target,
        ),
      ),
    );

    if (!mounted) return;
    setState(() => _target = null);

    if (paid == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Paket aktif: $target kamera.')),
      );
    }
  }

  void _downgrade(int target) {
    final state = context.read<AppState>();
    state.scheduleDowngrade(target);
    setState(() => _target = null);

    final at = state.pendingEffectiveAt;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          at == null
              ? 'Penurunan paket dijadwalkan.'
              : 'Paket turun ke $target kamera pada ${Fmt.fullDate(at)}.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final current = state.cameraQuota;
    final target = _target ?? current;

    final isUpgrade = target > current;
    final isDowngrade = target < current;
    final blocked = isDowngrade && !state.canDowngradeTo(target);

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('Paket langganan'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.page),
        children: [
          _ActivePlanCard(state: state),
          const SizedBox(height: AppSpacing.gap),

          if (state.hasPendingChange) ...[
            _PendingBanner(
              quota: state.pendingQuota!,
              effectiveAt: state.pendingEffectiveAt!,
              onCancel: () {
                context.read<AppState>().cancelPendingDowngrade();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Penurunan paket dibatalkan.'),
                  ),
                );
              },
            ),
            const SizedBox(height: AppSpacing.gap),
          ],

          const SizedBox(height: 8),
          const SectionLabel('Ubah paket'),
          QuantityStepper(
            value: target,
            max: DemoData.maxCameras,
            caption:
                '${Fmt.rupiah(target * DemoData.pricePerCamera)} per bulan',
            onChanged: (v) => setState(() => _target = v),
          ),
          const SizedBox(height: AppSpacing.gap),

          if (blocked)
            InfoBox(
              icon: Icons.info_outline,
              child: Text(
                'Anda memiliki ${state.cameras.length} kamera terhubung. '
                'Hapus kamera terlebih dahulu bila ingin turun ke '
                '$target kamera.',
              ),
            )
          else if (isUpgrade)
            InfoBox(
              icon: Icons.bolt_outlined,
              tone: InfoTone.green,
              child: Text(
                'Menambah ${target - current} kamera. Dibayar '
                '${Fmt.rupiah(state.upgradeCostTo(target))} sekarang, '
                'dan langsung aktif setelah pembayaran.',
              ),
            )
          else if (isDowngrade)
            const InfoBox(
              icon: Icons.schedule,
              child: Text(
                'Penurunan paket tidak dikenai biaya dan mulai berlaku pada '
                'awal periode tagihan berikutnya. Kamera Anda tetap aktif '
                'sampai saat itu.',
              ),
            )
          else
            const InfoBox(
              icon: Icons.info_outline,
              child: Text(
                'Naik paket berlaku seketika setelah pembayaran. Turun paket '
                'gratis dan berlaku mulai awal bulan berikutnya.',
              ),
            ),

          const SizedBox(height: AppSpacing.section),
          PrimaryButton(
            label: switch (true) {
              _ when blocked => 'Tidak bisa turun ke $target kamera',
              _ when isUpgrade =>
                'Tingkatkan · ${Fmt.rupiah(state.upgradeCostTo(target))}',
              _ when isDowngrade => 'Jadwalkan penurunan',
              _ => 'Paket sudah sesuai',
            },
            onPressed: switch (true) {
              _ when blocked => null,
              _ when isUpgrade => () => _upgrade(target),
              _ when isDowngrade => () => _downgrade(target),
              _ => null,
            },
          ),
        ],
      ),
    );
  }
}

class _ActivePlanCard extends StatelessWidget {
  const _ActivePlanCard({required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.orange,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'PAKET AKTIF',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${state.cameraQuota} Kamera',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${Fmt.rupiah(state.monthlyCost)} per bulan',
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '${state.cameras.length} dari ${state.cameraQuota} terpakai',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Penurunan paket yang sudah dijadwalkan.
///
/// Tanpa panel ini, keadaan "terjadwal" sama sekali tidak terlihat — dan
/// karenanya tidak bisa diperagakan.
class _PendingBanner extends StatelessWidget {
  const _PendingBanner({
    required this.quota,
    required this.effectiveAt,
    required this.onCancel,
  });

  final int quota;
  final DateTime effectiveAt;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.yellowSoft,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.yellowBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.schedule, size: 18, color: Color(0xFF92600E)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Penurunan paket terjadwal',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF92600E),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Paket turun ke $quota kamera pada '
                      '${Fmt.fullDate(effectiveAt)}.',
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.45,
                        color: Color(0xFF92600E),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: onCancel,
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF92600E),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                minimumSize: const Size(0, 34),
              ),
              child: const Text(
                'Batalkan',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
