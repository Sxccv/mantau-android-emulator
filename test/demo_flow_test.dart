// Uji alur demo Mantau.
//
// Fokusnya pada perkabelan antar layar yang mudah rusak diam-diam:
// sinkronisasi kuota Beranda ↔ paket, lompatan notifikasi → rekaman,
// dan urutan kontak darurat.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'package:mantau/app.dart';
import 'package:mantau/data/demo_data.dart';
import 'package:mantau/features/profile/card_form.dart';
import 'package:mantau/models/models.dart';
import 'package:mantau/state/app_state.dart';
import 'package:mantau/widgets/common.dart';

Future<void> pumpApp(WidgetTester tester, AppState state) async {
  // Ukuran seukuran ponsel: di bawah ambang 500px, PhoneFrame meneruskan saja
  // sehingga uji berjalan pada tata letak yang sama dengan perangkat asli.
  tester.view.physicalSize = const Size(430, 932);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ChangeNotifierProvider.value(value: state, child: const MantauApp()),
  );
  await tester.pumpAndSettle();
}

/// Menggulir sampai [finder] terlihat, lalu memastikannya ada.
Future<void> scrollTo(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    120,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID', null);
  });

  group('AppState', () {
    test('mulai dari belum masuk dan belum onboarding', () {
      final s = AppState();
      expect(s.loggedIn, isFalse);
      expect(s.onboarded, isFalse);
      expect(s.cameras, hasLength(1));
      expect(s.contacts, hasLength(1));
      expect(s.events, hasLength(3));
    });

    test('tepat satu kejadian belum ditinjau', () {
      final s = AppState();
      expect(s.unresolvedCount, 1);
      expect(s.hasUnresolved, isTrue);
    });

    test('kuota onboarding mengikat batas penambahan kamera', () {
      final s = AppState()
        ..login()
        ..subscribe(1, DemoData.sampleCard);

      // Satu kamera bawaan sudah memenuhi kuota 1.
      expect(s.cameraQuota, 1);
      expect(s.atCameraLimit, isTrue);

      s.applyUpgrade(3);
      expect(s.atCameraLimit, isFalse);
      expect(s.monthlyCost, 3 * DemoData.pricePerCamera);
    });

    test('paket bisa naik sampai batas 10 kamera', () {
      final s = AppState()..subscribe(1, DemoData.sampleCard);

      s.applyUpgrade(10);
      expect(s.cameraQuota, 10);
      expect(s.monthlyCost, 10 * DemoData.pricePerCamera);

      // Di atas batas diabaikan, bukan diterima diam-diam.
      s.applyUpgrade(11);
      expect(s.cameraQuota, 10);
    });

    test('biaya naik paket dihitung dari selisih kamera', () {
      final s = AppState()..subscribe(2, DemoData.sampleCard);
      expect(s.upgradeCostTo(5), 3 * DemoData.pricePerCamera);
      expect(s.upgradeCostTo(2), 0);
    });

    test('naik paket berlaku seketika dan tercatat di riwayat tagihan', () {
      final s = AppState()..subscribe(2, DemoData.sampleCard);
      final before = s.billing.length;

      s.applyUpgrade(5);

      expect(s.cameraQuota, 5);
      expect(s.billing, hasLength(before + 1));
      expect(s.billing.first.description, 'Tambahan 3 kamera');
      expect(s.billing.first.amount, 3 * DemoData.pricePerCamera);
    });

    test('turun paket dijadwalkan awal bulan depan, tidak berlaku sekarang',
        () {
      final s = AppState()..subscribe(5, DemoData.sampleCard);

      s.scheduleDowngrade(2);

      // Kuota aktif tidak berubah hari ini.
      expect(s.cameraQuota, 5);
      expect(s.hasPendingChange, isTrue);
      expect(s.pendingQuota, 2);

      final at = s.pendingEffectiveAt!;
      final now = DateTime.now();
      expect(at.day, 1);
      expect(at, DateTime(now.year, now.month + 1, 1));
      expect(at.isAfter(now), isTrue);
    });

    test('turun paket tidak dikenai biaya', () {
      final s = AppState()..subscribe(5, DemoData.sampleCard);
      final before = s.billing.length;

      s.scheduleDowngrade(2);
      expect(s.billing, hasLength(before));
    });

    test('naik paket membatalkan penurunan yang terjadwal', () {
      final s = AppState()..subscribe(5, DemoData.sampleCard);
      s.scheduleDowngrade(2);
      expect(s.hasPendingChange, isTrue);

      // Kalau tidak dibatalkan, pengguna membayar hari ini lalu diam-diam
      // turun bulan depan — justru kebalikan dari yang baru saja dibeli.
      s.applyUpgrade(8);

      expect(s.cameraQuota, 8);
      expect(s.hasPendingChange, isFalse);
      expect(s.pendingQuota, isNull);
    });

    test('penurunan bisa dibatalkan', () {
      final s = AppState()..subscribe(5, DemoData.sampleCard);
      s.scheduleDowngrade(2);

      s.cancelPendingDowngrade();
      expect(s.hasPendingChange, isFalse);
      expect(s.cameraQuota, 5);
    });

    test('paket tidak bisa turun di bawah jumlah kamera terpasang', () {
      final s = AppState()..subscribe(3, DemoData.sampleCard);
      s.addCamera(
        Camera(
          id: 'c2',
          name: 'Ruang Tengah',
          address: 'Jl. Melati No. 12',
          rtspUrl: 'rtsp://192.168.1.43:554/stream1',
          username: 'admin',
          password: 'cctv2024',
        ),
      );
      expect(s.cameras, hasLength(2));

      s.scheduleDowngrade(1); // ditolak: akan menghasilkan 2/1
      expect(s.hasPendingChange, isFalse);
      expect(s.cameraQuota, 3);
      expect(s.canDowngradeTo(1), isFalse);
      expect(s.canDowngradeTo(2), isTrue);
    });

    test('menutup kejadian menghapus penanda notifikasi', () {
      final s = AppState();
      final id = s.events.firstWhere((e) => e.isUnresolved).id;

      s.resolveEvent(id, FallStatus.dismissed);
      expect(s.hasUnresolved, isFalse);
    });

    test('mengurutkan kontak mengubah siapa yang dihubungi lebih dulu', () {
      final s = AppState();
      s.addContact(
        EmergencyContact(
          id: 'k2',
          name: 'Sri Rahayu',
          phone: '+62 813-2211-9087',
          relation: 'Menantu',
        ),
      );
      expect(s.contacts.first.name, 'Budi Santoso');

      s.reorderContacts(1, 0);
      expect(s.contacts.first.name, 'Sri Rahayu');
    });

    test('keluar akun mengembalikan seluruh state agar demo bisa diulang', () {
      final s = AppState()
        ..login()
        ..subscribe(3, DemoData.sampleCard);
      s.addCamera(
        Camera(
          id: 'c9',
          name: 'Tambahan',
          address: '-',
          rtspUrl: '-',
          username: '-',
          password: '-',
        ),
      );
      s.updateUser(name: 'Bukan Andi');
      s.scheduleDowngrade(2);

      s.logout();

      expect(s.loggedIn, isFalse);
      expect(s.onboarded, isFalse);
      expect(s.cameraQuota, 1);
      expect(s.cameras, hasLength(1));
      expect(s.user.name, 'Andi Pratama');
      expect(s.hasUnresolved, isTrue);
      // Demo babak kedua tidak boleh mulai di tengah perubahan langganan.
      expect(s.hasPendingChange, isFalse);
      // Kartu harus kosong lagi, kalau tidak pengisiannya hanya bisa
      // diperagakan satu kali per sesi.
      expect(s.hasPaymentCard, isFalse);
      expect(s.billing, isEmpty);
    });

    test('sebelum berlangganan belum ada kartu maupun tagihan', () {
      final s = AppState()..login();
      expect(s.hasPaymentCard, isFalse);
      expect(s.paymentCard, isNull);
      expect(s.billing, isEmpty);
    });

    test('berlangganan menyimpan kartu dan mencatat tagihan pertama', () {
      final s = AppState()..login();

      s.subscribe(3, DemoData.sampleCard);

      expect(s.onboarded, isTrue);
      expect(s.cameraQuota, 3);
      expect(s.hasPaymentCard, isTrue);
      expect(s.paymentCard!.last4, '4242');

      // Pembayaran hari ini di paling atas, disusul riwayat bulan-bulan lalu.
      expect(s.billing.first.description, 'Langganan 3 kamera');
      expect(s.billing.first.amount, 3 * DemoData.pricePerCamera);
      expect(s.billing, hasLength(4));
    });

    test('riwayat palsu tidak menabrak bulan berjalan', () {
      final s = AppState()..subscribe(2, DemoData.sampleCard);
      final now = DateTime.now();

      // Hanya pembayaran nyata yang boleh berada di bulan ini; kalau tidak,
      // layar tagihan terbaca seolah ditagih dua kali bulan ini.
      final thisMonth = s.billing.where(
        (b) => b.date.year == now.year && b.date.month == now.month,
      );
      expect(thisMonth, hasLength(1));
      expect(thisMonth.first.description, 'Langganan 2 kamera');
    });

    test('kartu bisa diganti setelah tersimpan', () {
      final s = AppState()..subscribe(2, DemoData.sampleCard);

      s.savePaymentCard(
        const PaymentCard(
          brand: 'Mastercard',
          last4: '5454',
          expiry: '11/30',
          holder: 'BUDI SANTOSO',
        ),
      );

      expect(s.paymentCard!.brand, 'Mastercard');
      expect(s.paymentCard!.last4, '5454');
    });

    test('merek kartu diturunkan dari digit pertama', () {
      expect(CardFormState.brandOf('4242424242424242'), 'Visa');
      expect(CardFormState.brandOf('5454 5454 5454 5454'), 'Mastercard');
      expect(CardFormState.brandOf('3782 822463 10005'), 'Amex');
      expect(CardFormState.brandOf('9999999999999999'), 'Kartu');
      expect(CardFormState.brandOf(''), 'Kartu');
    });
  });

  group('Alur layar', () {
    testWidgets('membuka aplikasi menampilkan layar masuk', (tester) async {
      await pumpApp(tester, AppState());

      expect(find.text('Masuk'), findsOneWidget);
      // Logo kini berupa wordmark bergambar; tidak boleh ada teks 'Mantau'
      // di sebelahnya, karena kata itu sudah ada di dalam gambar.
      expect(find.byType(BrandLogo), findsOneWidget);
      expect(find.text('Mantau'), findsNothing);
    });

    testWidgets('masuk membawa ke pemilihan paket', (tester) async {
      final state = AppState();
      await pumpApp(tester, state);

      await tester.tap(find.text('Masuk'));
      await tester.pumpAndSettle();

      expect(find.text('Pilih paket langganan'), findsOneWidget);
      expect(find.text('Lanjut ke pembayaran'), findsOneWidget);
    });

    testWidgets('berlangganan pertama harus mengisi kartu lalu membayar',
        (tester) async {
      final state = AppState()..login();
      await pumpApp(tester, state);

      // Belum ada kartu tersimpan sebelum pengguna mengetiknya.
      expect(state.hasPaymentCard, isFalse);

      // Naikkan stepper dari 1 ke 3, lalu lanjut ke pembayaran.
      final plus = find.bySemanticsLabel('Tambah kamera');
      await tester.tap(plus);
      await tester.pump();
      await tester.tap(plus);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Lanjut ke pembayaran'));
      await tester.pumpAndSettle();

      // Formulir kartu terbuka kosong — inilah bagian yang diperagakan.
      expect(find.text('Pembayaran'), findsOneWidget);
      expect(find.byType(CardForm), findsOneWidget);
      expect(find.text('Total dibayar'), findsOneWidget);

      // Menekan bayar dengan kartu kosong tidak melakukan apa pun.
      await scrollTo(tester, find.textContaining('Bayar '));
      await tester.tap(find.textContaining('Bayar '));
      await tester.pumpAndSettle();
      expect(state.onboarded, isFalse);
      expect(find.text('Nomor kartu wajib diisi'), findsOneWidget);

      await tester.enterText(
        find.widgetWithText(TextFormField, '4242 4242 4242 4242'),
        '4242424242424242',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'ANDI PRATAMA'),
        'Andi Pratama',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'MM/YY'),
        '0928',
      );
      await tester.enterText(find.widgetWithText(TextFormField, '123'), '123');
      await tester.pumpAndSettle();

      await scrollTo(tester, find.textContaining('Bayar '));
      await tester.tap(find.textContaining('Bayar '));
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      expect(find.text('Pembayaran berhasil'), findsOneWidget);
      expect(state.onboarded, isTrue);
      expect(state.cameraQuota, 3);

      // Kartu tersimpan, merek dan 4 digit terakhir diturunkan dari yang diketik.
      expect(state.paymentCard!.brand, 'Visa');
      expect(state.paymentCard!.last4, '4242');
      expect(state.paymentCard!.holder, 'ANDI PRATAMA');

      await tester.tap(find.text('Selesai'));
      await tester.pumpAndSettle();

      expect(find.text('Semua kamera aktif memantau'), findsOneWidget);
      expect(find.text('1/3'), findsOneWidget);
      expect(find.text('Kamar Ibu'), findsOneWidget);
    });

    testWidgets('mundur dari pembayaran membuat langganan tidak jadi',
        (tester) async {
      final state = AppState()..login();
      await pumpApp(tester, state);

      await tester.tap(find.text('Lanjut ke pembayaran'));
      await tester.pumpAndSettle();

      await scrollTo(tester, find.text('Batal'));
      await tester.tap(find.text('Batal'));
      await tester.pumpAndSettle();

      expect(state.onboarded, isFalse);
      expect(state.hasPaymentCard, isFalse);
      expect(find.text('Pilih paket langganan'), findsOneWidget);
    });

    testWidgets('menaikkan paket memakai kartu tersimpan tanpa isi ulang',
        (tester) async {
      final state = AppState()
        ..login()
        ..subscribe(2, DemoData.sampleCard);
      await pumpApp(tester, state);

      await tester.tap(find.text('Akun'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Paket langganan'));
      await tester.pumpAndSettle();

      await tester.tap(find.bySemanticsLabel('Tambah kamera'));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('Tingkatkan ·'));
      await tester.pumpAndSettle();

      // Kartu sudah ada, jadi yang tampil ringkasannya — bukan formulir lagi.
      expect(find.byType(CardForm), findsNothing);
      expect(find.textContaining('•••• 4242'), findsOneWidget);
      expect(find.text('Ganti kartu'), findsOneWidget);
    });

    testWidgets('Beranda menampilkan kuota penuh saat paket 1 kamera',
        (tester) async {
      final state = AppState()
        ..login()
        ..subscribe(1, DemoData.sampleCard);
      await pumpApp(tester, state);

      expect(find.text('1/1'), findsOneWidget);
      expect(find.text('Batas paket tercapai'), findsOneWidget);
    });

    testWidgets('menaikkan paket langsung tercermin di Beranda',
        (tester) async {
      final state = AppState()
        ..login()
        ..subscribe(1, DemoData.sampleCard);
      await pumpApp(tester, state);

      expect(find.text('1/1'), findsOneWidget);

      // Mengubah paket dari state, seperti yang dilakukan checkout 4.4.
      state.applyUpgrade(3);
      await tester.pumpAndSettle();

      expect(find.text('1/3'), findsOneWidget);
      expect(find.text('Hubungkan kamera baru'), findsOneWidget);
    });

    testWidgets('notifikasi menampilkan satu peringatan aktif', (tester) async {
      final state = AppState()
        ..login()
        ..subscribe(3, DemoData.sampleCard);
      await pumpApp(tester, state);

      await tester.tap(find.text('Notifikasi'));
      await tester.pumpAndSettle();

      expect(find.text('Kemungkinan jatuh\nterdeteksi'), findsOneWidget);
      expect(find.text('Perlu perhatian'.toUpperCase()), findsOneWidget);
    });

    testWidgets('mengetuk peringatan melompat ke detail rekaman',
        (tester) async {
      final state = AppState()
        ..login()
        ..subscribe(3, DemoData.sampleCard);
      await pumpApp(tester, state);

      await tester.tap(find.text('Notifikasi'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Lihat rekaman'));
      await tester.pumpAndSettle();

      // Mendarat di 3.2 — judul memuat nama kamera dan jam kejadian.
      expect(find.textContaining('Kamar Ibu ·'), findsWidgets);

      // Rincian dan kontak darurat berada lebih ke bawah pada halaman.
      await scrollTo(tester, find.text('Jenis kejadian'));
      expect(find.text('Jenis kejadian'), findsOneWidget);

      await scrollTo(tester, find.text('Budi Santoso'));
      expect(find.text('Budi Santoso'), findsOneWidget);

      await scrollTo(tester, find.text('Aman, tutup'));
      expect(find.text('Aman, tutup'), findsOneWidget);
    });

    testWidgets('Rekaman terbuka tanpa filter dan memuat tiga kejadian',
        (tester) async {
      final state = AppState()
        ..login()
        ..subscribe(3, DemoData.sampleCard);
      await pumpApp(tester, state);

      await tester.tap(find.text('Rekaman'));
      await tester.pumpAndSettle();

      // Filter bawaan harus "Semua tanggal", bukan hari ini — kalau tidak,
      // tab ini terbuka kosong karena kejadian berumur 3 dan 7 hari.
      expect(find.text('Semua tanggal'), findsOneWidget);
      expect(find.text('Tidak ada rekaman'), findsNothing);
      expect(find.textContaining('Kamar Ibu ·'), findsNWidgets(3));
    });

    testWidgets('tombol tambah saat kuota penuh membuka ajakan tingkatkan paket',
        (tester) async {
      final state = AppState()
        ..login()
        ..subscribe(1, DemoData.sampleCard);
      await pumpApp(tester, state);

      await tester.tap(find.text('Batas paket tercapai'));
      await tester.pumpAndSettle();

      expect(find.text('Batas kamera tercapai'), findsOneWidget);

      // Lembar ini menutup dirinya lalu mendorong halaman paket dari konteks
      // yang sama — jalur yang mudah patah, jadi diuji sampai halamannya muncul.
      await tester.tap(find.text('Tingkatkan paket'));
      await tester.pumpAndSettle();

      expect(find.text('Paket langganan'), findsOneWidget);
      expect(find.text('Ubah paket'.toUpperCase()), findsOneWidget);
    });

    testWidgets('pemilih tanggal Rekaman terbuka dalam bahasa Indonesia',
        (tester) async {
      final state = AppState()
        ..login()
        ..subscribe(3, DemoData.sampleCard);
      await pumpApp(tester, state);

      await tester.tap(find.text('Rekaman'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Semua tanggal'));
      await tester.pumpAndSettle();

      // Inilah satu-satunya alasan flutter_localizations ditambahkan.
      expect(find.text('Pilih tanggal kejadian'), findsOneWidget);
      expect(find.text('Batal'), findsOneWidget);
      expect(find.text('Pilih'), findsOneWidget);

      await tester.tap(find.text('Batal'));
      await tester.pumpAndSettle();
      expect(find.text('Semua tanggal'), findsOneWidget);
    });

    testWidgets('menaikkan paket harus lewat pembayaran dulu', (tester) async {
      final state = AppState()
        ..login()
        ..subscribe(2, DemoData.sampleCard);
      await pumpApp(tester, state);

      await tester.tap(find.text('Akun'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Paket langganan'));
      await tester.pumpAndSettle();

      // Naikkan target 2 → 4.
      final plus = find.bySemanticsLabel('Tambah kamera');
      await tester.tap(plus);
      await tester.pump();
      await tester.tap(plus);
      await tester.pumpAndSettle();

      await tester.tap(find.textContaining('Tingkatkan ·'));
      await tester.pumpAndSettle();

      // Mendarat di checkout — kuota belum berubah sebelum dibayar.
      expect(find.text('Pembayaran'), findsOneWidget);
      expect(find.text('Total dibayar'), findsOneWidget);
      expect(state.cameraQuota, 2);

      await tester.tap(find.textContaining('Bayar '));
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      expect(find.text('Pembayaran berhasil'), findsOneWidget);
      expect(state.cameraQuota, 4);

      await tester.tap(find.text('Selesai'));
      await tester.pumpAndSettle();

      // Kembali ke halaman paket dengan angka baru.
      expect(find.text('4 Kamera'), findsOneWidget);
    });

    testWidgets('membatalkan checkout tidak mengubah paket', (tester) async {
      final state = AppState()
        ..login()
        ..subscribe(2, DemoData.sampleCard);
      await pumpApp(tester, state);

      await tester.tap(find.text('Akun'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Paket langganan'));
      await tester.pumpAndSettle();

      await tester.tap(find.bySemanticsLabel('Tambah kamera'));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('Tingkatkan ·'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Batal'));
      await tester.pumpAndSettle();

      expect(state.cameraQuota, 2);
      expect(find.text('2 Kamera'), findsOneWidget);
    });

    testWidgets('menurunkan paket menjadwalkan tanpa pembayaran',
        (tester) async {
      final state = AppState()
        ..login()
        ..subscribe(4, DemoData.sampleCard);
      await pumpApp(tester, state);

      await tester.tap(find.text('Akun'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Paket langganan'));
      await tester.pumpAndSettle();

      await tester.tap(find.bySemanticsLabel('Kurangi kamera'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Jadwalkan penurunan'));
      await tester.pumpAndSettle();

      // Tidak ada layar pembayaran, dan kuota aktif tetap 4.
      expect(find.text('Pembayaran'), findsNothing);
      expect(state.cameraQuota, 4);
      expect(state.pendingQuota, 3);
      expect(find.text('Penurunan paket terjadwal'), findsOneWidget);

      await tester.tap(find.text('Batalkan'));
      await tester.pumpAndSettle();
      expect(state.hasPendingChange, isFalse);
    });

    testWidgets('Akun menampilkan paket dan jumlah kontak', (tester) async {
      final state = AppState()
        ..login()
        ..subscribe(2, DemoData.sampleCard);
      await pumpApp(tester, state);

      await tester.tap(find.text('Akun'));
      await tester.pumpAndSettle();

      expect(find.text('Andi Pratama'), findsOneWidget);
      expect(find.textContaining('2 kamera'), findsOneWidget);
      expect(find.text('1 kontak tersimpan'), findsOneWidget);
    });
  });
}
