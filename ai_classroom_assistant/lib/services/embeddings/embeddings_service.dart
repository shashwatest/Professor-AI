// lib/services/embeddings/embeddings_service.dart
import '../settings_service.dart';
import 'embeddings_factory.dart';
import 'embeddings_provider.dart';
import '../ai_service.dart';
import '../document_service.dart';

class EmbeddingsService {
  static EmbeddingsProvider? _cachedProvider;
  static EmbeddingProvider? _cachedProviderType;

  /// Get the configured embedding provider based on user settings
  static Future<EmbeddingsProvider?> getEmbeddingsProvider() async {
    try {
      final selectedProvider = await SettingsService.getEmbeddingProvider();
      
      // Return cached provider if it's the same type
      if (_cachedProvider != null && _cachedProviderType == selectedProvider) {
        return _cachedProvider;
      }

      String? apiKey;

      switch (selectedProvider) {
        case EmbeddingProvider.openai:
          apiKey = await SettingsService.getAPIKey(AIProvider.openai);
          break;
        case EmbeddingProvider.google:
          // Google embeddings use the same API key as Gemini
          apiKey = await SettingsService.getAPIKey(AIProvider.gemini);
          break;
        case EmbeddingProvider.meta:
          apiKey = await SettingsService.getAPIKey(AIProvider.meta);
          break;
      }

      if (apiKey == null || apiKey.isEmpty) {
        return null; // No API key configured
      }

      _cachedProvider = EmbeddingsFactory.createProvider(
        provider: selectedProvider,
        apiKey: apiKey,
      );
      _cachedProviderType = selectedProvider;

      return _cachedProvider;
    } catch (e) {
      // Return null if configuration fails
      return null;
    }
  }

  /// Clear cached provider (call when settings change)
  static void clearCache() {
    _cachedProvider = null;
    _cachedProviderType = null;
  }

  /// Refresh the DocumentService embeddings provider
  static Future<void> refreshDocumentServiceProvider() async {
    try {
      final provider = await getEmbeddingsProvider();
      DocumentService.embeddingsProvider = provider;
    } catch (e) {
      print('Failed to refresh embeddings provider: $e');
    }
  }
}