import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';

/// 4.5b — Pengaturan aplikasi.
///
/// Sakelar di sini bersifat tampilan: nilainya tersimpan di state dan bertahan
/// selama sesi, tetapi tidak mengubah perilaku lain pada demo.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('Pengaturan'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.page),
        children: [
          const SectionLabel('Notifikasi'),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _SwitchRow(
                  icon: Icons.notifications_outlined,
                  title: 'Notifikasi jatuh',
                  subtitle: 'Peringatan langsung saat terdeteksi jatuh',
                  value: state.notificationsEnabled,
                  onChanged: (v) =>
                      context.read<AppState>().setSetting(notifications: v),
                ),
                const Divider(indent: 62),
                _SwitchRow(
                  icon: Icons.volume_up_outlined,
                  title: 'Suara peringatan',
                  subtitle: 'Bunyikan nada darurat',
                  value: state.soundEnabled,
                  onChanged: (v) =>
                      context.read<AppState>().setSetting(sound: v),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.section),

          const SectionLabel('Rekaman'),
          AppCard(
            padding: EdgeInsets.zero,
            child: _SwitchRow(
              icon: Icons.save_outlined,
              title: 'Simpan klip otomatis',
              subtitle: 'Simpan 30 detik sebelum dan sesudah kejadian',
              value: state.autoRecordEnabled,
              onChanged: (v) =>
                  context.read<AppState>().setSetting(autoRecord: v),
            ),
          ),
          const SizedBox(height: AppSpacing.section),

          const SectionLabel('Umum'),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                const MenuRow(
                  icon: Icons.language,
                  title: 'Bahasa',
                  subtitle: 'Indonesia',
                  tint: AppColors.blueText,
                ),
                const Divider(indent: 62),
                MenuRow(
                  icon: Icons.help_outline,
                  title: 'Pusat bantuan',
                  tint: AppColors.textMuted,
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Hubungi dukungan di bantuan@mantau.id'),
                    ),
                  ),
                ),
                const Divider(indent: 62),
                MenuRow(
                  icon: Icons.privacy_tip_outlined,
                  title: 'Kebijakan privasi',
                  tint: AppColors.textMuted,
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Membuka kebijakan privasi...'),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.section),

          const Center(
            child: Text(
              'Mantau · versi demo 1.0.0',
              style: TextStyle(fontSize: 12, color: AppColors.textFaint),
            ),
          ),
        ],
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return MenuRow(
      icon: icon,
      title: title,
      subtitle: subtitle,
      onTap: () => onChanged(!value),
      trailing: Switch(
        value: value,
        activeThumbColor: Colors.white,
        activeTrackColor: AppColors.orange,
        onChanged: onChanged,
      ),
    );
  }
}
