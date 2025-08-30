import 'package:flutter/material.dart';
import 'screens/app_shell.dart';
import 'services/document_service.dart';
import 'services/embeddings/embeddings_service.dart';
import 'services/vectorstore/vector_store.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize RAG services
  await _initializeRAGServices();
  
  runApp(const AIClassroomAssistant());
}

Future<void> _initializeRAGServices() async {
  try {
    // Initialize vector store
    DocumentService.vectorStore = InMemoryVectorStore();
    
    // Initialize embeddings provider (will be set dynamically based on user settings)
    final embeddingsProvider = await EmbeddingsService.getEmbeddingsProvider();
    DocumentService.embeddingsProvider = embeddingsProvider;
    
    print('RAG services initialized successfully');
  } catch (e) {
    print('Failed to initialize RAG services: $e');
    // Continue without RAG - the app will work with basic keyword search
  }
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
      home: const AppShell(),
    );
  }
}