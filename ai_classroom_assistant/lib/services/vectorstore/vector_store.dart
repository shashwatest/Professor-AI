// lib/services/vectorstore/vector_store.dart
/// Vector store interface and in-memory implementation (cosine search)
import 'dart:math';

class VectorItem {
  final String id;
  final List<double> vector;
  final Map<String, dynamic>? metadata;
  VectorItem({required this.id, required this.vector, this.metadata});
}

abstract class VectorStore {
  /// Upsert items (replace if id exists)
  Future<void> upsert(List<VectorItem> items);

  /// Query by vector (returns topK nearest items with score)
  Future<List<VectorSearchResult>> queryByVector(List<double> query, {int topK = 5});
}

class VectorSearchResult {
  final String id;
  final double score;
  final Map<String, dynamic>? metadata;
  VectorSearchResult({required this.id, required this.score, this.metadata});
}

/// Simple in-memory vector store. Not for production (no persistence).
class InMemoryVectorStore implements VectorStore {
  final Map<String, VectorItem> _map = {};

  @override
  Future<void> upsert(List<VectorItem> items) async {
    for (final it in items) {
      _map[it.id] = it;
    }
  }

  @override
  Future<List<VectorSearchResult>> queryByVector(List<double> query, {int topK = 5}) async {
    if (_map.isEmpty) return [];
    final scores = <VectorSearchResult>[];
    for (final it in _map.values) {
      final s = _cosineSimilarity(query, it.vector);
      scores.add(VectorSearchResult(id: it.id, score: s, metadata: it.metadata));
    }
    scores.sort((a, b) => b.score.compareTo(a.score));
    return scores.take(topK).toList();
  }

  double _cosineSimilarity(List<double> a, List<double> b) {
    final n = min(a.length, b.length);
    double dot = 0, na = 0, nb = 0;
    for (var i = 0; i < n; i++) {
      dot += a[i] * b[i];
      na += a[i] * a[i];
      nb += b[i] * b[i];
    }
    if (na == 0 || nb == 0) return 0.0;
    return dot / (sqrt(na) * sqrt(nb));
  }
}
