import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';

/// 4.3 — Daftar kontak darurat, bisa ditambah, diubah, dan diurutkan.
///
/// Urutan daftar menentukan siapa dihubungi lebih dulu, jadi menggeser kontak
/// benar-benar mengubah perilaku — bukan sekadar tampilan.
class EmergencyContactsScreen extends StatelessWidget {
  const EmergencyContactsScreen({super.key});

  Future<void> _edit(BuildContext context, {EmergencyContact? existing}) async {
    final result = await showModalBottomSheet<_ContactDraft>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ContactForm(existing: existing),
    );
    if (result == null || !context.mounted) return;

    final state = context.read<AppState>();
    if (existing == null) {
      state.addContact(
        EmergencyContact(
          id: 'kontak-${DateTime.now().millisecondsSinceEpoch}',
          name: result.name,
          phone: result.phone,
          relation: result.relation,
        ),
      );
    } else {
      state.updateContact(
        existing.id,
        name: result.name,
        phone: result.phone,
        relation: result.relation,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final contacts = state.contacts;

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('Kontak darurat'),
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.page,
              4,
              AppSpacing.page,
              0,
            ),
            child: InfoBox(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Urutan dihubungi saat notifikasi tidak direspons',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'Kontak akan dihubungi berurutan dari atas ke bawah, '
                    'setiap 2 menit, sampai ada yang merespons. '
                    'Tekan dan geser untuk mengubah urutan.',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.section),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
            child: SectionLabel('Kontak (${contacts.length})'),
          ),
          Expanded(
            child: contacts.isEmpty
                ? const EmptyState(
                    icon: Icons.contact_phone_outlined,
                    title: 'Belum ada kontak',
                    message:
                        'Tambahkan minimal satu kontak agar keluarga bisa '
                        'dihubungi saat terjadi jatuh.',
                  )
                : ReorderableListView.builder(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.page,
                      0,
                      AppSpacing.page,
                      AppSpacing.page,
                    ),
                    itemCount: contacts.length,
                    onReorder: context.read<AppState>().reorderContacts,
                    proxyDecorator: (child, _, __) => Material(
                      color: Colors.transparent,
                      child: child,
                    ),
                    itemBuilder: (_, i) => Padding(
                      key: ValueKey(contacts[i].id),
                      padding: const EdgeInsets.only(bottom: AppSpacing.gap),
                      child: _ContactCard(
                        contact: contacts[i],
                        index: i,
                        onEdit: () => _edit(context, existing: contacts[i]),
                      ),
                    ),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.page,
              0,
              AppSpacing.page,
              AppSpacing.page,
            ),
            child: PrimaryButton(
              label: 'Tambah kontak',
              icon: Icons.add,
              onPressed: () => _edit(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  const _ContactCard({
    required this.contact,
    required this.index,
    required this.onEdit,
  });

  final EmergencyContact contact;
  final int index;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final tint = AppColors.avatarTints[index % AppColors.avatarTints.length];
    final isPrimary = index == 0;

    return AppCard(
      border: isPrimary ? Border.all(color: AppColors.orange, width: 1.4) : null,
      child: Row(
        children: [
          CircleAvatar(
            radius: 21,
            backgroundColor: tint.withValues(alpha: 0.15),
            child: Text(
              contact.initials,
              style: TextStyle(
                color: tint,
                fontWeight: FontWeight.w800,
                fontSize: 13.5,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        contact.name,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isPrimary) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.orangeSoft,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Utama',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.orange,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  '${contact.phone} · ${contact.relation}',
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textMuted,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          _RoundIconButton(
            icon: Icons.call,
            color: AppColors.green,
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Menghubungi ${contact.name}...')),
            ),
          ),
          const SizedBox(width: 8),
          _RoundIconButton(
            icon: Icons.edit_outlined,
            color: AppColors.blueText,
            onTap: onEdit,
          ),
          ReorderableDragStartListener(
            index: index,
            child: const Padding(
              padding: EdgeInsets.only(left: 4),
              child: Icon(
                Icons.drag_handle,
                size: 20,
                color: AppColors.textFaint,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.13),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 17, color: color),
      ),
    );
  }
}

/// Nilai yang dikembalikan formulir kontak.
class _ContactDraft {
  const _ContactDraft(this.name, this.phone, this.relation);

  final String name;
  final String phone;
  final String relation;
}

class _ContactForm extends StatefulWidget {
  const _ContactForm({this.existing});

  final EmergencyContact? existing;

  @override
  State<_ContactForm> createState() => _ContactFormState();
}

class _ContactFormState extends State<_ContactForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _relation;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.existing?.name ?? '');
    _phone = TextEditingController(text: widget.existing?.phone ?? '');
    _relation = TextEditingController(text: widget.existing?.relation ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _relation.dispose();
    super.dispose();
  }

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null;

  @override
  Widget build(BuildContext context) {
    final editing = widget.existing != null;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: SafeArea(
          top: false,
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  editing ? 'Ubah kontak' : 'Tambah kontak darurat',
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 18),
                LabeledField(
                  label: 'Nama',
                  controller: _name,
                  hint: 'mis. Sri Rahayu',
                  validator: _required,
                ),
                const SizedBox(height: 14),
                LabeledField(
                  label: 'Nomor telepon',
                  controller: _phone,
                  hint: '+62 813-2211-9087',
                  keyboardType: TextInputType.phone,
                  validator: _required,
                ),
                const SizedBox(height: 14),
                LabeledField(
                  label: 'Hubungan',
                  controller: _relation,
                  hint: 'mis. Menantu',
                  validator: _required,
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: SecondaryButton(
                        label: 'Batal',
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: PrimaryButton(
                        label: 'Simpan',
                        onPressed: () {
                          if (!_formKey.currentState!.validate()) return;
                          Navigator.of(context).pop(
                            _ContactDraft(
                              _name.text.trim(),
                              _phone.text.trim(),
                              _relation.text.trim(),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
