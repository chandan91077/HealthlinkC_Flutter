import 'dart:io';
import 'package:healthlink_connect_flutter/features/assistant/data/datasources/assistant_remote_datasource.dart';
import 'package:healthlink_connect_flutter/features/assistant/data/models/assistant_message.dart';

/// Assistant Repository
/// Abstracts the data source from the presentation layer.
class AssistantRepository {
  AssistantRepository({required this.datasource});

  final AssistantRemoteDatasource datasource;

  Future<AssistantResponseModel> processIntent({
    required String text,
    required String sessionId,
  }) =>
      datasource.processIntent(text: text, sessionId: sessionId);

  Future<ReportAnalysisModel> analyzeReport(File imageFile) =>
      datasource.analyzeReport(imageFile);

  Future<Map<String, dynamic>?> getMemoryProfile() =>
      datasource.getMemoryProfile();
}
