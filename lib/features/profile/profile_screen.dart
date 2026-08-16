import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/common.dart';
import 'edit_profile_screen.dart';
import 'emergency_contacts_screen.dart';
import 'membership_screen.dart';
import 'payment_screen.dart';
import 'settings_screen.dart';

/// 4.1 — Menu Akun.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _open(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Keluar akun?'),
        content: const Text(
          'Anda akan kembali ke halaman masuk dan perlu memilih paket lagi.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text(
              'Keluar',
              style: TextStyle(color: AppColors.red),
            ),
          ),
        ],
      ),
    );

    if (ok == true && context.mounted) context.read<AppState>().logout();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Akun'),
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.page),
        children: [
          AppCard(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 27,
                  backgroundColor: AppColors.blueSoft,
                  child: Text(
                    state.user.initial,
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                      color: AppColors.blueText,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        state.user.name,
                        style: const TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w800,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        state.user.email,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textMuted,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.section),

          const SectionLabel('Akun'),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                MenuRow(
                  icon: Icons.person_outline,
                  title: 'Informasi pengguna',
                  subtitle: 'Nama, email, kata sandi',
                  onTap: () => _open(context, const EditProfileScreen()),
                ),
                const Divider(indent: 62),
                MenuRow(
                  icon: Icons.contact_phone_outlined,
                  title: 'Kontak darurat',
                  subtitle: '${state.contacts.length} kontak tersimpan',
                  tint: AppColors.red,
                  onTap: () => _open(context, const EmergencyContactsScreen()),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.section),

          const SectionLabel('Langganan'),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                MenuRow(
                  icon: Icons.workspace_premium_outlined,
                  title: 'Paket langganan',
                  subtitle:
                      '${state.cameraQuota} kamera · ${Fmt.rupiah(state.monthlyCost)}/bulan',
                  onTap: () => _open(context, const MembershipScreen()),
                ),
                const Divider(indent: 62),
                MenuRow(
                  icon: Icons.credit_card,
                  title: 'Metode pembayaran',
                  subtitle: 'Visa •••• 4829',
                  tint: AppColors.blueText,
                  onTap: () => _open(context, const PaymentScreen()),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.section),

          const SectionLabel('Lainnya'),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                MenuRow(
                  icon: Icons.settings_outlined,
                  title: 'Pengaturan aplikasi',
                  subtitle: 'Notifikasi, suara, bahasa',
                  tint: AppColors.textMuted,
                  onTap: () => _open(context, const SettingsScreen()),
                ),
                const Divider(indent: 62),
                MenuRow(
                  icon: Icons.logout,
                  title: 'Keluar',
                  tint: AppColors.red,
                  trailing: const SizedBox.shrink(),
                  onTap: () => _confirmLogout(context),
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
