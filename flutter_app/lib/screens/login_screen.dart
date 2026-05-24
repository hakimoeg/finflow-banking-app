// lib/screens/login_screen.dart — Écran de connexion
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_provider.dart';
import 'dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final auth = context.read<AuthProvider>();
    final success = await auth.login(
      _emailCtrl.text.trim(),
      _passwordCtrl.text,
    );

    if (success && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1E),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                const Text(
                  '◈ FinFlow',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFC9A84C),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'BANQUE NUMÉRIQUE',
                  style: TextStyle(
                    fontSize: 11,
                    letterSpacing: 2,
                    color: Colors.white.withOpacity(0.4),
                  ),
                ),
                const SizedBox(height: 48),

                // Card de connexion
                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: const Color(0xFF141D2E),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF1E2D45)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Connexion à votre espace',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Email
                      _buildLabel('Adresse e-mail'),
                      const SizedBox(height: 6),
                      _buildTextField(
                        controller: _emailCtrl,
                        hint: 'jean@finflow.io',
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 16),

                      // Mot de passe
                      _buildLabel('Mot de passe'),
                      const SizedBox(height: 6),
                      _buildTextField(
                        controller: _passwordCtrl,
                        hint: '••••••••',
                        obscure: _obscurePassword,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off : Icons.visibility,
                            color: Colors.white38,
                            size: 20,
                          ),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                        onSubmitted: (_) => _handleLogin(),
                      ),
                      const SizedBox(height: 8),

                      // Erreur
                      if (auth.errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            auth.errorMessage!,
                            style: const TextStyle(color: Color(0xFFE05252), fontSize: 13),
                          ),
                        ),

                      const SizedBox(height: 20),

                      // Bouton connexion
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: auth.isLoading ? null : _handleLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFC9A84C),
                            foregroundColor: const Color(0xFF0A0F1E),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: auth.isLoading
                              ? const SizedBox(
                                  width: 20, height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Color(0xFF0A0F1E),
                                  ),
                                )
                              : const Text(
                                  'Se connecter',
                                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) => Text(
    text.toUpperCase(),
    style: TextStyle(
      fontSize: 11,
      letterSpacing: 0.5,
      color: Colors.white.withOpacity(0.5),
      fontWeight: FontWeight.w500,
    ),
  );

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    bool obscure = false,
    TextInputType? keyboardType,
    Widget? suffixIcon,
    ValueChanged<String>? onSubmitted,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      onSubmitted: onSubmitted,
      style: const TextStyle(color: Colors.white, fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.25)),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: const Color(0xFF0D1526),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF1E2D45)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF1E2D45)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFC9A84C)),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    );
  }
}