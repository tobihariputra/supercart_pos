import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/app_config.dart';

class AuthApiService {
  final String baseUrl = AppConfig.baseUrl;
  final storage = const FlutterSecureStorage();
  late final Dio _dio;

  AuthApiService() {
    _dio = Dio();
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);
    _dio.options.sendTimeout = const Duration(seconds: 30);
  }

  /// Login function
  Future<Map<String, dynamic>> login({
    required String nip,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        '$baseUrl/auth/login',
        data: {
          'nip': nip,
          'password': password,
        },
      );

      if (response.statusCode == 200) {
        final responseData = _convertMapTypes(response.data);
        
        // Save full response to secure storage
        await storage.write(
          key: 'login_response',
          value: json.encode(responseData),
        );

        // Extract and save token separately for easy access
        final token = _extractToken(responseData);
        if (token.isNotEmpty) {
          await storage.write(key: 'auth_token', value: token);
        }

        // Save user data
        if (responseData['result']?['data']?['user'] != null) {
          await storage.write(
            key: 'user_data',
            value: json.encode(responseData['result']['data']['user']),
          );
        }

        return {
          'success': true,
          'data': responseData,
        };
      } else {
        return _handleErrorResponse(response.data, response.statusCode ?? 500);
      }
    } on DioException catch (e) {
      if (kDebugMode) {
        print('Login error: ${e.message}');
      }

      if (e.response != null) {
        return _handleErrorResponse(
          e.response?.data,
          e.response?.statusCode ?? 500,
        );
      } else {
        return {
          'success': false,
          'error': 'Network error. Please check your connection.',
        };
      }
    } catch (e) {
      if (kDebugMode) {
        print('Unexpected error: $e');
      }
      return {
        'success': false,
        'error': 'An unexpected error occurred',
      };
    }
  }

  /// Logout function
  Future<void> logout() async {
    try {
      await storage.delete(key: 'login_response');
      await storage.delete(key: 'auth_token');
      await storage.delete(key: 'user_data');
    } catch (e) {
      if (kDebugMode) {
        print('Logout error: $e');
      }
    }
  }

  /// Check if user is logged in
  Future<bool> isLoggedIn() async {
    final token = await storage.read(key: 'auth_token');
    return token != null && token.isNotEmpty;
  }

  /// Get current user data
  Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      final userDataStr = await storage.read(key: 'user_data');
      if (userDataStr != null) {
        return json.decode(userDataStr) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Get user error: $e');
      }
      return null;
    }
  }


  String _extractToken(Map<String, dynamic> responseData) {
    String token = '';
    
    // Try to get token from result.data.token
    if (responseData['result'] != null &&
        responseData['result']['data'] != null &&
        responseData['result']['data']['token'] != null) {
      token = responseData['result']['data']['token'];
    }
    // Fallback to meta.message.token
    else if (responseData['meta'] != null &&
        responseData['meta']['message'] != null &&
        responseData['meta']['message']['token'] != null) {
      token = responseData['meta']['message']['token'];
    }
    // Fallback to result.token
    else if (responseData['result'] != null &&
        responseData['result']['token'] != null) {
      token = responseData['result']['token'];
    }
    
    return token;
  }

  Map<String, dynamic> _handleErrorResponse(
    dynamic responseData,
    int statusCode,
  ) {
    String errorMessage = 'An error occurred';

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

    if (errorMessage == 'An error occurred') {
      switch (statusCode) {
        case 401:
          errorMessage = 'NIP atau password salah';
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
}