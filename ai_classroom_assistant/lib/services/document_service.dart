import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:archive/archive.dart';
import 'dart:convert';

class DocumentChunk {
  final String content;
  final int pageNumber;
  final String source;
  
  DocumentChunk({
    required this.content,
    required this.pageNumber,
    required this.source,
  });
  
  Map<String, dynamic> toJson() => {
    'content': content,
    'pageNumber': pageNumber,
    'source': source,
  };
  
  factory DocumentChunk.fromJson(Map<String, dynamic> json) => DocumentChunk(
    content: json['content'],
    pageNumber: json['pageNumber'],
    source: json['source'],
  );
}

class DocumentService {
  static List<DocumentChunk> _documentChunks = [];
  static String? _currentDocumentName;
  
  static List<DocumentChunk> get documentChunks => _documentChunks;
  static String? get currentDocumentName => _currentDocumentName;
  static bool get hasDocument => _documentChunks.isNotEmpty;
  
  static Future<bool> uploadDocument() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'pptx'],
        allowMultiple: false,
      );
      
      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final fileName = result.files.single.name;
        _currentDocumentName = fileName;
        
        if (fileName.toLowerCase().endsWith('.pdf')) {
          await _processPDF(file);
        } else if (fileName.toLowerCase().endsWith('.pptx')) {
          await _processPPTX(file);
        }
        
        return true;
      }
      return false;
    } catch (e) {
      throw Exception('Failed to upload document: $e');
    }
  }
  
  static Future<void> _processPDF(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final document = PdfDocument(inputBytes: bytes);
      
      _documentChunks.clear();
      
      for (int i = 0; i < document.pages.count; i++) {
        final page = document.pages[i];
        final text = PdfTextExtractor(document).extractText(startPageIndex: i, endPageIndex: i);
        
        if (text.trim().isNotEmpty) {
          _documentChunks.add(DocumentChunk(
            content: text.trim(),
            pageNumber: i + 1,
            source: _currentDocumentName!,
          ));
        }
      }
      
      document.dispose();
    } catch (e) {
      throw Exception('Failed to process PDF: $e');
    }
  }
  
  static Future<void> _processPPTX(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);
      
      _documentChunks.clear();
      int slideNumber = 1;
      
      for (final file in archive) {
        if (file.name.startsWith('ppt/slides/slide') && file.name.endsWith('.xml')) {
          final content = utf8.decode(file.content as List<int>);
          final text = _extractTextFromSlideXML(content);
          
          if (text.trim().isNotEmpty) {
            _documentChunks.add(DocumentChunk(
              content: text.trim(),
              pageNumber: slideNumber,
              source: _currentDocumentName!,
            ));
            slideNumber++;
          }
        }
      }
    } catch (e) {
      throw Exception('Failed to process PPTX: $e');
    }
  }
  
  static String _extractTextFromSlideXML(String xml) {
    final textRegex = RegExp(r'<a:t[^>]*>([^<]*)</a:t>');
    final matches = textRegex.allMatches(xml);
    return matches.map((match) => match.group(1) ?? '').join(' ');
  }
  
  static List<DocumentChunk> findRelevantChunks(String topic) {
    if (_documentChunks.isEmpty) return [];
    
    // Simple keyword matching for RAG (replace with proper vector similarity)
    final topicLower = topic.toLowerCase();
    return _documentChunks.where((chunk) {
      return chunk.content.toLowerCase().contains(topicLower) ||
             _calculateSimilarity(chunk.content.toLowerCase(), topicLower) > 0.3;
    }).toList();
  }
  
  static double _calculateSimilarity(String text1, String text2) {
    final words1 = text1.split(' ').toSet();
    final words2 = text2.split(' ').toSet();
    final intersection = words1.intersection(words2);
    final union = words1.union(words2);
    return union.isEmpty ? 0.0 : intersection.length / union.length;
  }
  
  static void clearDocument() {
    _documentChunks.clear();
    _currentDocumentName = null;
  }
}