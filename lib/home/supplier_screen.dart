import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supercart_pos/services/supplier_api_services.dart';

class SupplierScreen extends StatefulWidget {
  const SupplierScreen({super.key});

  @override
  State<SupplierScreen> createState() => _SupplierScreenState();
}

class _SupplierScreenState extends State<SupplierScreen> {
  final SupplierApiService _apiService = SupplierApiService();

  List<dynamic> suppliers = [];
  bool isLoading = false;

  final _nameController = TextEditingController();
  final _contactPersonController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchSuppliers();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contactPersonController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _fetchSuppliers() async {
    try {
      if (!mounted) return;
      setState(() => isLoading = true);

      final result = await _apiService.getSuppliers();

      if (!mounted) return;

      debugPrint('🏢 Suppliers Response: $result');

      if (result['success'] == true) {
        setState(() {
          suppliers = result['data'] ?? [];
          isLoading = false;
        });
        debugPrint('✅ Supplier berhasil dimuat: ${suppliers.length} items');
      } else {
        setState(() => isLoading = false);
        final errorMsg = result['error'] ?? 'Gagal memuat supplier';
        debugPrint('❌ Error: $errorMsg');
        _showSnackBar(errorMsg);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      debugPrint('❌ Exception: $e');
      _showSnackBar("Error: $e");
    }
  }

  Future<void> _createSupplier() async {
    if (_nameController.text.isEmpty) {
      _showSnackBar("Nama supplier harus diisi");
      return;
    }

    try {
      final result = await _apiService.createSupplier(
        name: _nameController.text,
        contactPerson: _contactPersonController.text.isEmpty
            ? null
            : _contactPersonController.text,
        phone: _phoneController.text.isEmpty ? null : _phoneController.text,
        address: _addressController.text.isEmpty
            ? null
            : _addressController.text,
        email: _emailController.text.isEmpty ? null : _emailController.text,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        _showSnackBar("Supplier berhasil ditambahkan");
        _clearForm();
        await _fetchSuppliers();
      } else {
        final errorMsg = result['error'] ?? "Gagal menambahkan supplier";
        debugPrint('❌ Error: $errorMsg');
        _showSnackBar(errorMsg);
      }
    } catch (e) {
      if (!mounted) return;
      debugPrint('❌ Exception: $e');
      _showSnackBar("Error: $e");
    }
  }

  Future<void> _updateSupplier(int id) async {
    if (_nameController.text.isEmpty) {
      _showSnackBar("Nama supplier harus diisi");
      return;
    }

    try {
      final result = await _apiService.updateSupplier(
        id: id,
        name: _nameController.text,
        contactPerson: _contactPersonController.text.isEmpty
            ? null
            : _contactPersonController.text,
        phone: _phoneController.text.isEmpty ? null : _phoneController.text,
        address: _addressController.text.isEmpty
            ? null
            : _addressController.text,
        email: _emailController.text.isEmpty ? null : _emailController.text,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        _showSnackBar("Supplier berhasil diupdate");
        _clearForm();
        await _fetchSuppliers();
      } else {
        final errorMsg = result['error'] ?? "Gagal mengupdate supplier";
        debugPrint('❌ Error: $errorMsg');
        _showSnackBar(errorMsg);
      }
    } catch (e) {
      if (!mounted) return;
      debugPrint('❌ Exception: $e');
      _showSnackBar("Error: $e");
    }
  }

  Future<void> _deleteSupplier(int id) async {
    try {
      final result = await _apiService.deleteSupplier(id);

      if (!mounted) return;

      if (result['success'] == true) {
        _showSnackBar("Supplier berhasil dihapus");
        await _fetchSuppliers();
      } else {
        final errorMsg = result['error'] ?? "Gagal menghapus supplier";
        debugPrint('❌ Error: $errorMsg');
        _showSnackBar(errorMsg);
      }
    } catch (e) {
      if (!mounted) return;
      debugPrint('❌ Exception: $e');
      _showSnackBar("Error: $e");
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _clearForm() {
    _nameController.clear();
    _contactPersonController.clear();
    _phoneController.clear();
    _addressController.clear();
    _emailController.clear();
  }

  void _showForm({Map<String, dynamic>? item}) {
    _nameController.text = item?['name'] ?? "";
    _contactPersonController.text = item?['contact_person'] ?? "";
    _phoneController.text = item?['phone'] ?? "";
    _addressController.text = item?['address'] ?? "";
    _emailController.text = item?['email'] ?? "";

    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item == null ? "Tambah Supplier Baru" : "Edit Supplier",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: "Nama Supplier",
                    prefixIcon: const Icon(LucideIcons.building2),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _contactPersonController,
                  decoration: InputDecoration(
                    labelText: "Contact Person (Opsional)",
                    prefixIcon: const Icon(LucideIcons.user),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: "Phone (Opsional)",
                    prefixIcon: const Icon(LucideIcons.phone),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _addressController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: "Alamat (Opsional)",
                    prefixIcon: const Icon(LucideIcons.mapPin),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: "Email (Opsional)",
                    prefixIcon: const Icon(LucideIcons.mail),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text("Batal"),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () async {
                          Navigator.pop(dialogContext);
                          await Future.delayed(
                            const Duration(milliseconds: 100),
                          );

                          if (item == null) {
                            await _createSupplier();
                          } else {
                            await _updateSupplier(item['id'] as int);
                          }
                        },
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          backgroundColor: const Color(0xfff97316),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text("Simpan"),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manajemen Supplier'),
        backgroundColor: const Color(0xfff97316),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _clearForm();
          _showForm();
        },
        backgroundColor: const Color(0xfff97316),
        icon: const Icon(LucideIcons.plus),
        label: const Text('Tambah Supplier'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : suppliers.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    LucideIcons.building2,
                    size: 64,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Belum ada supplier',
                    style: TextStyle(fontSize: 16, color: Colors.grey[500]),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: suppliers.length,
              itemBuilder: (_, i) {
                final item = suppliers[i];
                final productCount = item['_count']?['products'] as int? ?? 0;

                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 0,
                    vertical: 8,
                  ),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(
                        colors: [
                          // ignore: deprecated_member_use
                          const Color(0xfff97316).withOpacity(0.05),
                          Colors.transparent,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          // ignore: deprecated_member_use
                          color: const Color(0xfff97316).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          LucideIcons.building2,
                          color: Color(0xfff97316),
                          size: 20,
                        ),
                      ),
                      title: Text(
                        item['name'] ?? 'Unknown',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 6),
                          if (item['contact_person'] != null)
                            Row(
                              children: [
                                Icon(
                                  LucideIcons.user,
                                  size: 14,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  item['contact_person'],
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          const SizedBox(height: 4),
                          if (item['phone'] != null)
                            Row(
                              children: [
                                Icon(
                                  LucideIcons.phone,
                                  size: 14,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  item['phone'],
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  // ignore: deprecated_member_use
                                  const Color(0xfff97316).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Produk: $productCount',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xfff97316),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(LucideIcons.edit),
                            color: Colors.blue,
                            onPressed: () => _showForm(item: item),
                          ),
                          IconButton(
                            icon: const Icon(LucideIcons.trash2),
                            color: Colors.red,
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: const Text("Konfirmasi Hapus"),
                                  content: Text(
                                    "Yakin ingin menghapus supplier '${item['name']}'?",
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text("Batal"),
                                    ),
                                    FilledButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                        _deleteSupplier(item['id'] as int);
                                      },
                                      style: FilledButton.styleFrom(
                                        backgroundColor: Colors.red,
                                      ),
                                      child: const Text("Hapus"),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
