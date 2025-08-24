import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';

class SpeechService {
  final SpeechToText _speechToText = SpeechToText();
  bool _isInitialized = false;
  bool _isListening = false;
  
  Function(String)? onResult;
  Function(String)? onError;
  Function(bool)? onListeningStateChanged;

  bool get isInitialized => _isInitialized;
  bool get isListening => _isListening;

  Future<bool> initialize() async {
    try {
      // Request microphone permission
      final permission = await Permission.microphone.request();
      if (permission != PermissionStatus.granted) {
        onError?.call('Microphone permission denied');
        return false;
      }

      _isInitialized = await _speechToText.initialize(
        onError: (error) => onError?.call(error.errorMsg),
        onStatus: (status) {
          final listening = status == 'listening';
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

  Future<void> startListening({bool singleSpeaker = true}) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (_isInitialized && !_isListening) {
      await _speechToText.listen(
        onResult: (result) {
          // Show partial results for real-time feedback
          onResult?.call(result.recognizedWords);
        },
        listenFor: const Duration(hours: 2), // Extended duration
        //pauseFor: const Duration(seconds: 1), // Shorter pause
        partialResults: true, // Enable real-time results
        cancelOnError: false,
        listenMode: singleSpeaker 
            ? ListenMode.dictation 
            : ListenMode.dictation,
      );
    }
  }

  Future<void> stopListening() async {
    if (_isListening) {
      await _speechToText.stop();
    }
  }

  void dispose() {
    _speechToText.cancel();
  }
}