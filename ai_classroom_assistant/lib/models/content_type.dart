import 'package:flutter/material.dart';

enum ContentType {
  topic,
  question,
}

extension ContentTypeExtension on ContentType {
  String get displayName {
    switch (this) {
      case ContentType.topic:
        return 'Topic';
      case ContentType.question:
        return 'Question';
    }
  }

  IconData get icon {
    switch (this) {
      case ContentType.topic:
        return Icons.topic_outlined;
      case ContentType.question:
        return Icons.help_outline;
    }
  }

  Color getThemeColor(BuildContext context) {
    switch (this) {
      case ContentType.topic:
        return Colors.blue; // Topics in blue
      case ContentType.question:
        return Colors.red; // Questions in red
    }
  }

  Color getBackgroundColor(BuildContext context) {
    switch (this) {
      case ContentType.topic:
        return Colors.blue.withOpacity(0.1); // Light blue background for topics
      case ContentType.question:
        return Colors.red.withOpacity(0.1); // Light red background for questions
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
    }
    return trimmed;
  }

  /// Detects content type from plain text (fallback for backward compatibility)
  static ContentType detectFromContent(String content) {
    final lower = content.toLowerCase();
    
    // Check for question patterns
    if (lower.contains('?') || 
        lower.startsWith('what ') || 
        lower.startsWith('how ') || 
        lower.startsWith('why ') || 
        lower.startsWith('when ') || 
        lower.startsWith('where ') ||
        lower.startsWith('who ')) {
      return ContentType.question;
    }
    
    // Default to topic
    return ContentType.topic;
  }
}