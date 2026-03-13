import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:healthlink_connect_flutter/core/di/injection_container.dart';

class AuthInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final storage = sl<FlutterSecureStorage>();
    final token = await storage.read(key: 'auth_token');
    
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    
    super.onRequest(options, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      // Future integration: handle token refresh via a dedicated refresh endpoint
      // and retry the failed request using a queued approach.
      // E.g. trigger router to login page if refresh fails.
    }
    super.onError(err, handler);
  }
}
