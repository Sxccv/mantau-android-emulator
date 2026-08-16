import 'package:flutter/material.dart';

/// Palet warna Mantau, diambil dari MVP_reference.png.
abstract class AppColors {
  static const orange = Color(0xFFF2762E);
  static const orangeDark = Color(0xFFD65F1A);
  static const orangeSoft = Color(0xFFFDEDE2);

  static const blueSoft = Color(0xFFE8F0FE);
  static const blueText = Color(0xFF1D4ED8);

  static const green = Color(0xFF16A34A);
  static const greenSoft = Color(0xFFDCFCE7);

  static const red = Color(0xFFDC2626);
  static const yellowSoft = Color(0xFFFEF6DC);
  static const yellowBorder = Color(0xFFF3D98B);

  static const background = Color(0xFFF7F8FA);
  static const surface = Colors.white;
  static const border = Color(0xFFE5E7EB);

  static const text = Color(0xFF1F2937);
  static const textMuted = Color(0xFF6B7280);
  static const textFaint = Color(0xFF9CA3AF);

  /// Warna ubin ikon kamera — dirotasi per kamera agar mudah dibedakan.
  static const cameraTiles = <Color>[
    Color(0xFF2563EB),
    Color(0xFF1D4ED8),
    Color(0xFF3B82F6),
  ];

  /// Warna avatar kontak darurat, dirotasi per indeks.
  static const avatarTints = <Color>[
    Color(0xFFDC2626),
    Color(0xFF7C3AED),
    Color(0xFF0891B2),
    Color(0xFFB45309),
  ];
}

abstract class AppRadius {
  static const card = 14.0;
  static const field = 12.0;
  static const button = 12.0;
}

/// Jarak antar elemen. Referensi memakai padding yang lapang.
abstract class AppSpacing {
  static const page = 20.0;
  static const gap = 12.0;
  static const section = 24.0;
}

ThemeData buildAppTheme() {
  final base = ThemeData(useMaterial3: true);

  return base.copyWith(
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.orange,
      primary: AppColors.orange,
      onPrimary: Colors.white,
      secondary: AppColors.blueSoft,
      onSecondary: AppColors.blueText,
      surface: AppColors.surface,
      onSurface: AppColors.text,
      error: AppColors.red,
    ),
    textTheme: base.textTheme.apply(
      bodyColor: AppColors.text,
      displayColor: AppColors.text,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.surface,
      foregroundColor: AppColors.text,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: AppColors.text,
        fontSize: 16,
        fontWeight: FontWeight.w700,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      hintStyle: const TextStyle(color: AppColors.textFaint),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.field),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.field),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.field),
        borderSide: const BorderSide(color: AppColors.orange, width: 1.6),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.border,
      thickness: 1,
      space: 1,
    ),
    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.text,
      contentTextStyle: TextStyle(color: Colors.white),
    ),
  );
}

/// Bayangan kartu yang dipakai di seluruh aplikasi.
const kCardShadow = <BoxShadow>[
  BoxShadow(
    color: Color(0x0F000000),
    blurRadius: 10,
    offset: Offset(0, 2),
  ),
];
