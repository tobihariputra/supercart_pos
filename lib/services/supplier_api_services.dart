import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supercart_pos/core/app_config.dart';

class SupplierApiService {
  final String baseUrl = AppConfig.baseUrl;
  final storage = const FlutterSecureStorage();
  late final Dio _dio;

  SupplierApiService() {
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

  // ================= GET SUPPLIERS =================

  Future<Map<String, dynamic>> getSuppliers() async {
    try {
      debugPrint('🏢 Fetching suppliers...');
      final response = await _dio.get('$baseUrl/suppliers/fetch');

      debugPrint('✅ Response status: ${response.statusCode}');
      debugPrint('📋 Raw response: ${response.data}');

      if (response.statusCode == 200) {
        final data = _convertMapTypes(response.data);
        var supplierData = data['result']?['data'];
        
        if (supplierData is List) {
          debugPrint('✅ Suppliers loaded: ${supplierData.length} items');
          return {
            'success': true,
            'data': supplierData,
          };
        }
        
        if (supplierData is Map) {
          debugPrint('⚠️ Supplier data is map, wrapping in array');
          return {
            'success': true,
            'data': [supplierData],
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

  // ================= CREATE SUPPLIER =================

  Future<Map<String, dynamic>> createSupplier({
    required String name,
    String? contactPerson,
    String? phone,
    String? address,
    String? email,
  }) async {
    try {
      debugPrint('➕ Creating supplier: $name');
      
      final body = {
        'name': name,
        if (contactPerson != null && contactPerson.isNotEmpty) 'contact_person': contactPerson,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
        if (address != null && address.isNotEmpty) 'address': address,
        if (email != null && email.isNotEmpty) 'email': email,
      };

      final response = await _dio.post(
        '$baseUrl/suppliers/create',
        data: body,
      );

      debugPrint('✅ Response status: ${response.statusCode}');
      debugPrint('📋 Response: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = _convertMapTypes(response.data);
        return {
          'success': true,
          'data': data['result']?['data'],
          'message': 'Supplier berhasil ditambahkan',
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

  // ================= UPDATE SUPPLIER =================

  Future<Map<String, dynamic>> updateSupplier({
    required int id,
    required String name,
    String? contactPerson,
    String? phone,
    String? address,
    String? email,
  }) async {
    try {
      debugPrint('✏️ Updating supplier: $id - $name');
      
      final body = {
        'name': name,
        if (contactPerson != null && contactPerson.isNotEmpty) 'contact_person': contactPerson,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
        if (address != null && address.isNotEmpty) 'address': address,
        if (email != null && email.isNotEmpty) 'email': email,
      };

      final response = await _dio.put(
        '$baseUrl/suppliers/update/$id',
        data: body,
      );

      debugPrint('✅ Response status: ${response.statusCode}');
      debugPrint('📋 Response: ${response.data}');

      if (response.statusCode == 200) {
        final data = _convertMapTypes(response.data);
        return {
          'success': true,
          'data': data['result']?['data'],
          'message': 'Supplier berhasil diupdate',
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

  // ================= DELETE SUPPLIER =================

  Future<Map<String, dynamic>> deleteSupplier(int id) async {
    try {
      debugPrint('🗑️ Deleting supplier: $id');
      
      final response = await _dio.delete('$baseUrl/suppliers/delete/$id');

      debugPrint('✅ Response status: ${response.statusCode}');
      debugPrint('📋 Response: ${response.data}');

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Supplier berhasil dihapus',
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