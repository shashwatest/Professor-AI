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

  // track last final text (helps avoid duplication)
  String _lastFinal = '';

  Future<bool> initialize() async {
    try {
      final permission = await Permission.microphone.request();
      if (permission != PermissionStatus.granted) {
        onError?.call('Microphone permission denied');
        return false;
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
  /// - singleSpeaker: controls listenMode; keep as needed
  /// - pauseFor: duration of silence to consider final (helps Android behavior)
  /// - onDevice: use on-device recognition when available
  Future<void> startListening({
    bool singleSpeaker = true,
    //Duration pauseFor = const Duration(milliseconds: 700),
    Duration listenFor = const Duration(hours: 2),
    bool onDevice = false,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    // Prevent duplicate starts
    if (_isInitialized && !_isListening) {
      _lastFinal = ''; // reset last final if desired on start
      try {
        await _speechToText.listen(
          onResult: (result) {
            final recognized = result.recognizedWords ?? '';

            // Some implementations provide a 'finalResult' boolean:
            final isFinal = (result as dynamic).finalResult == true;

            if (isFinal) {
              // avoid empty or duplicated appends
              if (recognized.trim().isNotEmpty && recognized.trim() != _lastFinal.trim()) {
                _lastFinal = recognized;
                onFinal?.call(recognized);
              } else {
                // Even if same as last final, notify final once to let UI clear partials
                onFinal?.call(recognized);
              }
            } else {
              // interim partial result: replace partial area in UI
              onPartial?.call(recognized);
            }
          },
          listenFor: listenFor,
          //pauseFor: pauseFor,
          partialResults: true,
          cancelOnError: true,
          listenMode: singleSpeaker ? ListenMode.dictation : ListenMode.dictation,
          onDevice: onDevice,
        );
      } catch (e) {
        onError?.call('Failed to start listening: $e');
      }
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
    _speechToText.cancel();
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
  
//   Function(String)? onResult;
//   Function(String)? onError;
//   Function(bool)? onListeningStateChanged;

//   bool get isInitialized => _isInitialized;
//   bool get isListening => _isListening;

//   Future<bool> initialize() async {
//     try {
//       // Request microphone permission
//       final permission = await Permission.microphone.request();
//       if (permission != PermissionStatus.granted) {
//         onError?.call('Microphone permission denied');
//         return false;
//       }

//       _isInitialized = await _speechToText.initialize(
//         onError: (error) => onError?.call(error.errorMsg),
//         onStatus: (status) {
//           final listening = status == 'listening';
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

//   Future<void> startListening({bool singleSpeaker = true}) async {
//     if (!_isInitialized) {
//       await initialize();
//     }

//     if (_isInitialized && !_isListening) {
//       await _speechToText.listen(
//         onResult: (result) {
//           // Show partial results for real-time feedback
//           onResult?.call(result.recognizedWords);
//         },
//         listenFor: const Duration(hours: 2), // Extended duration
//         //pauseFor: const Duration(seconds: 1), // Shorter pause
//         partialResults: true, // Enable real-time results
//         cancelOnError: false,
//         listenMode: singleSpeaker 
//             ? ListenMode.dictation 
//             : ListenMode.dictation,
//       );
//     }
//   }

//   Future<void> stopListening() async {
//     if (_isListening) {
//       await _speechToText.stop();
//     }
//   }

//   void dispose() {
//     _speechToText.cancel();
//   }
// }