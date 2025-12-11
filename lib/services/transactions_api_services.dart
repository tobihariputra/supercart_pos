import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supercart_pos/core/app_config.dart';

class TransactionDetail {
  final int id;
  final int transactionId;
  final int productId;
  final int quantity;
  final String unitPrice;
  final String discount;
  final String subtotal;
  final String createdAt;
  final TransactionProduct product;

  TransactionDetail({
    required this.id,
    required this.transactionId,
    required this.productId,
    required this.quantity,
    required this.unitPrice,
    required this.discount,
    required this.subtotal,
    required this.createdAt,
    required this.product,
  });

  factory TransactionDetail.fromJson(Map<String, dynamic> json) {
    return TransactionDetail(
      id: json['id'] ?? 0,
      transactionId: json['transaction_id'] ?? 0,
      productId: json['product_id'] ?? 0,
      quantity: json['quantity'] ?? 0,
      unitPrice: json['unit_price']?.toString() ?? '0',
      discount: json['discount']?.toString() ?? '0',
      subtotal: json['subtotal']?.toString() ?? '0',
      createdAt: json['created_at'] ?? '',
      product: TransactionProduct.fromJson(json['product'] ?? {}),
    );
  }
}

class TransactionProduct {
  final int? id;
  final String sku;
  final String name;
  final String unit;
  final String? sellingPrice;
  final String? barcode;

  TransactionProduct({
    this.id,
    required this.sku,
    required this.name,
    required this.unit,
    this.sellingPrice,
    this.barcode,
  });

  factory TransactionProduct.fromJson(Map<String, dynamic> json) {
    return TransactionProduct(
      id: json['id'],
      sku: json['sku'] ?? '',
      name: json['name'] ?? '',
      unit: json['unit'] ?? '',
      sellingPrice: json['selling_price']?.toString(),
      barcode: json['barcode']?.toString(),
    );
  }
}

class TransactionUser {
  final int id;
  final String nip;
  final String name;

  TransactionUser({
    required this.id,
    required this.nip,
    required this.name,
  });

  factory TransactionUser.fromJson(Map<String, dynamic> json) {
    return TransactionUser(
      id: json['id'] ?? 0,
      nip: json['nip'] ?? '',
      name: json['name'] ?? '',
    );
  }
}

class Transaction {
  final int id;
  final String transactionNo;
  final String transactionDate;
  final int userId;
  final int totalItems;
  final String subtotal;
  final String discountAmount;
  final String taxAmount;
  final String totalAmount;
  final String paymentMethod;
  final String paymentAmount;
  final String changeAmount;
  final String notes;
  final String status;
  final String? cancelledAt;
  final int? cancelledBy;
  final String? cancelReason;
  final String createdAt;
  final String updatedAt;
  final TransactionUser user;
  final TransactionUser? cancelledByUser;
  final List<TransactionDetail> details;

  Transaction({
    required this.id,
    required this.transactionNo,
    required this.transactionDate,
    required this.userId,
    required this.totalItems,
    required this.subtotal,
    required this.discountAmount,
    required this.taxAmount,
    required this.totalAmount,
    required this.paymentMethod,
    required this.paymentAmount,
    required this.changeAmount,
    required this.notes,
    required this.status,
    this.cancelledAt,
    this.cancelledBy,
    this.cancelReason,
    required this.createdAt,
    required this.updatedAt,
    required this.user,
    this.cancelledByUser,
    required this.details,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] ?? 0,
      transactionNo: json['transaction_no'] ?? '',
      transactionDate: json['transaction_date'] ?? '',
      userId: json['user_id'] ?? 0,
      totalItems: json['total_items'] ?? 0,
      subtotal: json['subtotal']?.toString() ?? '0',
      discountAmount: json['discount_amount']?.toString() ?? '0',
      taxAmount: json['tax_amount']?.toString() ?? '0',
      totalAmount: json['total_amount']?.toString() ?? '0',
      paymentMethod: json['payment_method'] ?? '',
      paymentAmount: json['payment_amount']?.toString() ?? '0',
      changeAmount: json['change_amount']?.toString() ?? '0',
      notes: json['notes'] ?? '',
      status: json['status'] ?? '',
      cancelledAt: json['cancelled_at'],
      cancelledBy: json['cancelled_by'],
      cancelReason: json['cancel_reason'],
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      user: TransactionUser.fromJson(json['user'] ?? {}),
      cancelledByUser: json['cancelled_by_user'] != null
          ? TransactionUser.fromJson(json['cancelled_by_user'])
          : null,
      details: (json['details'] as List<dynamic>?)
              ?.map((item) => TransactionDetail.fromJson(item))
              .toList() ??
          [],
    );
  }
}

class TransactionApiService {
  final String baseUrl = AppConfig.baseUrl;
  final storage = const FlutterSecureStorage();
  late final Dio _dio;

  TransactionApiService() {
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
          errorMessage = 'Data tidak valid';
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

  // ================= FETCH TRANSACTIONS =================

  Future<Map<String, dynamic>> fetchTransactions({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _dio.get(
        '$baseUrl/transactions/fetch',
        queryParameters: {
          'page': page,
          'limit': limit,
        },
      );

      if (response.statusCode == 200) {
        final data = _convertMapTypes(response.data);
        final result = data['result']?['data'];

        return {
          'success': true,
          'transactions': result?['transactions'] ?? [],
          'pagination': result?['pagination'] ?? {
            'page': 1,
            'limit': 20,
            'total': 0,
            'total_pages': 1,
          },
        };
      }

      return _handleErrorResponse(
        response.data,
        response.statusCode ?? 500,
      );
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout) {
        return {'success': false, 'error': 'Koneksi timeout'};
      } else if (e.type == DioExceptionType.receiveTimeout) {
        return {'success': false, 'error': 'Server tidak merespon'};
      } else if (e.response != null) {
        return _handleErrorResponse(
          e.response!.data,
          e.response!.statusCode ?? 500,
        );
      }
      return {
        'success': false,
        'error': 'Gagal memuat transaksi: ${e.message}',
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Gagal memuat transaksi: $e',
      };
    }
  }

  // ================= GET TRANSACTION DETAIL =================

  Future<Map<String, dynamic>> getTransactionDetail(int transactionId) async {
    try {
      final response = await _dio.get(
        '$baseUrl/transactions/detail/$transactionId',
      );

      if (response.statusCode == 200) {
        final data = _convertMapTypes(response.data);
        return {
          'success': true,
          'data': data['result']?['data'],
        };
      }

      return _handleErrorResponse(
        response.data,
        response.statusCode ?? 500,
      );
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout) {
        return {'success': false, 'error': 'Koneksi timeout'};
      } else if (e.type == DioExceptionType.receiveTimeout) {
        return {'success': false, 'error': 'Server tidak merespon'};
      } else if (e.response != null) {
        return _handleErrorResponse(
          e.response!.data,
          e.response!.statusCode ?? 500,
        );
      }
      return {
        'success': false,
        'error': 'Gagal memuat detail transaksi: ${e.message}',
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Gagal memuat detail transaksi: $e',
      };
    }
  }

  // ================= GET TRANSACTION BY NUMBER =================

  Future<Map<String, dynamic>> getTransactionByNumber(
      String transactionNo) async {
    try {
      final response = await _dio.get(
        '$baseUrl/transactions/no/$transactionNo',
      );

      if (response.statusCode == 200) {
        final data = _convertMapTypes(response.data);
        return {
          'success': true,
          'data': data['result']?['data'],
        };
      }

      return _handleErrorResponse(
        response.data,
        response.statusCode ?? 500,
      );
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout) {
        return {'success': false, 'error': 'Koneksi timeout'};
      } else if (e.type == DioExceptionType.receiveTimeout) {
        return {'success': false, 'error': 'Server tidak merespon'};
      } else if (e.response != null) {
        return _handleErrorResponse(
          e.response!.data,
          e.response!.statusCode ?? 500,
        );
      }
      return {
        'success': false,
        'error': 'Gagal memuat transaksi: ${e.message}',
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Gagal memuat transaksi: $e',
      };
    }
  }

  // ================= CREATE TRANSACTION =================

  Future<Map<String, dynamic>> createTransaction({
    required List<Map<String, dynamic>> items,
    required double discountAmount,
    required String paymentMethod,
    required double paymentAmount,
    required String notes,
  }) async {
    try {
      final requestBody = {
        'items': items,
        'discount_amount': discountAmount,
        'payment_method': paymentMethod,
        'payment_amount': paymentAmount,
        'notes': notes,
      };

      final response = await _dio.post(
        '$baseUrl/transactions/create',
        data: requestBody,
      );

      if (response.statusCode == 201) {
        final data = _convertMapTypes(response.data);
        return {
          'success': true,
          'data': data['result']?['data'],
        };
      }

      return _handleErrorResponse(
        response.data,
        response.statusCode ?? 500,
      );
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout) {
        return {'success': false, 'error': 'Koneksi timeout'};
      } else if (e.type == DioExceptionType.receiveTimeout) {
        return {'success': false, 'error': 'Server tidak merespon'};
      } else if (e.response != null) {
        return _handleErrorResponse(
          e.response!.data,
          e.response!.statusCode ?? 500,
        );
      }
      return {
        'success': false,
        'error': 'Gagal membuat transaksi: ${e.message}',
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Gagal membuat transaksi: $e',
      };
    }
  }

  // ================= CANCEL TRANSACTION =================

  Future<Map<String, dynamic>> cancelTransaction(int transactionId) async {
    try {
      final response = await _dio.post(
        '$baseUrl/transactions/cancel/$transactionId',
      );

      if (response.statusCode == 200) {
        final data = _convertMapTypes(response.data);
        return {
          'success': true,
          'message': data['meta']?['message'] ?? 'Transaksi berhasil dibatalkan',
        };
      }

      return _handleErrorResponse(
        response.data,
        response.statusCode ?? 500,
      );
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout) {
        return {'success': false, 'error': 'Koneksi timeout'};
      } else if (e.type == DioExceptionType.receiveTimeout) {
        return {'success': false, 'error': 'Server tidak merespon'};
      } else if (e.response != null) {
        return _handleErrorResponse(
          e.response!.data,
          e.response!.statusCode ?? 500,
        );
      }
      return {
        'success': false,
        'error': 'Gagal membatalkan transaksi: ${e.message}',
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Gagal membatalkan transaksi: $e',
      };
    }
  }

  // Tambahkan method-method ini ke class TransactionApiService Anda yang sudah ada
// Letakkan setelah method cancelTransaction()

// ================= GET TRANSACTIONS (dengan filter untuk laporan) =================

Future<Map<String, dynamic>> getTransactions({
  int page = 1,
  int limit = 1000,
  String? search,
  String? status,
  String? startDate,
  String? endDate,
}) async {
  try {
    final queryParams = {
      'page': page,
      'limit': limit,
      if (search != null) 'search': search,
      if (status != null && status != 'Semua') 'status': status,
      if (startDate != null) 'start_date': startDate,
      if (endDate != null) 'end_date': endDate,
    };

    final response = await _dio.get(
      '$baseUrl/transactions/fetch',
      queryParameters: queryParams,
    );

    if (response.statusCode == 200) {
      final data = _convertMapTypes(response.data);
      
      // Handle berbagai struktur response
      var transactionData = data['result']?['data'];
      
      // Jika data adalah list
      if (transactionData is List) {
        return {
          'success': true,
          'data': transactionData,
          'pagination': data['result']?['pagination'],
        };
      }
      
      // Jika data adalah object dengan key 'transactions'
      if (transactionData is Map && transactionData.containsKey('transactions')) {
        return {
          'success': true,
          'data': transactionData['transactions'] ?? [],
          'pagination': transactionData['pagination'],
        };
      }
      
      // Jika data langsung adalah transaksi
      if (transactionData is Map) {
        return {
          'success': true,
          'data': [transactionData],
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
    return {'success': false, 'error': 'Gagal memuat transaksi: ${e.message}'};
  } catch (e) {
    return {'success': false, 'error': 'Gagal memuat transaksi: $e'};
  }
}

// ================= GET TRANSACTION SUMMARY (untuk ringkasan laporan) =================

Future<Map<String, dynamic>> getTransactionSummary({
  String? startDate,
  String? endDate,
}) async {
  try {
    final queryParams = {
      if (startDate != null) 'start_date': startDate,
      if (endDate != null) 'end_date': endDate,
    };

    final response = await _dio.get(
      '$baseUrl/transactions/summary',
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

// ================= GET TRANSACTION BY ID (untuk detail laporan) =================

Future<Map<String, dynamic>> getTransactionById(int id) async {
  try {
    final response = await _dio.get('$baseUrl/transactions/detail/$id');

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
    return {'success': false, 'error': 'Gagal memuat transaksi: ${e.message}'};
  } catch (e) {
    return {'success': false, 'error': 'Gagal memuat transaksi: $e'};
  }
}
}