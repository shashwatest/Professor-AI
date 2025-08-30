// lib/services/embeddings/embeddings_factory.dart
import 'embeddings_provider.dart';

enum EmbeddingProvider {
  openai,
  google,
  meta,
}

class EmbeddingsFactory {
  static EmbeddingsProvider? createProvider({
    required EmbeddingProvider provider,
    required String apiKey,
    String? projectId, // Optional, not used for Google Generative AI
  }) {
    switch (provider) {
      case EmbeddingProvider.openai:
        return OpenAIEmbeddingsProvider(apiKey: apiKey);
      
      case EmbeddingProvider.google:
        // Google Generative AI embeddings use the same API key as Gemini
        return GoogleEmbeddingsProvider(apiKey: apiKey);
      
      case EmbeddingProvider.meta:
        return MetaEmbeddingsProvider(apiKey: apiKey);
    }
  }
}