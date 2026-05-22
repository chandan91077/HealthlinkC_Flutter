import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:healthlink_connect_flutter/core/network/api_client.dart';
import 'package:healthlink_connect_flutter/features/assistant/data/models/assistant_message.dart';

/// MediAI Assistant Remote Data Source
/// Handles all HTTP calls to the backend AI endpoints.
class AssistantRemoteDatasource {
  AssistantRemoteDatasource({required this.apiClient});

  final ApiClient apiClient;

  // ─── Chat Intent ──────────────────────────────────────────────────────────

  /// Send a text message to the AI and get back an action-response.
  Future<AssistantResponseModel> processIntent({
    required String text,
    required String sessionId,
  }) async {
    final response = await apiClient.post(
      '/assistant/intent',
      data: {'text': text, 'sessionId': sessionId},
    );
    return AssistantResponseModel.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  // ─── Medical Report Analyzer ──────────────────────────────────────────────

  /// Upload an image file to the Vision API for analysis.
  Future<ReportAnalysisModel> analyzeReport(File imageFile) async {
    // Convert image file to base64 data URL
    final bytes = await imageFile.readAsBytes();
    final mimeType = _getMimeType(imageFile.path);
    final base64Image = 'data:$mimeType;base64,${base64Encode(bytes)}';

    final response = await apiClient.post(
      '/assistant/report/analyze',
      data: {'imageBase64': base64Image},
    );

    return ReportAnalysisModel.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  // ─── Memory Profile ───────────────────────────────────────────────────────

  /// Fetch the user's memory profile (language, conditions, etc.)
  Future<Map<String, dynamic>?> getMemoryProfile() async {
    try {
      final response = await apiClient.get('/assistant/memory/profile');
      final data = response.data as Map<String, dynamic>?;
      return data?['profile'] as Map<String, dynamic>?;
    } on DioException catch (e) {
      // 404 means no profile yet — not an error
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  String _getMimeType(String path) {
    final ext = path.split('.').last.toLowerCase();
    const types = {
      'jpg': 'image/jpeg',
      'jpeg': 'image/jpeg',
      'png': 'image/png',
      'webp': 'image/webp',
    };
    return types[ext] ?? 'image/jpeg';
  }
}
