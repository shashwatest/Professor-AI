// lib/services/document_service.dart
import 'dart:convert';
import 'dart:typed_data';
import 'dart:io' show File;

import 'package:file_picker/file_picker.dart';
import 'package:archive/archive.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:crypto/crypto.dart'; // for chunk dedup hashing

import 'embeddings/embeddings_provider.dart';
import 'embeddings/embeddings_service.dart';
import 'vectorstore/vector_store.dart';
import 'utils/backoff.dart';

/// Document chunk metadata stored in application memory and indexed in vector store.
class DocumentChunk {
  final String id; // unique id for vector store
  final String content;
  final int pageNumber; // page or slide number (1-based)
  final String source; // filename
  final int chunkIndex; // chunk index within page
  final int length;

  DocumentChunk({
    required this.id,
    required this.content,
    required this.pageNumber,
    required this.source,
    required this.chunkIndex,
  }) : length = content.length;

  Map<String, dynamic> toJson() => {
        'id': id,
        'content': content,
        'pageNumber': pageNumber,
        'source': source,
        'chunkIndex': chunkIndex,
        'length': length,
      };

  factory DocumentChunk.fromJson(Map<String, dynamic> j) => DocumentChunk(
        id: j['id'],
        content: j['content'],
        pageNumber: j['pageNumber'],
        source: j['source'],
        chunkIndex: j['chunkIndex'],
      );
}

/// High-level DocumentService: parse PDF/PPTX, chunk, embed & index (RAG).
/// - Uses an EmbeddingsProvider to compute embeddings
/// - Uses a VectorStore to upsert vectors
/// - Keeps chunks in memory (_documentChunks) for immediate use
class DocumentService {
  // In-memory store of chunks (persist if you want)
  static final List<DocumentChunk> _documentChunks = [];
  static String? _currentDocumentName;

  // Exposed singletons (for dependency injection, set before using uploadDocument)
  static EmbeddingsProvider? embeddingsProvider;
  static VectorStore? vectorStore;

  // Chunking config
  static int chunkSize = 1000; // characters per chunk (tunable)
  static int chunkOverlap = 200;

  // Limits
  static int maxTotalIndexedChars = 20000; // avoid crazy large uploads (tunable)
  static int maxUploadBytes = 10 * 1024 * 1024; // 10 MB limit for uploads (tunable)

  // Getters
  static List<DocumentChunk> get documentChunks => List.unmodifiable(_documentChunks);
  static String? get currentDocumentName => _currentDocumentName;
  static bool get hasDocument => _documentChunks.isNotEmpty;

  /// Upload + process + index
  /// Returns true if upload & (best-effort) indexing succeeded.
  static Future<bool> uploadDocumentAndIndex({
    bool allowPdf = true,
    bool allowPptx = true,
    // optional overrides for providers
    EmbeddingsProvider? embeddingsProviderOverride,
    VectorStore? vectorStoreOverride,
  }) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          if (allowPdf) 'pdf',
          if (allowPptx) 'pptx',
        ],
        allowMultiple: false,
        withData: true, // necessary for web
      );

      if (result == null || result.files.isEmpty) return false;

      final pf = result.files.single;
      final fileName = pf.name;
      _currentDocumentName = fileName;

      // Safety checks
      final int? size = pf.size;
      if (size != null && size > maxUploadBytes) {
        throw Exception('File too large. Max allowed is ${maxUploadBytes ~/ (1024 * 1024)} MB');
      }

      final Uint8List? bytes = await _getFileBytes(pf);
      if (bytes == null) throw Exception('Unable to read uploaded file bytes');

      // Choose parser
      _documentChunks.clear();

      if (fileName.toLowerCase().endsWith('.pdf')) {
        await _processPDF(bytes, fileName);
      } else if (fileName.toLowerCase().endsWith('.pptx')) {
        await _processPPTX(bytes, fileName);
      } else {
        throw Exception('Unsupported file type');
      }

      // Trim if too large in total text
      final totalChars = _documentChunks.fold<int>(0, (a, b) => a + b.length);
      if (totalChars > maxTotalIndexedChars) {
        // keep earliest chunks up to limit (you can update policy)
        int running = 0;
        final keep = <DocumentChunk>[];
        for (final c in _documentChunks) {
          if (running + c.length <= maxTotalIndexedChars) {
            keep.add(c);
            running += c.length;
          } else {
            break;
          }
        }
        _documentChunks
          ..clear()
          ..addAll(keep);
      }

      // Index into vector store (RAG) - best-effort with retries
      final embProvider = embeddingsProviderOverride ?? 
                         embeddingsProvider ?? 
                         await EmbeddingsService.getEmbeddingsProvider();
      final vstore = vectorStoreOverride ?? vectorStore;

      if (embProvider == null || vstore == null) {
        // No vector backend configured — skip indexing but keep chunks in memory
        print('DocumentService: embeddingsProvider or vectorStore not configured; skipping RAG index.');
        return true;
      }

      // Build embeddings for each chunk and upsert to vector store.
      // We include metadata for retrieval.
      // Use batching and retry/backoff.
      final int batchSize = 16;
      final batches = <List<DocumentChunk>>[];
      for (var i = 0; i < _documentChunks.length; i += batchSize) {
        batches.add(_documentChunks.sublist(i, (i + batchSize).clamp(0, _documentChunks.length)));
      }

      for (final batch in batches) {
        // prepare texts
        final texts = batch.map((c) => c.content).toList();

        // generate embeddings with backoff
        final embeddings = await withExponentialBackoff<List<List<double>>>(
          () => embProvider.embedTextBatch(texts),
          maxAttempts: 5,
          initialDelayMs: 500,
        );

        // create vector items
        final items = <VectorItem>[];
        for (var i = 0; i < batch.length; i++) {
          final c = batch[i];
          final vec = embeddings[i];
          final meta = {
            'id': c.id,
            'source': c.source,
            'pageNumber': c.pageNumber,
            'chunkIndex': c.chunkIndex,
            'length': c.length,
            'textPreview': c.content.length > 200 ? c.content.substring(0, 200) + '...' : c.content,
          };
          items.add(VectorItem(id: c.id, vector: vec, metadata: meta));
        }

        // upsert with retry
        await withExponentialBackoff(
          () => vstore.upsert(items),
          maxAttempts: 5,
          initialDelayMs: 500,
        );
      }

      // success
      return true;
    } catch (e, st) {
      // bubble up; caller UI may show a friendly message. We keep chunks in memory regardless.
      print('DocumentService.uploadDocumentAndIndex failed: $e\n$st');
      throw Exception('Failed to upload/index document: $e');
    }
  }

  /// Retrieves relevant chunks either through vector search (preferred)
  /// or falls back to keyword similarity if vectorStore / embeddings not configured.
  static Future<List<DocumentChunk>> retrieveRelevantChunks(String query, {int topK = 5}) async {
    try {
      final embProvider = embeddingsProvider ?? await EmbeddingsService.getEmbeddingsProvider();
      if (vectorStore != null && embProvider != null) {
        // embed query and call vector search
        final qvec = await embProvider.embedText(query);
        final results = await vectorStore!.queryByVector(qvec, topK: topK);

        // Map results to DocumentChunk using stored metadata (if available)
        final found = <DocumentChunk>[];
        for (final r in results) {
          final meta = r.metadata;
          if (meta == null) continue;
          final id = meta['id'] ?? r.id;
          final contentPreview = meta['textPreview'] ?? '';
          final pageNumber = meta['pageNumber'] ?? 1;
          final source = meta['source'] ?? _currentDocumentName ?? 'document';
          final chunkIndex = meta['chunkIndex'] ?? 0;
          // Try to find full chunk text in memory (prefer exact)
          final local = _documentChunks.firstWhere(
            (c) => c.id == id,
            orElse: () => DocumentChunk(id: id, content: contentPreview, pageNumber: pageNumber, source: source, chunkIndex: chunkIndex),
          );
          found.add(local);
        }
        return found;
      } else {
        // fallback simple textual similarity
        return _keywordSimilaritySearch(query, topK: topK);
      }
    } catch (e) {
      print('retrieveRelevantChunks error: $e');
      return _keywordSimilaritySearch(query, topK: topK);
    }
  }

  // ----- internal helpers -----

  /// Read file bytes robustly (web: use file.bytes; mobile/desktop: use path)
  static Future<Uint8List?> _getFileBytes(PlatformFile pf) async {
    try {
      if (pf.bytes != null) return pf.bytes;
      if (pf.path != null) {
        final f = File(pf.path!);
        return await f.readAsBytes();
      }
      return null;
    } catch (e) {
      throw Exception('Error reading file bytes: $e');
    }
  }

  /// Parse PDF bytes using syncfusion flutter pdf
  static Future<void> _processPDF(Uint8List bytes, String filename) async {
    try {
      final doc = PdfDocument(inputBytes: bytes);
      final extractor = PdfTextExtractor(doc);
      int chunkGlobalIndex = 0;

      for (var i = 0; i < doc.pages.count; i++) {
        final pageText = extractor.extractText(startPageIndex: i, endPageIndex: i) ?? '';
        final cleaned = _cleanText(pageText);
        if (cleaned.trim().isEmpty) continue;

        final pageChunks = _chunkText(cleaned, chunkSize, chunkOverlap);
        for (var ci = 0; ci < pageChunks.length; ci++) {
          final content = pageChunks[ci];
          final id = _chunkId(filename, i + 1, ci, content);
          _documentChunks.add(DocumentChunk(
            id: id,
            content: content,
            pageNumber: i + 1,
            source: filename,
            chunkIndex: ci,
          ));
          chunkGlobalIndex++;
        }
      }
      doc.dispose();
    } catch (e) {
      throw Exception('Failed to process PDF: $e');
    }
  }

  /// Parse PPTX bytes by unzipping and extracting <a:t> text nodes
  static Future<void> _processPPTX(Uint8List bytes, String filename) async {
    try {
      final archive = ZipDecoder().decodeBytes(bytes);
      int slideNumber = 1;

      for (final f in archive) {
        if (f.isFile && f.name.startsWith('ppt/slides/slide') && f.name.endsWith('.xml')) {
          final xml = utf8.decode(f.content as List<int>);
          final extractedText = _extractTextFromSlideXML(xml);
          final cleaned = _cleanText(extractedText);
          if (cleaned.trim().isEmpty) {
            slideNumber++;
            continue;
          }
          final pageChunks = _chunkText(cleaned, chunkSize, chunkOverlap);
          for (var ci = 0; ci < pageChunks.length; ci++) {
            final content = pageChunks[ci];
            final id = _chunkId(filename, slideNumber, ci, content);
            _documentChunks.add(DocumentChunk(
              id: id,
              content: content,
              pageNumber: slideNumber,
              source: filename,
              chunkIndex: ci,
            ));
          }
          slideNumber++;
        }
      }
    } catch (e) {
      throw Exception('Failed to process PPTX: $e');
    }
  }

  static String _extractTextFromSlideXML(String xml) {
    final regex = RegExp(r'<a:t[^>]*>([^<]*)</a:t>');
    final matches = regex.allMatches(xml);
    return matches.map((m) => m.group(1) ?? '').join(' ');
  }

  static String _cleanText(String t) {
    // minimal cleaning: collapse whitespace, remove control chars
    final cleaned = t.replaceAll(RegExp(r'\s+'), ' ').trim();
    return cleaned;
  }

  static List<String> _chunkText(String text, int size, int overlap) {
    if (text.length <= size) return [text];
    final parts = <String>[];
    int start = 0;
    while (start < text.length) {
      final end = (start + size).clamp(0, text.length);
      final chunk = text.substring(start, end).trim();
      if (chunk.isNotEmpty) parts.add(chunk);
      if (end == text.length) break;
      start = end - overlap;
      if (start < 0) start = 0;
    }
    return parts;
  }

  static String _chunkId(String filename, int pageNumber, int chunkIndex, String content) {
    // produce stable id based on filename+page+chunkIndex+content hash
    final bytes = utf8.encode('$filename|$pageNumber|$chunkIndex|${content.substring(0, content.length.clamp(0, 64))}');
    final h = sha256.convert(bytes).toString();
    return h;
  }

  static List<DocumentChunk> _keywordSimilaritySearch(String query, {int topK = 5}) {
    final q = query.toLowerCase();
    final scored = _documentChunks.map((c) {
      final sim = _jaccardSimilarity(c.content.toLowerCase(), q);
      return MapEntry(c, sim);
    }).toList();
    scored.sort((a, b) => b.value.compareTo(a.value));
    return scored.take(topK).map((e) => e.key).toList();
  }

  static double _jaccardSimilarity(String a, String b) {
    final sa = a.split(RegExp(r'\s+')).toSet();
    final sb = b.split(RegExp(r'\s+')).toSet();
    if (sa.isEmpty || sb.isEmpty) return 0.0;
    final inter = sa.intersection(sb).length;
    final union = sa.union(sb).length;
    return union == 0 ? 0.0 : inter / union;
  }

  static void clearDocument() {
    _documentChunks.clear();
    _currentDocumentName = null;
  }

  /// Debug method to check RAG system status
  static Map<String, dynamic> getRAGStatus() {
    return {
      'hasEmbeddingsProvider': embeddingsProvider != null,
      'hasVectorStore': vectorStore != null,
      'embeddingsProviderType': embeddingsProvider?.runtimeType.toString(),
      'vectorStoreType': vectorStore?.runtimeType.toString(),
      'documentChunksCount': _documentChunks.length,
      'currentDocument': _currentDocumentName,
    };
  }
}