import 'package:flutter_test/flutter_test.dart';
import 'package:ai_classroom_assistant/models/extracted_content_item.dart';
import 'package:ai_classroom_assistant/models/content_type.dart';

void main() {
  group('ExtractedContentProcessor', () {
    test('should process AI response with prefixes correctly', () {
      final aiResponse = [
        'TOPIC: Quantum Mechanics',
        'QUESTION: What is wave-particle duality?',
        'Here\'s an analysis of the transcription', // Should be filtered out
        'TOPIC: Photons and Energy',
        '', // Empty line should be filtered out
        'Based on the classroom transcription', // Should be filtered out
      ];

      final result = ExtractedContentProcessor.processAIResponse(aiResponse);

      expect(result.length, equals(3)); // 3 valid items: 2 topics, 1 question
      
      expect(result[0].content, equals('Quantum Mechanics'));
      expect(result[0].type, equals(ContentType.topic));
      
      expect(result[1].content, equals('What is wave-particle duality?'));
      expect(result[1].type, equals(ContentType.question));
      
      expect(result[2].content, equals('Photons and Energy'));
      expect(result[2].type, equals(ContentType.topic));
    });

    test('should handle lines without prefixes', () {
      final aiResponse = [
        'What is the speed of light?', // Should be detected as question
        'Newton\'s Laws of Motion', // Should be detected as topic
        'How does gravity work?', // Should be detected as question
      ];

      final result = ExtractedContentProcessor.processAIResponse(aiResponse);

      expect(result.length, equals(3));
      expect(result[0].type, equals(ContentType.question));
      expect(result[1].type, equals(ContentType.topic));
      expect(result[2].type, equals(ContentType.question));
    });

    test('should filter out AI artifacts', () {
      final aiResponse = [
        'Here\'s an analysis of the provided classroom transcription',
        'TOPIC: Physics Concepts',
        'Based on the transcription for a student',
        'QUESTION: How does gravity work?',
        'Analyzing the classroom content',
        'TOPIC: Quantum Mechanics',
      ];

      final result = ExtractedContentProcessor.processAIResponse(aiResponse);

      expect(result.length, equals(3));
      expect(result[0].content, equals('Physics Concepts'));
      expect(result[1].content, equals('How does gravity work?'));
      expect(result[2].content, equals('Quantum Mechanics'));
    });
  });

  group('ContentTypeDetector', () {
    test('should detect content type from prefixed lines', () {
      expect(ContentTypeDetector.detectFromLine('TOPIC: Math'), equals(ContentType.topic));
      expect(ContentTypeDetector.detectFromLine('QUESTION: What is 2+2?'), equals(ContentType.question));
      expect(ContentTypeDetector.detectFromLine('- TOPIC: Physics'), equals(ContentType.topic));
      expect(ContentTypeDetector.detectFromLine('- QUESTION: How does this work?'), equals(ContentType.question));
      expect(ContentTypeDetector.detectFromLine('No prefix here'), isNull);
    });

    test('should extract content without prefixes', () {
      expect(ContentTypeDetector.extractContent('TOPIC: Math'), equals('Math'));
      expect(ContentTypeDetector.extractContent('QUESTION: What is 2+2?'), equals('What is 2+2?'));
      expect(ContentTypeDetector.extractContent('- TOPIC: Physics'), equals('Physics'));
      expect(ContentTypeDetector.extractContent('- QUESTION: How does this work?'), equals('How does this work?'));
      expect(ContentTypeDetector.extractContent('No prefix here'), equals('No prefix here'));
    });

    test('should detect content type from plain text', () {
      expect(ContentTypeDetector.detectFromContent('What is gravity?'), equals(ContentType.question));
      expect(ContentTypeDetector.detectFromContent('How does this work?'), equals(ContentType.question));
      expect(ContentTypeDetector.detectFromContent('Quantum Physics'), equals(ContentType.topic));
    });
  });
}