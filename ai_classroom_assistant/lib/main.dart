import 'package:flutter/material.dart';
import 'screens/transcription_screen.dart';

void main() {
  runApp(const AIClassroomAssistant());
}

class AIClassroomAssistant extends StatelessWidget {
  const AIClassroomAssistant({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Classroom Assistant',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
      ),
      home: const TranscriptionScreen(),
    );
  }
}