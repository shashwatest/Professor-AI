// lib/services/embeddings/embeddings_provider.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

/// Interface for embeddings provider.
abstract class EmbeddingsProvider {
  /// Embed a single text into vector (double list)
  Future<List<double>> embedText(String text);

  /// Embed a batch of texts
  Future<List<List<double>>> embedTextBatch(List<String> texts);
}

/// Example implementation using OpenAI embeddings API (text-embedding-3-small or text-embedding-3-large)
/// IMPORTANT: Do NOT hardcode your OpenAI API key in client-side apps in production.
/// Prefer to call your server endpoint which holds the key.
class OpenAIEmbeddingsProvider implements EmbeddingsProvider {
  final String apiKey;
  final String model;
  final String baseUrl;

  OpenAIEmbeddingsProvider({
    required this.apiKey,
    this.model = 'text-embedding-3-small',
    this.baseUrl = 'https://api.openai.com/v1/embeddings',
  });

  @override
  Future<List<double>> embedText(String text) async {
    final res = await embedTextBatch([text]);
    return res.first;
  }

  @override
  Future<List<List<double>>> embedTextBatch(List<String> texts) async {
    final body = jsonEncode({'model': model, 'input': texts});
    final resp = await http.post(
      Uri.parse(baseUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: body,
    );
    if (resp.statusCode != 200) {
      throw Exception('Embeddings API error: ${resp.statusCode} ${resp.body}');
    }
    final j = jsonDecode(resp.body) as Map<String, dynamic>;
    final data = j['data'] as List<dynamic>;
    final vectors = data.map<List<double>>((e) {
      final v = (e['embedding'] as List<dynamic>).map((x) => (x as num).toDouble()).toList();
      return v;
    }).toList();
    return vectors;
  }
}

/// Google embeddings provider using Generative AI API (same as Gemini)
/// Uses Google's text-embedding-004 model for generating embeddings
/// Uses the same API key as Gemini - no project ID required
class GoogleEmbeddingsProvider implements EmbeddingsProvider {
  final String apiKey;
  final String model;
  final String baseUrl;

  GoogleEmbeddingsProvider({
    required this.apiKey,
    this.model = 'text-embedding-004',
  }) : baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models/$model:embedContent';

  @override
  Future<List<double>> embedText(String text) async {
    final res = await embedTextBatch([text]);
    return res.first;
  }

  @override
  Future<List<List<double>>> embedTextBatch(List<String> texts) async {
    try {
      // Process texts one by one since Google's embedContent API doesn't support batch processing
      final List<List<double>> allVectors = [];
      
      for (final text in texts) {
        final body = jsonEncode({
          'content': {
            'parts': [
              {'text': text}
            ]
          },
          'taskType': 'RETRIEVAL_DOCUMENT',
        });

        final resp = await http.post(
          Uri.parse('$baseUrl?key=$apiKey'),
          headers: {
            'Content-Type': 'application/json',
          },
          body: body,
        );

        if (resp.statusCode != 200) {
          throw Exception('Google Embeddings API error: ${resp.statusCode} ${resp.body}');
        }

        final j = jsonDecode(resp.body) as Map<String, dynamic>;
        final embedding = j['embedding'];
        final values = embedding['values'] as List<dynamic>;
        final vector = values.map((x) => (x as num).toDouble()).toList();
        allVectors.add(vector);
      }

      return allVectors;
    } catch (e) {
      throw Exception('Google Embeddings API error: $e');
    }
  }
}

/// Meta embeddings provider using Llama embeddings API
/// Uses Meta's text embedding models for generating embeddings
class MetaEmbeddingsProvider implements EmbeddingsProvider {
  final String apiKey;
  final String model;
  final String baseUrl;

  MetaEmbeddingsProvider({
    required this.apiKey,
    this.model = 'llama-2-7b-chat', // Use a valid Meta model
    this.baseUrl = 'https://api.llama-api.com/embeddings',
  });

  @override
  Future<List<double>> embedText(String text) async {
    final res = await embedTextBatch([text]);
    return res.first;
  }

  @override
  Future<List<List<double>>> embedTextBatch(List<String> texts) async {
    try {
      final body = jsonEncode({
        'model': model,
        'input': texts,
      });

      final resp = await http.post(
        Uri.parse(baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: body,
      );

      if (resp.statusCode != 200) {
        throw Exception('Meta Embeddings API error: ${resp.statusCode} ${resp.body}');
      }

      final j = jsonDecode(resp.body) as Map<String, dynamic>;
      final data = j['data'] as List<dynamic>;
      
      final vectors = data.map<List<double>>((item) {
        final embedding = item['embedding'] as List<dynamic>;
        return embedding.map((x) => (x as num).toDouble()).toList();
      }).toList();

      return vectors;
    } catch (e) {
      throw Exception('Meta Embeddings API error: $e');
    }
  }
}
