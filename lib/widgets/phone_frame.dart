import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Membingkai aplikasi dalam bentuk ponsel saat dijalankan di jendela lebar.
///
/// Demo ini dijalankan di Chrome, jadi tanpa pembatas apa pun tata letaknya
/// akan melar selebar peramban dan tidak menyerupai MVP_reference.png.
///
/// Catatan penting: pembatasan dilakukan murni lewat constraint ([SizedBox]),
/// **tanpa** menimpa `MediaQuery.size`. Widget berbasis Overlay — showDatePicker,
/// showModalBottomSheet, SnackBar — menghitung tata letaknya dari MediaQuery
/// akar, sehingga menimpanya justru merusak pemilih tanggal di halaman Rekaman
/// dan lembar batas kuota di Beranda.
class PhoneFrame extends StatelessWidget {
  const PhoneFrame({super.key, required this.child});

  final Widget child;

  /// Di bawah lebar ini, layar dianggap sudah seukuran ponsel.
  static const _breakpoint = 500.0;
  static const _frameWidth = 430.0;
  static const _frameHeight = 932.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < _breakpoint) return child;

        final height = constraints.maxHeight < _frameHeight
            ? constraints.maxHeight
            : _frameHeight;

        return ColoredBox(
          color: const Color(0xFFE4E6EB),
          child: Center(
            child: Container(
              width: _frameWidth,
              height: height,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x33000000),
                    blurRadius: 28,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: ColoredBox(color: AppColors.background, child: child),
            ),
          ),
        );
      },
    );
  }
}
