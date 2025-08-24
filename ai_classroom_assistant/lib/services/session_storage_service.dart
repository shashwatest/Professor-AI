import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/transcription_session.dart';

class SessionStorageService {
  static const String _sessionsKey = 'saved_sessions';
  
  static Future<void> saveSession(TranscriptionSession session) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessions = await getSessions();
      
      // Add new session to the beginning of the list
      sessions.insert(0, session);
      
      // Keep only last 50 sessions to prevent storage bloat
      if (sessions.length > 50) {
        sessions.removeRange(50, sessions.length);
      }
      
      final sessionsJson = sessions.map((s) => _sessionToJson(s)).toList();
      await prefs.setString(_sessionsKey, jsonEncode(sessionsJson));
    } catch (e) {
      throw Exception('Failed to save session: $e');
    }
  }
  
  static Future<List<TranscriptionSession>> getSessions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionsString = prefs.getString(_sessionsKey);
      
      if (sessionsString == null) return [];
      
      final sessionsList = jsonDecode(sessionsString) as List;
      return sessionsList.map((json) => _sessionFromJson(json)).toList();
    } catch (e) {
      return []; // Return empty list on error
    }
  }
  
  static Future<void> deleteSession(String sessionId) async {
    try {
      final sessions = await getSessions();
      sessions.removeWhere((session) => session.id == sessionId);
      
      final prefs = await SharedPreferences.getInstance();
      final sessionsJson = sessions.map((s) => _sessionToJson(s)).toList();
      await prefs.setString(_sessionsKey, jsonEncode(sessionsJson));
    } catch (e) {
      throw Exception('Failed to delete session: $e');
    }
  }
  
  static Map<String, dynamic> _sessionToJson(TranscriptionSession session) {
    return {
      'id': session.id,
      'startTime': session.startTime.millisecondsSinceEpoch,
      'endTime': session.endTime?.millisecondsSinceEpoch,
      'transcriptionChunks': session.transcriptionChunks,
      'extractedTopics': session.extractedTopics,
      'wordCount': session.wordCount,
      'isRecording': session.isRecording,
    };
  }
  
  static TranscriptionSession _sessionFromJson(Map<String, dynamic> json) {
    return TranscriptionSession(
      id: json['id'],
      startTime: DateTime.fromMillisecondsSinceEpoch(json['startTime']),
      endTime: json['endTime'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(json['endTime'])
          : null,
      transcriptionChunks: List<String>.from(json['transcriptionChunks']),
      extractedTopics: List<String>.from(json['extractedTopics']),
      wordCount: json['wordCount'],
      isRecording: json['isRecording'],
    );
  }
}