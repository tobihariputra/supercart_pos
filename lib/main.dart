import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supercart_pos/features/auth/login_screen.dart';
import 'package:supercart_pos/home/category_screen.dart';
import 'package:supercart_pos/home/dashboard_screen.dart';
import 'package:supercart_pos/home/cashier_screen.dart';
import 'package:supercart_pos/home/laporan_screen.dart';
import 'package:supercart_pos/home/management_screen.dart';
import 'package:supercart_pos/home/supplier_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load file .env
  await dotenv.load(fileName: ".env");

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Supercart POS',

      // Gunakan initialRoute untuk navigasi awal
      initialRoute: '/login',

      // Daftar routes
      routes: {
        '/login': (context) => const LoginScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/cashier': (context) => const CashierScreen(),
        '/laporan': (context) => const LaporanScreen(),
        '/management': (context) => const ManagementScreen(),
        '/categories': (context) => const CategoryScreen(),
        '/suppliers': (context) => const SupplierScreen(),
      },
    );
  }
}