import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class LaporanScreen extends StatefulWidget {
  const LaporanScreen({super.key});

  @override
  State<LaporanScreen> createState() => _LaporanScreenState();
}

class _LaporanScreenState extends State<LaporanScreen> {
  final List<Map<String, dynamic>> transactions = [
    {"id": "TRX001", "date": "2024-01-15", "items": 5, "total": 12500000, "status": "Selesai"},
    {"id": "TRX002", "date": "2024-01-15", "items": 3, "total": 8750000, "status": "Selesai"},
    {"id": "TRX003", "date": "2024-01-14", "items": 2, "total": 5000000, "status": "Selesai"},
    {"id": "TRX004", "date": "2024-01-14", "items": 7, "total": 15300000, "status": "Selesai"},
    {"id": "TRX005", "date": "2024-01-13", "items": 4, "total": 9200000, "status": "Selesai"},
  ];

  double _getTotalRevenue() =>
      transactions.fold(0, (sum, item) => sum + item['total']);

  int _getTotalTransactions() => transactions.length;

  double _getAverageTransaction() =>
      transactions.isEmpty ? 0 : _getTotalRevenue() / transactions.length;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isTablet = width >= 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Penjualan'),
        backgroundColor: const Color(0xff7c3aed),
        foregroundColor: Colors.white,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          int gridCount = 1;
          if (constraints.maxWidth >= 900) {
            gridCount = 4;
          } else if (constraints.maxWidth >= 600) {
            gridCount = 3;
          } else {
            gridCount = 2;
          }

          return Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xfff8fafc), Color(0xffe2e8f0)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: gridCount,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: isTablet ? 1.8 : 1.4,
                  children: [
                    _summaryCard(
                      title: 'Total Revenue',
                      value:
                          'Rp ${(_getTotalRevenue() / 1000000).toStringAsFixed(1)}M',
                      icon: LucideIcons.dollarSign,
                      color: const Color(0xff2563eb),
                    ),
                    _summaryCard(
                      title: 'Transactions',
                      value: '${_getTotalTransactions()}',
                      icon: LucideIcons.shoppingCart,
                      color: const Color(0xff7c3aed),
                    ),
                    _summaryCard(
                      title: 'Avg Transaction',
                      value:
                          'Rp ${(_getAverageTransaction() / 1000000).toStringAsFixed(1)}M',
                      icon: LucideIcons.trendingUp,
                      color: const Color(0xff10b981),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.shade300,
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              decoration: InputDecoration(
                                hintText: 'Cari transaksi...',
                                prefixIcon: const Icon(LucideIcons.search),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                contentPadding:
                                    const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          OutlinedButton.icon(
                            onPressed: () {},
                            icon: const Icon(LucideIcons.filter),
                            label: const Text('Filter'),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton.icon(
                            onPressed: () {},
                            icon: const Icon(LucideIcons.download),
                            label: const Text('Export'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    color: Colors.white,
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          color: Colors.grey.shade100,
                          child: Row(
                            children: [
                              Expanded(flex: isTablet ? 2 : 3, child: const Text('ID')),
                              Expanded(flex: 2, child: const Text('Tanggal')),
                              Expanded(flex: 1, child: const Text('Items')),
                              Expanded(flex: 2, child: const Text('Total')),
                              Expanded(flex: 1, child: const Text('Status')),
                            ],
                          ),
                        ),
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: transactions.length,
                          separatorBuilder: (context, index) => Divider(
                            height: 1,
                            color: Colors.grey.shade200,
                          ),
                          itemBuilder: (context, index) {
                            final t = transactions[index];
                            return InkWell(
                              onTap: () => _showTransactionDetail(t),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: isTablet ? 2 : 3,
                                      child: Text(
                                        t['id'],
                                        style: const TextStyle(
                                          color: Color(0xff2563eb),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(t['date']),
                                    ),
                                    Expanded(
                                      flex: 1,
                                      child: Text('${t['items']}'),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        'Rp ${t['total']}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 1,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.green.shade50,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          t['status'],
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: Colors.green.shade700,
                                            fontSize: isTablet ? 14 : 11,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _summaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isTablet = constraints.maxWidth >= 150;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.shade300,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: isTablet ? 32 : 24),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: isTablet ? 13 : 11,
                    ),
                  ),
                  Text(
                    value,
                    style: TextStyle(
                      color: color,
                      fontSize: isTablet ? 20 : 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showTransactionDetail(Map<String, dynamic> t) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Detail ${t['id']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tanggal: ${t['date']}'),
            Text('Items: ${t['items']}'),
            Text('Total: Rp ${t['total']}'),
            Text('Status: ${t['status']}'),
          ],
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
}
