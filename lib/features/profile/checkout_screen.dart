import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/demo_data.dart';
import '../../models/models.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/common.dart';
import 'card_form.dart';

/// Layar pembayaran, dipakai untuk dua hal:
///
/// * langganan pertama ([isInitial] true) — ditagih satu bulan penuh, dan di
///   sinilah pengguna mengisi kartu untuk pertama kali;
/// * menaikkan paket — ditagih selisih kamera, memakai kartu yang tersimpan.
///
/// Demo: tidak ada transaksi sungguhan. Paket hanya berubah bila pembayaran
/// "berhasil", jadi membatalkan atau menekan kembali tidak mengubah apa pun.
class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({
    super.key,
    required this.currentQuota,
    required this.targetQuota,
    this.isInitial = false,
  });

  final int currentQuota;
  final int targetQuota;
  final bool isInitial;

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

enum _Stage { review, processing, done }

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _cardFormKey = GlobalKey<CardFormState>();

  _Stage _stage = _Stage.review;

  /// True saat formulir kartu ditampilkan — otomatis bila belum ada kartu
  /// tersimpan, atau saat pengguna menekan "Ganti kartu".
  bool _editingCard = false;
  bool _initialised = false;

  int get _added => widget.targetQuota - widget.currentQuota;

  int get _total => widget.isInitial
      ? widget.targetQuota * DemoData.pricePerCamera
      : _added * DemoData.pricePerCamera;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialised) return;
    _initialised = true;
    // Belum punya kartu berarti formulir langsung terbuka — inilah alur
    // langganan pertama.
    _editingCard = !context.read<AppState>().hasPaymentCard;
  }

  Future<void> _pay() async {
    final state = context.read<AppState>();

    PaymentCard? entered;
    if (_editingCard) {
      entered = _cardFormKey.currentState?.submit();
      // Formulir belum lengkap — pesan galat sudah muncul di tiap kolom.
      if (entered == null) return;
    }

    final card = entered ?? state.paymentCard;
    if (card == null) return;

    setState(() => _stage = _Stage.processing);
    await Future<void>.delayed(const Duration(milliseconds: 1800));
    if (!mounted) return;

    // Paket berubah tepat di sini — setelah pembayaran, bukan sebelumnya.
    if (widget.isInitial) {
      state.subscribe(widget.targetQuota, card);
    } else {
      if (entered != null) state.savePaymentCard(entered);
      state.applyUpgrade(widget.targetQuota);
    }

    setState(() => _stage = _Stage.done);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Setelah dibayar, menekan kembali tidak boleh membatalkan apa pun.
      canPop: _stage == _Stage.review,
      child: Scaffold(
        appBar: AppBar(
          leading: _stage == _Stage.review ? const BackButton() : null,
          automaticallyImplyLeading: false,
          title: const Text('Pembayaran'),
        ),
        body: _stage == _Stage.done ? _buildSuccess() : _buildReview(),
      ),
    );
  }

  Widget _buildReview() {
    final state = context.watch<AppState>();
    final busy = _stage == _Stage.processing;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.page),
      children: [
        const SectionLabel('Rincian'),
        AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Column(
            children: [
              if (widget.isInitial) ...[
                DetailRow(
                  label: 'Paket',
                  value: '${widget.targetQuota} kamera',
                ),
                const Divider(),
                DetailRow(
                  label: 'Harga per kamera',
                  value: '${Fmt.rupiah(DemoData.pricePerCamera)} / bulan',
                ),
                const Divider(),
                DetailRow(
                  label: 'Tagihan pertama',
                  value: '${widget.targetQuota} × '
                      '${Fmt.rupiah(DemoData.pricePerCamera)}',
                ),
              ] else ...[
                DetailRow(
                  label: 'Paket saat ini',
                  value: '${widget.currentQuota} kamera',
                ),
                const Divider(),
                DetailRow(
                  label: 'Paket baru',
                  value: '${widget.targetQuota} kamera',
                ),
                const Divider(),
                DetailRow(
                  label: 'Kamera tambahan',
                  value: '$_added × ${Fmt.rupiah(DemoData.pricePerCamera)}',
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.gap),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.orangeSoft,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: AppColors.orange, width: 1.4),
          ),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Total dibayar',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
              Text(
                Fmt.rupiah(_total),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.orange,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            widget.isInitial
                ? 'Ditagih setiap bulan. Bisa diubah kapan saja dari Akun.'
                : 'Tagihan bulanan berikutnya menyesuaikan paket baru.',
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
        ),
        const SizedBox(height: AppSpacing.section),

        SectionLabel(
          _editingCard ? 'Data kartu' : 'Metode pembayaran',
          trailing: (!_editingCard && state.hasPaymentCard)
              ? GestureDetector(
                  onTap: busy
                      ? null
                      : () => setState(() => _editingCard = true),
                  child: const Text(
                    'Ganti kartu',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.orange,
                    ),
                  ),
                )
              : null,
        ),

        if (_editingCard)
          AppCard(
            padding: const EdgeInsets.all(16),
            child: CardForm(key: _cardFormKey),
          )
        else
          SavedCardTile(card: state.paymentCard!),

        const SizedBox(height: AppSpacing.section),
        InfoBox(
          icon: Icons.lock_outline,
          child: Text(
            widget.isInitial
                ? 'Kartu disimpan untuk tagihan berikutnya. Ini aplikasi demo — '
                    'tidak ada pembayaran yang benar-benar diproses.'
                : 'Kamera tambahan aktif segera setelah pembayaran berhasil.',
          ),
        ),
        const SizedBox(height: AppSpacing.section),

        PrimaryButton(
          label: 'Bayar ${Fmt.rupiah(_total)}',
          busy: busy,
          onPressed: busy ? null : _pay,
        ),
        const SizedBox(height: 10),
        if (!busy)
          SecondaryButton(
            label: 'Batal',
            onPressed: () => Navigator.of(context).pop(false),
          ),
      ],
    );
  }

  Widget _buildSuccess() {
    final card = context.read<AppState>().paymentCard;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.page),
      child: Column(
        children: [
          const Spacer(),
          Container(
            width: 84,
            height: 84,
            decoration: const BoxDecoration(
              color: AppColors.greenSoft,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              color: AppColors.green,
              size: 46,
            ),
          ),
          const SizedBox(height: 22),
          const Text(
            'Pembayaran berhasil',
            style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          Text(
            widget.isInitial
                ? 'Langganan Anda aktif dengan ${widget.targetQuota} kamera.'
                : 'Paket Anda kini ${widget.targetQuota} kamera dan sudah '
                    'aktif sekarang juga.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13.5,
              height: 1.5,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 20),
          if (card != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${Fmt.rupiah(_total)} · ${card.brand} •••• ${card.last4}',
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                ),
              ),
            ),
          const Spacer(),
          PrimaryButton(
            label: 'Selesai',
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );
  }
}

/// Ringkasan satu baris kartu tersimpan. Dipakai di checkout dan di 4.5.
class SavedCardTile extends StatelessWidget {
  const SavedCardTile({super.key, required this.card, this.trailing});

  final PaymentCard card;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.text,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.credit_card,
              color: Colors.white,
              size: 21,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${card.brand} •••• ${card.last4}',
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Berlaku ${card.expiry} · ${card.holder}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          trailing ??
              const Icon(Icons.check_circle, color: AppColors.green, size: 20),
        ],
      ),
    );
  }
}
