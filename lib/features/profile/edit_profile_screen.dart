import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';

/// 4.2 — Ubah nama, email, dan kata sandi.
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _email;
  final _password = TextEditingController();
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    final user = context.read<AppState>().user;
    _name = TextEditingController(text: user.name);
    _email = TextEditingController(text: user.email);
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    context.read<AppState>().updateUser(
          name: _name.text,
          email: _email.text,
          password: _password.text.isEmpty ? null : _password.text,
        );

    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Informasi pengguna diperbarui.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('Informasi pengguna'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.page),
          children: [
            LabeledField(
              label: 'Nama lengkap',
              controller: _name,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Nama wajib diisi' : null,
            ),
            const SizedBox(height: 16),
            LabeledField(
              label: 'Email',
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Email wajib diisi';
                if (!v.contains('@')) return 'Format email tidak valid';
                return null;
              },
            ),
            const SizedBox(height: 16),
            LabeledField(
              label: 'Kata sandi baru',
              controller: _password,
              hint: 'Kosongkan bila tidak diubah',
              obscure: _obscure,
              validator: (v) {
                if (v == null || v.isEmpty) return null;
                return v.length < 6 ? 'Minimal 6 karakter' : null;
              },
              suffix: IconButton(
                icon: Icon(
                  _obscure ? Icons.visibility_off : Icons.visibility,
                  size: 19,
                  color: AppColors.textMuted,
                ),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
            const SizedBox(height: 28),
            PrimaryButton(label: 'Simpan perubahan', onPressed: _save),
          ],
        ),
      ),
    );
  }
}
