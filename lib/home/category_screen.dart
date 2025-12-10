import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supercart_pos/services/categories_api_services.dart';

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  final CategoriesApiService _apiService = CategoriesApiService();

  List<dynamic> categories = [];
  bool isLoading = false;

  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _fetchCategories() async {
    try {
      if (!mounted) return;
      setState(() => isLoading = true);

      final result = await _apiService.getCategories();

      if (!mounted) return;

      debugPrint('📂 Categories Response: $result');

      if (result['success'] == true) {
        setState(() {
          categories = result['data'] ?? [];
          isLoading = false;
        });
        debugPrint('✅ Kategori berhasil dimuat: ${categories.length} items');
      } else {
        setState(() => isLoading = false);
        final errorMsg = result['error'] ?? 'Gagal memuat kategori';
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

  Future<void> _createCategory() async {
    if (_nameController.text.isEmpty) {
      _showSnackBar("Nama kategori harus diisi");
      return;
    }

    try {
      final result = await _apiService.createCategory(
        name: _nameController.text,
        description: _descriptionController.text,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        _showSnackBar("Kategori berhasil ditambahkan");
        _clearForm();
        await _fetchCategories();
      } else {
        final errorMsg = result['error'] ?? "Gagal menambahkan kategori";
        debugPrint('❌ Error: $errorMsg');
        _showSnackBar(errorMsg);
      }
    } catch (e) {
      if (!mounted) return;
      debugPrint('❌ Exception: $e');
      _showSnackBar("Error: $e");
    }
  }

  Future<void> _updateCategory(int id) async {
    if (_nameController.text.isEmpty) {
      _showSnackBar("Nama kategori harus diisi");
      return;
    }

    try {
      final result = await _apiService.updateCategory(
        id: id,
        name: _nameController.text,
        description: _descriptionController.text,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        _showSnackBar("Kategori berhasil diupdate");
        await _fetchCategories();
      } else {
        final errorMsg = result['error'] ?? "Gagal mengupdate kategori";
        debugPrint('❌ Error: $errorMsg');
        _showSnackBar(errorMsg);
      }
    } catch (e) {
      if (!mounted) return;
      debugPrint('❌ Exception: $e');
      _showSnackBar("Error: $e");
    }
  }

  Future<void> _deleteCategory(int id) async {
    try {
      final result = await _apiService.deleteCategory(id);

      if (!mounted) return;

      if (result['success'] == true) {
        _showSnackBar("Kategori berhasil dihapus");
        await _fetchCategories();
      } else {
        final errorMsg = result['error'] ?? "Gagal menghapus kategori";
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
    _descriptionController.clear();
  }

  void _showForm({Map<String, dynamic>? item}) {
    _nameController.text = item?['name'] ?? "";
    _descriptionController.text = item?['description'] ?? "";

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
                  item == null ? "Tambah Kategori Baru" : "Edit Kategori",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: "Nama Kategori",
                    prefixIcon: const Icon(LucideIcons.tag),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _descriptionController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: "Deskripsi",
                    prefixIcon: const Icon(LucideIcons.fileText),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignLabelWithHint: true,
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
                              const Duration(milliseconds: 100));

                          if (item == null) {
                            await _createCategory();
                          } else {
                            await _updateCategory(item['id'] as int);
                          }
                        },
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          backgroundColor: const Color(0xff06b6d4),
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
        title: const Text('Manajemen Kategori'),
        backgroundColor: const Color(0xff06b6d4),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _clearForm();
          _showForm();
        },
        backgroundColor: const Color(0xff06b6d4),
        icon: const Icon(LucideIcons.plus),
        label: const Text('Tambah Kategori'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : categories.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        LucideIcons.tag,
                        size: 64,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Belum ada kategori',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: categories.length,
                  itemBuilder: (_, i) {
                    final item = categories[i];
                    final productCount =
                        item['_count']?['products'] as int? ?? 0;

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
                              const Color(0xff06b6d4).withOpacity(0.05),
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
                              color: const Color(0xff06b6d4).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              LucideIcons.tag,
                              color: Color(0xff06b6d4),
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
                              Text(
                                item['description'] ?? 'Tidak ada deskripsi',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      // ignore: deprecated_member_use
                                      const Color(0xff06b6d4).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'Produk: $productCount',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xff06b6d4),
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
                                      title:
                                          const Text("Konfirmasi Hapus"),
                                      content: Text(
                                        "Yakin ingin menghapus kategori '${item['name']}'?",
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context),
                                          child: const Text("Batal"),
                                        ),
                                        FilledButton(
                                          onPressed: () {
                                            Navigator.pop(context);
                                            _deleteCategory(
                                                item['id'] as int);
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