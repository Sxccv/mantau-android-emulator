import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';

/// 1.4 — Formulir pendaftaran kamera CCTV baru.
class AddCameraScreen extends StatefulWidget {
  const AddCameraScreen({super.key});

  @override
  State<AddCameraScreen> createState() => _AddCameraScreenState();
}

class _AddCameraScreenState extends State<AddCameraScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _address = TextEditingController();
  final _rtsp = TextEditingController();
  final _username = TextEditingController();
  final _password = TextEditingController();

  bool _obscure = true;
  bool _testing = false;
  bool _tested = false;

  @override
  void dispose() {
    for (final c in [_name, _address, _rtsp, _username, _password]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null;

  /// Uji koneksi tiruan — demo tidak menghubungi CCTV mana pun.
  Future<void> _testConnection() async {
    if (_rtsp.text.trim().isEmpty) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Isi RTSP URL terlebih dahulu.')),
      );
      return;
    }

    setState(() {
      _testing = true;
      _tested = false;
    });

    await Future<void>.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;

    setState(() {
      _testing = false;
      _tested = true;
    });
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final state = context.read<AppState>();
    state.addCamera(
      Camera(
        id: 'cam-${DateTime.now().millisecondsSinceEpoch}',
        name: _name.text.trim(),
        address: _address.text.trim(),
        rtspUrl: _rtsp.text.trim(),
        username: _username.text.trim(),
        password: _password.text,
      ),
    );

    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Kamera "${_name.text.trim()}" tersimpan.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('Tambah kamera'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.page),
          children: [
            LabeledField(
              label: 'Nama kamera',
              controller: _name,
              hint: 'mis. Kamar Ibu',
              validator: _required,
            ),
            const SizedBox(height: 16),
            LabeledField(
              label: 'Alamat',
              controller: _address,
              hint: 'mis. Jl. Melati No. 12, Bandung',
              validator: _required,
            ),
            const SizedBox(height: 16),
            LabeledField(
              label: 'RTSP URL',
              controller: _rtsp,
              hint: 'rtsp://192.168.1.42:554/stream1',
              validator: _required,
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: LabeledField(
                    label: 'Username',
                    controller: _username,
                    hint: 'admin',
                    validator: _required,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: LabeledField(
                    label: 'Password',
                    controller: _password,
                    hint: '••••••',
                    obscure: _obscure,
                    validator: _required,
                    suffix: IconButton(
                      icon: Icon(
                        _obscure ? Icons.visibility_off : Icons.visibility,
                        size: 18,
                        color: AppColors.textMuted,
                      ),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            const InfoBox(
              icon: Icons.help_outline,
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: 'Biasanya ada di aplikasi CCTV Anda di bawah ',
                    ),
                    TextSpan(
                      text: 'Pengaturan → Jaringan → RTSP',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    TextSpan(text: '. Formatnya seperti '),
                    TextSpan(
                      text: 'rtsp://user:pass@ip:port/stream',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    TextSpan(text: '.'),
                  ],
                ),
              ),
            ),

            if (_tested) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Koneksi berhasil diuji — gambar diterima',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.green,
                      ),
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: SecondaryButton(
                    label: _testing ? 'Menguji...' : 'Uji koneksi',
                    onPressed: _testing ? null : _testConnection,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: PrimaryButton(
                    label: 'Simpan kamera',
                    onPressed: _save,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
