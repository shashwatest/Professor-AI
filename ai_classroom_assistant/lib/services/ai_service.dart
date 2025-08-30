import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/content_type.dart';

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
Analyze this classroom transcription for a $educationLevel student and extract:
1. Key academic topics (3-5 items)
2. Questions asked by students or instructor (if any)

IMPORTANT: Return ONLY the extracted items, one per line, with these exact prefixes:
- TOPIC: [topic name]
- QUESTION: [question text]
- CODE_QUESTION: [programming/coding question text]

Use CODE_QUESTION for any questions related to programming, coding, algorithms, data structures, software development, or any programming language (Java, Python, C++, etc.).

Do not include any explanatory text, analysis, or additional commentary. Return only the prefixed items.

Transcription: $transcription
''';

    try {
      final response = await _makeRequest('chat/completions', {
        'model': 'gpt-3.5-turbo',
        'messages': [
          {'role': 'user', 'content': prompt}
        ],
        'max_tokens': 300,
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
You are an AI academic assistant specializing in distilling complex information. Your task is to transform the provided classroom transcription into a clear, comprehensive, and well-structured set of study notes for a `$educationLevel` student.

**Primary Instructions:**
1.  **Analyze and Clean:** First, read the entire transcription to understand the core topics. You MUST ignore filler words (e.g., 'um', 'like', 'uh'), conversational tangents, and repeated phrases to focus solely on the academic content.
2.  **Synthesize and Structure:** Do not just extract text. Rephrase concepts in clear, simple language suitable for the student's level. Organize all extracted information logically into the format specified below.
3.  **Be Comprehensive:** The final notes must be a complete study guide for exam preparation based ONLY on the provided text.

**Required Output Format:**

# [Infer the Main Topic of the Lecture]
> **Date:** [Insert today's date: August 25, 2025]

## Executive Summary
A concise, 3-5 bullet point summary of the lecture's most critical takeaways.

---

## Key Terminology
Create a table with key terms/vocabulary mentioned and their precise definitions.

| Term | Definition |
| :--- | :--- |
| [Term 1] | [Clear definition from the text] |
| [Term 2] | [Clear definition from the text] |

---

## Core Concepts & Detailed Explanations
This is the main body of the notes. Use nested bullet points to create a clear hierarchy. **Bold** all key terms.
* **Main Concept 1**
    * Detailed explanation paraphrased for clarity.
    * Supporting point or sub-topic.
* **Main Concept 2**
    * Detailed explanation.

---

## Formulas & Equations (If applicable)
For each formula mentioned:
1.  Present the formula using LaTeX: \$\$ [Formula] \$\$
2.  **Variables:** List and explain each variable.
3.  **Application:** Briefly explain what the formula is used for.

---

## Practical Examples & Applications
Detail any real-world examples, case studies, or practice problems discussed. If the transcription lacks a clear example for a key concept, create one simple, illustrative example.

---

---

## Potential Exam Questions
Based on the lecture content, generate 2-3 potential exam questions (e.g., short answer, multiple-choice) to help the student test their understanding.

---

**Transcription to Process:**
$transcription

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
    // Detect content type to provide appropriate response
    final contentType = ContentTypeDetector.detectFromContent(topic);
    
    String prompt;
    
    switch (contentType) {
      case ContentType.codingQuestion:
        // Specialized prompt for coding questions
        prompt = '''
CODING QUESTION: "$topic"

You are a programming instructor. This is a $educationLevel coding question. 

RESPOND ONLY IN THIS EXACT FORMAT - DO NOT DEVIATE:

## Java Code
```java
// Complete, runnable Java code solution
// Include all necessary imports, class structure, main method
// Add clear comments explaining the logic
```

## Code Explanation
[2-3 sentences explaining how the code works and why it solves the problem]

## Search Keywords
Java programming, [specific concept], [algorithm/data structure], [relevant topic]

STRICT REQUIREMENTS:
- Start response with "## Java Code"
- Provide ONLY complete, compilable Java code in code blocks
- Include proper class structure, imports, main method
- NO definitions, theory, or formulas
- Focus ONLY on working code solution
- If question mentions another language, use that instead of Java
- Keep explanation brief and code-focused
''';
        break;

      case ContentType.question:
        // Regular question prompt
        prompt = '''
You are an expert educator answering: "$topic"

For a $educationLevel student, provide a focused answer:

## Direct Answer
[Clear, immediate answer in 1-2 sentences]

## Explanation
[Concise explanation appropriate for $educationLevel level]

## Key Formula
[If applicable: \$\$formula\$\$ with brief explanation]

## Example
[One concrete example]

## Search Keywords
[3-4 relevant search terms]

Keep it concise and educational. Avoid unnecessary complexity.
''';
        break;
        

        
      default: // ContentType.topic
        prompt = '''
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
*  \$\$[Formula 1]\$\$
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
        break;
    }

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
Analyze this classroom transcription for a $educationLevel student and extract:
1. Key academic topics, however many are there, if there aren't any dont' return any topics.
2. Questions asked by students or instructor (if any)

IMPORTANT: Return ONLY the extracted items, one per line, with these exact prefixes:
- TOPIC: [topic name]
- QUESTION: [question text]
- CODE_QUESTION: [programming/coding question text]

Use CODE_QUESTION for any questions related to programming, coding, algorithms, data structures, software development, or any programming language (Java, Python, C++, etc.).

Do not include any explanatory text, analysis, or additional commentary. Return only the prefixed items.

Transcription: $transcription
''';

    try {
      final response = await _makeRequest('models/gemini-2.0-flash:generateContent', {
        'contents': [{
          'parts': [{'text': prompt}]
        }],
        'generationConfig': {
          'maxOutputTokens': 300,
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
    // Detect content type to provide appropriate response
    final contentType = ContentTypeDetector.detectFromContent(topic);
    
    String prompt;
    
    switch (contentType) {
      case ContentType.codingQuestion:
        // Specialized prompt for coding questions
        prompt = '''
CODING QUESTION: "$topic"

You are a programming instructor. This is a $educationLevel coding question.

RESPOND ONLY IN THIS EXACT FORMAT - DO NOT DEVIATE:

## Java Code
```java
// Complete, runnable Java code solution
// Include all necessary imports, class structure, main method
// Add clear comments explaining the logic
```

## Code Explanation
[2-3 sentences explaining how the code works and why it solves the problem]

## Search Keywords
Java programming, [specific concept], [algorithm/data structure], [relevant topic]

STRICT REQUIREMENTS:
- Start response with "## Java Code"
- Provide ONLY complete, compilable Java code in code blocks
- Include proper class structure, imports, main method
- NO definitions, theory, or formulas
- Focus ONLY on working code solution
- If question mentions another language, use that instead of Java
- Keep explanation brief and code-focused
''';
        break;

      case ContentType.question:
        // Regular question prompt
        prompt = '''
Answer this question: "$topic" for a $educationLevel student.

## Direct Answer
[Clear, immediate answer in 1-2 sentences]

## Explanation
[Concise explanation appropriate for $educationLevel level]

## Key Formula
[If applicable: \$\$formula\$\$ with brief explanation]

## Example
[One concrete example]

## Search Keywords
[3-4 relevant search terms]

Keep it focused and educational.
''';
        break;
        

        
      default: // ContentType.topic
        prompt = '''
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
        break;
    }

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
Analyze this classroom transcription for a $educationLevel student and extract:
1. Key academic topics (3-5 items)
2. Questions asked by students or instructor (if any)

IMPORTANT: Return ONLY the extracted items, one per line, with these exact prefixes:
- TOPIC: [topic name]
- QUESTION: [question text]
- CODE_QUESTION: [programming/coding question text]

Use CODE_QUESTION for any questions related to programming, coding, algorithms, data structures, software development, or any programming language (Java, Python, C++, etc.).

Do not include any explanatory text, analysis, or additional commentary. Return only the prefixed items.

Transcription: $transcription
''';

    try {
      final response = await _makeRequest('chat/completions', {
        'model': 'llama3.1-70b',
        'messages': [
          {'role': 'user', 'content': prompt}
        ],
        'max_tokens': 300,
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

**Format your response as:**

# [Subject/Topic Title]

## Key Concepts
[Main concepts and definitions]

## Important Formulas
[Relevant formulas with explanations]

## Examples & Applications
[Real-world examples]

## Summary
[Overview of main points]

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
    // Detect content type to provide appropriate response
    final contentType = ContentTypeDetector.detectFromContent(topic);
    
    String prompt;
    
    switch (contentType) {
      case ContentType.codingQuestion:
        // Specialized prompt for coding questions
        prompt = '''
CODING QUESTION: "$topic"

You are a programming instructor. This is a $educationLevel coding question.

RESPOND ONLY IN THIS EXACT FORMAT - DO NOT DEVIATE:

## Java Code
```java
// Complete, runnable Java code solution
// Include all necessary imports, class structure, main method
// Add clear comments explaining the logic
```

## Code Explanation
[2-3 sentences explaining how the code works and why it solves the problem]

## Search Keywords
Java programming, [specific concept], [algorithm/data structure], [relevant topic]

STRICT REQUIREMENTS:
- Start response with "## Java Code"
- Provide ONLY complete, compilable Java code in code blocks
- Include proper class structure, imports, main method
- NO definitions, theory, or formulas
- Focus ONLY on working code solution
- If question mentions another language, use that instead of Java
- Keep explanation brief and code-focused
''';
        break;

      case ContentType.question:
        // Regular question prompt
        prompt = '''
Answer: "$topic" for a $educationLevel student.

## Direct Answer
[Clear answer in 1-2 sentences]

## Explanation
[Concise explanation for $educationLevel level]

## Key Formula
[If applicable: \$\$formula\$\$ with explanation]

## Example
[One concrete example]

## Search Keywords
[3-4 search terms]

Keep it focused and educational.
''';
        break;
        

        
      default: // ContentType.topic
        prompt = '''
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
        break;
    }

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