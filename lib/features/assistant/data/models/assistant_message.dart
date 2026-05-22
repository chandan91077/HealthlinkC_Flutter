/// Represents a single chat message in the MediAI assistant.
class AssistantMessage {
  const AssistantMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.timestamp,
    this.isLoading = false,
    this.action,
  });

  final String id;
  final String role; // 'user' | 'assistant'
  final String content;
  final DateTime timestamp;
  final bool isLoading;
  final String? action;

  factory AssistantMessage.user(String content) => AssistantMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        role: 'user',
        content: content,
        timestamp: DateTime.now(),
      );

  factory AssistantMessage.loading() => AssistantMessage(
        id: 'loading_${DateTime.now().millisecondsSinceEpoch}',
        role: 'assistant',
        content: '',
        timestamp: DateTime.now(),
        isLoading: true,
      );

  factory AssistantMessage.reply({
    required String id,
    required String content,
    String? action,
  }) =>
      AssistantMessage(
        id: id,
        role: 'assistant',
        content: content,
        timestamp: DateTime.now(),
        action: action,
      );

  AssistantMessage copyWith({
    String? content,
    bool? isLoading,
    String? action,
  }) =>
      AssistantMessage(
        id: id,
        role: role,
        content: content ?? this.content,
        timestamp: timestamp,
        isLoading: isLoading ?? this.isLoading,
        action: action ?? this.action,
      );
}

/// Model for the parsed backend response
class AssistantResponseModel {
  const AssistantResponseModel({
    required this.reply,
    required this.action,
    this.params,
  });

  final String reply;
  final String action;
  final Map<String, dynamic>? params;

  factory AssistantResponseModel.fromJson(Map<String, dynamic> json) =>
      AssistantResponseModel(
        reply: json['reply'] as String? ?? '',
        action: json['action'] as String? ?? 'reply',
        params: json['params'] as Map<String, dynamic>?,
      );
}

/// Model for the medical report analysis response
class ReportAnalysisModel {
  const ReportAnalysisModel({
    required this.diagnoses,
    required this.vitals,
    required this.summary,
  });

  final List<String> diagnoses;
  final Map<String, String> vitals;
  final String summary;

  factory ReportAnalysisModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? {};
    final rawVitals = data['vitals'] as Map<String, dynamic>? ?? {};

    return ReportAnalysisModel(
      diagnoses: List<String>.from(data['diagnoses'] as List? ?? []),
      vitals: rawVitals.map((k, v) => MapEntry(k, v.toString())),
      summary: data['summary'] as String? ?? '',
    );
  }
}
