import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../constants/api_endpoints.dart';
import '../storage/secure_storage_service.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class ApiClient {
  static ApiClient? _instance;
  late Dio _dio;
  String? _lastExtractedToken;

  ApiClient._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.defaultBaseUrl,
        connectTimeout: const Duration(seconds: 8),
        sendTimeout: const Duration(seconds: 8),
        receiveTimeout: const Duration(seconds: 8),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          try {
            if (kDebugMode) {
              final customUrl = await SecureStorageService.getBaseUrl();
              if (customUrl != null && customUrl.trim().isNotEmpty) {
                options.baseUrl = customUrl.trim();
              }
            } else {
              options.baseUrl = ApiEndpoints.defaultBaseUrl;
            }

            final token = await SecureStorageService.getSessionToken();
            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
              options.headers['Cookie'] = 'roamora_session=$token';
            }
          } catch (e) {
            debugPrint('[API Interceptor Warning] Error reading storage: $e');
          }

          debugPrint('[API REQUEST] ${options.method} ${options.uri.path}');
          debugPrint('[API BASE URL] ${options.baseUrl}');
          return handler.next(options);
        },
        onResponse: (response, handler) {
          debugPrint('[API] ${response.statusCode} OK from ${response.requestOptions.path}');
          _extractSessionCookie(response.headers);
          return handler.next(response);
        },
        onError: (DioException error, handler) {
          final status = error.response?.statusCode;
          final path = error.requestOptions.path;
          debugPrint('[API Error] Status: $status, Path: $path, Type: ${error.type}');

          String message;
          if (error.response?.data is Map && error.response?.data['error'] != null) {
            message = error.response!.data['error'].toString();
          } else if (error.type == DioExceptionType.connectionTimeout ||
              error.type == DioExceptionType.receiveTimeout ||
              error.type == DioExceptionType.sendTimeout) {
            message = 'Connection timed out. Pookie Match server took too long to respond.';
          } else if (error.type == DioExceptionType.connectionError) {
            message = 'Cannot connect to Pookie Match servers. Please check your internet connection.';
          } else if (status == 401) {
            message = 'Email or password is incorrect. Please try again.';
          } else if (status == 404) {
            message = 'Account or resource not found. Please verify your details.';
          } else if (status == 429) {
            message = 'Too many requests. Please wait a moment and try again.';
          } else if (status == 500) {
            message = 'Pookie Match server error. Please try again shortly.';
          } else if (status == 503) {
            message = 'Service is temporarily unavailable. Please try again in a few moments.';
          } else if (error.message != null && error.message!.isNotEmpty) {
            message = error.message!;
          } else {
            message = 'A network error occurred. Please try again.';
          }

          return handler.reject(
            DioException(
              requestOptions: error.requestOptions,
              response: error.response,
              type: error.type,
              error: ApiException(message, statusCode: status),
            ),
          );
        },
      ),
    );
  }

  static ApiClient get instance {
    _instance ??= ApiClient._internal();
    return _instance!;
  }

  Dio get dio => _dio;
  String? get lastExtractedToken => _lastExtractedToken;

  void _extractSessionCookie(Headers headers) {
    final setCookies = headers['set-cookie'];
    if (setCookies != null && setCookies.isNotEmpty) {
      for (final cookie in setCookies) {
        final match = RegExp(r'roamora_session=([^;,\s]+)').firstMatch(cookie);
        if (match != null && match.group(1) != null) {
          final extracted = match.group(1)!;
          if (extracted.isNotEmpty) {
            _lastExtractedToken = extracted;
            SecureStorageService.saveSessionToken(extracted);
            debugPrint('[API] Saved session token from Set-Cookie header.');
          }
        }
      }
    }
  }

  Future<dynamic> get(String path, {Map<String, dynamic>? queryParameters}) async {
    try {
      final response = await _dio.get(path, queryParameters: queryParameters);
      return response.data;
    } on DioException catch (e) {
      if (e.error is ApiException) throw e.error!;
      throw ApiException(e.message ?? 'Request failed');
    }
  }

  Future<dynamic> post(String path, {dynamic data, Map<String, dynamic>? queryParameters}) async {
    try {
      final response = await _dio.post(path, data: data, queryParameters: queryParameters);
      _extractSessionCookie(response.headers);
      return response.data;
    } on DioException catch (e) {
      if (e.error is ApiException) throw e.error!;
      throw ApiException(e.message ?? 'Request failed');
    }
  }

  Future<dynamic> patch(String path, {dynamic data}) async {
    try {
      final response = await _dio.patch(path, data: data);
      _extractSessionCookie(response.headers);
      return response.data;
    } on DioException catch (e) {
      if (e.error is ApiException) throw e.error!;
      throw ApiException(e.message ?? 'Request failed');
    }
  }

  Future<dynamic> put(String path, {dynamic data}) async {
    try {
      final response = await _dio.put(path, data: data);
      _extractSessionCookie(response.headers);
      return response.data;
    } on DioException catch (e) {
      if (e.error is ApiException) throw e.error!;
      throw ApiException(e.message ?? 'Request failed');
    }
  }

  Future<dynamic> delete(String path, {dynamic data}) async {
    try {
      final response = await _dio.delete(path, data: data);
      return response.data;
    } on DioException catch (e) {
      if (e.error is ApiException) throw e.error!;
      throw ApiException(e.message ?? 'Request failed');
    }
  }
}
