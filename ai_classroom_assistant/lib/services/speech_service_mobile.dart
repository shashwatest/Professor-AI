import 'dart:async';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;
import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';
import 'foreground_speech_service.dart';

class SpeechService {
  static final SpeechService _instance = SpeechService._internal();
  factory SpeechService() => _instance;
  SpeechService._internal();

  final SpeechToText _speechToText = SpeechToText();
  bool _isInitialized = false;
  bool _isListening = false;

  void Function(String)? onPartial;
  void Function(String)? onFinal;
  void Function(String)? onError;
  void Function(bool)? onListeningStateChanged;
  void Function(String)? onTranscriptChanged;

  String _fullTranscript = '';
  String _currentPartial = '';

  bool? _isDesktopCached;

  bool get isInitialized => _isInitialized;
  bool get isListening => _isListening;
  String get currentTranscript => _fullTranscript;

  bool get _isDesktop {
    _isDesktopCached ??= !kIsWeb && (
      defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.linux ||
      defaultTargetPlatform == TargetPlatform.macOS
    );
    return _isDesktopCached!;
  }

  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      if (_isDesktop) {
        onError?.call('Speech recognition is not supported on desktop builds.');
        return false;
      }

      if (!kIsWeb) {
        final micPermission = await Permission.microphone.status;
        if (micPermission != PermissionStatus.granted) {
          final result = await Permission.microphone.request();
          if (result != PermissionStatus.granted) {
            onError?.call('Microphone permission denied');
            return false;
          }
        }
        
        final notificationPermission = await Permission.notification.status;
        if (notificationPermission != PermissionStatus.granted) {
          await Permission.notification.request();
        }
      }

      _isInitialized = await _speechToText.initialize(
        onError: (error) => onError?.call(error?.errorMsg ?? error.toString()),
        onStatus: (status) {
          final listening = status.toLowerCase() == 'listening';
          if (_isListening != listening) {
            _isListening = listening;
            onListeningStateChanged?.call(_isListening);
          }
        },
      );

      return _isInitialized;
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
    if (_isDesktop) {
      onError?.call('Speech recognition is not supported on desktop platforms.');
      return;
    }

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

    await ForegroundSpeechService.initialize();
    final started = await ForegroundSpeechService.start();
    if (!started) {
      onError?.call('Failed to start foreground service');
    }

    try {
      await _speechToText.listen(
        onResult: (result) {
          final recognized = result.recognizedWords;
          final isFinal = result.finalResult;

          if (isFinal) {
            if (recognized.trim().isNotEmpty) {
              if (_fullTranscript.isEmpty) {
                _fullTranscript = recognized.trim();
              } else {
                _fullTranscript += ' ${recognized.trim()}';
              }
            }
            _currentPartial = '';
            onFinal?.call(recognized);
          } else {
            _currentPartial = recognized;
            onPartial?.call(recognized);
          }
          _notifyTranscriptChanged();
        },
        listenFor: listenFor,
        pauseFor: pauseFor ?? const Duration(days: 1),
        partialResults: true,
        cancelOnError: false,
        listenMode: ListenMode.dictation,
        onDevice: onDevice,
      );
    } catch (e) {
      onError?.call('Failed to start listening: $e');
    }
  }

  Future<void> stopListening() async {
    if (!_isListening) return;
    
    try {
      await _speechToText.stop();
      await ForegroundSpeechService.stop();
    } catch (e) {
      onError?.call('Failed to stop listening: $e');
    }
  }

  Future<void> cancel() async {
    if (!_isListening) return;
    
    try {
      await _speechToText.cancel();
      await ForegroundSpeechService.stop();
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
    onPartial = null;
    onFinal = null;
    onError = null;
    onListeningStateChanged = null;
    onTranscriptChanged = null;
  }
}