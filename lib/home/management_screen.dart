import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class ManagementScreen extends StatefulWidget {
  const ManagementScreen({super.key});

  @override
  State<ManagementScreen> createState() => _ManagementScreenState();
}

class _ManagementScreenState extends State<ManagementScreen> {
  final List<Map<String, dynamic>> stocks = [
    {"id": 1, "name": "Laptop HP", "category": "Electronics", "stock": 15, "minStock": 5},
    {"id": 2, "name": "Mouse Logitech", "category": "Accessories", "stock": 50, "minStock": 20},
    {"id": 3, "name": "Keyboard Mechanical", "category": "Accessories", "stock": 30, "minStock": 15},
    {"id": 4, "name": "Monitor LG 24\"", "category": "Electronics", "stock": 20, "minStock": 10},
    {"id": 5, "name": "Webcam HD", "category": "Electronics", "stock": 25, "minStock": 10},
  ];

  final _nameController = TextEditingController();
  final _categoryController = TextEditingController();
  final _stockController = TextEditingController();
  final _minStockController = TextEditingController();

  void _showAddDialog() {
    _nameController.clear();
    _categoryController.clear();
    _stockController.clear();
    _minStockController.clear();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tambah Produk'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nama Produk',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _categoryController,
                decoration: const InputDecoration(
                  labelText: 'Kategori',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _stockController,
                decoration: const InputDecoration(
                  labelText: 'Stok',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _minStockController,
                decoration: const InputDecoration(
                  labelText: 'Minimal Stok',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                stocks.add({
                  "id": stocks.length + 1,
                  "name": _nameController.text,
                  "category": _categoryController.text,
                  "stock": int.parse(_stockController.text),
                  "minStock": int.parse(_minStockController.text),
                });
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Produk berhasil ditambahkan!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(int index) {
    final item = stocks[index];
    _nameController.text = item['name'];
    _categoryController.text = item['category'];
    _stockController.text = item['stock'].toString();
    _minStockController.text = item['minStock'].toString();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Produk'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nama Produk',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _categoryController,
                decoration: const InputDecoration(
                  labelText: 'Kategori',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _stockController,
                decoration: const InputDecoration(
                  labelText: 'Stok',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _minStockController,
                decoration: const InputDecoration(
                  labelText: 'Minimal Stok',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                stocks[index] = {
                  "id": item['id'],
                  "name": _nameController.text,
                  "category": _categoryController.text,
                  "stock": int.parse(_stockController.text),
                  "minStock": int.parse(_minStockController.text),
                };
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Produk berhasil diupdate!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _deleteItem(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Produk'),
        content: Text('Yakin ingin menghapus ${stocks[index]['name']}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                stocks.removeAt(index);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Produk berhasil dihapus!'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manajemen Gudang'),
        backgroundColor: const Color(0xffa855f7),
        foregroundColor: Colors.white,
        actions: [], // <-- hapus icon + di kanan atas
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDialog,
        backgroundColor: const Color(0xffa855f7),
        icon: const Icon(LucideIcons.plus),
        label: const Text('Tambah Produk'),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xfff8fafc), Color(0xffe2e8f0)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            // Summary
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xffa855f7), Color(0xff7e22ce)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _summaryItem('Total Produk', '${stocks.length}', LucideIcons.package),
                  Container(width: 1, height: 40, color: Colors.white24),
                  _summaryItem('Total Stok', '${stocks.fold(0, (sum, item) => sum + (item['stock'] as int))}', LucideIcons.box),
                  Container(width: 1, height: 40, color: Colors.white24),
                  _summaryItem('Low Stock', '${stocks.where((item) => item['stock'] <= item['minStock']).length}', LucideIcons.alertTriangle),
                ],
              ),
            ),
            
            // Stock List
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
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
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                        ),
                      ),
                      child: const Row(
                        children: [
                          Expanded(flex: 3, child: Text('Produk', style: TextStyle(fontWeight: FontWeight.bold))),
                          Expanded(flex: 2, child: Text('Kategori', style: TextStyle(fontWeight: FontWeight.bold))),
                          Expanded(child: Text('Stok', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                          Expanded(flex: 2, child: Text('Aksi', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.separated(
                        itemCount: stocks.length,
                        separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey.shade200),
                        itemBuilder: (context, index) {
                          final item = stocks[index];
                          final isLowStock = item['stock'] <= item['minStock'];
                          
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.purple.shade50,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Icon(
                                          LucideIcons.package,
                                          color: Colors.purple.shade700,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          item['name'],
                                          style: const TextStyle(fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      item['category'],
                                      style: TextStyle(
                                        color: Colors.blue.shade700,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isLowStock ? Colors.red.shade50 : Colors.green.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '${item['stock']}',
                                      style: TextStyle(
                                        color: isLowStock ? Colors.red.shade700 : Colors.green.shade700,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      IconButton(
                                        icon: const Icon(LucideIcons.edit, size: 18),
                                        onPressed: () => _showEditDialog(index),
                                        color: Colors.blue,
                                      ),
                                      IconButton(
                                        icon: const Icon(LucideIcons.trash2, size: 18),
                                        onPressed: () => _deleteItem(index),
                                        color: Colors.red,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _summaryItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
