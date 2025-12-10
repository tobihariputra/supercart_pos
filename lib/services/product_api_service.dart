import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supercart_pos/core/app_config.dart';

class ProductApiService {
  final String baseUrl = AppConfig.baseUrl;
  final storage = const FlutterSecureStorage();
  late final Dio _dio;

  ProductApiService() {
    _dio = Dio();
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);
    _dio.options.sendTimeout = const Duration(seconds: 30);
    _setupInterceptor();
  }

  void _setupInterceptor() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await storage.read(key: 'auth_token');

          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          return handler.next(options);
        },
        onError: (error, handler) {
          return handler.next(error);
        },
      ),
    );
  }

  Map<String, dynamic> _handleErrorResponse(
    dynamic responseData,
    int statusCode,
  ) {
    String errorMessage = 'Terjadi kesalahan';

    if (responseData is Map<String, dynamic>) {
      if (responseData['meta'] != null &&
          responseData['meta']['message'] != null) {
        errorMessage = responseData['meta']['message'];
      } else if (responseData['message'] != null) {
        errorMessage = responseData['message'];
      } else if (responseData['error'] != null) {
        errorMessage = responseData['error'];
      }
    }

    if (errorMessage == 'Terjadi kesalahan') {
      switch (statusCode) {
        case 400:
          errorMessage = 'Permintaan tidak valid';
          break;
        case 401:
          errorMessage = 'Tidak terautentikasi. Silakan login kembali';
          break;
        case 403:
          errorMessage = 'Anda tidak memiliki akses';
          break;
        case 404:
          errorMessage = 'Data tidak ditemukan';
          break;
        case 422:
          errorMessage = 'Data yang dikirim tidak valid';
          break;
        case 500:
          errorMessage = 'Server error. Silakan coba lagi nanti';
          break;
        default:
          errorMessage = 'Terjadi kesalahan (Status: $statusCode)';
      }
    }

    return {'error': errorMessage, 'success': false};
  }

  Map<String, dynamic> _convertMapTypes(dynamic data) {
    if (data is Map) {
      return Map<String, dynamic>.fromEntries(
        data.entries.map((entry) {
          final key = entry.key.toString();
          var value = entry.value;

          if (value is Map) {
            value = _convertMapTypes(value);
          } else if (value is List) {
            value = _convertListItems(value);
          }

          return MapEntry(key, value);
        }),
      );
    }
    return <String, dynamic>{};
  }

  List _convertListItems(List items) {
    return items.map((item) {
      if (item is Map) {
        return _convertMapTypes(item);
      } else if (item is List) {
        return _convertListItems(item);
      }
      return item;
    }).toList();
  }

  // ================= GET PRODUCTS =================

  Future<Map<String, dynamic>> getProducts({
    int page = 1,
    int limit = 10,
    String? search,
    int? categoryId,
    int? supplierId,
  }) async {
    try {
      final queryParams = {
        'page': page,
        'limit': limit,
        if (search != null) 'search': search,
        if (categoryId != null) 'category_id': categoryId,
        if (supplierId != null) 'supplier_id': supplierId,
      };

      final response = await _dio.get(
        '$baseUrl/products/fetch',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final data = _convertMapTypes(response.data);
        var productData = data['result']?['data'];

        if (productData is List) {
          return {
            'success': true,
            'data': productData,
            'pagination': data['result']?['pagination'],
          };
        }

        if (productData is Map) {
          return {
            'success': true,
            'data': [productData],
            'pagination': data['result']?['pagination'],
          };
        }

        return {
          'success': true,
          'data': [],
          'pagination': data['result']?['pagination'],
        };
      }

      return _handleErrorResponse(response.data, response.statusCode ?? 500);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout) {
        return {'success': false, 'error': 'Koneksi timeout'};
      } else if (e.type == DioExceptionType.receiveTimeout) {
        return {'success': false, 'error': 'Server tidak merespon'};
      } else if (e.response != null) {
        return _handleErrorResponse(e.response!.data, e.response!.statusCode ?? 500);
      }
      return {'success': false, 'error': 'Gagal memuat produk: ${e.message}'};
    } catch (e) {
      return {'success': false, 'error': 'Gagal memuat produk: $e'};
    }
  }

  // ================= GET SINGLE PRODUCT =================

  Future<Map<String, dynamic>> getProductById(int id) async {
    try {
      final response = await _dio.get('$baseUrl/products/$id');

      if (response.statusCode == 200) {
        final data = _convertMapTypes(response.data);
        return {'success': true, 'data': data['result']?['data']};
      }

      return _handleErrorResponse(response.data, response.statusCode ?? 500);
    } on DioException catch (e) {
      if (e.response != null) {
        return _handleErrorResponse(e.response!.data, e.response!.statusCode ?? 500);
      }
      return {'success': false, 'error': 'Gagal memuat produk: ${e.message}'};
    } catch (e) {
      return {'success': false, 'error': 'Gagal memuat produk: $e'};
    }
  }

  // ================= CREATE PRODUCT =================

  Future<Map<String, dynamic>> createProduct({
    required String barcode,
    required String name,
    required int categoryId,
    required int supplierId,
    required int stockQuantity,
    required int minStock,
    required int maxStock,
    required String unit,
    required int purchasePrice,
    required int sellingPrice,
    String? imageUrl,
  }) async {
    try {
      final body = {
        'barcode': barcode,
        'name': name,
        'category_id': categoryId,
        'supplier_id': supplierId,
        'stock_quantity': stockQuantity,
        'min_stock': minStock,
        'max_stock': maxStock,
        'unit': unit,
        'purchase_price': purchasePrice,
        'selling_price': sellingPrice,
        if (imageUrl != null) 'image_url': imageUrl,
      };

      final response = await _dio.post('$baseUrl/products/create', data: body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = _convertMapTypes(response.data);
        return {
          'success': true,
          'data': data['result']?['data'],
          'message': 'Produk berhasil ditambahkan',
        };
      }

      return _handleErrorResponse(response.data, response.statusCode ?? 500);
    } on DioException catch (e) {
      if (e.response != null) {
        return _handleErrorResponse(e.response!.data, e.response!.statusCode ?? 500);
      }
      return {'success': false, 'error': 'Gagal menambahkan produk: ${e.message}'};
    } catch (e) {
      return {'success': false, 'error': 'Gagal menambahkan produk: $e'};
    }
  }

  // ================= UPDATE PRODUCT =================

  Future<Map<String, dynamic>> updateProduct({
    required int id,
    required String barcode,
    required String name,
    required int categoryId,
    required int supplierId,
    required int stockQuantity,
    required int minStock,
    required int maxStock,
    required String unit,
    required int purchasePrice,
    required int sellingPrice,
    bool isActive = true,
  }) async {
    try {
      final body = {
        'barcode': barcode,
        'name': name,
        'category_id': categoryId,
        'supplier_id': supplierId,
        'stock_quantity': stockQuantity,
        'min_stock': minStock,
        'max_stock': maxStock,
        'unit': unit,
        'purchase_price': purchasePrice,
        'selling_price': sellingPrice,
        'is_active': isActive,
      };

      final response = await _dio.put(
        '$baseUrl/products/update/$id',
        data: body,
      );

      if (response.statusCode == 200) {
        final data = _convertMapTypes(response.data);
        return {
          'success': true,
          'data': data['result']?['data'],
          'message': 'Produk berhasil diupdate',
        };
      }

      return _handleErrorResponse(response.data, response.statusCode ?? 500);
    } on DioException catch (e) {
      if (e.response != null) {
        return _handleErrorResponse(e.response!.data, e.response!.statusCode ?? 500);
      }
      return {'success': false, 'error': 'Gagal mengupdate produk: ${e.message}'};
    } catch (e) {
      return {'success': false, 'error': 'Gagal mengupdate produk: $e'};
    }
  }

  // ================= DELETE PRODUCT =================

  Future<Map<String, dynamic>> deleteProduct(int id) async {
    try {
      final response = await _dio.delete('$baseUrl/products/delete/$id');

      if (response.statusCode == 200) {
        return {'success': true, 'message': 'Produk berhasil dihapus'};
      }

      return _handleErrorResponse(response.data, response.statusCode ?? 500);
    } on DioException catch (e) {
      if (e.response != null) {
        return _handleErrorResponse(e.response!.data, e.response!.statusCode ?? 500);
      }
      return {'success': false, 'error': 'Gagal menghapus produk: ${e.message}'};
    } catch (e) {
      return {'success': false, 'error': 'Gagal menghapus produk: $e'};
    }
  }

  // ================= STOCK OPERATIONS =================

  Future<Map<String, dynamic>> updateStock({
    required int productId,
    required int quantity,
    required String type,
  }) async {
    try {
      final body = {
        'product_id': productId,
        'quantity': quantity,
        'type': type,
      };

      final response = await _dio.post(
        '$baseUrl/products/$productId/stock',
        data: body,
      );

      if (response.statusCode == 200) {
        final data = _convertMapTypes(response.data);
        return {'success': true, 'data': data['result']?['data']};
      }

      return _handleErrorResponse(response.data, response.statusCode ?? 500);
    } on DioException catch (e) {
      if (e.response != null) {
        return _handleErrorResponse(e.response!.data, e.response!.statusCode ?? 500);
      }
      return {'success': false, 'error': 'Gagal update stok: ${e.message}'};
    } catch (e) {
      return {'success': false, 'error': 'Gagal update stok: $e'};
    }
  }
}