import 'package:flutter_test/flutter_test.dart';
import 'package:ai_classroom_assistant/models/extracted_content_item.dart';

void main() {
  test('Full flow simulation - what user might see', () {
    // Simulate what AI services might return (with potential issues)
    final problematicAIResponse = [
      '- TOPIC: Quantum Mechanics',  // With dash prefix
      '- QUESTION: What is wave-particle duality?',  // With dash prefix
      'TOPIC: Photons and Energy',  // Normal prefix
      'Here is an analysis of the transcription',  // Should be filtered
      'QUESTION: How do photons work?',  // Normal prefix
    ];

    print('Problematic AI Response (what might cause issues):');
    for (int i = 0; i < problematicAIResponse.length; i++) {
      print('  $i: "${problematicAIResponse[i]}"');
    }

    final result = ExtractedContentProcessor.processAIResponse(problematicAIResponse);

    print('\nProcessed Results:');
    for (int i = 0; i < result.length; i++) {
      print('  $i: displayText="${result[i].displayText}", type=${result[i].type}');
    }

    print('\nWhat user would see in UI:');
    for (int i = 0; i < result.length; i++) {
      final item = result[i];
      print('  ${item.icon.codePoint}: ${item.displayText}');
    }
  });
}