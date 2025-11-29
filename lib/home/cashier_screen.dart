// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

class Product {
  final String id;
  final String name;
  final double price;
  final String category;
  final String image;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.category,
    required this.image,
  });
}

class CartItem {
  final String id;
  final String name;
  final double price;
  int quantity;
  final String image;

  CartItem({
    required this.id,
    required this.name,
    required this.price,
    required this.quantity,
    required this.image,
  });
}

class CashierScreen extends StatefulWidget {
  const CashierScreen({super.key});

  @override
  State<CashierScreen> createState() => _CashierScreenState();
}

class _CashierScreenState extends State<CashierScreen>
    with SingleTickerProviderStateMixin {
  final List<CartItem> _cart = [];
  String _selectedCategory = "All";
  String _searchQuery = "";
  late AnimationController _cartAnimationController;

  final List<Product> _products = [
    Product(
      id: "1",
      name: "Cappuccino",
      price: 4.50,
      category: "Drinks",
      image:
          "https://images.unsplash.com/photo-1592663527359-cf6642f54cff?w=400",
    ),
    Product(
      id: "2",
      name: "Classic Burger",
      price: 8.99,
      category: "Food",
      image:
          "https://images.unsplash.com/photo-1688246780164-00c01647e78c?w=400",
    ),
    Product(
      id: "3",
      name: "Margherita Pizza",
      price: 12.50,
      category: "Food",
      image: "https://images.unsplash.com/photo-1544982503-9f984c14501a?w=400",
    ),
    Product(
      id: "4",
      name: "Caesar Salad",
      price: 7.50,
      category: "Food",
      image:
          "https://images.unsplash.com/photo-1677653805080-59c57727c84e?w=400",
    ),
    Product(
      id: "5",
      name: "Iced Latte",
      price: 5.00,
      category: "Drinks",
      image:
          "https://images.unsplash.com/photo-1517487881594-2787fef5ebf7?w=400",
    ),
    Product(
      id: "6",
      name: "Chocolate Cake",
      price: 6.50,
      category: "Dessert",
      image:
          "https://images.unsplash.com/photo-1578985545062-69928b1d9587?w=400",
    ),
    Product(
      id: "7",
      name: "French Fries",
      price: 3.99,
      category: "Snacks",
      image:
          "https://images.unsplash.com/photo-1630384082652-3ef3a7d8f07d?w=400",
    ),
    Product(
      id: "8",
      name: "Ice Cream",
      price: 4.50,
      category: "Dessert",
      image: "https://images.unsplash.com/photo-1563805042-7684c019e1cb?w=400",
    ),
  ];

  final List<String> _categories = [
    "All",
    "Food",
    "Drinks",
    "Snacks",
    "Dessert"
  ];

  @override
  void initState() {
    super.initState();
    _cartAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _cartAnimationController.dispose();
    super.dispose();
  }

  void _addToCart(Product product) {
    setState(() {
      final existingIndex = _cart.indexWhere((item) => item.id == product.id);
      if (existingIndex != -1) {
        _cart[existingIndex].quantity++;
      } else {
        _cart.add(CartItem(
          id: product.id,
          name: product.name,
          price: product.price,
          quantity: 1,
          image: product.image,
        ));
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
      final matchesSearch =
          product.name.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF8FAFC),
              Color(0xFFF1F5F9),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              _buildHeader(),

              // Search Bar
              _buildSearchBar(),

              // Categories
              _buildCategories(),

              // Products Grid
              Expanded(
                child: _buildProductsGrid(),
              ),

              // Cart Summary
              if (_cart.isNotEmpty) _buildCartSummary(),
              if (_cart.isEmpty) _buildEmptyCart(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Colors.blue[600]!,
            Colors.purple[700]!,
          ],
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
                icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
                onPressed: () {},
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
                onTap: () => setState(() => _selectedCategory = category),
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
                        color:
                            isSelected ? Colors.white : const Color(0xFF334155),
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
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
                            product.image,
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
                        style: const TextStyle(
                          color: Color(0xFF0F172A),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "\$${product.price.toStringAsFixed(2)}",
                        style: TextStyle(
                          color: Colors.blue[600],
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
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
        border: Border(
          top: BorderSide(color: Colors.blue[600]!, width: 4),
        ),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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

            // Cart Items
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 160),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _cart.length,
                itemBuilder: (context, index) {
                  final item = _cart[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        // Item Image
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            item.image,
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 48,
                                height: 48,
                                color: const Color(0xFFE2E8F0),
                                child: const Icon(Icons.image,
                                    color: Color(0xFF94A3B8)),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Item Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.name,
                                style: const TextStyle(
                                  color: Color(0xFF0F172A),
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                "\$${item.price.toStringAsFixed(2)}",
                                style: const TextStyle(
                                  color: Color(0xFF475569),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Quantity Controls
                        Row(
                          children: [
                            IconButton(
                              onPressed: () => _updateQuantity(item.id, -1),
                              icon: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFE2E8F0),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.remove, size: 16),
                              ),
                            ),
                            Text(
                              "${item.quantity}",
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            IconButton(
                              onPressed: () => _updateQuantity(item.id, 1),
                              icon: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.blue[600],
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.add,
                                    size: 16, color: Colors.white),
                              ),
                            ),
                            IconButton(
                              onPressed: () => _removeFromCart(item.id),
                              icon: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.red[100],
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.delete,
                                    size: 16, color: Colors.red[600]),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),

            // Totals
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Subtotal",
                    style: TextStyle(color: Color(0xFF475569))),
                Text("\$${_subtotal.toStringAsFixed(2)}",
                    style: const TextStyle(color: Color(0xFF475569))),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Tax (10%)",
                    style: TextStyle(color: Color(0xFF475569))),
                Text("\$${_tax.toStringAsFixed(2)}",
                    style: const TextStyle(color: Color(0xFF475569))),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Total",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                Text(
                  "\$${_total.toStringAsFixed(2)}",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Checkout Button
            Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue[600]!, Colors.purple[700]!],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          "Processing payment of \$${_total.toStringAsFixed(2)}"),
                      backgroundColor: Colors.green[700],
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.credit_card, color: Colors.white),
                    const SizedBox(width: 12),
                    Text(
                      "Proceed to Payment - \$${_total.toStringAsFixed(2)}",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyCart() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.qr_code_scanner,
            size: 48,
            color: Color(0xFFCBD5E1),
          ),
          SizedBox(height: 12),
          Text(
            "No items in cart",
            style: TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 16,
            ),
          ),
          Text(
            "Scan or select products to start",
            style: TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
