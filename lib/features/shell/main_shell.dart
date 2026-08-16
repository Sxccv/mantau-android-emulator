import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../home/home_screen.dart';
import '../notifications/notifications_screen.dart';
import '../profile/profile_screen.dart';
import '../recordings/recording_detail_screen.dart';
import '../recordings/recordings_screen.dart';

/// Kerangka utama dengan empat tab: Beranda, Notifikasi, Rekaman, Akun.
///
/// Setiap tab punya [Navigator] sendiri supaya halaman detail terbuka di dalam
/// tab dan bilah bawah tetap terlihat — persis seperti layar 4 dan 5 pada
/// MVP_reference.png.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  static MainShellState of(BuildContext context) =>
      context.findAncestorStateOfType<MainShellState>()!;

  @override
  State<MainShell> createState() => MainShellState();
}

class MainShellState extends State<MainShell> {
  static const tabBeranda = 0;
  static const tabNotifikasi = 1;
  static const tabRekaman = 2;
  static const tabAkun = 3;

  int _index = tabBeranda;

  final _navKeys = List.generate(4, (_) => GlobalKey<NavigatorState>());

  void goToTab(int index) {
    if (_index == index) {
      // Mengetuk tab yang sedang aktif akan kembali ke akar tab tersebut.
      _navKeys[index].currentState?.popUntil((r) => r.isFirst);
    } else {
      setState(() => _index = index);
    }
  }

  /// Lompatan dari notifikasi jatuh (2.1) langsung ke detail rekaman (3.2).
  ///
  /// Inilah satu-satunya jalur yang perlu berpindah tab sekaligus membuka
  /// halaman, jadi logikanya dikumpulkan di sini.
  void openRecording(String eventId) {
    setState(() => _index = tabRekaman);

    // Menunggu satu frame agar Navigator tab Rekaman sudah terpasang.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final nav = _navKeys[tabRekaman].currentState;
      if (nav == null) return;
      nav.popUntil((r) => r.isFirst);
      nav.push(
        MaterialPageRoute(
          builder: (_) => RecordingDetailScreen(eventId: eventId),
        ),
      );
    });
  }

  Widget _tabNavigator(int index, Widget root) {
    return Navigator(
      key: _navKeys[index],
      onGenerateRoute: (settings) =>
          MaterialPageRoute(settings: settings, builder: (_) => root),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        final nav = _navKeys[_index].currentState;
        if (nav != null && nav.canPop()) {
          nav.pop();
        } else if (_index != tabBeranda) {
          setState(() => _index = tabBeranda);
        }
      },
      child: Scaffold(
        body: IndexedStack(
          index: _index,
          children: [
            _tabNavigator(0, const HomeScreen()),
            _tabNavigator(1, const NotificationsScreen()),
            _tabNavigator(2, const RecordingsScreen()),
            _tabNavigator(3, const ProfileScreen()),
          ],
        ),
        bottomNavigationBar: _BottomNav(
          index: _index,
          onTap: goToTab,
        ),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.index, required this.onTap});

  final int index;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final hasAlert = context.select<AppState, bool>((s) => s.hasUnresolved);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 62,
          child: Row(
            children: [
              _NavItem(
                icon: Icons.home_outlined,
                activeIcon: Icons.home,
                label: 'Beranda',
                selected: index == 0,
                onTap: () => onTap(0),
              ),
              _NavItem(
                icon: Icons.notifications_none,
                activeIcon: Icons.notifications,
                label: 'Notifikasi',
                selected: index == 1,
                badge: hasAlert,
                onTap: () => onTap(1),
              ),
              _NavItem(
                icon: Icons.play_circle_outline,
                activeIcon: Icons.play_circle_fill,
                label: 'Rekaman',
                selected: index == 2,
                onTap: () => onTap(2),
              ),
              _NavItem(
                icon: Icons.person_outline,
                activeIcon: Icons.person,
                label: 'Akun',
                selected: index == 3,
                onTap: () => onTap(3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.badge = false,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool badge;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.orange : AppColors.textMuted;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(selected ? activeIcon : icon, size: 23, color: color),
                if (badge)
                  Positioned(
                    right: -3,
                    top: -2,
                    child: Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: AppColors.red,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.surface, width: 1.5),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
