import 'dart:convert';
import 'package:http/http.dart' as http;

enum AIProvider { gemini, openai, meta }

abstract class AIService {
  Future<List<String>> extractTopics(String transcription, String educationLevel);
  Future<String> generateEnhancedNotes(String transcription, String educationLevel);
  Future<String> getTopicDetails(String topic, String educationLevel);
}

class OpenAIService implements AIService {
  final String apiKey;
  static const String baseUrl = 'https://api.openai.com/v1';

  OpenAIService(this.apiKey);

  @override
  Future<List<String>> extractTopics(String transcription, String educationLevel) async {
    final prompt = '''
Extract 3-5 key topics from this classroom transcription for a $educationLevel student.
Return only topic names, one per line, no numbering or bullets.

Transcription: $transcription
''';

    try {
      final response = await _makeRequest('chat/completions', {
        'model': 'gpt-3.5-turbo',
        'messages': [
          {'role': 'user', 'content': prompt}
        ],
        'max_tokens': 200,
        'temperature': 0.3,
      });

      final content = response['choices'][0]['message']['content'] as String;
      return content.split('\n').where((line) => line.trim().isNotEmpty).toList();
    } catch (e) {
      throw Exception('Failed to extract topics: $e');
    }
  }

  @override
  Future<String> generateEnhancedNotes(String transcription, String educationLevel) async {
    final prompt = '''
You are an expert academic note-taker. Create comprehensive, well-structured study notes from this classroom transcription for a $educationLevel student.

**Requirements:**
- Extract ALL key concepts, definitions, and explanations
- Include detailed formulas with step-by-step explanations
- Organize content with clear headings and subheadings
- Add practical examples and applications
- Include study tips and memory aids
- Make notes comprehensive enough for exam preparation
- Use bullet points, numbered lists, and formatting for clarity

**Format your response as:**

# [Subject/Topic Title]

## Key Concepts
[Detailed explanations of main concepts]

## Important Formulas & Equations
[All formulas with explanations and when to use them]

## Detailed Explanations
[Step-by-step breakdowns of complex topics]

## Examples & Applications
[Real-world examples and practice problems]

## Study Tips & Memory Aids
[Mnemonics, tips for remembering key points]

## Summary
[Concise overview of all main points]

Transcription: $transcription
''';

    try {
      final response = await _makeRequest('chat/completions', {
        'model': 'gpt-3.5-turbo',
        'messages': [
          {'role': 'system', 'content': 'You are an expert academic tutor who creates comprehensive, detailed study notes that help students excel in their studies.'},
          {'role': 'user', 'content': prompt}
        ],
        'max_tokens': 2000,
        'temperature': 0.1,
      });

      return response['choices'][0]['message']['content'] as String;
    } catch (e) {
      throw Exception('Failed to generate notes: $e');
    }
  }

  @override
  Future<String> getTopicDetails(String topic, String educationLevel) async {
    final prompt = '''
You are an expert educator. Your mission is to create a comprehensive and easy-to-understand guide on the topic of "$topic" for a "$educationLevel" student.

Strictly adhere to the following format and guidelines. Replace bracketed placeholders with relevant information. If a section is not applicable (e.g., formulas for a history topic), omit it.

---

##Introduction
A brief, one-paragraph overview that explains the topic and its importance.

##Core Definition
Provide a simple, concise definition. **Bold** the main term.
* **Analogy:** Use a relatable analogy to explain the core idea.

##Key Concepts
Use a bulleted list to explain the most critical concepts.
* **Concept 1:** [Brief explanation]
* **Concept 2:** [Brief explanation]
* **Concept 3:** [Brief explanation]

##Key Formulas / Syntax (If applicable)
List essential formulas or code syntax using LaTeX for math. Explain each component.
*  \$\$[Formula\ 1]\$\$
    * **Explanation:** [Describe what it calculates and define its variables.]

##Worked Example
Provide one clear, step-by-step example applying the concepts.

##Real-World Applications
List 2-3 practical, real-world applications.

##Common Misconceptions
Point out and clarify 1-2 common misunderstandings about this topic.

##Quick Tips
* **Study Tip:** [Provide a useful study technique.]
* **Mnemonic:** [Provide a simple mnemonic, if one exists.]
''';

    try {
      final response = await _makeRequest('chat/completions', {
        'model': 'gpt-3.5-turbo',
        'messages': [
          {'role': 'user', 'content': prompt}
        ],
        'max_tokens': 800,
        'temperature': 0.2,
      });

      return response['choices'][0]['message']['content'] as String;
    } catch (e) {
      throw Exception('Failed to get topic details: $e');
    }
  }

  Future<Map<String, dynamic>> _makeRequest(String endpoint, Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/$endpoint'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode(data),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('API request failed: ${response.statusCode} ${response.body}');
    }
  }
}

class GeminiService implements AIService {
  final String apiKey;
  static const String baseUrl = 'https://generativelanguage.googleapis.com/v1beta';

  GeminiService(this.apiKey);

  @override
  Future<List<String>> extractTopics(String transcription, String educationLevel) async {
    final prompt = '''
Extract 3-5 key topics from this classroom transcription for a $educationLevel student.
Return only topic names, one per line, no numbering or bullets.

Transcription: $transcription
''';

    try {
      final response = await _makeRequest('models/gemini-2.0-flash:generateContent', {
        'contents': [{
          'parts': [{'text': prompt}]
        }],
        'generationConfig': {
          'maxOutputTokens': 200,
          'temperature': 0.3,
        }
      });

      final content = response['candidates'][0]['content']['parts'][0]['text'] as String;
      return content.split('\n').where((line) => line.trim().isNotEmpty).toList();
    } catch (e) {
      throw Exception('Failed to extract topics: $e');
    }
  }

  @override
  Future<String> generateEnhancedNotes(String transcription, String educationLevel) async {
    final prompt = '''
You are an expert academic note-taker. Create comprehensive, well-structured study notes from this classroom transcription for a $educationLevel student.

**Requirements:**
- Extract ALL key concepts, definitions, and explanations
- Include detailed formulas with step-by-step explanations
- Organize content with clear headings and subheadings
- Add practical examples and applications
- Include study tips and memory aids
- Make notes comprehensive enough for exam preparation
- Use bullet points, numbered lists, and formatting for clarity

**Format your response as:**

# [Subject/Topic Title]

## Key Concepts
[Detailed explanations of main concepts]

## Important Formulas & Equations
[All formulas with explanations and when to use them]

## Detailed Explanations
[Step-by-step breakdowns of complex topics]

## Examples & Applications
[Real-world examples and practice problems]

## Study Tips & Memory Aids
[Mnemonics, tips for remembering key points]

## Summary
[Concise overview of all main points]

Transcription: $transcription
''';

    try {
      final response = await _makeRequest('models/gemini-2.0-flash:generateContent', {
        'contents': [{
          'parts': [{'text': prompt}]
        }],
        'generationConfig': {
          'maxOutputTokens': 2000,
          'temperature': 0.1,
        }
      });

      return response['candidates'][0]['content']['parts'][0]['text'] as String;
    } catch (e) {
      throw Exception('Failed to generate notes: $e');
    }
  }

  @override
  Future<String> getTopicDetails(String topic, String educationLevel) async {
    final prompt = '''
Provide detailed information about "$topic" for a $educationLevel student in this structured format:

**Definition:**
[Clear definition of the topic]

**Key Concepts:**
• [Concept 1]
• [Concept 2]
• [Concept 3]

**Important Formulas:**
[List relevant formulas with explanations in proper latex format]

**Examples:**
[Practical examples or applications]

**Quick Tips:**
[Study tips or mnemonics]

Keep each section concise but informative.
''';

    try {
      final response = await _makeRequest('models/gemini-2.0-flash:generateContent', {
        'contents': [{
          'parts': [{'text': prompt}]
        }],
        'generationConfig': {
          'maxOutputTokens': 800,
          'temperature': 0.2,
        }
      });

      return response['candidates'][0]['content']['parts'][0]['text'] as String;
    } catch (e) {
      throw Exception('Failed to get topic details: $e');
    }
  }

  Future<Map<String, dynamic>> _makeRequest(String endpoint, Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/$endpoint?key=$apiKey'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode(data),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('API request failed: ${response.statusCode} ${response.body}');
    }
  }
}

class MetaService implements AIService {
  final String apiKey;
  static const String baseUrl = 'https://api.llama-api.com';

  MetaService(this.apiKey);

  @override
  Future<List<String>> extractTopics(String transcription, String educationLevel) async {
    final prompt = '''
Extract 3-5 key topics from this classroom transcription for a $educationLevel student.
Return only topic names, one per line, no numbering or bullets.

Transcription: $transcription
''';

    try {
      final response = await _makeRequest('chat/completions', {
        'model': 'llama3.1-70b',
        'messages': [
          {'role': 'user', 'content': prompt}
        ],
        'max_tokens': 200,
        'temperature': 0.3,
      });

      final content = response['choices'][0]['message']['content'] as String;
      return content.split('\n').where((line) => line.trim().isNotEmpty).toList();
    } catch (e) {
      throw Exception('Failed to extract topics: \$e');
    }
  }

  @override
  Future<String> generateEnhancedNotes(String transcription, String educationLevel) async {
    final prompt = '''
Create structured study notes from this classroom transcription for a $educationLevel student.
Include key concepts, important formulas, and main points in a clear format.

Transcription: $transcription
''';

    try {
      final response = await _makeRequest('chat/completions', {
        'model': 'llama3.1-70b',
        'messages': [
          {'role': 'user', 'content': prompt}
        ],
        'max_tokens': 1000,
        'temperature': 0.2,
      });

      return response['choices'][0]['message']['content'] as String;
    } catch (e) {
      throw Exception('Failed to generate notes: \$e');
    }
  }

  @override
  Future<String> getTopicDetails(String topic, String educationLevel) async {
    final prompt = '''
Provide detailed information about "$topic" for a $educationLevel student in this structured format:

**Definition:**
[Clear definition of the topic]

**Key Concepts:**
• [Concept 1]
• [Concept 2]
• [Concept 3]

**Important Formulas:**
[List relevant formulas with explanations]

**Examples:**
[Practical examples or applications]

**Quick Tips:**
[Study tips or mnemonics]

Keep each section concise but informative.
''';

    try {
      final response = await _makeRequest('chat/completions', {
        'model': 'llama3.1-70b',
        'messages': [
          {'role': 'user', 'content': prompt}
        ],
        'max_tokens': 800,
        'temperature': 0.2,
      });

      return response['choices'][0]['message']['content'] as String;
    } catch (e) {
      throw Exception('Failed to get topic details: \$e');
    }
  }

  Future<Map<String, dynamic>> _makeRequest(String endpoint, Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('\$baseUrl/\$endpoint'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer \$apiKey',
      },
      body: jsonEncode(data),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('API request failed: \${response.statusCode} \${response.body}');
    }
  }
}

class AIServiceFactory {
  static AIService? create(AIProvider provider, String apiKey) {
    switch (provider) {
      case AIProvider.gemini:
        return GeminiService(apiKey);
      case AIProvider.openai:
        return OpenAIService(apiKey);
      case AIProvider.meta:
        return MetaService(apiKey);
    }
  }
}