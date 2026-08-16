import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';

/// Logo Mantau.
///
/// Berkasnya adalah wordmark — kata "Mantau" sudah termasuk di dalam gambar,
/// jadi jangan pernah menaruh Text('Mantau') di sebelahnya.
class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, this.height = 26});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/mantau_logo.png',
      height: height,
      fit: BoxFit.contain,
      // Rasio gambar tetap 1190:341, jadi tinggi saja sudah menentukan lebar.
      semanticLabel: 'Mantau',
    );
  }
}

/// Pemilih jumlah kamera: [−] N [+].
///
/// Menggantikan daftar kartu satu-per-pilihan begitu batas paket naik ke 10 —
/// sepuluh kartu bertumpuk tidak lagi terbaca.
class QuantityStepper extends StatelessWidget {
  const QuantityStepper({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 1,
    this.max = 10,
    this.caption,
  });

  final int value;
  final ValueChanged<int> onChanged;
  final int min;
  final int max;

  /// Baris keterangan di bawah angka, mis. rincian harga.
  final String? caption;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _StepButton(
                icon: Icons.remove,
                enabled: value > min,
                onTap: () => onChanged(value - 1),
              ),
              Column(
                children: [
                  Text(
                    '$value',
                    style: const TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                    ),
                  ),
                  const Text(
                    'kamera',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
              _StepButton(
                icon: Icons.add,
                enabled: value < max,
                onTap: () => onChanged(value + 1),
              ),
            ],
          ),
          if (caption != null) ...[
            const SizedBox(height: 14),
            const Divider(),
            const SizedBox(height: 12),
            Text(
              caption!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13.5,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: enabled,
      label: icon == Icons.add ? 'Tambah kamera' : 'Kurangi kamera',
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: enabled ? AppColors.orangeSoft : AppColors.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: enabled ? AppColors.orange : AppColors.border,
              width: 1.4,
            ),
          ),
          child: Icon(
            icon,
            size: 22,
            color: enabled ? AppColors.orange : AppColors.textFaint,
          ),
        ),
      ),
    );
  }
}

/// Judul bagian dengan HURUF BESAR dan spasi lebar.
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text.toUpperCase(),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.9,
                color: AppColors.textMuted,
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// Kartu putih standar dengan sudut membulat dan bayangan lembut.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.onTap,
    this.border,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Border? border;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: kCardShadow,
        border: border,
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// Varian warna untuk [InfoBox].
enum InfoTone { blue, yellow, green }

/// Kotak keterangan dengan ikon, seperti panduan RTSP dan penjelasan urutan
/// kontak pada referensi.
class InfoBox extends StatelessWidget {
  const InfoBox({
    super.key,
    required this.child,
    this.tone = InfoTone.blue,
    this.icon = Icons.info_outline,
  });

  final Widget child;
  final InfoTone tone;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    late final Color bg;
    late final Color fg;
    switch (tone) {
      case InfoTone.blue:
        bg = AppColors.blueSoft;
        fg = AppColors.blueText;
      case InfoTone.yellow:
        bg = AppColors.yellowSoft;
        fg = const Color(0xFF92600E);
      case InfoTone.green:
        bg = AppColors.greenSoft;
        fg = const Color(0xFF15803D);
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: fg),
          const SizedBox(width: 10),
          Expanded(
            child: DefaultTextStyle.merge(
              style: TextStyle(fontSize: 13, height: 1.45, color: fg),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

/// Tombol utama beraksen oranye.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.busy = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: FilledButton(
        onPressed: busy ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.orange,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.orange.withValues(alpha: 0.5),
          disabledForegroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
        child: busy
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 18),
                    const SizedBox(width: 8),
                  ],
                  Flexible(child: Text(label, textAlign: TextAlign.center)),
                ],
              ),
      ),
    );
  }
}

/// Tombol sekunder biru muda, dipakai berdampingan dengan [PrimaryButton].
class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.blueSoft,
          foregroundColor: AppColors.blueText,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18),
              const SizedBox(width: 8),
            ],
            Flexible(child: Text(label, textAlign: TextAlign.center)),
          ],
        ),
      ),
    );
  }
}

/// Kolom isian berlabel yang dipakai di seluruh formulir.
class LabeledField extends StatelessWidget {
  const LabeledField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.obscure = false,
    this.suffix,
    this.keyboardType,
    this.validator,
    this.enabled = true,
    this.inputFormatters,
    this.textCapitalization = TextCapitalization.none,
  });

  final String label;
  final TextEditingController controller;
  final String? hint;
  final bool obscure;
  final Widget? suffix;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final bool enabled;
  final List<TextInputFormatter>? inputFormatters;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.text,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboardType,
          validator: validator,
          enabled: enabled,
          inputFormatters: inputFormatters,
          textCapitalization: textCapitalization,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            suffixIcon: suffix,
          ),
        ),
      ],
    );
  }
}

/// Baris "label — nilai" seperti pada detail kejadian di referensi.
class DetailRow extends StatelessWidget {
  const DetailRow({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 14, color: AppColors.textMuted),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

/// Baris menu dengan ikon dan tanda panah, dipakai di halaman Akun.
class MenuRow extends StatelessWidget {
  const MenuRow({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.tint = AppColors.orange,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Color tint;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: tint.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 19, color: tint),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              trailing ??
                  const Icon(
                    Icons.chevron_right,
                    size: 20,
                    color: AppColors.textFaint,
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tampilan kosong yang ramah, mis. saat filter tanggal tidak menemukan apa pun.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 44, color: AppColors.textFaint),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                height: 1.45,
                color: AppColors.textMuted,
              ),
            ),
            if (action != null) ...[const SizedBox(height: 18), action!],
          ],
        ),
      ),
    );
  }
}
