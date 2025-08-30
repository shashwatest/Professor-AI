import 'package:flutter_test/flutter_test.dart';
import 'package:ai_classroom_assistant/models/extracted_content_item.dart';
import 'package:ai_classroom_assistant/models/content_type.dart';

void main() {
  test('Debug extraction process', () {
    // Simulate what the AI might return
    final aiResponse = [
      'TOPIC: Quantum Mechanics',
      'QUESTION: What is wave-particle duality?',
      'TOPIC: Photons and Energy',
    ];

    print('AI Response:');
    for (int i = 0; i < aiResponse.length; i++) {
      print('  $i: "${aiResponse[i]}"');
    }

    final result = ExtractedContentProcessor.processAIResponse(aiResponse);

    print('\nProcessed Results:');
    for (int i = 0; i < result.length; i++) {
      print('  $i: content="${result[i].content}", displayText="${result[i].displayText}", type=${result[i].type}');
    }

    // Test individual extraction
    print('\nIndividual Extraction Tests:');
    for (final line in aiResponse) {
      final type = ContentTypeDetector.detectFromLine(line);
      final content = ContentTypeDetector.extractContent(line);
      print('  Line: "$line" -> Type: $type, Content: "$content"');
    }
  });
}