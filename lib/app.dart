import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'features/auth/login_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/shell/main_shell.dart';
import 'state/app_state.dart';
import 'theme/app_theme.dart';
import 'widgets/phone_frame.dart';

class MantauApp extends StatelessWidget {
  const MantauApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mantau',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),

      // Seluruh antarmuka berbahasa Indonesia, termasuk pemilih tanggal bawaan
      // Material yang dipakai di halaman Rekaman.
      locale: const Locale('id'),
      supportedLocales: const [Locale('id'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      builder: (context, child) => PhoneFrame(child: child ?? const SizedBox()),
      home: const _RootGate(),
    );
  }
}

/// Menentukan layar pertama berdasarkan state: login → onboarding → beranda.
///
/// Karena state hanya di memori, keluar akun selalu mengembalikan alur ini ke
/// awal sehingga demo bisa diperagakan berulang kali.
class _RootGate extends StatelessWidget {
  const _RootGate();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    final Widget screen;
    if (!state.loggedIn) {
      screen = const LoginScreen();
    } else if (!state.onboarded) {
      screen = const OnboardingScreen();
    } else {
      screen = const MainShell();
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 260),
      child: KeyedSubtree(
        key: ValueKey('${state.loggedIn}-${state.onboarded}'),
        child: screen,
      ),
    );
  }
}
