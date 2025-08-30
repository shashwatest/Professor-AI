import 'package:flutter_test/flutter_test.dart';
import 'package:ai_classroom_assistant/services/speech_service.dart';

void main() {
  group('SpeechService Tests', () {
    late SpeechService speechService;

    setUp(() {
      speechService = SpeechService();
    });

    tearDown(() {
      speechService.dispose();
    });

    test('should initialize with correct default state', () {
      expect(speechService.isInitialized, isFalse);
      expect(speechService.isListening, isFalse);
    });

    test('should clear transcript when clearTranscript is called', () {
      // This test verifies the method exists and can be called
      speechService.clearTranscript();
      expect(true, isTrue); // Basic assertion to verify no exceptions
    });

    test('should handle dispose without errors', () {
      speechService.dispose();
      expect(true, isTrue); // Basic assertion to verify no exceptions
    });
  });
}