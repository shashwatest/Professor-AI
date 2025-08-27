// lib/services/speech_service.dart
import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';

/// Robust SpeechService with partial-stabilization debounce to handle
/// cumulative interim results (common on Android Chrome).
class SpeechService {
  final SpeechToText _speechToText = SpeechToText();
  bool _isInitialized = false;
  bool _isListening = false;

  // Callbacks
  Function(String)? onPartial; // raw partials (optional)
  Function(String)? onFinal; // raw finals (optional)
  Function(String)? onError;
  Function(bool)? onListeningStateChanged;
  Function(String)? onTranscriptChanged; // combined committed + partial for UI

  bool get isInitialized => _isInitialized;
  bool get isListening => _isListening;

  // Internal transcript state
  String _committed = '';
  String _partial = '';

  // Timer to detect when partials stabilize (no new partials for N ms)
  Timer? _stabilizeTimer;
  Duration stabilizeDuration = const Duration(milliseconds: 800);

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

  /// Start listening. resetSessionText clears previous transcript.
  Future<void> startListening({
    bool resetSessionText = false,
    Duration? pauseFor,
    Duration listenFor = const Duration(minutes: 10),
    bool onDevice = false,
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

    if (_isListening) return;

    if (resetSessionText) {
      _committed = '';
      _partial = '';
      _emitTranscriptChanged();
    }

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

  Future<void> stopListening() async {
    if (_isListening) {
      try {
        await _speechToText.stop();
      } catch (e) {
        onError?.call('Failed to stop listening: $e');
      }
    }
    // commit any stabilized partial immediately when stopping
    _commitStabilizedPartialImmediately();
  }

  Future<void> cancel() async {
    try {
      await _speechToText.cancel();
    } catch (_) {}
    _clearPartialTimer();
    _partial = '';
    _emitTranscriptChanged();
  }

  void dispose() {
    cancel();
  }

  // ---- Core result handling ----

  // Use dynamic because package versions differ
  void _handleResult(dynamic result) {
    try {
      final recognized = (result?.recognizedWords ?? '') as String;

      // Detect final reliably if available
      bool isFinal = false;
      try {
        final dyn = result;
        isFinal = (dyn?.finalResult == true) || (result?.finalResult == true);
      } catch (_) {
        try {
          isFinal = (result?.finalResult ?? false) as bool;
        } catch (_) {
          isFinal = false;
        }
      }

      if (isFinal) {
        // final received -> cancel stabilize timer and commit immediately
        _clearPartialTimer();
        _processFinal(recognized.trim());
      } else {
        // interim partial -> process and (re)start stabilize timer
        _processPartial(recognized);
        _startOrResetStabilizeTimer();
      }
    } catch (e) {
      onError?.call('Error processing speech result: $e');
    }
  }

  void _processPartial(String recognized) {
    // Keep the latest partial; notify optional raw partial callback
    if (recognized != _partial) {
      _partial = recognized;
      try {
        onPartial?.call(_partial);
      } catch (_) {}
      _emitTranscriptChanged();
    } else {
      // even if identical, refresh stabilize timer to defer commit
      _startOrResetStabilizeTimer();
    }
  }

  void _processFinal(String recognized) {
    // If recognized is empty, clear partial and notify
    if (recognized.isEmpty) {
      _partial = '';
      onFinal?.call('');
      _emitTranscriptChanged();
      return;
    }

    // If recognized contains previously committed as prefix -> replace committed
    if (_committed.isNotEmpty && recognized.startsWith(_committed)) {
      _committed = recognized;
    } else if (_committed.isEmpty) {
      _committed = recognized;
    } else if (!_committed.isEmpty && !recognized.startsWith(_committed)) {
      // Append with overlap handling
      final overlapLen = _commonSuffixPrefixLength(_committed, recognized);
      if (overlapLen > 0 && overlapLen < recognized.length) {
        final appendPart = recognized.substring(overlapLen).trim();
        _committed = '${_committed.trim()} ${appendPart}';
      } else {
        _committed = '${_committed.trim()} ${recognized.trim()}';
      }
    }

    _partial = '';
    try {
      onFinal?.call(recognized);
    } catch (_) {}
    _emitTranscriptChanged();
  }

  // ---- Stabilization (debounce) logic ----

  void _startOrResetStabilizeTimer() {
    _clearPartialTimer();
    _stabilizeTimer = Timer(stabilizeDuration, () {
      // When timer fires, treat the current partial as final
      final toCommit = _partial.trim();
      if (toCommit.isNotEmpty) {
        _processFinal(toCommit);
      } else {
        // clear partial if empty
        _partial = '';
        _emitTranscriptChanged();
      }
    });
  }

  void _clearPartialTimer() {
    if (_stabilizeTimer?.isActive ?? false) {
      try {
        _stabilizeTimer?.cancel();
      } catch (_) {}
    }
    _stabilizeTimer = null;
  }

  void _commitStabilizedPartialImmediately() {
    _clearPartialTimer();
    final toCommit = _partial.trim();
    if (toCommit.isNotEmpty) {
      _processFinal(toCommit);
    }
  }

  // ---- UI emit helpers ----

  void _emitTranscriptChanged() {
    final combined = _buildCombined();
    try {
      onTranscriptChanged?.call(combined);
    } catch (_) {}
  }

  String _buildCombined() {
    final c = _committed.trim();
    final p = _partial.trim();
    if (c.isEmpty && p.isEmpty) return '';
    if (p.isEmpty) return c;
    if (c.isEmpty) return p;
    return '$c ${p}';
  }

  /// Return length (in characters) of largest suffix of a that is a prefix of b.
  int _commonSuffixPrefixLength(String a, String b) {
    if (a.isEmpty || b.isEmpty) return 0;
    final aTokens = a.split(RegExp(r'\s+'));
    final bTokens = b.split(RegExp(r'\s+'));
    int maxLen = 0;
    final maxCheck = aTokens.length < bTokens.length ? aTokens.length : bTokens.length;
    for (int k = 1; k <= maxCheck; k++) {
      final aSuffix = aTokens.sublist(aTokens.length - k).join(' ');
      final bPrefix = bTokens.sublist(0, k).join(' ');
      if (aSuffix == bPrefix) maxLen = k;
    }
    if (maxLen == 0) return 0;
    final prefix = bTokens.sublist(0, maxLen).join(' ');
    return prefix.length;
  }
}









// // lib/services/speech_service.dart
// import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
// import 'package:speech_to_text/speech_to_text.dart';
// import 'package:permission_handler/permission_handler.dart';

// /// Robust SpeechService that centralizes transcript merging to avoid
// /// duplication from cumulative interim results (common on Android Chrome).
// class SpeechService {
//   final SpeechToText _speechToText = SpeechToText();
//   bool _isInitialized = false;
//   bool _isListening = false;

//   // Callbacks:
//   Function(String)? onPartial; // interim (raw) partials
//   Function(String)? onFinal; // raw final strings
//   Function(String)? onError;
//   Function(bool)? onListeningStateChanged;

//   /// Primary convenience callback: combined committed + partial text for UI.
//   Function(String)? onTranscriptChanged;

//   bool get isInitialized => _isInitialized;
//   bool get isListening => _isListening;

//   // Internal state to avoid duplication and to merge correctly.
//   String _committed = ''; // finalized transcript
//   String _partial = ''; // current interim

//   bool get _isDesktop {
//     if (kIsWeb) return false;
//     return defaultTargetPlatform == TargetPlatform.windows ||
//         defaultTargetPlatform == TargetPlatform.linux ||
//         defaultTargetPlatform == TargetPlatform.macOS;
//   }

//   Future<bool> initialize() async {
//     try {
//       if (_isDesktop) {
//         onError?.call('Speech recognition is not supported on desktop builds.');
//         return false;
//       }

//       if (!kIsWeb) {
//         final permission = await Permission.microphone.request();
//         if (permission != PermissionStatus.granted) {
//           onError?.call('Microphone permission denied');
//           return false;
//         }
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

//   /// Start listening. UI can pass resetSessionText=true to clear previous transcript.
//   Future<void> startListening({
//     bool resetSessionText = false,
//     Duration? pauseFor,
//     Duration listenFor = const Duration(minutes: 10),
//     bool onDevice = false,
//   }) async {
//     pauseFor ??= const Duration(milliseconds: 700);

//     if (_isDesktop) {
//       onError?.call('Speech recognition is not supported on desktop platforms.');
//       return;
//     }

//     if (!_isInitialized) {
//       final ok = await initialize();
//       if (!ok) return;
//     }

//     if (_isListening) return;

//     if (resetSessionText) {
//       _committed = '';
//       _partial = '';
//       _emitTranscriptChanged();
//     }

//     try {
//       await _speechToText.listen(
//         onResult: _handleResult,
//         listenFor: listenFor,
//         pauseFor: pauseFor,
//         partialResults: true,
//         cancelOnError: true,
//         listenMode: ListenMode.dictation,
//         onDevice: onDevice,
//       );
//     } catch (e) {
//       onError?.call('Failed to start listening: $e');
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

//   Future<void> cancel() async {
//     try {
//       await _speechToText.cancel();
//     } catch (_) {}
//     _partial = '';
//     _emitTranscriptChanged();
//   }

//   void dispose() {
//     cancel();
//   }

//   // ---- Core merging logic ----
//   // Accept 'dynamic' because package versions/platforms may differ in exported type.
//   void _handleResult(dynamic result) {
//     try {
//       final recognized = (result?.recognizedWords ?? '') as String;

//       // Try to detect final flag reliably
//       bool isFinal = false;
//       try {
//         final dyn = result;
//         isFinal = (dyn?.finalResult == true) || (result?.finalResult == true);
//       } catch (_) {
//         // if property access fails, fall back to result.finalResult if available
//         try {
//           isFinal = (result?.finalResult ?? false) as bool;
//         } catch (_) {
//           isFinal = false;
//         }
//       }

//       if (isFinal) {
//         _processFinal(recognized.trim());
//       } else {
//         _processPartial(recognized);
//       }
//     } catch (e) {
//       onError?.call('Error processing speech result: $e');
//     }
//   }

//   void _processPartial(String recognized) {
//     if (recognized != _partial) {
//       _partial = recognized;
//       onPartial?.call(_partial);
//       _emitTranscriptChanged();
//     }
//   }

//   void _processFinal(String recognized) {
//     if (recognized.isEmpty) {
//       _partial = '';
//       onFinal?.call('');
//       _emitTranscriptChanged();
//       return;
//     }

//     if (_committed.isNotEmpty && recognized.startsWith(_committed)) {
//       _committed = recognized;
//     } else if (_committed.isEmpty && recognized.isNotEmpty) {
//       _committed = recognized;
//     } else if (!_committed.isEmpty && !recognized.startsWith(_committed)) {
//       final overlapLen = _commonSuffixPrefixLength(_committed, recognized);
//       if (overlapLen > 0 && overlapLen < recognized.length) {
//         final appendPart = recognized.substring(overlapLen).trim();
//         _committed = '${_committed.trim()} ${appendPart}';
//       } else {
//         _committed = '${_committed.trim()} ${recognized.trim()}';
//       }
//     }

//     _partial = '';
//     onFinal?.call(recognized);
//     _emitTranscriptChanged();
//   }

//   void _emitTranscriptChanged() {
//     final combined = _buildCombined();
//     onTranscriptChanged?.call(combined);
//   }

//   String _buildCombined() {
//     final c = _committed.trim();
//     final p = _partial.trim();
//     if (c.isEmpty && p.isEmpty) return '';
//     if (p.isEmpty) return c;
//     if (c.isEmpty) return p;
//     return '$c $p';
//   }

//   /// Return length of largest suffix of a that is a prefix of b (in characters).
//   int _commonSuffixPrefixLength(String a, String b) {
//     if (a.isEmpty || b.isEmpty) return 0;
//     final aTokens = a.split(RegExp(r'\s+'));
//     final bTokens = b.split(RegExp(r'\s+'));
//     int maxLen = 0;
//     final maxCheck = aTokens.length < bTokens.length ? aTokens.length : bTokens.length;
//     for (int k = 1; k <= maxCheck; k++) {
//       final aSuffix = aTokens.sublist(aTokens.length - k).join(' ');
//       final bPrefix = bTokens.sublist(0, k).join(' ');
//       if (aSuffix == bPrefix) maxLen = k;
//     }
//     if (maxLen == 0) return 0;
//     final prefix = bTokens.sublist(0, maxLen).join(' ');
//     return prefix.length;
//   }
// }







// // lib/services/speech_service.dart
// import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
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

//   // track last final and partial to avoid duplicates/flooding UI
//   String _lastFinal = '';
//   String _lastPartial = '';

//   // Detect desktop platforms where speech_to_text is typically unsupported
//   bool get _isDesktop {
//     if (kIsWeb) return false;
//     return defaultTargetPlatform == TargetPlatform.windows ||
//         defaultTargetPlatform == TargetPlatform.linux ||
//         defaultTargetPlatform == TargetPlatform.macOS;
//   }

//   Future<bool> initialize() async {
//     try {
//       if (_isDesktop) {
//         onError?.call('Speech recognition is not supported on desktop builds.');
//         return false;
//       }

//       // On web, browser prompts for microphone permission; permission_handler is for native
//       if (!kIsWeb) {
//         final permission = await Permission.microphone.request();
//         if (permission != PermissionStatus.granted) {
//           onError?.call('Microphone permission denied');
//           return false;
//         }
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
//   /// - pauseFor: silence timeout to consider phrase finalized (helps control finalization)
//   /// - listenFor: overall session timeout
//   /// - onDevice: prefer on-device recognition when available
//   Future<void> startListening({
//     bool singleSpeaker = true,
//     Duration? pauseFor,
//     Duration listenFor = const Duration(hours: 2),
//     bool onDevice = false,
//     bool resetSessionText = false,
//   }) async {
//     pauseFor ??= const Duration(milliseconds: 400);

//     if (_isDesktop) {
//       onError?.call('Speech recognition is not supported on desktop platforms.');
//       return;
//     }

//     if (!_isInitialized) {
//       final ok = await initialize();
//       if (!ok) return;
//     }

//     // Prevent duplicate starts
//     if (_isListening) return;

//     // Optionally reset text tracking for a new session
//     if (resetSessionText) {
//       _lastFinal = '';
//       _lastPartial = '';
//     }

//     try {
//       await _speechToText.listen(
//         onResult: (result) {
//           final recognized = result.recognizedWords ?? '';

//           // Many implementations expose a finalResult boolean; use dynamic defensively
//           bool isFinal = false;
//           try {
//             final dyn = result as dynamic;
//             isFinal = (dyn.finalResult == true);
//           } catch (_) {
//             isFinal = result.finalResult ?? false;
//           }

//           if (isFinal) {
//             final text = recognized.trim();

//             // If final is empty, still notify so UI can clear partials
//             if (text.isEmpty) {
//               _lastPartial = '';
//               onFinal?.call('');
//               return;
//             }

//             // If final contains previous final (cumulative), prefer replacement
//             if (_lastFinal.isNotEmpty && text.startsWith(_lastFinal)) {
//               _lastFinal = text;
//               onFinal?.call(text);
//             } else if (_lastFinal.isEmpty) {
//               _lastFinal = text;
//               onFinal?.call(text);
//             } else {
//               // New final chunk; send full text and let UI decide append/merge
//               _lastFinal = text;
//               onFinal?.call(text);
//             }

//             // clear partial
//             _lastPartial = '';
//           } else {
//             // Interim partial — replace ephemeral partial region (do not append)
//             if (recognized != _lastPartial) {
//               _lastPartial = recognized;
//               onPartial?.call(recognized);
//             }
//           }
//         },
//         listenFor: listenFor,
//         pauseFor: pauseFor,
//         partialResults: true,
//         cancelOnError: true,
//         listenMode: ListenMode.dictation,
//         onDevice: onDevice,
//       );
//     } catch (e) {
//       onError?.call('Failed to start listening: $e');
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
//     try {
//       _speechToText.cancel();
//     } catch (_) {}
//     _lastPartial = '';
//   }

//   void dispose() {
//     cancel();
//   }
// }




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