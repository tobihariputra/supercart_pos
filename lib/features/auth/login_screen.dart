import 'package:flutter/material.dart';
import 'package:supercart_pos/services/auth_api_services.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _nipC = TextEditingController();
  final TextEditingController _passwordC = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final AuthApiService _authService = AuthApiService();

  bool _loading = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward();

    // sementara comment login check untuk debugging
    // _checkLoginStatus();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nipC.dispose();
    _passwordC.dispose();
    super.dispose();
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            isError ? Colors.red.withAlpha(180) : Colors.green.withAlpha(180),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _login() async {
    if (_nipC.text.isEmpty || _passwordC.text.isEmpty) {
      _showSnackBar("NIP dan password harus diisi!", isError: true);
      return;
    }

    setState(() => _loading = true);

    try {
      final result = await _authService.login(
        nip: _nipC.text.trim(),
        password: _passwordC.text,
      );

      if (result['success'] == true) {
        _showSnackBar("Login kasir berhasil!", isError: false);

        await Future.delayed(const Duration(milliseconds: 500));

        if (mounted) {
          Navigator.pushReplacementNamed(context, '/dashboard');
        }
      } else {
        _showSnackBar(result['error'] ?? 'Login gagal', isError: true);
      }
    } catch (e) {
      _showSnackBar("Terjadi kesalahan: ${e.toString()}", isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade700, // warna sementara agar tidak putih
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.point_of_sale_rounded,
                        size: 80, color: Colors.white),
                    const SizedBox(height: 20),
                    const Text(
                      "Login",
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 40),
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha((0.3 * 255).round()),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Column(
                        children: [
                          TextField(
                            controller: _nipC,
                            enabled: !_loading,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              hintText: "NIP",
                              filled: true,
                              fillColor: Colors.white,
                              prefixIcon: const Icon(Icons.badge_outlined),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _passwordC,
                            obscureText: _obscurePassword,
                            enabled: !_loading,
                            decoration: InputDecoration(
                              hintText: "Password",
                              filled: true,
                              fillColor: Colors.white,
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(_obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none),
                            ),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _loading ? null : _login,
                              child: _loading
                                  ? const CircularProgressIndicator(
                                      color: Colors.white,
                                    )
                                  : const Text("Masuk",
                                      style: TextStyle(fontSize: 18)),
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
        ),
      ),
    );
  }
}
