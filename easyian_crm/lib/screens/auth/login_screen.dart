import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/app_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  bool _obscure = true, _loading = false;
  String? _error;

  @override
  void dispose() { _usernameCtrl.dispose(); _passCtrl.dispose(); super.dispose(); }

  Future<void> _login() async {
    if (_usernameCtrl.text.trim().isEmpty || _passCtrl.text.isEmpty) {
      setState(() => _error = 'Please enter username and password'); return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      await context.read<AppProvider>().login(_usernameCtrl.text.trim(), _passCtrl.text);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Row(
        children: [
          // Left brand panel
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                  colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                ),
              ),
              padding: const EdgeInsets.all(48),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.logoRed,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: Text('E', style: GoogleFonts.inter(
                          color: Colors.white, fontWeight: FontWeight.w800, fontSize: 20)),
                    ),
                    const SizedBox(width: 12),
                    Text('Easyian', style: GoogleFonts.inter(
                        color: Colors.white, fontWeight: FontWeight.w700, fontSize: 20)),
                  ]),
                  const Spacer(),
                  Text('Your entire pipeline,\none place.',
                      style: GoogleFonts.inter(
                          color: Colors.white, fontSize: 36,
                          fontWeight: FontWeight.w800, height: 1.2)),
                  const SizedBox(height: 16),
                  Text('Track leads, manage communications, and close\nmore deals with Easyian CRM.',
                      style: GoogleFonts.inter(
                          color: Colors.white60, fontSize: 15, height: 1.6)),
                  const Spacer(),
                  // Feature pills
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    for (final f in ['Lead Management', 'Email Campaigns',
                        'Analytics', 'Pipeline Tracking', 'Team Collaboration'])
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.07),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withOpacity(0.12)),
                        ),
                        child: Text(f, style: GoogleFonts.inter(
                            fontSize: 12, color: Colors.white70, fontWeight: FontWeight.w500)),
                      ),
                  ]),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),

          // Right login form
          Container(
            width: 440,
            color: Colors.white,
            padding: const EdgeInsets.all(48),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Sign in to Easyian',
                    style: GoogleFonts.inter(
                        fontSize: 24, fontWeight: FontWeight.w700,
                        color: AppColors.lightText)),
                const SizedBox(height: 8),
                Text('Enter your credentials to access your CRM',
                    style: GoogleFonts.inter(
                        fontSize: 13, color: AppColors.lightTextMuted)),
                const SizedBox(height: 32),

                if (_error != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppColors.errorBg,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.error.withOpacity(0.3)),
                    ),
                    child: Row(children: [
                      const Icon(Icons.error_outline_rounded,
                          size: 16, color: AppColors.error),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_error!,
                          style: GoogleFonts.inter(fontSize: 13, color: AppColors.error))),
                    ]),
                  ),
                ],

                Text('Username', style: GoogleFonts.inter(
                    fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.lightTextSub)),
                const SizedBox(height: 6),
                TextField(
                  controller: _usernameCtrl,
                  keyboardType: TextInputType.text,
                  onSubmitted: (_) => _login(),
                  style: GoogleFonts.inter(fontSize: 14),
                  decoration: const InputDecoration(
                    hintText: 'your username',
                    prefixIcon: Icon(Icons.person_outline_rounded, size: 18),
                  ),
                ),
                const SizedBox(height: 16),

                Text('Password', style: GoogleFonts.inter(
                    fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.lightTextSub)),
                const SizedBox(height: 6),
                TextField(
                  controller: _passCtrl,
                  obscureText: _obscure,
                  onSubmitted: (_) => _login(),
                  style: GoogleFonts.inter(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: '••••••••',
                    prefixIcon: const Icon(Icons.lock_outline_rounded, size: 18),
                    suffixIcon: IconButton(
                      icon: Icon(_obscure
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined, size: 18),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 42,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _login,
                    child: _loading
                        ? const SizedBox(width: 18, height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text('Sign In',
                            style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
