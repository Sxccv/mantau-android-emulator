import 'package:flutter/material.dart';

import '../../data/demo_data.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/common.dart';
import '../profile/checkout_screen.dart';

/// 1.2 — Pemilihan jumlah kamera yang dilanggan.
///
/// Kuota yang dipilih di sini menjadi penyebut "x/y" di Beranda dan batas
/// penambahan kamera, jadi angka ini benar-benar mengikat.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _quota = 1;

  /// Langganan hanya jadi setelah pembayaran berhasil, jadi layar ini tidak
  /// pernah menyelesaikan onboarding sendiri — mundur dari pembayaran akan
  /// mengembalikan pengguna ke sini dalam keadaan belum berlangganan.
  Future<void> _subscribe() async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => CheckoutScreen(
          currentQuota: 0,
          targetQuota: _quota,
          isInitial: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final total = _quota * DemoData.pricePerCamera;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.page),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    const BrandLogo(height: 28),
                    const SizedBox(height: 24),
                    const Text(
                      'Pilih paket langganan',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Berapa kamera CCTV yang ingin Anda pantau? '
                      'Anda bisa mengubahnya kapan saja dari halaman Akun.',
                      style: const TextStyle(
                        fontSize: 13.5,
                        height: 1.5,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 24),

                    QuantityStepper(
                      value: _quota,
                      max: DemoData.maxCameras,
                      caption: '${Fmt.rupiah(DemoData.pricePerCamera)} '
                          'per kamera per bulan',
                      onChanged: (v) => setState(() => _quota = v),
                    ),

                    const SizedBox(height: AppSpacing.section),
                    const InfoBox(
                      child: Text(
                        'Setiap kamera dipantau otomatis 24 jam. Saat terdeteksi '
                        'jatuh, Anda menerima notifikasi dalam hitungan detik '
                        'lengkap dengan rekaman kejadian.',
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Ringkasan harga menempel di bawah agar selalu terlihat saat memilih.
            Container(
              padding: const EdgeInsets.all(AppSpacing.page),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '$_quota kamera × ${Fmt.rupiah(DemoData.pricePerCamera)}',
                          style: const TextStyle(
                            fontSize: 13.5,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                      Text(
                        '${Fmt.rupiah(total)}/bulan',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  PrimaryButton(
                    label: 'Lanjut ke pembayaran',
                    onPressed: _subscribe,
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
