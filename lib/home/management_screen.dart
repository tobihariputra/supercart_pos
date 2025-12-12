// ignore_for_file: unused_local_variable, deprecated_member_use

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supercart_pos/services/categories_api_services.dart';
import 'package:supercart_pos/services/product_api_service.dart';
import 'package:supercart_pos/services/supplier_api_services.dart';

class ManagementScreen extends StatefulWidget {
  const ManagementScreen({super.key});

  @override
  State<ManagementScreen> createState() => _ManagementScreenState();
}

class _ManagementScreenState extends State<ManagementScreen> {
  final ProductApiService _productApiService = ProductApiService();
  final CategoriesApiService _categoriesApiService = CategoriesApiService();
  final SupplierApiService _supplierApiService = SupplierApiService();
  final ImagePicker _imagePicker = ImagePicker();

  List<dynamic> products = [];
  List<dynamic> categories = [];
  List<dynamic> suppliers = [];
  bool isLoading = false;
  bool isProcessing = false;

  final _nameController = TextEditingController();
  final _barcodeController = TextEditingController();
  final _stockController = TextEditingController();
  final _minStockController = TextEditingController();
  final _priceController = TextEditingController();

  int? selectedCategory;
  int? selectedSupplier;
  File? selectedImage;
  String? existingImageUrl;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await Future.wait([
      fetchProducts(),
      fetchCategories(),
      fetchSuppliers(),
    ]);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _barcodeController.dispose();
    _stockController.dispose();
    _minStockController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  // ================= IMAGE PICKER =================

  Future<void> pickImage(StateSetter dialogSetState) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (image != null) {
        dialogSetState(() {
          selectedImage = File(image.path);
        });
      }
    } catch (e) {
      _showSnackBar('Error picking image: $e', isError: true);
    }
  }

  Future<void> takePhoto(StateSetter dialogSetState) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );

      if (image != null) {
        dialogSetState(() {
          selectedImage = File(image.path);
        });
      }
    } catch (e) {
      _showSnackBar('Error taking photo: $e', isError: true);
    }
  }

  void clearImage(StateSetter dialogSetState) {
    dialogSetState(() {
      selectedImage = null;
    });
  }

  // ================= FETCH =================

  Future<void> fetchProducts() async {
    if (!mounted || isLoading) return;

    setState(() => isLoading = true);

    try {
      final result = await _productApiService.getProducts(limit: 100);

      if (!mounted) return;

      if (result['success'] == true) {
        setState(() {
          products =
              (result['data'] as List?)?.cast<Map<String, dynamic>>() ?? [];
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
        _showSnackBar(result['error'] ?? 'Gagal memuat produk', isError: true);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      _showSnackBar("Error: $e", isError: true);
    }
  }

  Future<void> fetchCategories() async {
    if (!mounted) return;

    try {
      final result = await _categoriesApiService.getCategories();

      if (!mounted) return;

      if (result['success'] == true) {
        setState(() {
          categories =
              (result['data'] as List?)?.cast<Map<String, dynamic>>() ?? [];
        });
      }
    } catch (e) {
      debugPrint('Error fetching categories: $e');
    }
  }

  Future<void> fetchSuppliers() async {
    if (!mounted) return;

    try {
      final result = await _supplierApiService.getSuppliers();

      if (!mounted) return;

      if (result['success'] == true) {
        setState(() {
          suppliers =
              (result['data'] as List?)?.cast<Map<String, dynamic>>() ?? [];
        });
      }
    } catch (e) {
      debugPrint('Error fetching suppliers: $e');
    }
  }

  // ================= IMAGE MANAGEMENT DIALOG =================

  void _showImageManagementDialog(Map<String, dynamic> item) {
    selectedImage = null;
    existingImageUrl = item['image_url_presigned'] ?? 
        item['image_url'] ?? 
        item['image'];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, dialogSetState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            padding: const EdgeInsets.all(24),
            constraints: const BoxConstraints(maxWidth: 450),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Kelola Foto Produk",
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Color(0xffa855f7),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item['name'] ?? 'Unknown Product',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          selectedImage = null;
                          Navigator.pop(dialogContext);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Image Preview
                  Container(
                    width: double.infinity,
                    height: 280,
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xffa855f7), width: 2),
                      borderRadius: BorderRadius.circular(16),
                      color: Colors.grey[50],
                    ),
                    child: selectedImage != null
                        ? Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: Image.file(
                                  selectedImage!,
                                  width: double.infinity,
                                  height: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: GestureDetector(
                                  onTap: () => clearImage(dialogSetState),
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.red.shade400,
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.red.withOpacity(0.3),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : existingImageUrl != null && existingImageUrl != ''
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: Image.network(
                                  existingImageUrl!,
                                  width: double.infinity,
                                  height: double.infinity,
                                  fit: BoxFit.cover,
                                  loadingBuilder: (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Center(
                                      child: CircularProgressIndicator(
                                        value: loadingProgress.expectedTotalBytes != null
                                            ? loadingProgress.cumulativeBytesLoaded /
                                                loadingProgress.expectedTotalBytes!
                                            : null,
                                        color: const Color(0xffa855f7),
                                      ),
                                    );
                                  },
                                  errorBuilder: (context, error, stackTrace) {
                                    return Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(LucideIcons.image, size: 48, color: Colors.grey[400]),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Gagal memuat gambar',
                                            style: TextStyle(color: Colors.grey[600]),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              )
                            : Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(LucideIcons.image, size: 56, color: Colors.grey[400]),
                                    const SizedBox(height: 12),
                                    Text(
                                      'Belum ada gambar',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                  ),
                  const SizedBox(height: 20),

                  // Delete Image Button (if existing image)
                  if (existingImageUrl != null && existingImageUrl != '')
                    Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: isProcessing
                                ? null
                                : () async {
                                    Navigator.pop(dialogContext);
                                    await _deleteImage(item['id'] as int);
                                  },
                            icon: const Icon(LucideIcons.trash2),
                            label: const Text('Hapus Foto Saat Ini'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: const BorderSide(color: Colors.red, width: 1.5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              foregroundColor: Colors.red,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),

                  // Pick Image Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: isProcessing ? null : () => pickImage(dialogSetState),
                          icon: const Icon(LucideIcons.image),
                          label: const Text('Galeri'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xffa855f7),
                            side: const BorderSide(color: Color(0xffa855f7), width: 1.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: isProcessing ? null : () => takePhoto(dialogSetState),
                          icon: const Icon(LucideIcons.camera),
                          label: const Text('Kamera'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xffa855f7),
                            side: const BorderSide(color: Color(0xffa855f7), width: 1.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Upload Button (if image selected)
                  if (selectedImage != null)
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: isProcessing
                            ? null
                            : () async {
                                Navigator.pop(dialogContext);
                                await _uploadImage(item['id'] as int);
                              },
                        icon: isProcessing
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(LucideIcons.upload),
                        label: const Text('Upload Foto'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: const Color(0xffa855f7),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _uploadImage(int productId) async {
    if (selectedImage == null || isProcessing) return;

    setState(() => isProcessing = true);

    try {
      final result = await _productApiService.uploadImage(
        productId: productId,
        imageFile: selectedImage!,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        _showSnackBar("Foto berhasil diupload");
        selectedImage = null;
        await fetchProducts();
      } else {
        _showSnackBar(
          result['error'] ?? "Gagal upload foto",
          isError: true,
        );
      }

      setState(() => isProcessing = false);
    } catch (e) {
      if (!mounted) return;
      setState(() => isProcessing = false);
      _showSnackBar("Error: $e", isError: true);
    }
  }

  Future<void> _deleteImage(int productId) async {
    if (isProcessing) return;

    setState(() => isProcessing = true);

    try {
      final result = await _productApiService.deleteProductImage(productId);

      if (!mounted) return;

      if (result['success'] == true) {
        _showSnackBar("Foto berhasil dihapus");
        await fetchProducts();
      } else {
        _showSnackBar(
          result['error'] ?? "Gagal menghapus foto",
          isError: true,
        );
      }

      setState(() => isProcessing = false);
    } catch (e) {
      if (!mounted) return;
      setState(() => isProcessing = false);
      _showSnackBar("Error: $e", isError: true);
    }
  }

  // ================= CREATE =================

  Future<void> createProduct() async {
    if (isProcessing) return;

    if (_nameController.text.trim().isEmpty ||
        _barcodeController.text.trim().isEmpty) {
      _showSnackBar("Nama dan Barcode harus diisi", isError: true);
      return;
    }

    setState(() => isProcessing = true);

    try {
      final result = await _productApiService.createProduct(
        barcode: _barcodeController.text.trim(),
        name: _nameController.text.trim(),
        categoryId: selectedCategory ?? 0,
        supplierId: selectedSupplier ?? 0,
        stockQuantity: int.tryParse(_stockController.text.trim()) ?? 0,
        minStock: int.tryParse(_minStockController.text.trim()) ?? 0,
        maxStock: 500,
        unit: "pcs",
        purchasePrice: 2500,
        sellingPrice: int.tryParse(_priceController.text.trim()) ?? 0,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        _showSnackBar("Produk berhasil ditambahkan");
        clearForm();
        await fetchProducts();
      } else {
        _showSnackBar(
          result['error'] ?? "Gagal menambahkan produk",
          isError: true,
        );
      }

      setState(() => isProcessing = false);
    } catch (e) {
      if (!mounted) return;
      setState(() => isProcessing = false);
      _showSnackBar("Error: $e", isError: true);
    }
  }

  // ================= UPDATE =================

  Future<void> updateProduct(int id, int index) async {
    if (isProcessing) return;

    setState(() => isProcessing = true);

    try {
      final result = await _productApiService.updateProduct(
        id: id,
        barcode: _barcodeController.text.trim(),
        name: _nameController.text.trim(),
        categoryId: selectedCategory ?? 0,
        supplierId: selectedSupplier ?? 0,
        stockQuantity: int.tryParse(_stockController.text.trim()) ?? 0,
        minStock: int.tryParse(_minStockController.text.trim()) ?? 0,
        maxStock: 500,
        unit: "pcs",
        purchasePrice: 2500,
        sellingPrice: int.tryParse(_priceController.text.trim()) ?? 0,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        _showSnackBar("Produk berhasil diupdate");
        clearForm();
        await fetchProducts();
      } else {
        _showSnackBar(
          result['error'] ?? "Gagal mengupdate produk",
          isError: true,
        );
      }

      setState(() => isProcessing = false);
    } catch (e) {
      if (!mounted) return;
      setState(() => isProcessing = false);
      _showSnackBar("Error: $e", isError: true);
    }
  }

  // ================= DELETE =================

  Future<void> deleteProduct(int id, int index) async {
    if (isProcessing) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi'),
        content: const Text('Apakah Anda yakin ingin menghapus produk ini?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => isProcessing = true);

    try {
      final result = await _productApiService.deleteProduct(id);

      if (!mounted) return;

      setState(() => isProcessing = false);

      if (result['success'] == true) {
        _showSnackBar("Produk berhasil dihapus");
        clearForm();
        await fetchProducts();
      } else {
        _showSnackBar(
          result['error'] ?? "Gagal menghapus produk",
          isError: true,
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => isProcessing = false);
      _showSnackBar("Error: $e", isError: true);
    }
  }

  // ================= HELPER =================

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? Colors.red : Colors.green,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void clearForm() {
    _nameController.clear();
    _barcodeController.clear();
    _stockController.clear();
    _minStockController.clear();
    _priceController.clear();
    selectedCategory = null;
    selectedSupplier = null;
    selectedImage = null;
    existingImageUrl = null;
  }

  String _generateBarcode() {
    final random = DateTime.now().millisecondsSinceEpoch;
    final barcode = (random % 9999999999999).toString().padLeft(13, '0');
    return barcode;
  }

  void showForm({Map<String, dynamic>? item, int? index}) {
    _nameController.text = item?['name'] ?? "";
    _barcodeController.text = item?['barcode'] ?? _generateBarcode();
    _stockController.text = item?['stock_quantity']?.toString() ?? "";
    _minStockController.text = item?['min_stock']?.toString() ?? "";
    _priceController.text = item?['selling_price']?.toString() ?? "";
    selectedCategory = item?['category_id'];
    selectedSupplier = item?['supplier_id'];
    selectedImage = null;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, dialogSetState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            constraints: const BoxConstraints(maxWidth: 500),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        item == null ? "Tambah Produk Baru" : "Edit Produk",
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          clearForm();
                          Navigator.pop(dialogContext);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // ========== FORM FIELDS ==========
                  TextField(
                    controller: _barcodeController,
                    readOnly: item != null,
                    decoration: InputDecoration(
                      labelText: "Barcode",
                      prefixIcon: const Icon(LucideIcons.scan),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      suffixIcon: item == null
                          ? IconButton(
                              icon: const Icon(Icons.refresh),
                              onPressed: () {
                                dialogSetState(() {
                                  _barcodeController.text = _generateBarcode();
                                });
                              },
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: "Nama Produk",
                      prefixIcon: const Icon(LucideIcons.package),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _stockController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: "Stok",
                            prefixIcon: const Icon(LucideIcons.box),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _minStockController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: "Min Stok",
                            prefixIcon: const Icon(LucideIcons.alertTriangle),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _priceController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: "Harga Jual",
                      prefixIcon: const Icon(LucideIcons.dollarSign),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    value: selectedCategory,
                    hint: const Text("Pilih Kategori"),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(LucideIcons.tag),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: categories
                        .map<DropdownMenuItem<int>>(
                          (e) => DropdownMenuItem<int>(
                            value: e['id'] as int,
                            child: Text(e['name'] ?? 'Unknown'),
                          ),
                        )
                        .toList(),
                    onChanged: (val) =>
                        dialogSetState(() => selectedCategory = val),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    value: selectedSupplier,
                    hint: const Text("Pilih Supplier"),
                    isExpanded: true,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(LucideIcons.building2),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: suppliers
                        .map<DropdownMenuItem<int>>(
                          (e) => DropdownMenuItem<int>(
                            value: e['id'] as int,
                            child: Text(
                              e['name'] ?? 'Unknown',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (val) =>
                        dialogSetState(() => selectedSupplier = val),
                  ),
                  const SizedBox(height: 24),

                  // ========== ACTION BUTTONS ==========
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: isProcessing
                              ? null
                              : () {
                                  clearForm();
                                  Navigator.pop(dialogContext);
                                },
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
                          onPressed: isProcessing
                              ? null
                              : () async {
                                  Navigator.pop(dialogContext);

                                  if (item == null) {
                                    await createProduct();
                                  } else {
                                    await updateProduct(
                                      item['id'] as int,
                                      index ?? -1,
                                    );
                                  }
                                },
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            backgroundColor: const Color(0xffa855f7),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: isProcessing
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Text("Simpan"),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _summaryItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalStock = products.fold<int>(
      0,
      (sum, item) => sum + ((item['stock_quantity'] as num?)?.toInt() ?? 0),
    );
    final lowStock = products
        .where(
          (e) =>
              ((e['stock_quantity'] as num?)?.toInt() ?? 0) <=
              ((e['min_stock'] as num?)?.toInt() ?? 0),
        )
        .length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manajemen Gudang'),
        backgroundColor: const Color(0xffa855f7),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.tag),
            onPressed: () async {
              await Navigator.pushNamed(context, '/categories');
              await fetchCategories();
            },
            tooltip: 'Manajemen Kategori',
          ),
          IconButton(
            icon: const Icon(LucideIcons.building2),
            onPressed: () async {
              await Navigator.pushNamed(context, '/suppliers');
              await fetchSuppliers();
            },
            tooltip: 'Manajemen Supplier',
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: isProcessing
            ? null
            : () {
                clearForm();
                showForm();
              },
        backgroundColor: const Color(0xffa855f7),
        icon: const Icon(LucideIcons.plus),
        label: const Text('Tambah Produk'),
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xffa855f7), Color(0xff7e22ce)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xffa855f7).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _summaryItem(
                  'Total Produk',
                  '${products.length}',
                  LucideIcons.package,
                ),
                _summaryItem('Total Stok', '$totalStock', LucideIcons.box),
                _summaryItem(
                  'Low Stock',
                  '$lowStock',
                  LucideIcons.alertTriangle,
                ),
              ],
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : products.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              LucideIcons.package,
                              size: 64,
                              color: Colors.grey[300],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Belum ada produk',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[500],
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextButton.icon(
                              onPressed: fetchProducts,
                              icon: const Icon(LucideIcons.refreshCw),
                              label: const Text('Refresh'),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: fetchProducts,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(8),
                          itemCount: products.length,
                          itemBuilder: (_, i) {
                            final item = products[i];
                            final stock =
                                (item['stock_quantity'] as num?)?.toInt() ?? 0;
                            final minStock =
                                (item['min_stock'] as num?)?.toInt() ?? 0;
                            final isLow = stock <= minStock;
                            final imageUrl = item['image_url_presigned'] ??
                                item['image_url'] ??
                                item['image'];

                            return Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 6,
                              ),
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                leading: Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: imageUrl != null && imageUrl != ''
                                          ? const Color(0xffa855f7)
                                          : Colors.transparent,
                                      width: 2,
                                    ),
                                  ),
                                  child: imageUrl != null && imageUrl != ''
                                      ? ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(6),
                                          child: Image.network(
                                            imageUrl,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error,
                                                stackTrace) {
                                              return Icon(
                                                LucideIcons.image,
                                                color: Colors.grey[400],
                                              );
                                            },
                                          ),
                                        )
                                      : Icon(
                                          LucideIcons.image,
                                          color: Colors.grey[400],
                                        ),
                                ),
                                title: Text(
                                  item['name'] ?? 'Unknown',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            LucideIcons.box,
                                            size: 14,
                                            color: Colors.grey[600],
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            'Stok: $stock',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: isLow
                                                  ? Colors.red
                                                  : Colors.grey[600],
                                              fontWeight: isLow
                                                  ? FontWeight.bold
                                                  : FontWeight.normal,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            LucideIcons.tag,
                                            size: 14,
                                            color: Colors.grey[600],
                                          ),
                                          const SizedBox(width: 6),
                                          Flexible(
                                            child: Text(
                                              'Kategori: ${item['categories']?['name'] ?? '-'}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[600],
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: Icon(
                                        imageUrl != null && imageUrl != ''
                                            ? LucideIcons.check
                                            : LucideIcons.upload,
                                        color: imageUrl != null &&
                                                imageUrl != ''
                                            ? Colors.green
                                            : Colors.orange,
                                      ),
                                      onPressed: isProcessing
                                          ? null
                                          : () =>
                                              _showImageManagementDialog(item),
                                      tooltip: 'Kelola Foto',
                                    ),
                                    IconButton(
                                      icon: const Icon(LucideIcons.edit),
                                      color: Colors.blue,
                                      onPressed: isProcessing
                                          ? null
                                          : () =>
                                              showForm(item: item, index: i),
                                    ),
                                    IconButton(
                                      icon: const Icon(LucideIcons.trash2),
                                      color: Colors.red,
                                      onPressed: isProcessing
                                          ? null
                                          : () =>
                                              deleteProduct(item['id'] as int, i),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
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