import 'package:flutter/material.dart';

enum ContentType {
  topic,
  question,
  codingQuestion,
}

extension ContentTypeExtension on ContentType {
  String get displayName {
    switch (this) {
      case ContentType.topic:
        return 'Topic';
      case ContentType.question:
        return 'Question';
      case ContentType.codingQuestion:
        return 'Code Question';
    }
  }

  IconData get icon {
    switch (this) {
      case ContentType.topic:
        return Icons.topic_outlined;
      case ContentType.question:
        return Icons.help_outline;
      case ContentType.codingQuestion:
        return Icons.code;
    }
  }

  Color getThemeColor(BuildContext context) {
    switch (this) {
      case ContentType.topic:
        return Colors.blue; // Topics in blue
      case ContentType.question:
        return Colors.red; // Questions in red
      case ContentType.codingQuestion:
        return Colors.green; // Coding questions in green
    }
  }

  Color getBackgroundColor(BuildContext context) {
    switch (this) {
      case ContentType.topic:
        return Colors.blue.withOpacity(0.1); // Light blue background for topics
      case ContentType.question:
        return Colors.red.withOpacity(0.1); // Light red background for questions
      case ContentType.codingQuestion:
        return Colors.green.withOpacity(0.1); // Light green background for coding questions
    }
  }
}

class ContentTypeDetector {
  /// Detects content type from AI response line with prefix
  static ContentType? detectFromLine(String line) {
    final trimmed = line.trim();
    // Handle both "TOPIC:" and "- TOPIC:" formats
    if (trimmed.startsWith('TOPIC:') || trimmed.startsWith('- TOPIC:')) {
      return ContentType.topic;
    } else if (trimmed.startsWith('QUESTION:') || trimmed.startsWith('- QUESTION:')) {
      return ContentType.question;
    } else if (trimmed.startsWith('CODE_QUESTION:') || trimmed.startsWith('- CODE_QUESTION:')) {
      return ContentType.codingQuestion;
    }
    return null;
  }

  /// Extracts content text by removing the prefix
  static String extractContent(String line) {
    final trimmed = line.trim();
    if (trimmed.startsWith('- TOPIC:')) {
      return trimmed.substring(8).trim(); // Remove "- TOPIC:"
    } else if (trimmed.startsWith('TOPIC:')) {
      return trimmed.substring(6).trim(); // Remove "TOPIC:"
    } else if (trimmed.startsWith('- QUESTION:')) {
      return trimmed.substring(11).trim(); // Remove "- QUESTION:"
    } else if (trimmed.startsWith('QUESTION:')) {
      return trimmed.substring(9).trim(); // Remove "QUESTION:"
    } else if (trimmed.startsWith('- CODE_QUESTION:')) {
      return trimmed.substring(16).trim(); // Remove "- CODE_QUESTION:"
    } else if (trimmed.startsWith('CODE_QUESTION:')) {
      return trimmed.substring(14).trim(); // Remove "CODE_QUESTION:"
    }
    return trimmed;
  }

  /// Detects content type from plain text (fallback for backward compatibility)
  static ContentType detectFromContent(String content) {
    final lower = content.toLowerCase();
    
    // First check if it's a coding question (don't require question patterns for coding)
    if (isCodingQuestion(content)) {
      return ContentType.codingQuestion;
    }
    
    // Check for regular question patterns
    if (isQuestion(content)) {
      return ContentType.question;
    }
    
    // Default to topic
    return ContentType.topic;
  }

  /// Detects if content is a question
  static bool isQuestion(String content) {
    final lower = content.toLowerCase();
    return lower.contains('?') || 
        lower.startsWith('what ') || 
        lower.startsWith('how ') || 
        lower.startsWith('why ') || 
        lower.startsWith('when ') || 
        lower.startsWith('where ') ||
        lower.startsWith('who ');
  }

  /// Detects if a question is programming/coding related
  static bool isCodingQuestion(String content) {
    final lower = content.toLowerCase();
    
    // Programming keywords and concepts
    final codingKeywords = [
      'java', 'python', 'javascript', 'c++', 'c#', 'code', 'program', 'function',
      'method', 'class', 'object', 'variable', 'array', 'loop', 'if statement',
      'algorithm', 'data structure', 'recursion', 'inheritance', 'polymorphism',
      'exception', 'thread', 'database', 'sql', 'api', 'framework', 'library',
      'syntax', 'compile', 'debug', 'runtime', 'memory', 'pointer', 'reference',
      'constructor', 'destructor', 'interface', 'abstract', 'static', 'final',
      'public', 'private', 'protected', 'void', 'int', 'string', 'boolean',
      'list', 'map', 'set', 'queue', 'stack', 'tree', 'graph', 'sorting',
      'searching', 'binary', 'hash', 'linked list', 'arraylist', 'hashmap'
    ];
    
    return codingKeywords.any((keyword) => lower.contains(keyword));
  }
}