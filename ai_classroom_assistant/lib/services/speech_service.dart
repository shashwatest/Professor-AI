// lib/services/speech_service.dart
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';

class SpeechService {
  final SpeechToText _speechToText = SpeechToText();
  bool _isInitialized = false;
  bool _isListening = false;

  /// Callbacks:
  /// onPartial -> receives temporary / interim text (updated frequently)
  /// onFinal -> receives committed text (finalized by the engine)
  /// onError -> error strings
  /// onListeningStateChanged -> listening true/false
  Function(String)? onPartial;
  Function(String)? onFinal;
  Function(String)? onError;
  Function(bool)? onListeningStateChanged;

  bool get isInitialized => _isInitialized;
  bool get isListening => _isListening;

  // track last final and partial to avoid duplicates/flooding UI
  String _lastFinal = '';
  String _lastPartial = '';

  // Detect desktop platforms where speech_to_text is typically unsupported
  bool get _isDesktop {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.macOS;
  }

  Future<bool> initialize() async {
    try {
      if (_isDesktop) {
        onError?.call('Speech recognition is not supported on desktop builds.');
        return false;
      }

      // On web, browser prompts for microphone permission; permission_handler is for native
      if (!kIsWeb) {
        final permission = await Permission.microphone.request();
        if (permission != PermissionStatus.granted) {
          onError?.call('Microphone permission denied');
          return false;
        }
      }

      _isInitialized = await _speechToText.initialize(
        onError: (error) => onError?.call(error.errorMsg ?? error.toString()),
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

  /// Start listening
  /// - pauseFor: silence timeout to consider phrase finalized (helps control finalization)
  /// - listenFor: overall session timeout
  /// - onDevice: prefer on-device recognition when available
  Future<void> startListening({
    bool singleSpeaker = true,
    Duration? pauseFor,
    Duration listenFor = const Duration(hours: 2),
    bool onDevice = false,
    bool resetSessionText = false,
  }) async {
    pauseFor ??= const Duration(milliseconds: 700);

    if (_isDesktop) {
      onError?.call('Speech recognition is not supported on desktop platforms.');
      return;
    }

    if (!_isInitialized) {
      final ok = await initialize();
      if (!ok) return;
    }

    // Prevent duplicate starts
    if (_isListening) return;

    // Optionally reset text tracking for a new session
    if (resetSessionText) {
      _lastFinal = '';
      _lastPartial = '';
    }

    try {
      await _speechToText.listen(
        onResult: (result) {
          final recognized = result.recognizedWords ?? '';

          // Many implementations expose a finalResult boolean; use dynamic defensively
          bool isFinal = false;
          try {
            final dyn = result as dynamic;
            isFinal = (dyn.finalResult == true);
          } catch (_) {
            isFinal = result.finalResult ?? false;
          }

          if (isFinal) {
            final text = recognized.trim();

            // If final is empty, still notify so UI can clear partials
            if (text.isEmpty) {
              _lastPartial = '';
              onFinal?.call('');
              return;
            }

            // If final contains previous final (cumulative), prefer replacement
            if (_lastFinal.isNotEmpty && text.startsWith(_lastFinal)) {
              _lastFinal = text;
              onFinal?.call(text);
            } else if (_lastFinal.isEmpty) {
              _lastFinal = text;
              onFinal?.call(text);
            } else {
              // New final chunk; send full text and let UI decide append/merge
              _lastFinal = text;
              onFinal?.call(text);
            }

            // clear partial
            _lastPartial = '';
          } else {
            // Interim partial — replace ephemeral partial region (do not append)
            if (recognized != _lastPartial) {
              _lastPartial = recognized;
              onPartial?.call(recognized);
            }
          }
        },
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

  Future<void> stopListening() async {
    if (_isListening) {
      try {
        await _speechToText.stop();
      } catch (e) {
        onError?.call('Failed to stop listening: $e');
      }
    }
  }

  void cancel() {
    try {
      _speechToText.cancel();
    } catch (_) {}
    _lastPartial = '';
  }

  void dispose() {
    cancel();
  }
}




// import 'package:speech_to_text/speech_to_text.dart';
// import 'package:permission_handler/permission_handler.dart';

// class SpeechService {
//   final SpeechToText _speechToText = SpeechToText();
//   bool _isInitialized = false;
//   bool _isListening = false;

//   /// Callbacks:
//   /// onPartial -> receives temporary / interim text (updated frequently)
//   /// onFinal -> receives committed text (finalized by the engine)
//   /// onError -> error strings
//   /// onListeningStateChanged -> listening true/false
//   Function(String)? onPartial;
//   Function(String)? onFinal;
//   Function(String)? onError;
//   Function(bool)? onListeningStateChanged;

//   bool get isInitialized => _isInitialized;
//   bool get isListening => _isListening;

//   // track last final text (helps avoid duplication)
//   String _lastFinal = '';

//   Future<bool> initialize() async {
//     try {
//       final permission = await Permission.microphone.request();
//       if (permission != PermissionStatus.granted) {
//         onError?.call('Microphone permission denied');
//         return false;
//       }

//       _isInitialized = await _speechToText.initialize(
//         onError: (error) => onError?.call(error.errorMsg ?? error.toString()),
//         onStatus: (status) {
//           final listening = status.toLowerCase() == 'listening';
//           if (_isListening != listening) {
//             _isListening = listening;
//             onListeningStateChanged?.call(_isListening);
//           }
//         },
//       );

//       return _isInitialized;
//     } catch (e) {
//       onError?.call('Failed to initialize speech recognition: $e');
//       return false;
//     }
//   }

//   /// Start listening
//   /// - singleSpeaker: controls listenMode; keep as needed
//   /// - pauseFor: duration of silence to consider final (helps Android behavior)
//   /// - onDevice: use on-device recognition when available
//   Future<void> startListening({
//     bool singleSpeaker = true,
//     //Duration pauseFor = const Duration(milliseconds: 700),
//     Duration listenFor = const Duration(hours: 2),
//     bool onDevice = false,
//   }) async {
//     if (!_isInitialized) {
//       await initialize();
//     }

//     // Prevent duplicate starts
//     if (_isInitialized && !_isListening) {
//       _lastFinal = ''; // reset last final if desired on start
//       try {
//         await _speechToText.listen(
//           onResult: (result) {
//             final recognized = result.recognizedWords ?? '';

//             // Some implementations provide a 'finalResult' boolean:
//             final isFinal = (result as dynamic).finalResult == true;

//             if (isFinal) {
//               // avoid empty or duplicated appends
//               if (recognized.trim().isNotEmpty && recognized.trim() != _lastFinal.trim()) {
//                 _lastFinal = recognized;
//                 onFinal?.call(recognized);
//               } else {
//                 // Even if same as last final, notify final once to let UI clear partials
//                 onFinal?.call(recognized);
//               }
//             } else {
//               // interim partial result: replace partial area in UI
//               onPartial?.call(recognized);
//             }
//           },
//           listenFor: listenFor,
//           //pauseFor: pauseFor,
//           partialResults: true,
//           cancelOnError: true,
//           // Dictation mode is best for long-form speech like lectures.
//           listenMode: ListenMode.dictation,
//           onDevice: onDevice,
//         );
//       } catch (e) {
//         onError?.call('Failed to start listening: $e');
//       }
//     }
//   }

//   Future<void> stopListening() async {
//     if (_isListening) {
//       try {
//         await _speechToText.stop();
//       } catch (e) {
//         onError?.call('Failed to stop listening: $e');
//       }
//     }
//   }

//   void cancel() {
//     _speechToText.cancel();
//   }

//   void dispose() {
//     cancel();
//   }
// }