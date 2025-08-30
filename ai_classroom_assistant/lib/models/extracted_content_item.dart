import 'package:flutter/material.dart';
import 'content_type.dart';

class ExtractedContentItem {
  final String content;
  final ContentType type;
  final String displayText;
  final DateTime timestamp;

  ExtractedContentItem({
    required this.content,
    required this.type,
    required this.displayText,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Factory method to create item from AI response line
  factory ExtractedContentItem.fromAIResponse(String line) {
    final type = ContentTypeDetector.detectFromLine(line);
    final content = ContentTypeDetector.extractContent(line);
    
    // If no prefix was found, treat the whole line as content
    final finalContent = content.isEmpty ? line.trim() : content;
    final finalType = type ?? ContentTypeDetector.detectFromContent(finalContent);
    
    return ExtractedContentItem(
      content: finalContent,
      type: finalType,
      displayText: finalContent,
    );
  }

  /// Factory method for backward compatibility with plain text
  factory ExtractedContentItem.fromPlainText(String text) {
    final type = ContentTypeDetector.detectFromContent(text);
    return ExtractedContentItem(
      content: text,
      type: type,
      displayText: text,
    );
  }

  /// Get theme color for this content type
  Color getThemeColor(BuildContext context) {
    return type.getThemeColor(context);
  }

  /// Get background color for this content type
  Color getBackgroundColor(BuildContext context) {
    return type.getBackgroundColor(context);
  }

  /// Get icon for this content type
  IconData get icon => type.icon;

  /// Get display name for this content type
  String get typeName => type.displayName;

  /// Convert to JSON for persistence
  Map<String, dynamic> toJson() {
    return {
      'content': content,
      'type': type.name,
      'displayText': displayText,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  /// Create from JSON
  factory ExtractedContentItem.fromJson(Map<String, dynamic> json) {
    return ExtractedContentItem(
      content: json['content'] as String,
      type: ContentType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => ContentType.topic,
      ),
      displayText: json['displayText'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  /// Create a copy with modified properties
  ExtractedContentItem copyWith({
    String? content,
    ContentType? type,
    String? displayText,
    DateTime? timestamp,
  }) {
    return ExtractedContentItem(
      content: content ?? this.content,
      type: type ?? this.type,
      displayText: displayText ?? this.displayText,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ExtractedContentItem &&
        other.content == content &&
        other.type == type &&
        other.displayText == displayText;
  }

  @override
  int get hashCode {
    return content.hashCode ^ type.hashCode ^ displayText.hashCode;
  }

  @override
  String toString() {
    return 'ExtractedContentItem(content: $content, type: $type, displayText: $displayText, timestamp: $timestamp)';
  }
}

/// Utility class to process AI responses into ExtractedContentItem list
class ExtractedContentProcessor {
  /// Process AI response lines into ExtractedContentItem list
  static List<ExtractedContentItem> processAIResponse(List<String> lines) {
    return lines
        .where((line) => _isValidContentLine(line))
        .map((line) => ExtractedContentItem.fromAIResponse(line))
        .where((item) => _isValidExtractedItem(item))
        .toList();
  }

  /// Check if a line is valid content (has proper prefix or is meaningful content)
  static bool _isValidContentLine(String line) {
    final trimmed = line.trim();
    if (trimmed.isEmpty) return false;
    
    // Check if line has proper prefix (with or without dash)
    if (trimmed.startsWith('TOPIC:') || 
        trimmed.startsWith('QUESTION:') ||
        trimmed.startsWith('CODE_QUESTION:') ||
        trimmed.startsWith('- TOPIC:') || 
        trimmed.startsWith('- QUESTION:') ||
        trimmed.startsWith('- CODE_QUESTION:')) {
      return true;
    }
    
    // Filter out common AI response artifacts
    final lower = trimmed.toLowerCase();
    if (lower.startsWith('here\'s') ||
        lower.startsWith('here are') ||
        lower.startsWith('based on') ||
        lower.startsWith('analyzing') ||
        lower.startsWith('analysis of') ||
        lower.startsWith('from the') ||
        lower.startsWith('the following') ||
        lower.startsWith('i\'ve analyzed') ||
        lower.startsWith('after analyzing') ||
        lower.contains('transcription') && lower.contains('analysis') ||
        lower.contains('classroom transcription') ||
        trimmed.length < 10) { // Too short to be meaningful content
      return false;
    }
    
    return true;
  }

  /// Check if an extracted item is valid and meaningful
  static bool _isValidExtractedItem(ExtractedContentItem item) {
    final content = item.content.trim();
    if (content.isEmpty || content.length < 5) return false;
    
    // Filter out common AI artifacts that might slip through
    final lower = content.toLowerCase();
    if (lower.startsWith('here\'s') ||
        lower.startsWith('here are') ||
        lower.startsWith('based on') ||
        lower.contains('transcription for a') ||
        lower.contains('student and extract') ||
        lower.contains('format your response')) {
      return false;
    }
    
    return true;
  }

  /// Process plain text list for backward compatibility
  static List<ExtractedContentItem> processPlainTextList(List<String> texts) {
    return texts
        .where((text) => text.trim().isNotEmpty)
        .map((text) => ExtractedContentItem.fromPlainText(text))
        .toList();
  }

  /// Group items by content type
  static Map<ContentType, List<ExtractedContentItem>> groupByType(
      List<ExtractedContentItem> items) {
    final Map<ContentType, List<ExtractedContentItem>> grouped = {};
    
    for (final item in items) {
      grouped.putIfAbsent(item.type, () => []).add(item);
    }
    
    return grouped;
  }

  /// Filter items by content type
  static List<ExtractedContentItem> filterByType(
      List<ExtractedContentItem> items, ContentType type) {
    return items.where((item) => item.type == type).toList();
  }
}