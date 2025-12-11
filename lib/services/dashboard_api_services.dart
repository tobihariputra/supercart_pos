import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supercart_pos/core/app_config.dart';

class DashboardApiService {
  final String baseUrl = AppConfig.baseUrl;
  final storage = const FlutterSecureStorage();
  late final Dio _dio;

  DashboardApiService() {
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

  // ================= GET DASHBOARD DATA =================

  Future<Map<String, dynamic>> getDashboardCashier({
    String? date,
  }) async {
    try {
      final queryParams = {
        if (date != null) 'date': date,
      };

      final response = await _dio.get(
        '$baseUrl/dashboard/cashier',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final data = _convertMapTypes(response.data);
        return {
          'success': true,
          'data': data['result']?['data'],
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
      return {'success': false, 'error': 'Gagal memuat dashboard: ${e.message}'};
    } catch (e) {
      return {'success': false, 'error': 'Gagal memuat dashboard: $e'};
    }
  }

  // ================= GET DAILY SUMMARY =================

  Future<Map<String, dynamic>> getDailySummary({
    String? date,
  }) async {
    try {
      final queryParams = {
        if (date != null) 'date': date,
      };

      final response = await _dio.get(
        '$baseUrl/dashboard/daily-summary',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final data = _convertMapTypes(response.data);
        return {
          'success': true,
          'data': data['result']?['data'],
        };
      }

      return _handleErrorResponse(response.data, response.statusCode ?? 500);
    } on DioException catch (e) {
      if (e.response != null) {
        return _handleErrorResponse(e.response!.data, e.response!.statusCode ?? 500);
      }
      return {'success': false, 'error': 'Gagal memuat ringkasan: ${e.message}'};
    } catch (e) {
      return {'success': false, 'error': 'Gagal memuat ringkasan: $e'};
    }
  }

  // ================= GET HOURLY SALES =================

  Future<Map<String, dynamic>> getHourlySales({
    String? date,
  }) async {
    try {
      final queryParams = {
        if (date != null) 'date': date,
      };

      final response = await _dio.get(
        '$baseUrl/dashboard/hourly-sales',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final data = _convertMapTypes(response.data);
        return {
          'success': true,
          'data': data['result']?['data'] ?? [],
        };
      }

      return _handleErrorResponse(response.data, response.statusCode ?? 500);
    } on DioException catch (e) {
      if (e.response != null) {
        return _handleErrorResponse(e.response!.data, e.response!.statusCode ?? 500);
      }
      return {'success': false, 'error': 'Gagal memuat penjualan per jam: ${e.message}'};
    } catch (e) {
      return {'success': false, 'error': 'Gagal memuat penjualan per jam: $e'};
    }
  }

  // ================= GET PAYMENT METHODS =================

  Future<Map<String, dynamic>> getPaymentMethods({
    String? date,
  }) async {
    try {
      final queryParams = {
        if (date != null) 'date': date,
      };

      final response = await _dio.get(
        '$baseUrl/dashboard/payment-methods',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final data = _convertMapTypes(response.data);
        return {
          'success': true,
          'data': data['result']?['data'] ?? [],
        };
      }

      return _handleErrorResponse(response.data, response.statusCode ?? 500);
    } on DioException catch (e) {
      if (e.response != null) {
        return _handleErrorResponse(e.response!.data, e.response!.statusCode ?? 500);
      }
      return {'success': false, 'error': 'Gagal memuat metode pembayaran: ${e.message}'};
    } catch (e) {
      return {'success': false, 'error': 'Gagal memuat metode pembayaran: $e'};
    }
  }

  // ================= GET TOP PRODUCTS =================

  Future<Map<String, dynamic>> getTopProducts({
    String? date,
    int limit = 10,
  }) async {
    try {
      final queryParams = {
        'limit': limit,
        if (date != null) 'date': date,
      };

      final response = await _dio.get(
        '$baseUrl/dashboard/top-products',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final data = _convertMapTypes(response.data);
        return {
          'success': true,
          'data': data['result']?['data'] ?? [],
        };
      }

      return _handleErrorResponse(response.data, response.statusCode ?? 500);
    } on DioException catch (e) {
      if (e.response != null) {
        return _handleErrorResponse(e.response!.data, e.response!.statusCode ?? 500);
      }
      return {'success': false, 'error': 'Gagal memuat produk terpopuler: ${e.message}'};
    } catch (e) {
      return {'success': false, 'error': 'Gagal memuat produk terpopuler: $e'};
    }
  }

  // ================= GET SALES TREND =================

  Future<Map<String, dynamic>> getSalesTrend({
    int days = 7,
  }) async {
    try {
      final queryParams = {
        'days': days,
      };

      final response = await _dio.get(
        '$baseUrl/dashboard/sales-trend',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final data = _convertMapTypes(response.data);
        return {
          'success': true,
          'data': data['result']?['data'] ?? [],
        };
      }

      return _handleErrorResponse(response.data, response.statusCode ?? 500);
    } on DioException catch (e) {
      if (e.response != null) {
        return _handleErrorResponse(e.response!.data, e.response!.statusCode ?? 500);
      }
      return {'success': false, 'error': 'Gagal memuat tren penjualan: ${e.message}'};
    } catch (e) {
      return {'success': false, 'error': 'Gagal memuat tren penjualan: $e'};
    }
  }
}