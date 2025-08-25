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
