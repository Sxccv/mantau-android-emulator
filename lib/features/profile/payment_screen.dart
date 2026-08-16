import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/common.dart';
import 'card_form.dart';

/// 4.5a — Metode pembayaran dan riwayat tagihan.
///
/// Kartunya adalah kartu yang benar-benar diisi pengguna saat berlangganan,
/// bukan data bawaan.
class PaymentScreen extends StatelessWidget {
  const PaymentScreen({super.key});

  /// Mengganti kartu memakai formulir yang sama dengan layar pembayaran.
  static Future<void> editCard(BuildContext context) async {
    final card = await showModalBottomSheet<PaymentCard>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _CardFormSheet(),
    );
    if (card != null && context.mounted) {
      context.read<AppState>().savePaymentCard(card);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Kartu diperbarui: ${card.brand} •••• ${card.last4}'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final card = state.paymentCard;
    // Dibaca dari state, bukan dibuat ulang dari kuota — supaya pembayaran
    // peningkatan paket benar-benar muncul di riwayat.
    final billing = state.billing;

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('Metode pembayaran'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.page),
        children: [
          const SectionLabel('Kartu tersimpan'),
          if (card == null)
            AppCard(
              padding: const EdgeInsets.symmetric(vertical: 28),
              child: EmptyState(
                icon: Icons.credit_card_off_outlined,
                title: 'Belum ada kartu',
                message: 'Tambahkan kartu untuk membayar langganan.',
                action: SecondaryButton(
                  label: 'Tambah kartu',
                  icon: Icons.add,
                  onPressed: () => editCard(context),
                ),
              ),
            )
          else
            Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1F2937), Color(0xFF374151)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppRadius.card),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.credit_card, color: Colors.white70),
                    const Spacer(),
                    Text(
                      card.brand.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 26),
                Text(
                  '•••• •••• •••• ${card.last4}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    letterSpacing: 2.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'PEMEGANG KARTU',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 9,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            card.holder,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'BERLAKU',
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 9,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          card.expiry,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (card != null) ...[
            const SizedBox(height: AppSpacing.gap),
            SecondaryButton(
              label: 'Ganti kartu',
              icon: Icons.edit_outlined,
              onPressed: () => editCard(context),
            ),
          ],
          const SizedBox(height: AppSpacing.section),

          const SectionLabel('Riwayat tagihan'),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (var i = 0; i < billing.length; i++) ...[
                  if (i > 0) const Divider(indent: 14, endIndent: 14),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 13,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.greenSoft,
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: const Icon(
                            Icons.check,
                            size: 18,
                            color: Color(0xFF15803D),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                Fmt.monthYear(billing[i].date),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                billing[i].description,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          Fmt.rupiah(billing[i].amount),
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Lembar pengisian kartu, memakai [CardForm] yang sama dengan layar
/// pembayaran sehingga aturan validasinya tidak bercabang.
class _CardFormSheet extends StatefulWidget {
  const _CardFormSheet();

  @override
  State<_CardFormSheet> createState() => _CardFormSheetState();
}

class _CardFormSheetState extends State<_CardFormSheet> {
  final _formKey = GlobalKey<CardFormState>();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Data kartu',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 18),
              CardForm(key: _formKey),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: SecondaryButton(
                      label: 'Batal',
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: PrimaryButton(
                      label: 'Simpan kartu',
                      onPressed: () {
                        final card = _formKey.currentState?.submit();
                        if (card == null) return;
                        Navigator.of(context).pop(card);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
