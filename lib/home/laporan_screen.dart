// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supercart_pos/services/transactions_api_services.dart';
import 'package:intl/intl.dart';

class LaporanScreen extends StatefulWidget {
  const LaporanScreen({super.key});

  @override
  State<LaporanScreen> createState() => _LaporanScreenState();
}

class _LaporanScreenState extends State<LaporanScreen> {
  final TransactionApiService _transactionApiService = TransactionApiService();
  
  List<Map<String, dynamic>> transactions = [];
  List<Map<String, dynamic>> filteredTransactions = [];
  
  bool isLoading = false;
  String searchQuery = '';
  String selectedStatus = 'Semua';
  DateTimeRange? selectedDateRange;

  @override
  void initState() {
    super.initState();
    fetchTransactions();
  }

  Future<void> fetchTransactions() async {
    if (!mounted || isLoading) return;

    setState(() => isLoading = true);

    try {
      final result = await _transactionApiService.getTransactions(limit: 1000);

      if (!mounted) return;

      if (result['success'] == true) {
        setState(() {
          transactions = (result['data'] as List?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ?? [];
          _applyFilters();
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
        _showSnackBar(result['error'] ?? 'Gagal memuat transaksi', isError: true);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      _showSnackBar("Error: $e", isError: true);
    }
  }

  void _applyFilters() {
    filteredTransactions = transactions.where((t) {
      if (searchQuery.isNotEmpty) {
        final id = (t['id'] ?? '').toString().toLowerCase();
        final transNo = (t['transaction_no'] ?? '').toString().toLowerCase();
        if (!id.contains(searchQuery.toLowerCase()) &&
            !transNo.contains(searchQuery.toLowerCase())) {
          return false;
        }
      }

      if (selectedStatus != 'Semua') {
        if (t['status'] != selectedStatus) return false;
      }

      if (selectedDateRange != null) {
        try {
          final transDate = DateTime.parse(t['created_at'].toString().split(' ')[0]);
          if (transDate.isBefore(selectedDateRange!.start) ||
              transDate.isAfter(selectedDateRange!.end)) {
            return false;
          }
        } catch (e) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  void _onSearchChanged(String value) {
    setState(() {
      searchQuery = value;
      _applyFilters();
    });
  }

  void _onStatusFilterChanged(String? value) {
    if (value != null) {
      setState(() {
        selectedStatus = value;
        _applyFilters();
      });
    }
  }

  Future<void> _selectDateRange() async {
    final result = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: selectedDateRange,
    );

    if (result != null) {
      setState(() {
        selectedDateRange = result;
        _applyFilters();
      });
    }
  }

  void _clearFilters() {
    setState(() {
      searchQuery = '';
      selectedStatus = 'Semua';
      selectedDateRange = null;
      _applyFilters();
    });
  }

  double _getTotalRevenue() {
    return filteredTransactions.fold(0.0, (sum, item) {
      final amount = item['total_amount'];
      double value = 0;
      if (amount is num) {
        value = amount.toDouble();
      } else if (amount is String) {
        value = double.tryParse(amount) ?? 0;
      }
      return sum + value;
    });
  }

  int _getTotalTransactions() => filteredTransactions.length;

  double _getAverageTransaction() =>
      filteredTransactions.isEmpty ? 0 : _getTotalRevenue() / filteredTransactions.length;

  String _formatCurrency(dynamic value) {
    double amount = 0;
    if (value is num) {
      amount = value.toDouble();
    } else if (value is String) {
      amount = double.tryParse(value) ?? 0;
    }
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  String _formatDate(String? date) {
    if (date == null) return '-';
    try {
      final dateTime = DateTime.parse(date);
      return DateFormat('dd MMM yyyy', 'id_ID').format(dateTime);
    } catch (e) {
      return date;
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? Colors.red : null,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _exportReport() async {
    if (filteredTransactions.isEmpty) {
      _showSnackBar('Tidak ada data untuk diekspor', isError: true);
      return;
    }

    try {
      StringBuffer csv = StringBuffer();
      csv.writeln('ID,Nomor Transaksi,Tanggal,Total,Items,Status');
      for (var t in filteredTransactions) {
        csv.writeln(
          '${t['id']},${t['transaction_no']},${_formatDate(t['created_at'])},${t['total_amount']},${t['items_count'] ?? 0},${t['status']}',
        );
      }
      _showSnackBar('Data siap untuk diekspor');
    } catch (e) {
      _showSnackBar('Gagal mengekspor data: $e', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Penjualan'),
        backgroundColor: const Color(0xff7c3aed),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw),
            onPressed: isLoading ? null : fetchTransactions,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xfff5f3ff), Color(0xffefe5ff)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // ========== HEADER WITH STATS ==========
                    _buildStatsHeader(),
                    const SizedBox(height: 24),

                    // ========== FILTERS ==========
                    _buildFiltersSection(),
                    const SizedBox(height: 24),

                    // ========== TRANSACTIONS TABLE ==========
                    _buildTransactionsSection(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatsHeader() {
    return Column(
      children: [
        _statsCard(
          icon: LucideIcons.dollarSign,
          label: 'Total Revenue',
          value: _formatCurrency(_getTotalRevenue()),
          color: const Color(0xff2563eb),
        ),
        const SizedBox(height: 12),
        _statsCard(
          icon: LucideIcons.shoppingCart,
          label: 'Total Transaksi',
          value: '${_getTotalTransactions()}',
          color: const Color(0xff7c3aed),
        ),
        const SizedBox(height: 12),
        _statsCard(
          icon: LucideIcons.trendingUp,
          label: 'Rata-rata Transaksi',
          value: _formatCurrency(_getAverageTransaction()),
          color: const Color(0xff10b981),
        ),
      ],
    );
  }

  Widget _statsCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filter Laporan',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xff1e293b),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Cari nomor transaksi...',
                    prefixIcon: const Icon(LucideIcons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xffe2e8f0)),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onChanged: _onSearchChanged,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: selectedStatus,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(LucideIcons.filter),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xffe2e8f0)),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  items: ['Semua', 'Pending', 'Selesai', 'Dibatalkan']
                      .map((status) => DropdownMenuItem(
                            value: status,
                            child: Text(status),
                          ))
                      .toList(),
                  onChanged: _onStatusFilterChanged,
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: _selectDateRange,
                icon: const Icon(LucideIcons.calendar),
                label: const Text('Tanggal'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (searchQuery.isNotEmpty ||
                  selectedStatus != 'Semua' ||
                  selectedDateRange != null)
                OutlinedButton.icon(
                  onPressed: _clearFilters,
                  icon: const Icon(LucideIcons.x),
                  label: const Text('Reset'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: _exportReport,
                icon: const Icon(LucideIcons.download),
                label: const Text('Export'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xff7c3aed),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xfff8fafc),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: const Text(
              'Daftar Transaksi',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Color(0xff1e293b),
              ),
            ),
          ),
          if (filteredTransactions.isEmpty)
            Padding(
              padding: const EdgeInsets.all(48),
              child: Column(
                children: [
                  Icon(
                    LucideIcons.packageX,
                    size: 56,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Tidak ada transaksi',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredTransactions.length,
              separatorBuilder: (_, __) => Divider(
                height: 1,
                color: Colors.grey.shade100,
              ),
              itemBuilder: (context, index) {
                final t = filteredTransactions[index];
                return InkWell(
                  onTap: () => _showTransactionDetail(t),
                  hoverColor: const Color(0xfff5f3ff),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Row 1: ID dan Status
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'No. Transaksi',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade600,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    t['transaction_no'] ?? t['id'].toString(),
                                    style: const TextStyle(
                                      color: Color(0xff2563eb),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: _getStatusColor(t['status'])
                                    .withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                t['status'] ?? '-',
                                style: TextStyle(
                                  color: _getStatusColor(t['status']),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Row 2: Tanggal dan Items
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Tanggal',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade600,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _formatDate(t['created_at']),
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Color(0xff1e293b),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Items',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade600,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${t['items_count'] ?? 0} item',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Color(0xff1e293b),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Row 3: Total
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatCurrency(t['total_amount']),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: Color(0xff7c3aed),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'selesai':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'dibatalkan':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _showTransactionDetail(Map<String, dynamic> t) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xff7c3aed),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                LucideIcons.receipt,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text('Detail ${t['transaction_no'] ?? t['id']}'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _detailRow('No. Transaksi:', t['transaction_no'] ?? '-'),
              _detailRow('ID:', t['id'].toString()),
              _detailRow('Tanggal:', _formatDate(t['created_at'])),
              _detailRow('Jumlah Items:', '${t['items_count'] ?? 0}'),
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                height: 1,
                color: Colors.grey.shade200,
              ),
              _detailRow('Total:', _formatCurrency(t['total_amount']),
                  isBold: true),
              _detailRow('Status:', t['status'] ?? '-'),
              if (t['notes'] != null && t['notes'].toString().isNotEmpty)
                _detailRow('Catatan:', t['notes'].toString()),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xff1e293b),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                color: isBold ? const Color(0xff7c3aed) : Colors.grey.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}