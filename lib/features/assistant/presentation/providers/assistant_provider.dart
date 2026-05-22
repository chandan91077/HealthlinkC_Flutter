import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:healthlink_connect_flutter/features/assistant/data/models/assistant_message.dart';
import 'package:healthlink_connect_flutter/features/assistant/data/repositories/assistant_repository.dart';
import 'package:healthlink_connect_flutter/services/voice_service.dart';

/// MediAI Assistant Provider
/// Manages chat history, processes intents, analyzes reports,
/// and coordinates with VoiceService for STT/TTS.
class AssistantProvider extends ChangeNotifier {
  AssistantProvider({
    required this.repository,
    required this.voiceService,
  });

  final AssistantRepository repository;
  final VoiceService voiceService;

  final String _sessionId = const Uuid().v4();
  final List<AssistantMessage> _messages = [];

  bool _isThinking = false;
  String _interimText = '';
  bool _isTtsEnabled = false;

  List<AssistantMessage> get messages => List.unmodifiable(_messages);
  bool get isThinking => _isThinking;
  bool get isListening => voiceService.isListening;
  String get interimText => _interimText;
  bool get isTtsEnabled => _isTtsEnabled;
  bool get hasMessages => _messages.isNotEmpty;

  // ─── Initialization ───────────────────────────────────────────────────────

  Future<void> initialize(String userId) async {
    // Load language preference from memory profile
    try {
      final profile = await repository.getMemoryProfile();
      final lang = profile?['aiPreferences']?['language'] as String?;
      if (lang != null && lang.isNotEmpty) {
        await voiceService.setLanguage(lang);
      }
    } catch (_) {}

    // Set up voice callbacks
    voiceService.onResult = (text, isFinal) {
      _interimText = isFinal ? '' : text;
      if (isFinal && text.isNotEmpty) {
        submitText(text);
      }
      notifyListeners();
    };
    voiceService.onError = (error) {
      _interimText = '';
      _addSystemMessage('⚠️ $error');
      notifyListeners();
    };

    // Welcome message
    if (_messages.isEmpty) {
      _messages.add(AssistantMessage(
        id: 'welcome',
        role: 'assistant',
        content: '👋 Hi! I\'m MediAI, your personal healthcare assistant. '
            'Ask me anything, upload a medical report, or say it out loud!',
        timestamp: DateTime.now(),
      ));
      notifyListeners();
    }
  }

  // ─── Text / Voice Submit ──────────────────────────────────────────────────

  Future<void> submitText(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _isThinking) return;

    _messages.add(AssistantMessage.user(trimmed));
    final loadingMsg = AssistantMessage.loading();
    _messages.add(loadingMsg);
    _isThinking = true;
    notifyListeners();

    try {
      final response = await repository.processIntent(
        text: trimmed,
        sessionId: _sessionId,
      );

      _replaceLoading(
        loadingMsg.id,
        AssistantMessage.reply(
          id: loadingMsg.id,
          content: response.reply,
          action: response.action,
        ),
      );

      if (_isTtsEnabled && response.reply.isNotEmpty) {
        await voiceService.speak(response.reply);
      }
    } catch (e) {
      _replaceLoading(
        loadingMsg.id,
        AssistantMessage.reply(
          id: loadingMsg.id,
          content: "Sorry, I couldn't process that right now. Please try again. 🩺",
        ),
      );
    } finally {
      _isThinking = false;
      notifyListeners();
    }
  }

  // ─── Medical Report Analyzer ──────────────────────────────────────────────

  Future<void> analyzeReport(File imageFile) async {
    _messages.add(AssistantMessage.user('📎 Uploaded report: ${imageFile.path.split('/').last}'));
    final loadingMsg = AssistantMessage.loading();
    _messages.add(loadingMsg);
    _isThinking = true;
    notifyListeners();

    try {
      final result = await repository.analyzeReport(imageFile);

      final buffer = StringBuffer();
      buffer.writeln('I\'ve analyzed your report. ${result.summary}');
      buffer.writeln();

      if (result.diagnoses.isNotEmpty) {
        buffer.writeln('**Detected Conditions:** ${result.diagnoses.join(', ')}');
      }

      if (result.vitals.isNotEmpty) {
        buffer.writeln('**Key Vitals:**');
        result.vitals.forEach((k, v) => buffer.writeln('- $k: $v'));
      }

      buffer.writeln();
      buffer.writeln('*I\'ve securely updated your permanent health profile.*');

      final reply = buffer.toString().trim();

      _replaceLoading(
        loadingMsg.id,
        AssistantMessage.reply(id: loadingMsg.id, content: reply, action: 'reportAnalysis'),
      );

      if (_isTtsEnabled) {
        await voiceService.speak('I\'ve analyzed your report and updated your health profile.');
      }
    } catch (e) {
      _replaceLoading(
        loadingMsg.id,
        AssistantMessage.reply(
          id: loadingMsg.id,
          content: "Sorry, I couldn't analyze this report right now. Please ensure it's a clear image.",
        ),
      );
    } finally {
      _isThinking = false;
      notifyListeners();
    }
  }

  // ─── Voice Controls ───────────────────────────────────────────────────────

  Future<void> toggleVoiceInput() async {
    if (voiceService.isListening) {
      voiceService.stopListening();
    } else {
      _interimText = '';
      await voiceService.startListening();
    }
    notifyListeners();
  }

  void toggleTts() {
    _isTtsEnabled = !_isTtsEnabled;
    if (!_isTtsEnabled) voiceService.stopSpeaking();
    notifyListeners();
  }

  void clearMessages() {
    _messages.clear();
    notifyListeners();
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  void _replaceLoading(String id, AssistantMessage replacement) {
    final idx = _messages.indexWhere((m) => m.id == id);
    if (idx != -1) {
      _messages[idx] = replacement;
    } else {
      _messages.add(replacement);
    }
  }

  void _addSystemMessage(String content) {
    _messages.add(AssistantMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      role: 'assistant',
      content: content,
      timestamp: DateTime.now(),
    ));
  }
}
