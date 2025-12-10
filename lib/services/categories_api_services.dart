import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supercart_pos/core/app_config.dart';

class CategoriesApiService {
  final String baseUrl = AppConfig.baseUrl;
  final storage = const FlutterSecureStorage();
  late final Dio _dio;

  CategoriesApiService() {
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
          debugPrint('🔑 Auth Token from storage: ${token != null ? 'Found' : 'Not found'}');
          
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
            debugPrint('✅ Authorization header set');
          } else {
            debugPrint('⚠️ No token found, request will be sent without auth');
          }
          
          debugPrint('📤 Request: ${options.method} ${options.path}');
          return handler.next(options);
        },
        onError: (error, handler) {
          debugPrint('❌ Dio Error: ${error.message}');
          debugPrint('📊 Status Code: ${error.response?.statusCode}');
          debugPrint('📋 Response: ${error.response?.data}');
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

  // ================= GET CATEGORIES =================

  Future<Map<String, dynamic>> getCategories() async {
    try {
      debugPrint('📂 Fetching categories...');
      final response = await _dio.get('$baseUrl/categories/fetch');

      debugPrint('✅ Response status: ${response.statusCode}');
      debugPrint('📋 Raw response: ${response.data}');

      if (response.statusCode == 200) {
        final data = _convertMapTypes(response.data);
        var categoryData = data['result']?['data'];
        
        if (categoryData is List) {
          debugPrint('✅ Categories loaded: ${categoryData.length} items');
          return {
            'success': true,
            'data': categoryData,
          };
        }
        
        if (categoryData is Map) {
          debugPrint('⚠️ Category data is map, wrapping in array');
          return {
            'success': true,
            'data': [categoryData],
          };
        }
        
        return {
          'success': true,
          'data': [],
        };
      }

      return _handleErrorResponse(response.data, response.statusCode ?? 500);
    } on DioException catch (e) {
      debugPrint('❌ Dio Error: ${e.message}');
      return _handleErrorResponse(e.response?.data, e.response?.statusCode ?? 500);
    }
  }

  // ================= CREATE CATEGORY =================

  Future<Map<String, dynamic>> createCategory({
    required String name,
    String? description,
  }) async {
    try {
      debugPrint('➕ Creating category: $name');
      
      final body = {
        'name': name,
        if (description != null && description.isNotEmpty) 'description': description,
      };

      final response = await _dio.post(
        '$baseUrl/categories/create',
        data: body,
      );

      debugPrint('✅ Response status: ${response.statusCode}');
      debugPrint('📋 Response: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = _convertMapTypes(response.data);
        return {
          'success': true,
          'data': data['result']?['data'],
          'message': 'Kategori berhasil ditambahkan',
        };
      }

      return _handleErrorResponse(response.data, response.statusCode ?? 500);
    } on DioException catch (e) {
      debugPrint('❌ Dio Exception: ${e.message}');
      debugPrint('❌ Status Code: ${e.response?.statusCode}');
      debugPrint('❌ Response Data: ${e.response?.data}');
      return _handleErrorResponse(e.response?.data, e.response?.statusCode ?? 500);
    } catch (e) {
      debugPrint('❌ Unexpected Error: $e');
      return {
        'success': false,
        'error': 'Unexpected error: $e',
      };
    }
  }

  // ================= UPDATE CATEGORY =================

  Future<Map<String, dynamic>> updateCategory({
    required int id,
    required String name,
    String? description,
  }) async {
    try {
      debugPrint('✏️ Updating category: $id - $name');
      
      final body = {
        'name': name,
        if (description != null && description.isNotEmpty) 'description': description,
      };

      final response = await _dio.put(
        '$baseUrl/categories/update/$id',
        data: body,
      );

      debugPrint('✅ Response status: ${response.statusCode}');
      debugPrint('📋 Response: ${response.data}');

      if (response.statusCode == 200) {
        final data = _convertMapTypes(response.data);
        return {
          'success': true,
          'data': data['result']?['data'],
          'message': 'Kategori berhasil diupdate',
        };
      }

      return _handleErrorResponse(response.data, response.statusCode ?? 500);
    } on DioException catch (e) {
      debugPrint('❌ Dio Exception: ${e.message}');
      return _handleErrorResponse(e.response?.data, e.response?.statusCode ?? 500);
    } catch (e) {
      debugPrint('❌ Unexpected Error: $e');
      return {
        'success': false,
        'error': 'Unexpected error: $e',
      };
    }
  }

  // ================= DELETE CATEGORY =================

  Future<Map<String, dynamic>> deleteCategory(int id) async {
    try {
      debugPrint('🗑️ Deleting category: $id');
      
      final response = await _dio.delete('$baseUrl/categories/delete/$id');

      debugPrint('✅ Response status: ${response.statusCode}');
      debugPrint('📋 Response: ${response.data}');

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Kategori berhasil dihapus',
        };
      }

      return _handleErrorResponse(response.data, response.statusCode ?? 500);
    } on DioException catch (e) {
      debugPrint('❌ Dio Exception: ${e.message}');
      return _handleErrorResponse(e.response?.data, e.response?.statusCode ?? 500);
    } catch (e) {
      debugPrint('❌ Unexpected Error: $e');
      return {
        'success': false,
        'error': 'Unexpected error: $e',
      };
    }
  }
}