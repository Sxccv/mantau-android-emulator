import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/models.dart';
import '../../widgets/common.dart';

/// Formulir kartu pembayaran.
///
/// Dipakai di dua tempat — di layar pembayaran saat belum ada kartu tersimpan,
/// dan di Akun → Metode pembayaran saat mengganti kartu — sehingga aturan
/// validasi dan cara menurunkan merek kartu hanya ditulis sekali.
///
/// Ambil hasilnya lewat [GlobalKey]:
/// ```dart
/// final key = GlobalKey<CardFormState>();
/// final card = key.currentState?.submit(); // null bila tidak valid
/// ```
class CardForm extends StatefulWidget {
  const CardForm({super.key, this.onChanged});

  /// Dipanggil setiap isian berubah, mis. untuk menyalakan tombol bayar.
  final VoidCallback? onChanged;

  @override
  State<CardForm> createState() => CardFormState();
}

class CardFormState extends State<CardForm> {
  final _formKey = GlobalKey<FormState>();
  final _number = TextEditingController();
  final _holder = TextEditingController();
  final _expiry = TextEditingController();
  final _cvv = TextEditingController();

  @override
  void dispose() {
    for (final c in [_number, _holder, _expiry, _cvv]) {
      c.dispose();
    }
    super.dispose();
  }

  /// Merek kartu diturunkan dari digit pertama — inilah yang membuat kartu
  /// tersimpan terasa berasal dari apa yang benar-benar diketik.
  static String brandOf(String number) {
    final digits = number.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return 'Kartu';
    return switch (digits[0]) {
      '4' => 'Visa',
      '5' => 'Mastercard',
      '3' => 'Amex',
      _ => 'Kartu',
    };
  }

  /// Memvalidasi isian dan mengembalikan kartunya, atau null bila belum benar.
  PaymentCard? submit() {
    if (!_formKey.currentState!.validate()) return null;

    final digits = _number.text.replaceAll(RegExp(r'\D'), '');
    return PaymentCard(
      brand: brandOf(digits),
      last4: digits.substring(digits.length - 4),
      expiry: _expiry.text.trim(),
      holder: _holder.text.trim().toUpperCase(),
    );
  }

  String? _validateNumber(String? v) {
    final digits = (v ?? '').replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return 'Nomor kartu wajib diisi';
    // Panjang dan angka saja — sengaja tanpa pemeriksaan Luhn, supaya nomor
    // apa pun yang masuk akal tetap diterima saat demo berlangsung.
    if (digits.length < 13 || digits.length > 19) return 'Nomor kartu tidak valid';
    return null;
  }

  String? _validateExpiry(String? v) {
    final text = (v ?? '').trim();
    if (text.isEmpty) return 'Wajib diisi';
    final match = RegExp(r'^(\d{2})/(\d{2})$').firstMatch(text);
    if (match == null) return 'Format MM/YY';
    final month = int.parse(match.group(1)!);
    if (month < 1 || month > 12) return 'Bulan tidak valid';
    return null;
  }

  String? _validateCvv(String? v) {
    final text = (v ?? '').trim();
    if (text.isEmpty) return 'Wajib diisi';
    if (text.length < 3 || text.length > 4) return '3–4 digit';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      onChanged: widget.onChanged,
      child: Column(
        children: [
          LabeledField(
            label: 'Nomor kartu',
            controller: _number,
            hint: '4242 4242 4242 4242',
            keyboardType: TextInputType.number,
            validator: _validateNumber,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(19),
              _CardNumberFormatter(),
            ],
          ),
          const SizedBox(height: 14),
          LabeledField(
            label: 'Nama pemegang kartu',
            controller: _holder,
            hint: 'ANDI PRATAMA',
            textCapitalization: TextCapitalization.characters,
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Nama wajib diisi' : null,
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: LabeledField(
                  label: 'Masa berlaku',
                  controller: _expiry,
                  hint: 'MM/YY',
                  keyboardType: TextInputType.number,
                  validator: _validateExpiry,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                    _ExpiryFormatter(),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: LabeledField(
                  label: 'CVV',
                  controller: _cvv,
                  hint: '123',
                  obscure: true,
                  keyboardType: TextInputType.number,
                  validator: _validateCvv,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Menyisipkan spasi setiap empat digit: 4242 4242 4242 4242.
class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(digits[i]);
    }
    final text = buffer.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

/// Menyisipkan garis miring setelah dua digit bulan: 09/28.
class _ExpiryFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final text = digits.length <= 2
        ? digits
        : '${digits.substring(0, 2)}/${digits.substring(2)}';
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
