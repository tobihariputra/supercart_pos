// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supercart_pos/services/transactions_api_services.dart';
import 'package:supercart_pos/core/app_config.dart';
import 'package:intl/intl.dart';

final rupiah = NumberFormat.currency(
  locale: 'id',
  symbol: 'Rp ',
  decimalDigits: 0,
);

class Product {
  final String id;
  final String name;
  final double price;
  final String category;
  final String image;
  final String? imageUrlPresigned;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.category,
    required this.image,
    this.imageUrlPresigned,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? 'Unknown',
      price: double.tryParse(json['selling_price']?.toString() ?? '0') ?? 0.0,
      category: json['category'] ?? json['categories']?['name'] ?? 'General',
      image:
          json['image_url'] ??
          json['image'] ??
          'https://via.placeholder.com/400',
      imageUrlPresigned: json['image_url_presigned'],
    );
  }
}

class CartItem {
  final String id;
  final String name;
  final double price;
  int quantity;
  final String image;
  final String? imageUrlPresigned;

  CartItem({
    required this.id,
    required this.name,
    required this.price,
    required this.quantity,
    required this.image,
    this.imageUrlPresigned,
  });
}

class CashierScreen extends StatefulWidget {
  const CashierScreen({super.key});

  @override
  State<CashierScreen> createState() => _CashierScreenState();
}

class _CashierScreenState extends State<CashierScreen>
    with SingleTickerProviderStateMixin {
  final TransactionApiService _apiService = TransactionApiService();
  final storage = const FlutterSecureStorage();
  late final Dio _dio;

  final List<CartItem> _cart = [];
  String _selectedCategory = "All";
  String _searchQuery = "";
  late AnimationController _cartAnimationController;

  List<Product> _products = [];
  List<Product> _allProducts = [];
  List<String> _categories = ["All"];
  bool _isLoading = true;
  String? _errorMessage;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _cartAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _setupDio();
    _fetchProducts();
  }

  void _setupDio() {
    _dio = Dio();
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await storage.read(key: 'auth_token');

          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          options.headers['Content-Type'] = 'application/json';
          options.headers['Accept'] = 'application/json';

          return handler.next(options);
        },
        onError: (error, handler) {
          return handler.next(error);
        },
      ),
    );
  }

  @override
  void dispose() {
    _cartAnimationController.dispose();
    super.dispose();
  }

  Future<void> _fetchProducts() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final response = await _dio.get('${AppConfig.baseUrl}/products/fetch');

      if (response.statusCode == 200) {
        final jsonData = response.data;

        List<Product> products = [];
        Set<String> categorySet = {'All'};

        if (jsonData['result'] != null && jsonData['result']['data'] != null) {
          final List<dynamic> items = jsonData['result']['data'];
          products = items.map((item) => Product.fromJson(item)).toList();

          for (var product in products) {
            categorySet.add(product.category);
          }
        }

        setState(() {
          _allProducts = products;
          _products = products;
          _categories = categorySet.toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load products (${response.statusCode})';
          _isLoading = false;
        });
      }
    } on DioException catch (e) {
      setState(() {
        if (e.response?.statusCode == 401) {
          _errorMessage = 'Unauthorized. Please login again';
        } else if (e.type == DioExceptionType.connectionTimeout) {
          _errorMessage = 'Connection timeout';
        } else if (e.type == DioExceptionType.receiveTimeout) {
          _errorMessage = 'Server not responding';
        } else {
          _errorMessage = 'Error: ${e.message}';
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _addToCart(Product product) {
    setState(() {
      final existingIndex = _cart.indexWhere((item) => item.id == product.id);
      if (existingIndex != -1) {
        _cart[existingIndex].quantity++;
      } else {
        _cart.add(
          CartItem(
            id: product.id,
            name: product.name,
            price: product.price,
            quantity: 1,
            image: product.image,
            imageUrlPresigned: product.imageUrlPresigned,
          ),
        );
      }
    });
    _cartAnimationController.forward(from: 0);
  }

  void _updateQuantity(String id, int change) {
    setState(() {
      final index = _cart.indexWhere((item) => item.id == id);
      if (index != -1) {
        _cart[index].quantity += change;
        if (_cart[index].quantity <= 0) {
          _cart.removeAt(index);
        }
      }
    });
  }

  void _removeFromCart(String id) {
    setState(() {
      _cart.removeWhere((item) => item.id == id);
    });
  }

  double get _subtotal =>
      _cart.fold(0, (sum, item) => sum + (item.price * item.quantity));
  double get _tax => _subtotal * 0.1;
  double get _total => _subtotal + _tax;

  List<Product> get _filteredProducts {
    return _products.where((product) {
      final matchesCategory =
          _selectedCategory == "All" || product.category == _selectedCategory;
      final matchesSearch = product.name.toLowerCase().contains(
        _searchQuery.toLowerCase(),
      );
      return matchesCategory && matchesSearch;
    }).toList();
  }

  void _updateCategory(String category) {
    setState(() {
      _selectedCategory = category;
      if (category == "All") {
        _products = _allProducts;
      } else {
        _products = _allProducts.where((p) => p.category == category).toList();
      }
    });
  }

  Future<void> _submitTransaction(
    String paymentMethod,
    double paymentAmount,
    String notes,
  ) async {
    if (_cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Keranjang masih kosong'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final items = _cart.map((item) {
        return {
          'product_id': int.parse(item.id),
          'quantity': item.quantity,
          'unit_price': item.price,
          'discount': 0,
        };
      }).toList();

      final response = await _apiService.createTransaction(
        items: items,
        discountAmount: 0,
        paymentMethod: paymentMethod,
        paymentAmount: paymentAmount,
        notes: notes,
      );

      if (mounted) {
        if (response['success'] == true) {
          final transactionData = response['data']['transaction'];
          final transactionNo = transactionData['transaction_no'];

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Transaction $transactionNo created successfully'),
              backgroundColor: Colors.green[700],
              duration: const Duration(seconds: 3),
            ),
          );

          final totalItems = transactionData['total_items'];
          final totalAmount = transactionData['total_amount'];

          setState(() {
            _cart.clear();
          });

          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green[600], size: 28),
                  const SizedBox(width: 8),

                  // ⬇️ Tambahan kecil untuk cegah overflow
                  const Expanded(
                    child: Text(
                      'Transaction Successful',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              // ⬇️ Tambahan kecil: bungkus content agar tidak overflow
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDialogRow('Transaction No:', transactionNo),
                    const SizedBox(height: 8),

                    _buildDialogRow('Total Items:', '$totalItems'),
                    const SizedBox(height: 8),

                    _buildDialogRow(
                      'Total Amount:',
                      'Rp ${double.parse(totalAmount).toStringAsFixed(0)}',
                    ),
                    const SizedBox(height: 8),

                    _buildDialogRow('Payment:', paymentMethod.toUpperCase()),
                    const SizedBox(height: 8),

                    _buildDialogRow(
                      'Payment Amount:',
                      'Rp ${double.parse(paymentAmount.toStringAsFixed(0)).toStringAsFixed(0)}',
                    ),
                  ],
                ),
              ),

              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                response['error'] ?? 'Failed to create transaction',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Widget _buildDialogRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
        ),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ],
    );
  }

  void _showPaymentDialog() {
    if (_cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Keranjang masih kosong'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    String selectedPayment = 'cash';
    TextEditingController amountController = TextEditingController(
      text: _total.toStringAsFixed(0),
    );
    TextEditingController notesController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Payment Method',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                Column(
                  children: [
                    RadioListTile<String>(
                      title: const Text('Cash'),
                      value: 'cash',
                      groupValue: selectedPayment,
                      onChanged: (value) => setModalState(
                        () => selectedPayment = value ?? 'cash',
                      ),
                    ),
                    RadioListTile<String>(
                      title: const Text('Card'),
                      value: 'card',
                      groupValue: selectedPayment,
                      onChanged: (value) => setModalState(
                        () => selectedPayment = value ?? 'card',
                      ),
                    ),
                    RadioListTile<String>(
                      title: const Text('Transfer'),
                      value: 'transfer',
                      groupValue: selectedPayment,
                      onChanged: (value) => setModalState(
                        () => selectedPayment = value ?? 'transfer',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                const Text(
                  'Payment Amount',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: 'Enter payment amount',
                    prefixText: 'Rp ',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                const Text(
                  'Notes (Optional)',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: notesController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'Add notes for this transaction',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Subtotal'),
                          Text('Rp${_subtotal.toStringAsFixed(0)}'),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Tax (10%)'),
                          Text('Rp${_tax.toStringAsFixed(0)}'),
                        ],
                      ),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            'Rp${_total.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Color(0xff2563eb),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isProcessing
                            ? null
                            : () {
                                final paymentAmount =
                                    double.tryParse(
                                      amountController.text.replaceAll(
                                        RegExp(r'[^0-9]'),
                                        '',
                                      ),
                                    ) ??
                                    _total;

                                if (paymentAmount < _total) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Jumlah pembayaran kurang'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                  return;
                                }

                                Navigator.pop(context);
                                _submitTransaction(
                                  selectedPayment,
                                  paymentAmount,
                                  notesController.text,
                                );
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xff2563eb),
                        ),
                        child: _isProcessing
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
                            : const Text(
                                'Confirm Payment',
                                style: TextStyle(color: Colors.white),
                              ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF8FAFC), Color(0xFFF1F5F9)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildSearchBar(),
              _buildCategories(),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _errorMessage != null
                    ? _buildErrorWidget()
                    : _filteredProducts.isEmpty
                    ? _buildNoProductsWidget()
                    : _buildProductsGrid(),
              ),
              if (_cart.isNotEmpty) _buildCartSummary(),
              if (_cart.isEmpty && !_isLoading) _buildEmptyCart(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              _errorMessage ?? 'An error occurred',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF475569)),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _fetchProducts, child: const Text('Retry')),
          if (_errorMessage?.contains('Unauthorized') == true) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/login');
              },
              child: const Text('Go to Login'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNoProductsWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.inventory_2_outlined,
            size: 48,
            color: Color(0xFFCBD5E1),
          ),
          const SizedBox(height: 16),
          const Text(
            'No products found',
            style: TextStyle(color: Color(0xFF475569), fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Colors.blue[600]!, Colors.purple[700]!],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "CashierPro",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "New Transaction",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Stack(
            children: [
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.shopping_cart, color: Colors.white),
              ),
              if (_cart.isNotEmpty)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Text(
                      '${_cart.fold(0, (sum, item) => sum + item.quantity)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TextField(
          onChanged: (value) => setState(() => _searchQuery = value),
          decoration: InputDecoration(
            hintText: "Search products...",
            prefixIcon: const Icon(Icons.search, color: Color(0xFF94A3B8)),
            suffixIcon: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue[600],
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white),
                onPressed: _fetchProducts,
              ),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
          ),
        ),
      ),
    );
  }

  Widget _buildCategories() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: SizedBox(
        height: 45,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: _categories.length,
          itemBuilder: (context, index) {
            final category = _categories[index];
            final isSelected = _selectedCategory == category;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => _updateCategory(category),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? LinearGradient(
                            colors: [Colors.blue[600]!, Colors.purple[700]!],
                          )
                        : null,
                    color: isSelected ? null : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? Colors.transparent
                          : const Color(0xFFCBD5E1),
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: Colors.blue.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      category,
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : const Color(0xFF334155),
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildProductsGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _filteredProducts.length,
      itemBuilder: (context, index) {
        final product = _filteredProducts[index];
        final imageUrl = product.imageUrlPresigned ?? product.image;

        return GestureDetector(
          onTap: () => _addToCart(product),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Image
                Expanded(
                  child: Stack(
                    children: [
                      Container(
                        decoration: const BoxDecoration(
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(20),
                            topRight: Radius.circular(20),
                          ),
                          color: Color(0xFFF1F5F9),
                        ),
                        child: ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(20),
                            topRight: Radius.circular(20),
                          ),
                          child: Image.network(
                            imageUrl,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Center(
                                child: Icon(
                                  Icons.image_not_supported,
                                  color: Color(0xFFCBD5E1),
                                  size: 40,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue[600],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            product.category,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Product Info
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Rp ${product.price.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCartSummary() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
        border: Border(top: BorderSide(color: Colors.blue[600]!, width: 4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Current Order",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "${_cart.fold(0, (sum, item) => sum + item.quantity)} items",
                    style: TextStyle(
                      color: Colors.blue[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Cart Items List
            SizedBox(
              height: 160,
              child: ListView.builder(
                itemCount: _cart.length,
                itemBuilder: (context, index) {
                  final item = _cart[index];
                  final itemImageUrl = item.imageUrlPresigned ?? item.image;

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            itemImageUrl,
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 40,
                              height: 40,
                              color: Colors.grey[300],
                              child: const Icon(Icons.image),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                "Rp${item.price.toStringAsFixed(0)}",
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              onPressed: () => _updateQuantity(item.id, -1),
                              icon: const Icon(Icons.remove_circle_outline),
                              color: Colors.red[400],
                            ),
                            Text(
                              item.quantity.toString(),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            IconButton(
                              onPressed: () => _updateQuantity(item.id, 1),
                              icon: const Icon(Icons.add_circle_outline),
                              color: Colors.green[400],
                            ),
                          ],
                        ),
                        IconButton(
                          onPressed: () => _removeFromCart(item.id),
                          icon: const Icon(Icons.delete, color: Colors.red),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            const Divider(),
            _summaryRow("Subtotal", _subtotal),
            _summaryRow("Tax (10%)", _tax),
            const Divider(),
            _summaryRow("Total", _total, isBold: true),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.payment, color: Colors.white),
                label: const Text(
                  "Proceed to Payment",
                  style: TextStyle(color: Colors.white),
                ),
                onPressed: _showPaymentDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff2563eb),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(String label, double value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: isBold ? 16 : 14,
            ),
          ),
          Text(
            "Rp${value.toStringAsFixed(0)}",
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: isBold ? 16 : 14,
              color: isBold ? const Color(0xff2563eb) : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCart() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: const Center(
        child: Text(
          "Keranjang masih kosong",
          style: TextStyle(color: Colors.grey, fontSize: 14),
        ),
      ),
    );
  }
}
