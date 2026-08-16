import 'package:intl/intl.dart';

/// Pemformat teks berbahasa Indonesia yang dipakai di banyak layar.
abstract class Fmt {
  static final _rupiah = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp',
    decimalDigits: 0,
  );

  static final _timeOfDay = DateFormat('HH:mm', 'id_ID');
  static final _fullDate = DateFormat('d MMMM yyyy', 'id_ID');
  static final _shortDate = DateFormat('d MMM yyyy', 'id_ID');
  static final _monthYear = DateFormat('MMMM yyyy', 'id_ID');

  static String rupiah(int amount) => _rupiah.format(amount);

  static String time(DateTime dt) => _timeOfDay.format(dt);

  static String fullDate(DateTime dt) => _fullDate.format(dt);

  static String shortDate(DateTime dt) => _shortDate.format(dt);

  static String monthYear(DateTime dt) => _monthYear.format(dt);

  /// Label relatif seperti "baru saja" atau "3 hari lalu".
  static String relative(DateTime dt) {
    final diff = DateTime.now().difference(dt);

    if (diff.isNegative) return 'baru saja';
    if (diff.inMinutes < 1) return 'baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    if (diff.inDays == 1) return 'kemarin';
    if (diff.inDays < 30) return '${diff.inDays} hari lalu';
    return shortDate(dt);
  }

  /// Durasi video sebagai m:ss — klip demo hanya ~6 detik, jadi jam tidak perlu.
  static String duration(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  /// True bila dua tanggal jatuh pada hari kalender yang sama.
  static bool sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
