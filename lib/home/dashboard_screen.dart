// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supercart_pos/services/dashboard_api_services.dart';
import 'package:supercart_pos/services/transactions_api_services.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DashboardApiService _apiService = DashboardApiService();
  final TransactionApiService _transactionApiService = TransactionApiService();
  
  bool _isLoading = true;
  String? _errorMessage;
  
  // Data untuk daily sales (overall performance)
  double _totalDailySales = 0;
  int _totalDailyTransactions = 0;
  int _totalDailyItems = 0;
  double _averageDailyTransaction = 0;
  
  // Data tambahan
  List<Map<String, dynamic>> _paymentMethods = [];
  List<Map<String, dynamic>> _topProducts = [];
  
  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Load dashboard data
      final dashboardResponse = await _apiService.getDashboardCashier();
      
      // Load transactions untuk daily sales chart
      await _transactionApiService.getTransactions(limit: 1000);


      if (dashboardResponse['success'] == true && dashboardResponse['data'] != null) {
        final data = dashboardResponse['data'];
        
        setState(() {
          // Overall Performance (Penjualan Hari Ini)
          final overallPerf = data['overall_performance'] ?? {};
          _totalDailySales = _toDouble(overallPerf['total_sales']);
          _totalDailyTransactions = _toInt(overallPerf['total_transactions']);
          _totalDailyItems = _toInt(overallPerf['total_items']);
          _averageDailyTransaction = _toDouble(overallPerf['average_transaction']);
          
          // Payment Methods
          if (data['payment_methods'] != null && data['payment_methods'] is List) {
            _paymentMethods = List<Map<String, dynamic>>.from(
              (data['payment_methods'] as List).map((e) => _toMap(e))
            );
          }
          
          // Top Products
          if (data['top_products'] != null && data['top_products'] is List) {
            _topProducts = List<Map<String, dynamic>>.from(
              (data['top_products'] as List).map((e) => _toMap(e))
            );
          }
        });
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Terjadi kesalahan: $e';
        _isLoading = false;
      });
    }
  }

  // Helper functions untuk convert type
  double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  Map<String, dynamic> _toMap(dynamic value) {
    if (value is Map) return Map<String, dynamic>.from(value);
    return {};
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/cashier'),
        backgroundColor: const Color(0xff2563eb),
        elevation: 8,
        icon: const Icon(LucideIcons.shoppingCart, color: Colors.white),
        label: const Text(
          "New Sale",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xfff8fafc), Color(0xffe2e8f0)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? _buildLoadingState()
              : _errorMessage != null
                  ? _buildErrorState()
                  : _buildContent(),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(
            "Memuat dashboard...",
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.alertCircle,
              size: 64,
              color: Colors.red.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadDashboardData,
              icon: const Icon(LucideIcons.refreshCw),
              label: const Text("Coba Lagi"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff2563eb),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header
          _buildHeader(),
          const SizedBox(height: 20),

          // Daily Sales Summary
          _buildDailySalesSummary(),
          const SizedBox(height: 20),



          // Payment Methods
          if (_paymentMethods.isNotEmpty) ...[
            _buildPaymentMethods(),
            const SizedBox(height: 20),
          ],

          // Top Products
          if (_topProducts.isNotEmpty) ...[
            _buildTopProducts(),
            const SizedBox(height: 80),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xff2563eb), Color(0xff7c3aed)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.dashboard_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Dashboard",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "Penjualan Harian",
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(LucideIcons.fileText, color: Colors.white),
            onPressed: () => Navigator.pushNamed(context, '/laporan'),
            tooltip: 'Sales Report',
          ),
          IconButton(
            icon: const Icon(LucideIcons.logOut, color: Colors.white),
            onPressed: () {
              _showLogoutDialog();
            },
            tooltip: 'Logout',
          ),
        ],
      ),
    );
  }

  Widget _buildDailySalesSummary() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xff2563eb), Color(0xff7c3aed)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                LucideIcons.calendar,
                color: Colors.white,
                size: 24,
              ),
              SizedBox(width: 12),
              Text(
                'Penjualan Hari Ini',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _formatCurrency(_totalDailySales),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _summaryItem(
                label: 'Transaksi',
                value: '$_totalDailyTransactions',
              ),
              _summaryItem(
                label: 'Item Terjual',
                value: '$_totalDailyItems',
              ),
              _summaryItem(
                label: 'Rata-rata',
                value: _formatCurrency(_averageDailyTransaction),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryItem({required String label, required String value}) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 12,
          ),
        ),
      ],
    );
  }



  Widget _buildPaymentMethods() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(LucideIcons.creditCard, size: 20, color: Color(0xff2563eb)),
              SizedBox(width: 8),
              Text(
                "Metode Pembayaran",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ..._paymentMethods.map((method) {
            final methodName = method['payment_method']?.toString() ?? 
                             method['method']?.toString() ?? 
                             method['name']?.toString() ?? 
                             'Unknown';
            
            final total = _toDouble(method['total_amount'] ?? 
                                   method['total'] ?? 
                                   method['amount'] ?? 
                                   0);
            
            final transactionCount = _toInt(method['transaction_count'] ?? 0);
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        methodName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '$transactionCount transaksi',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    _formatCurrency(total),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xff2563eb),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTopProducts() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(LucideIcons.trendingUp, size: 20, color: Color(0xff2563eb)),
              SizedBox(width: 8),
              Text(
                "Produk Top",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ..._topProducts.asMap().entries.map((entry) {
            final index = entry.key;
            final product = entry.value;
            
            // Extract product information
            String name = 'Unknown Product';
            
            if (product['product'] != null && product['product'] is Map) {
              final prodMap = product['product'];
              name = prodMap['name']?.toString() ?? 'Unknown Product';
            }
            
            final quantity = _toInt(product['total_quantity'] ?? 0);
            final totalSales = _toDouble(product['total_sales'] ?? 0);

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: const Color(0xff2563eb).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xff2563eb),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '$quantity terjual',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    _formatCurrency(totalSales),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xff2563eb),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Apakah Anda yakin ingin logout?'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/login',
                (route) => false,
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}