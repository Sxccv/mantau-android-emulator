import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';

/// 1.1 — Layar masuk.
///
/// Demo: kredensial apa pun diterima asal tidak kosong, dan tombol Google/Apple
/// langsung masuk. Salah ketik di atas panggung tidak boleh menggagalkan demo.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController(text: 'andi.pratama@gmail.com');
  final _password = TextEditingController(text: 'demo1234');
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<AppState>().login(email: _email.text);
  }

  void _social(String provider) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Masuk dengan $provider')),
    );
    context.read<AppState>().login();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.page),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(child: BrandLogo(height: 44)),
                  const SizedBox(height: 12),
                  const Text(
                    'Pantau orang tersayang, dapatkan peringatan\nsaat terjadi jatuh.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13.5,
                      height: 1.5,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 32),

                  LabeledField(
                    label: 'Email',
                    controller: _email,
                    hint: 'nama@email.com',
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Email wajib diisi' : null,
                  ),
                  const SizedBox(height: 16),
                  LabeledField(
                    label: 'Kata sandi',
                    controller: _password,
                    hint: '••••••••',
                    obscure: _obscure,
                    validator: (v) => (v == null || v.isEmpty)
                        ? 'Kata sandi wajib diisi'
                        : null,
                    suffix: IconButton(
                      icon: Icon(
                        _obscure ? Icons.visibility_off : Icons.visibility,
                        size: 19,
                        color: AppColors.textMuted,
                      ),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),

                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Tautan atur ulang dikirim ke email.'),
                          ),
                        );
                      },
                      child: const Text(
                        'Lupa kata sandi?',
                        style: TextStyle(
                          color: AppColors.orange,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),

                  PrimaryButton(label: 'Masuk', onPressed: _submit),
                  const SizedBox(height: 22),

                  Row(
                    children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'atau lanjutkan dengan',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                      const Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 18),

                  Row(
                    children: [
                      Expanded(
                        child: _SocialButton(
                          asset: 'assets/images/google_icon.png',
                          label: 'Google',
                          onTap: () => _social('Google'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _SocialButton(
                          asset: 'assets/images/apple_icon.png',
                          label: 'Apple',
                          onTap: () => _social('Apple'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 26),

                  Text.rich(
                    TextSpan(
                      text: 'Belum punya akun? ',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textMuted,
                      ),
                      children: [
                        TextSpan(
                          text: 'Daftar',
                          style: const TextStyle(
                            color: AppColors.orange,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.asset,
    required this.label,
    required this.onTap,
  });

  final String asset;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.text,
          side: const BorderSide(color: AppColors.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(asset, width: 18, height: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
