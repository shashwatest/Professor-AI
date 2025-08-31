import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';

/// Optimized SpeechService for speech-to-text functionality
/// - Manual start/stop control only
/// - No automatic restarts
/// - Persistent transcript support
/// - Memory efficient transcript management
class SpeechService {
  static final SpeechService _instance = SpeechService._internal();
  factory SpeechService() => _instance;
  SpeechService._internal();

  final SpeechToText _speechToText = SpeechToText();
  bool _isInitialized = false;
  bool _isListening = false;

  // Optimized callbacks for better performance
  void Function(String)? onPartial;
  void Function(String)? onFinal;
  void Function(String)? onError;
  void Function(bool)? onListeningStateChanged;
  void Function(String)? onTranscriptChanged;

  // Auto-restart functionality
  bool _shouldAutoRestart = false;
  Timer? _restartTimer;

  // Internal transcript state - using StringBuffer for efficient concatenation
  final StringBuffer _committedBuffer = StringBuffer();
  String _partial = '';

  // Cache for platform detection
  bool? _isDesktopCached;

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isListening => _isListening;

  // Cached platform detection for better performance
  bool get _isDesktop {
    _isDesktopCached ??= !kIsWeb && (
      defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.linux ||
      defaultTargetPlatform == TargetPlatform.macOS
    );
    return _isDesktopCached!;
  }

  /// Initialize the speech service with optimized error handling
  Future<bool> initialize() async {
    if (_isInitialized) return true; // Skip if already initialized

    try {
      if (_isDesktop) {
        onError?.call('Speech recognition is not supported on desktop builds.');
        return false;
      }

      // Optimized permission check - only for non-web platforms
      if (!kIsWeb) {
        final permission = await Permission.microphone.status;
        if (permission != PermissionStatus.granted) {
          final result = await Permission.microphone.request();
          if (result != PermissionStatus.granted) {
            onError?.call('Microphone permission denied');
            return false;
          }
        }
      }

      _isInitialized = await _speechToText.initialize(
        onError: _handleError,
        onStatus: _handleStatus,
      );

      return _isInitialized;
    } catch (e) {
      onError?.call('Failed to initialize speech recognition: $e');
      return false;
    }
  }

  // Optimized error handler
  void _handleError(dynamic error) {
    final errorMsg = error?.errorMsg ?? error.toString();
    onError?.call(errorMsg);
  }

  /// Start listening for speech with optimized parameters
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

    if (_isListening) return; // Already listening

    if (resetSessionText) {
      _committedBuffer.clear();
      _partial = '';
      _emitTranscriptChanged();
    }

    // Set auto-restart flag
    _shouldAutoRestart = enableAutoRestart;

    try {
      await _speechToText.listen(
        onResult: _handleResult,
        listenFor: listenFor,
        pauseFor: pauseFor,
        partialResults: true,
        cancelOnError: true,
        listenMode: ListenMode.dictation,
        onDevice: onDevice,
      );
    } catch (e) {
      onError?.call('Failed to start listening: $e');
    }
  }

  /// Stop listening with optimized state management
  Future<void> stopListening() async {
    if (!_isListening) return;
    
    // Disable auto-restart when manually stopping
    _shouldAutoRestart = false;
    _restartTimer?.cancel();
    
    try {
      await _speechToText.stop();
    } catch (e) {
      onError?.call('Failed to stop listening: $e');
    }
  }

  /// Cancel listening and clear partials
  Future<void> cancel() async {
    if (!_isListening) return;
    
    // Disable auto-restart when cancelling
    _shouldAutoRestart = false;
    _restartTimer?.cancel();
    
    try {
      await _speechToText.cancel();
    } catch (_) {
      // Ignore cancel errors
    }
    _partial = '';
    _emitTranscriptChanged();
  }

  /// Clear all transcript data efficiently
  void clearTranscript() {
    _committedBuffer.clear();
    _partial = '';
    _emitTranscriptChanged();
  }

  /// Set existing transcript content (for preserving across recording sessions)
  void setExistingTranscript(String existingText) {
    if (existingText.trim().isNotEmpty) {
      _committedBuffer.clear();
      _committedBuffer.write(existingText.trim());
      _partial = '';
      _emitTranscriptChanged();
    }
  }

  /// Get current committed transcript
  String get currentTranscript => _committedBuffer.toString().trim();

  /// Dispose of the service
  void dispose() {
    if (_isListening) {
      cancel();
    }
    _restartTimer?.cancel();
    // Clear callbacks to prevent memory leaks
    onPartial = null;
    onFinal = null;
    onError = null;
    onListeningStateChanged = null;
    onTranscriptChanged = null;
  }

  // ---- Optimized Private methods ----

  void _handleStatus(String status) {
    final listening = status.toLowerCase() == 'listening';
    if (_isListening != listening) {
      _isListening = listening;
      onListeningStateChanged?.call(_isListening);
      
      // Auto-restart if stopped unexpectedly and auto-restart is enabled
      if (!listening && _shouldAutoRestart && _isInitialized) {
        _scheduleRestart();
      }
    }
  }

  void _handleResult(dynamic result) {
    if (result == null) return;
    
    try {
      final recognized = result.recognizedWords as String? ?? '';
      final isFinal = result.finalResult == true;

      if (isFinal) {
        _processFinal(recognized.trim());
      } else {
        _processPartial(recognized);
      }
    } catch (e) {
      onError?.call('Error processing speech result: $e');
    }
  }

  void _processPartial(String recognized) {
    if (recognized == _partial) return; // Skip if no change
    
    _partial = recognized;
    onPartial?.call(_partial);
    _emitTranscriptChanged();
  }

  void _processFinal(String recognized) {
    if (recognized.isEmpty) {
      _partial = '';
      onFinal?.call('');
      _emitTranscriptChanged();
      return;
    }

    // FIXED: Improved transcript merging to preserve previous content
    final currentCommitted = _committedBuffer.toString().trim();
    final recognizedTrimmed = recognized.trim();
    
    if (currentCommitted.isEmpty) {
      // First transcription
      _committedBuffer.write(recognizedTrimmed);
    } else {
      // Check if the new text is cumulative (contains previous text)
      if (recognizedTrimmed.startsWith(currentCommitted)) {
        // This is a cumulative result, replace the buffer
        _committedBuffer.clear();
        _committedBuffer.write(recognizedTrimmed);
      } else if (!currentCommitted.contains(recognizedTrimmed)) {
        // This is new content, append it
        _committedBuffer.write(' ');
        _committedBuffer.write(recognizedTrimmed);
      }
      // If the recognized text is already contained in current committed text,
      // we don't need to do anything (avoid duplicates)
    }

    _partial = '';
    onFinal?.call(recognized);
    _emitTranscriptChanged();
  }

  void _emitTranscriptChanged() {
    final combined = _buildCombined();
    onTranscriptChanged?.call(combined);
  }

  String _buildCombined() {
    final committed = _committedBuffer.toString().trim();
    final partial = _partial.trim();
    
    if (committed.isEmpty && partial.isEmpty) return '';
    if (partial.isEmpty) return committed;
    if (committed.isEmpty) return partial;
    return '$committed $partial';
  }

  /// Schedule automatic restart with minimal delay
  void _scheduleRestart() {
    _restartTimer?.cancel();
    _restartTimer = Timer(const Duration(milliseconds: 900), () async {
      if (_shouldAutoRestart && !_isListening && _isInitialized) {
        try {
          await _speechToText.listen(
            onResult: _handleResult,
            listenFor: const Duration(hours: 2),
            pauseFor: const Duration(seconds: 3),
            partialResults: true,
            cancelOnError: true,
            listenMode: ListenMode.dictation,
            onDevice: false,
          );
        } catch (e) {
          // If restart fails, try again after a short delay
          if (_shouldAutoRestart) {
            Timer(const Duration(milliseconds: 200), _scheduleRestart);
          }
        }
      }
    });
  }
}