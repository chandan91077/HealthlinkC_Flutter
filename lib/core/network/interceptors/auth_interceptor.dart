import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:healthlink_connect_flutter/core/di/injection_container.dart';

class AuthInterceptor extends Interceptor {
  @override
  void onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    final storage = sl<FlutterSecureStorage>();
    final token = await storage.read(key: 'auth_token');

    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    super.onRequest(options, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // Handle session invalidation (logged in on another device)
    if (err.response?.statusCode == 403) {
      final responseData = err.response?.data;
      if (responseData is Map<String, dynamic> &&
          responseData['code'] == 'SESSION_INVALIDATED') {
        // Clear stored credentials
        final storage = sl<FlutterSecureStorage>();
        await storage.delete(key: 'auth_token');
        await storage.delete(key: 'user_role');

        // Trigger logout and navigation (handled by AppRouter/GoRouter)
        // The app will detect no token and redirect to auth
        handler.reject(
          DioException(
            requestOptions: err.requestOptions,
            response: err.response,
            type: DioExceptionType.unknown,
            error: 'Session invalidated on another device',
          ),
        );
        return;
      }
    }

    if (err.response?.statusCode == 401) {
      // Future integration: handle token refresh via a dedicated refresh endpoint
      // and retry the failed request using a queued approach.
      // E.g. trigger router to login page if refresh fails.
    }
    super.onError(err, handler);
  }
}
