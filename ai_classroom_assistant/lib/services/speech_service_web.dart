import 'dart:async';
import 'dart:js_interop';
import 'package:web/web.dart' as web;

class SpeechService {
  static final SpeechService _instance = SpeechService._internal();
  factory SpeechService() => _instance;
  SpeechService._internal();

  web.SpeechRecognition? _recognition;
  bool _isInitialized = false;
  bool _isListening = false;

  void Function(String)? onPartial;
  void Function(String)? onFinal;
  void Function(String)? onError;
  void Function(bool)? onListeningStateChanged;
  void Function(String)? onTranscriptChanged;

  String _fullTranscript = '';
  String _currentPartial = '';

  bool get isInitialized => _isInitialized;
  bool get isListening => _isListening;
  String get currentTranscript => _fullTranscript;

  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      _recognition = web.SpeechRecognition();
      _recognition!.continuous = true;
      _recognition!.interimResults = true;
      _recognition!.lang = 'en-US';

      _recognition!.addEventListener('result', (web.Event e) {
        final event = e as web.SpeechRecognitionEvent;
        final results = event.results;
        if (results.length == 0) return;

        final result = results.item(results.length - 1);
        if (result == null) return;
        
        final alternative = result.item(0);
        if (alternative == null) return;
        
        final transcript = alternative.transcript;
        final isFinal = result.isFinal;

        if (isFinal) {
          if (transcript.trim().isNotEmpty) {
            if (_fullTranscript.isEmpty) {
              _fullTranscript = transcript.trim();
            } else {
              _fullTranscript += ' ${transcript.trim()}';
            }
          }
          _currentPartial = '';
          onFinal?.call(transcript);
        } else {
          _currentPartial = transcript;
          onPartial?.call(transcript);
        }
        _notifyTranscriptChanged();
      }.toJS);

      _recognition!.addEventListener('error', (web.Event e) {
        final event = e as web.SpeechRecognitionErrorEvent;
        onError?.call('Speech recognition error: ${event.error}');
      }.toJS);

      _recognition!.addEventListener('end', (web.Event event) {
        if (_isListening) {
          _isListening = false;
          onListeningStateChanged?.call(false);
        }
      }.toJS);

      _recognition!.addEventListener('start', (web.Event event) {
        if (!_isListening) {
          _isListening = true;
          onListeningStateChanged?.call(true);
        }
      }.toJS);

      _isInitialized = true;
      return true;
    } catch (e) {
      onError?.call('Failed to initialize speech recognition: $e');
      return false;
    }
  }

  Future<void> startListening({
    bool resetSessionText = false,
    Duration? pauseFor,
    Duration listenFor = const Duration(minutes: 60),
    bool onDevice = false,
    bool enableAutoRestart = false,
  }) async {
    if (!_isInitialized) {
      final ok = await initialize();
      if (!ok) return;
    }

    if (_isListening) return;

    if (resetSessionText) {
      _fullTranscript = '';
      _currentPartial = '';
      _notifyTranscriptChanged();
    }

    try {
      _recognition?.start();
    } catch (e) {
      onError?.call('Failed to start listening: $e');
    }
  }

  Future<void> stopListening() async {
    if (!_isListening) return;

    try {
      _recognition?.stop();
    } catch (e) {
      onError?.call('Failed to stop listening: $e');
    }
  }

  Future<void> cancel() async {
    if (!_isListening) return;

    try {
      _recognition?.abort();
    } catch (_) {}
    _currentPartial = '';
    _notifyTranscriptChanged();
  }

  void clearTranscript() {
    _fullTranscript = '';
    _currentPartial = '';
    _notifyTranscriptChanged();
  }

  void setExistingTranscript(String existingText) {
    _fullTranscript = existingText.trim();
    _currentPartial = '';
    _notifyTranscriptChanged();
  }

  void _notifyTranscriptChanged() {
    final combined = _fullTranscript.isEmpty && _currentPartial.isEmpty
        ? ''
        : _currentPartial.isEmpty
            ? _fullTranscript
            : _fullTranscript.isEmpty
                ? _currentPartial
                : '$_fullTranscript $_currentPartial';
    onTranscriptChanged?.call(combined);
  }

  void dispose() {
    if (_isListening) cancel();
    _recognition = null;
    onPartial = null;
    onFinal = null;
    onError = null;
    onListeningStateChanged = null;
    onTranscriptChanged = null;
  }
}
