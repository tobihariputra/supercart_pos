import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
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
  final storage = const FlutterSecureStorage();

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

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
        );

    _animationController.forward();
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
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.fixed,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Get user role from secure storage
  Future<String> _getUserRole() async {
    try {
      final rolesStr = await storage.read(key: 'user_roles');
      debugPrint('📋 User Roles from storage: $rolesStr');

      if (rolesStr != null && rolesStr.isNotEmpty) {
        final roles = json.decode(rolesStr) as List<dynamic>;
        
        if (roles.isNotEmpty) {
          final roleName = roles[0]['name'];
          debugPrint('✅ User Role: $roleName');
          return roleName.toString().toLowerCase();
        }
      }

      debugPrint('❌ No roles found in storage');
      return '';
    } catch (e) {
      debugPrint('❌ Error getting user role: $e');
      return '';
    }
  }

  /// Get route based on user role
  String _getRouteByRole(String role) {
    switch (role) {
      case 'gudang':
        debugPrint('🏭 Navigating to /management (gudang)');
        return '/management';
      case 'kasir':
        debugPrint('🛒 Navigating to /dashboard (kasir)');
        return '/dashboard';
      default:
        debugPrint('⚠️ Unknown role: $role, defaulting to /dashboard');
        return '/dashboard';
    }
  }

  /// Handle login process
  Future<void> _login() async {
    if (_nipC.text.isEmpty || _passwordC.text.isEmpty) {
      _showSnackBar("NIP dan password harus diisi!", isError: true);
      return;
    }

    setState(() => _loading = true);

    try {
      debugPrint('🔐 Attempting login with NIP: ${_nipC.text}');
      
      final result = await _authService.login(
        nip: _nipC.text.trim(),
        password: _passwordC.text,
      );

      debugPrint('📨 Login Response: $result');

      if (result['success'] == true) {
        // Get role from secure storage (saved by AuthApiService)
        final userRole = await _getUserRole();

        if (userRole.isEmpty) {
          if (mounted) {
            _showSnackBar(
              'Login berhasil tapi role tidak ditemukan',
              isError: true,
            );
          }
          return;
        }

        final route = _getRouteByRole(userRole);

        if (mounted) {
          // Navigate to appropriate screen based on role
          Navigator.pushReplacementNamed(context, route);

          // Show success message
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    userRole == 'gudang'
                        ? '✅ Login gudang berhasil!'
                        : '✅ Login kasir berhasil!',
                  ),
                  backgroundColor: Colors.green,
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          });
        }
      } else {
        final errorMsg = result['error'] ?? 'Login gagal';
        debugPrint('❌ Login Error: $errorMsg');
        _showSnackBar(errorMsg, isError: true);
      }
    } catch (e) {
      debugPrint('❌ Login Exception: $e');
      _showSnackBar("Terjadi kesalahan: ${e.toString()}", isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xff2563eb), Color(0xff7c3aed)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
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
                      // Logo Icon
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.point_of_sale_rounded,
                          size: 64,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        "SuperCart POS",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Login to continue",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Login Form Card
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // NIP Field
                            TextField(
                              controller: _nipC,
                              enabled: !_loading,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                hintText: "NIP",
                                filled: true,
                                fillColor: Colors.grey[100],
                                prefixIcon: Icon(
                                  Icons.badge_outlined,
                                  color: Colors.blue[700],
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(
                                    color: Colors.blue[700]!,
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Password Field
                            TextField(
                              controller: _passwordC,
                              obscureText: _obscurePassword,
                              enabled: !_loading,
                              onSubmitted: (_) => _login(),
                              decoration: InputDecoration(
                                hintText: "Password",
                                filled: true,
                                fillColor: Colors.grey[100],
                                prefixIcon: Icon(
                                  Icons.lock_outline,
                                  color: Colors.blue[700],
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: Colors.grey[600],
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(
                                    color: Colors.blue[700]!,
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Login Button
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                onPressed: _loading ? null : _login,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xff2563eb),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 0,
                                ),
                                child: _loading
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2.5,
                                        ),
                                      )
                                    : const Text(
                                        "Login",
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
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
          ),
        ),
      ),
    );
  }
}