import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';

/// MediAI Voice Service
/// Wraps native STT (speech_to_text) and TTS (flutter_tts) with dynamic
/// language switching — mirrors the web VoiceService.ts behaviour.
class VoiceService extends ChangeNotifier {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();

  bool _isListening = false;
  bool _isSpeaking = false;
  String _interimText = '';
  String _currentLang = 'en-US';
  bool _isInitialized = false;

  bool get isListening => _isListening;
  bool get isSpeaking => _isSpeaking;
  String get interimText => _interimText;
  String get currentLang => _currentLang;

  // ─── Callbacks ────────────────────────────────────────────────────────────
  void Function(String text, bool isFinal)? onResult;
  void Function(String error)? onError;

  // ─── Initialization ───────────────────────────────────────────────────────

  Future<bool> initialize() async {
    if (_isInitialized) return true;
    try {
      _isInitialized = await _speech.initialize(
        onError: (error) {
          debugPrint('[VoiceService] STT error: ${error.errorMsg}');
          _isListening = false;
          onError?.call(error.errorMsg);
          notifyListeners();
        },
        onStatus: (status) {
          debugPrint('[VoiceService] STT status: $status');
          if (status == 'done' || status == 'notListening') {
            _isListening = false;
            notifyListeners();
          }
        },
      );

      await _tts.setSharedInstance(true);
      await _tts.awaitSpeakCompletion(true);
      _tts.setCompletionHandler(() {
        _isSpeaking = false;
        notifyListeners();
      });

      return _isInitialized;
    } catch (e) {
      debugPrint('[VoiceService] init error: $e');
      return false;
    }
  }

  // ─── Language ─────────────────────────────────────────────────────────────

  /// Set language for both STT and TTS.
  /// langCode examples: 'en-US', 'hi-IN', 'es-ES', 'fr-FR'
  Future<void> setLanguage(String langCode) async {
    _currentLang = langCode;
    try {
      await _tts.setLanguage(langCode);
    } catch (e) {
      debugPrint('[VoiceService] setLanguage error (TTS): $e');
    }
    notifyListeners();
  }

  // ─── Voice Input (STT) ────────────────────────────────────────────────────

  Future<bool> startListening() async {
    final ready = await initialize();
    if (!ready) {
      onError?.call('Voice recognition is not available on this device.');
      return false;
    }

    if (_isListening) return false;

    _interimText = '';
    _isListening = true;
    notifyListeners();

    await _speech.listen(
      localeId: _currentLang,
      partialResults: true,
      onResult: (result) {
        _interimText = result.recognizedWords;
        final isFinal = result.finalResult;
        if (isFinal) {
          _isListening = false;
          _interimText = '';
        }
        onResult?.call(result.recognizedWords, isFinal);
        notifyListeners();
      },
    );

    return true;
  }

  void stopListening() {
    _speech.stop();
    _isListening = false;
    _interimText = '';
    notifyListeners();
  }

  // ─── Voice Output (TTS) ───────────────────────────────────────────────────

  /// Speak text aloud using native TTS in the user's current language.
  Future<void> speak(String text) async {
    if (text.isEmpty) return;

    // Strip markdown formatting
    final clean = text
        .replaceAll(RegExp(r'\*\*(.*?)\*\*'), r'$1')
        .replaceAll(RegExp(r'\*(.*?)\*'), r'$1')
        .replaceAll(RegExp(r'[^\x00-\x7F]', unicode: true), '') // strip emoji
        .trim();

    if (clean.isEmpty) return;

    try {
      await _tts.setLanguage(_currentLang);
      await _tts.setSpeechRate(0.5);
      await _tts.setPitch(1.0);
      _isSpeaking = true;
      notifyListeners();
      await _tts.speak(clean);
    } catch (e) {
      debugPrint('[VoiceService] TTS error: $e');
      _isSpeaking = false;
      notifyListeners();
    }
  }

  Future<void> stopSpeaking() async {
    await _tts.stop();
    _isSpeaking = false;
    notifyListeners();
  }

  bool get isSupported => _isInitialized;

  @override
  void dispose() {
    _speech.stop();
    _tts.stop();
    super.dispose();
  }
}
