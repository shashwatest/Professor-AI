import 'dart:async';
import 'package:google_speech/google_speech.dart';
import 'package:sound_stream/sound_stream.dart';

class GoogleCloudSpeechService {
  SpeechToText? _speechToText;
  RecorderStream? _recorder;
  StreamSubscription? _audioStreamSubscription;
  StreamSubscription? _recognizeStreamSubscription;
  
  bool _isListening = false;
  String _fullTranscript = '';
  
  void Function(String)? onTranscriptChanged;
  void Function(String)? onError;
  void Function(bool)? onListeningStateChanged;
  
  bool get isListening => _isListening;
  String get currentTranscript => _fullTranscript;

  Future<bool> initialize(String serviceAccountJson) async {
    try {
      final serviceAccount = ServiceAccount.fromString(serviceAccountJson);
      _speechToText = SpeechToText.viaServiceAccount(serviceAccount);
      _recorder = RecorderStream();
      return true;
    } catch (e) {
      onError?.call('Failed to initialize: $e');
      return false;
    }
  }

  Future<void> startListening() async {
    if (_isListening || _speechToText == null) return;

    try {
      await _recorder!.start();
      _isListening = true;
      onListeningStateChanged?.call(true);

      final config = RecognitionConfig(
        encoding: AudioEncoding.LINEAR16,
        model: RecognitionModel.command_and_search,
        enableAutomaticPunctuation: true,
        sampleRateHertz: 16000,
        languageCode: 'en-US',
      );

      final streamingConfig = StreamingRecognitionConfig(
        config: config,
        interimResults: true,
      );

      final responseStream = _speechToText!.streamingRecognize(
        streamingConfig,
        _recorder!.audioStream,
      );

      _recognizeStreamSubscription = responseStream.listen(
        (data) {
          if (data.results.isEmpty) return;
          
          final result = data.results.first;
          final transcript = result.alternatives.first.transcript;
          
          if (result.isFinal) {
            if (transcript.trim().isNotEmpty) {
              if (_fullTranscript.isEmpty) {
                _fullTranscript = transcript.trim();
              } else {
                _fullTranscript += ' ${transcript.trim()}';
              }
            }
          }
          
          final combined = _fullTranscript.isEmpty
              ? transcript
              : '$_fullTranscript $transcript';
          onTranscriptChanged?.call(combined);
        },
        onError: (error) {
          onError?.call('Recognition error: $error');
        },
      );
    } catch (e) {
      onError?.call('Failed to start listening: $e');
      _isListening = false;
      onListeningStateChanged?.call(false);
    }
  }

  Future<void> stopListening() async {
    if (!_isListening) return;

    await _recognizeStreamSubscription?.cancel();
    await _recorder?.stop();
    _isListening = false;
    onListeningStateChanged?.call(false);
  }

  void clearTranscript() {
    _fullTranscript = '';
    onTranscriptChanged?.call('');
  }

  void dispose() {
    stopListening();
    _audioStreamSubscription?.cancel();
    _recognizeStreamSubscription?.cancel();
    onTranscriptChanged = null;
    onError = null;
    onListeningStateChanged = null;
  }
}
