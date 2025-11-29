import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:fl_chart/fl_chart.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String selectedPeriod = "monthly";

  final monthlyEarnings = [
    {"month": "Jan", "earnings": 45000.0, "expenses": 28000.0},
    {"month": "Feb", "earnings": 52000.0, "expenses": 30000.0},
    {"month": "Mar", "earnings": 48000.0, "expenses": 29000.0},
    {"month": "Apr", "earnings": 61000.0, "expenses": 32000.0},
    {"month": "May", "earnings": 55000.0, "expenses": 31000.0},
    {"month": "Jun", "earnings": 67000.0, "expenses": 33000.0},
    {"month": "Jul", "earnings": 72000.0, "expenses": 35000.0},
    {"month": "Aug", "earnings": 68000.0, "expenses": 34000.0},
    {"month": "Sep", "earnings": 75000.0, "expenses": 36000.0},
    {"month": "Oct", "earnings": 82000.0, "expenses": 38000.0},
    {"month": "Nov", "earnings": 78000.0, "expenses": 37000.0},
    {"month": "Dec", "earnings": 91000.0, "expenses": 40000.0},
  ];

  final int warehouseStock = 856;
  final int storeStock = 374;

  @override
  Widget build(BuildContext context) {
    final double currentMonth = monthlyEarnings.last["earnings"] as double;
    final double previousMonth =
        monthlyEarnings[monthlyEarnings.length - 2]["earnings"] as double;
    final double growth =
        ((currentMonth - previousMonth) / previousMonth) * 100;

    return Scaffold(
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // FAB untuk Laporan Penjualan
          FloatingActionButton(
            heroTag: 'laporan',
            backgroundColor: const Color(0xff7c3aed),
            onPressed: () {
              Navigator.pushNamed(context, '/laporan');
            },
            child: const Icon(LucideIcons.fileText, color: Colors.white),
          ),
          const SizedBox(height: 12),
          // FAB untuk Transaksi
          FloatingActionButton(
            heroTag: 'transaksi',
            backgroundColor: const Color(0xff2563eb),
            onPressed: () {
              Navigator.pushNamed(context, '/cashier');
            },
            child: const Icon(LucideIcons.shoppingCart, color: Colors.white),
          ),
        ],
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
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xff2563eb), Color(0xff7c3aed)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Dashboard",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              GridView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.2,
                ),
                children: [
                  _metricCard(
                    title: "Monthly Earnings",
                    value: "\$${(currentMonth / 1000).toStringAsFixed(1)}k",
                    icon: LucideIcons.dollarSign,
                    gradient: const [Color(0xff3b82f6), Color(0xff2563eb)],
                    trailing: "+${growth.toStringAsFixed(1)}%",
                  ),
                  _metricCard(
                    title: "Warehouse Stock",
                    value: "$warehouseStock",
                    icon: LucideIcons.box,
                    gradient: const [Color(0xffa855f7), Color(0xff7e22ce)],
                    onTap: () => Navigator.pushNamed(context, '/warehouse'),
                  ),
                  _metricCard(
                    title: "Store Stock",
                    value: "$storeStock",
                    icon: LucideIcons.store,
                    gradient: const [Color(0xffec4899), Color(0xffbe185d)],
                  ),
                  _metricCard(
                    title: "Transactions",
                    value: "1458",
                    icon: LucideIcons.shoppingCart,
                    gradient: const [Color(0xfff59e0b), Color(0xffd97706)],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: _box(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Monthly Revenue",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 220,
                      child: LineChart(
                        LineChartData(
                          titlesData: FlTitlesData(
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: true),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  int index = value.toInt();
                                  if (index < monthlyEarnings.length) {
                                    return Text(
                                      monthlyEarnings[index]["month"]
                                          .toString(),
                                    );
                                  }
                                  return const SizedBox();
                                },
                              ),
                            ),
                          ),
                          lineBarsData: [
                            LineChartBarData(
                              spots: monthlyEarnings.asMap().entries.map((e) {
                                return FlSpot(
                                  e.key.toDouble(),
                                  (e.value["earnings"] as double),
                                );
                              }).toList(),
                              isCurved: true,
                              color: Colors.blue,
                              barWidth: 3,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: const Color(0xff2563eb),
                      ),
                      icon: const Icon(LucideIcons.shoppingCart),
                      label: const Text("New Sale"),
                      onPressed: () {
                        Navigator.pushNamed(context, '/cashier');
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      icon: const Icon(LucideIcons.package),
                      label: const Text("Manage Stock"),
                      onPressed: () {
                        Navigator.pushNamed(context, '/warehouse');
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _metricCard({
    required String title,
    required String value,
    required IconData icon,
    required List<Color> gradient,
    String? trailing,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: gradient),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: Colors.white, size: 30),
                if (trailing != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      trailing,
                      style: const TextStyle(color: Colors.white),
                    ),
                  )
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            Text(
              value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  BoxDecoration _box() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.shade300,
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }
}