import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:supercart_pos/services/dashboard_api_services.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DashboardApiService _apiService = DashboardApiService();
  
  bool _isLoading = true;
  String? _errorMessage;
  
  // Data dari API - My Performance
  double _myTotalSales = 0;
  int _myTotalTransactions = 0;
  int _myTotalItems = 0;
  double _myAverageTransaction = 0;
  
  // Data dari API - Overall Performance
  double _overallTotalSales = 0;
  int _overallTotalTransactions = 0;
  int _overallTotalItems = 0;
  double _overallAverageTransaction = 0;
  
  // Data tambahan
  List<Map<String, dynamic>> _paymentMethods = [];
  List<Map<String, dynamic>> _topProducts = [];
  List<Map<String, dynamic>> _hourlySales = [];
  
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
      final response = await _apiService.getDashboardCashier();

      if (response['success'] == true && response['data'] != null) {
        final data = response['data'];
        
        setState(() {
          // My Performance
          final myPerf = data['my_performance'] ?? {};
          _myTotalSales = _toDouble(myPerf['total_sales']);
          _myTotalTransactions = _toInt(myPerf['total_transactions']);
          _myTotalItems = _toInt(myPerf['total_items']);
          _myAverageTransaction = _toDouble(myPerf['average_transaction']);
          
          // Overall Performance
          final overallPerf = data['overall_performance'] ?? {};
          _overallTotalSales = _toDouble(overallPerf['total_sales']);
          _overallTotalTransactions = _toInt(overallPerf['total_transactions']);
          _overallTotalItems = _toInt(overallPerf['total_items']);
          _overallAverageTransaction = _toDouble(overallPerf['average_transaction']);
          
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
          
          // Hourly Sales
          if (data['hourly_sales'] != null && data['hourly_sales'] is List) {
            _hourlySales = List<Map<String, dynamic>>.from(
              (data['hourly_sales'] as List).map((e) => _toMap(e))
            );
          }
          
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = response['error'] ?? 'Gagal memuat data';
          _isLoading = false;
        });
      }
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

          // My Performance Section
          _buildSectionTitle("My Performance"),
          const SizedBox(height: 12),
          _buildMyPerformanceGrid(),
          const SizedBox(height: 20),

          // Overall Performance Section
          _buildSectionTitle("Overall Performance"),
          const SizedBox(height: 12),
          _buildOverallPerformanceGrid(),
          const SizedBox(height: 20),

          // Hourly Sales Chart
          if (_hourlySales.isNotEmpty) ...[
            _buildHourlySalesChart(),
            const SizedBox(height: 20),
          ],

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
            color: Colors.black.withValues(alpha: 0.1),
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
              color: Colors.blue.withValues(alpha: 0.2),
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
                  "Overview & Analytics",
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
            icon: const Icon(LucideIcons.refreshCw, color: Colors.white),
            onPressed: _loadDashboardData,
            tooltip: 'Refresh',
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xff1e293b),
        ),
      ),
    );
  }

  Widget _buildMyPerformanceGrid() {
    return GridView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.3,
      ),
      children: [
        _metricCard(
          title: "My Total Sales",
          value: _formatCurrency(_myTotalSales),
          icon: LucideIcons.dollarSign,
          gradient: const [Color(0xff3b82f6), Color(0xff2563eb)],
        ),
        _metricCard(
          title: "My Transactions",
          value: "$_myTotalTransactions",
          icon: LucideIcons.shoppingCart,
          gradient: const [Color(0xffa855f7), Color(0xff7e22ce)],
        ),
        _metricCard(
          title: "Items Sold",
          value: "$_myTotalItems",
          icon: LucideIcons.package,
          gradient: const [Color(0xffec4899), Color(0xffbe185d)],
        ),
        _metricCard(
          title: "Avg Transaction",
          value: _formatCurrency(_myAverageTransaction),
          icon: LucideIcons.trendingUp,
          gradient: const [Color(0xfff59e0b), Color(0xffd97706)],
        ),
      ],
    );
  }

  Widget _buildOverallPerformanceGrid() {
    return GridView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.3,
      ),
      children: [
        _metricCard(
          title: "Total Sales",
          value: _formatCurrency(_overallTotalSales),
          icon: LucideIcons.dollarSign,
          gradient: const [Color(0xff10b981), Color(0xff059669)],
        ),
        _metricCard(
          title: "Total Transactions",
          value: "$_overallTotalTransactions",
          icon: LucideIcons.shoppingBag,
          gradient: const [Color(0xff06b6d4), Color(0xff0891b2)],
        ),
        _metricCard(
          title: "Total Items",
          value: "$_overallTotalItems",
          icon: LucideIcons.package2,
          gradient: const [Color(0xff8b5cf6), Color(0xff7c3aed)],
        ),
        _metricCard(
          title: "Avg Transaction",
          value: _formatCurrency(_overallAverageTransaction),
          icon: LucideIcons.barChart3,
          gradient: const [Color(0xffef4444), Color(0xffdc2626)],
        ),
      ],
    );
  }

  Widget _metricCard({
    required String title,
    required String value,
    required IconData icon,
    required List<Color> gradient,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradient),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHourlySalesChart() {
    if (_hourlySales.isEmpty) {
      return const SizedBox();
    }

    // Filter data yang valid
    final validData = _hourlySales
        .where((e) {
          final sales = _toDouble(e['sales']);
          return sales > 0;
        })
        .toList();

    if (validData.isEmpty) {
      return const SizedBox();
    }

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
              Icon(LucideIcons.clock, size: 20, color: Color(0xff2563eb)),
              SizedBox(width: 8),
              Text(
                "Hourly Sales",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(color: Colors.grey.shade200, strokeWidth: 1);
                  },
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 50,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          _formatCurrency(value),
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        int index = value.toInt();
                        if (index >= 0 && index < validData.length) {
                          final hour = _toInt(validData[index]['hour']);
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              '$hour:00',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.grey,
                              ),
                            ),
                          );
                        }
                        return const SizedBox();
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: validData.asMap().entries.map((e) {
                      return FlSpot(
                        e.key.toDouble(),
                        _toDouble(e.value['sales']),
                      );
                    }).toList(),
                    isCurved: true,
                    color: const Color(0xff2563eb),
                    barWidth: 3,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: const Color(0xff2563eb).withValues(alpha: 0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
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
                "Payment Methods",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ..._paymentMethods.map((method) {
            // Try different keys for method name
            final methodName = method['method']?.toString() ?? 
                             method['payment_method']?.toString() ?? 
                             method['name']?.toString() ?? 
                             method['type']?.toString() ??
                             'Unknown';
            
            // Try different keys for total
            final total = _toDouble(method['total'] ?? 
                                   method['amount'] ?? 
                                   method['total_amount'] ?? 
                                   0);
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    methodName,
                    style: const TextStyle(fontSize: 14),
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
                "Top Products",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ..._topProducts.asMap().entries.map((entry) {
            final index = entry.key;
            final product = entry.value;
            
            // Extract product name dari berbagai kemungkinan struktur
            String name = 'Unknown Product';
            
            // Cek apakah ada nested product object
            if (product['product'] != null) {
              final nestedProduct = product['product'];
              if (nestedProduct is Map) {
                name = nestedProduct['name']?.toString() ?? 'Unknown Product';
              }
            }
            
            // Fallback ke field langsung
            if (name == 'Unknown Product') {
              name = product['name']?.toString() ?? 
                    product['product_name']?.toString() ?? 
                    product['item_name']?.toString() ??
                    'Unknown Product';
            }
            
            // Try different keys for quantity
            final quantity = _toInt(product['quantity'] ?? 
                                   product['qty'] ?? 
                                   product['total_quantity'] ?? 
                                   0);
            
            // Try different keys for total sales
            final totalSales = _toDouble(product['total_sales'] ?? 
                                        product['total'] ?? 
                                        product['amount'] ?? 
                                        product['total_amount'] ?? 
                                        0);

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: const Color(0xff2563eb).withValues(alpha: 0.1),
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
}