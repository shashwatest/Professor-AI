// lib/screens/topic_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_math_fork/flutter_math.dart';

import '../services/ai_service.dart';
import '../services/document_service.dart';
import '../widgets/glass_container.dart';

class TopicDetailScreen extends StatefulWidget {
  final String topic;
  final AIService aiService;
  final String educationLevel;
  final Function(String)? onAddToNotes;

  const TopicDetailScreen({
    super.key,
    required this.topic,
    required this.aiService,
    required this.educationLevel,
    this.onAddToNotes,
  });

  @override
  State<TopicDetailScreen> createState() => _TopicDetailScreenState();
}

class _TopicDetailScreenState extends State<TopicDetailScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  String? _topicDetails;
  List<DocumentChunk> _documentChunks = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadTopicDetails();
    _loadDocumentContent();
  }

  Future<void> _loadTopicDetails() async {
    try {
      final details = await widget.aiService.getTopicDetails(
        widget.topic,
        widget.educationLevel,
      );
      setState(() {
        _topicDetails = details;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }


  Future<void> _loadDocumentContent() async {
    try {
      // Debug: Check if RAG services are available
      final hasEmbeddings = DocumentService.embeddingsProvider != null;
      final hasVectorStore = DocumentService.vectorStore != null;
      debugPrint('RAG Status - Embeddings: $hasEmbeddings, VectorStore: $hasVectorStore');
      
      final chunks = await DocumentService.retrieveRelevantChunks(widget.topic, topK: 5);
      setState(() {
        _documentChunks = chunks;
      });
      
      debugPrint('Retrieved ${chunks.length} relevant chunks for topic: ${widget.topic}');
    } catch (e) {
      setState(() {
        _documentChunks = [];
      });
      debugPrint('Error loading document content: $e');
    }
  }

  // void _loadDocumentContent() {
  //   _documentChunks = DocumentService.findRelevantChunks(widget.topic);
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.05),
              Theme.of(context).colorScheme.secondary.withOpacity(0.05),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildTabBar(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: _buildLLMContent(),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: _buildDocumentContent(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return GlassContainer(
      margin: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.topic,
              color: Theme.of(context).colorScheme.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.topic,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
              ),
            ),
            child: Text(
              widget.educationLevel,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (widget.onAddToNotes != null)
            IconButton(
              onPressed: () {
                final content = _topicDetails ?? '';
                final documentContent = _documentChunks.map((chunk) => 
                  'Page ${chunk.pageNumber}: ${chunk.content}').join('\n\n');
                final fullContent = '## ${widget.topic}\n\n$content${documentContent.isNotEmpty ? '\n\n### From Document\n$documentContent' : ''}';
                widget.onAddToNotes!(fullContent);
                Navigator.pop(context);
              },
              icon: const Icon(Icons.note_add),
              tooltip: 'Add to Notes',
            ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return GlassContainer(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
          ),
        ),
        child: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary.withOpacity(0.3),
                Theme.of(context).colorScheme.secondary.withOpacity(0.3),
              ],
            ),
          ),
          tabs: [
            const Tab(
              icon: Icon(Icons.psychology),
              text: 'AI Knowledge',
            ),
            Tab(
              icon: const Icon(Icons.description),
              text: DocumentService.hasDocument 
                ? (DocumentService.embeddingsProvider != null ? 'Document (RAG)' : 'Document (Basic)')
                : 'No Document',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLLMContent() {
    if (_isLoading) {
      return const GlassContainer(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading topic details...'),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return GlassContainer(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Failed to load topic details',
                style: TextStyle(
                  fontSize: 18,
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _error = null;
                  });
                  _loadTopicDetails();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final content = _topicDetails ?? '';
    return GlassContainer(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Key Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                ),
              ),
              child: _renderRobustContent(context, content),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.2, end: 0);
  }

  Widget _buildDocumentContent() {
    if (!DocumentService.hasDocument) {
      return GlassContainer(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.description_outlined,
                size: 64,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'No Document Uploaded',
                style: TextStyle(
                  fontSize: 18,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Upload a document to see relevant content for this topic',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    if (_documentChunks.isEmpty) {
      return GlassContainer(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search_off,
                size: 64,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'No Relevant Content Found',
                style: TextStyle(
                  fontSize: 18,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'The uploaded document "${DocumentService.currentDocumentName}" doesn\'t contain relevant information about "${widget.topic}"',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return GlassContainer(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.description,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'From Document: ${DocumentService.currentDocumentName}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: DocumentService.embeddingsProvider != null 
                      ? Colors.green.withOpacity(0.2)
                      : Colors.orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    DocumentService.embeddingsProvider != null ? 'RAG' : 'Basic',
                    style: TextStyle(
                      fontSize: 10,
                      color: DocumentService.embeddingsProvider != null 
                        ? Colors.green.shade700
                        : Colors.orange.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ..._documentChunks.map((chunk) => Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.bookmark_outline,
                        size: 16,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Page ${chunk.pageNumber}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SelectableText(
                    chunk.content,
                    style: const TextStyle(fontSize: 16, height: 1.5),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.2, end: 0);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// ---------- Robust renderer ----------
  Widget _renderRobustContent(BuildContext ctx, String content) {
    // Step A: Find fenced code blocks and split around them.
    final fencedRegex = RegExp(r'```.*?```', dotAll: true);
    final parts = <_Segment>[];
    int last = 0;

    for (final m in fencedRegex.allMatches(content)) {
      if (m.start > last) {
        parts.add(_Segment(content.substring(last, m.start), isCode: false));
      }
      parts.add(_Segment(content.substring(m.start, m.end), isCode: true));
      last = m.end;
    }
    if (last < content.length) {
      parts.add(_Segment(content.substring(last), isCode: false));
    }

    // For each part, further split and produce widgets
    final widgets = <Widget>[];
    for (final part in parts) {
      if (part.isCode) {
        // Render fenced code blocks using Markdown so code blocks render nicely
        widgets.add(
          MarkdownBody(
            data: part.text,
            selectable: true,
            styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(ctx)).copyWith(
              p: const TextStyle(fontSize: 14),
            ),
          ),
        );
        continue;
      }

      // Step B: Split by block math $$...$$
      final blockMathRegex = RegExp(r'\$\$(.+?)\$\$', dotAll: true);
      int lastB = 0;
      for (final bm in blockMathRegex.allMatches(part.text)) {
        if (bm.start > lastB) {
          final before = part.text.substring(lastB, bm.start);
          widgets.addAll(_renderNonCodeChunk(ctx, before));
        }
        final formula = bm.group(1) ?? '';
        widgets.add(_buildDisplayMath(ctx, formula));
        lastB = bm.end;
      }
      if (lastB < part.text.length) {
        final tail = part.text.substring(lastB);
        widgets.addAll(_renderNonCodeChunk(ctx, tail));
      }
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: widgets);
  }

  List<Widget> _renderNonCodeChunk(BuildContext ctx, String chunk) {
    final widgets = <Widget>[];
    if (chunk.trim().isEmpty) return widgets;

    final lines = chunk.split('\n');
    final buffer = <String>[];

    void flushBufferAsParagraph() {
      if (buffer.isEmpty) return;
      final paragraph = buffer.join('\n').trim();
      if (paragraph.isNotEmpty) {
        widgets.addAll(_renderParagraphOrBlock(ctx, paragraph));
      }
      buffer.clear();
    }

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final trimmed = line.trimLeft();

      if (trimmed.startsWith('#') ||
          trimmed.startsWith('- ') ||
          trimmed.startsWith('* ') ||
          RegExp(r'^\d+\.\s').hasMatch(trimmed) ||
          trimmed.startsWith('> ')) {
        flushBufferAsParagraph();
        widgets.addAll(_renderParagraphOrBlock(ctx, trimmed));
      } else if (trimmed.isEmpty) {
        flushBufferAsParagraph();
      } else {
        buffer.add(line);
      }
    }
    flushBufferAsParagraph();
    return widgets;
  }

  List<Widget> _renderParagraphOrBlock(BuildContext ctx, String text) {
    final widgets = <Widget>[];
    final t = text.trim();

    // HEADINGS (#, ##, ###)
    final headingMatch = RegExp(r'^(#{1,6})\s+(.*)$').firstMatch(t);
    if (headingMatch != null) {
      final level = headingMatch.group(1)!.length;
      final content = headingMatch.group(2)!;
      widgets.add(Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 6),
        child: Text(
          content,
          style: TextStyle(
            fontSize: 22 - (level * 2).clamp(0, 10).toDouble(),
            fontWeight: FontWeight.bold,
            color: Theme.of(ctx).colorScheme.primary,
          ),
        ),
      ));
      return widgets;
    }

    // LIST ITEMS (-, * or numbered)
    final bulletMatch = RegExp(r'^(-|\*|\u2022|\d+\.)\s+(.*)$').firstMatch(t);
    if (bulletMatch != null) {
      final bullet = bulletMatch.group(1)!;
      final rest = bulletMatch.group(2)!;
      widgets.add(Container(
        margin: const EdgeInsets.only(bottom: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 24,
              child: Text(
                bullet.endsWith('.') ? bullet : '•',
                style: const TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(child: _buildInlineRich(ctx, rest)),
          ],
        ),
      ));
      return widgets;
    }

    // Blockquote
    if (t.startsWith('> ')) {
      final inner = t.substring(2).trim();
      widgets.add(Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(ctx).colorScheme.surface.withOpacity(0.06),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withOpacity(0.04)),
        ),
        child: _buildInlineRich(ctx, inner),
      ));
      return widgets;
    }

    // Plain paragraph - if it contains no inline math, prefer MarkdownBody so many inline markdown features work.
    if (!_containsInlineMath(t)) {
      widgets.add(MarkdownBody(
        data: t,
        selectable: true,
        styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(ctx)).copyWith(
          p: const TextStyle(fontSize: 16, height: 1.5),
        ),
      ));
      return widgets;
    }

    widgets.add(Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: _buildInlineRich(ctx, t),
    ));
    return widgets;
  }

  bool _containsInlineMath(String s) {
    final placeholder = '\uE000';
    final temp = s.replaceAll(r'\$', placeholder);
    final match = RegExp(r'(?<!\$)\$(?!\$)(.+?)(?<!\$)\$(?!\$)', dotAll: true).hasMatch(temp);
    return match;
  }

  Widget _buildDisplayMath(BuildContext ctx, String formula) {
    final trimmed = formula.trim();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(ctx).colorScheme.primaryContainer.withOpacity(0.12),
              Theme.of(ctx).colorScheme.secondaryContainer.withOpacity(0.08),
            ],
          ),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: Theme.of(ctx).colorScheme.primary.withOpacity(0.18),
            width: 1.2,
          ),
        ),
        child: Center(
          child: Math.tex(
            trimmed,
            mathStyle: MathStyle.display,
            textStyle: const TextStyle(fontSize: 18),
          ),
        ),
      ),
    );
  }

  Widget _buildInlineRich(BuildContext ctx, String source) {
    final escapedDollarPlaceholder = '\uE001';
    source = source.replaceAll(r'\$', escapedDollarPlaceholder);

    final spans = <InlineSpan>[];
    int index = 0;
    final length = source.length;

    while (index < length) {
      final nextPositions = <_TokenMatch>[];

      final findMath = RegExp(r'(?<!\$)\$(?!\$)(.+?)(?<!\$)\$(?!\$)', dotAll: true).firstMatch(source.substring(index));
      if (findMath != null) {
        nextPositions.add(_TokenMatch('math', index + findMath.start, index + findMath.end, findMath.group(1)!));
      }
      final findBold = RegExp(r'\*\*(.+?)\*\*', dotAll: true).firstMatch(source.substring(index));
      if (findBold != null) {
        nextPositions.add(_TokenMatch('bold', index + findBold.start, index + findBold.end, findBold.group(1)!));
      }
      final findItalic = RegExp(r'_(.+?)_', dotAll: true).firstMatch(source.substring(index));
      if (findItalic != null) {
        nextPositions.add(_TokenMatch('italic', index + findItalic.start, index + findItalic.end, findItalic.group(1)!));
      }
      final findCode = RegExp(r'`([^`]+?)`', dotAll: true).firstMatch(source.substring(index));
      if (findCode != null) {
        nextPositions.add(_TokenMatch('code', index + findCode.start, index + findCode.end, findCode.group(1)!));
      }

      if (nextPositions.isEmpty) {
        final remaining = source.substring(index).replaceAll(escapedDollarPlaceholder, r'$');
        spans.add(TextSpan(text: remaining));
        break;
      }

      nextPositions.sort((a, b) => a.start.compareTo(b.start));
      final token = nextPositions.first;

      if (token.start > index) {
        final plain = source.substring(index, token.start).replaceAll(escapedDollarPlaceholder, r'$');
        spans.add(TextSpan(text: plain));
      }

      if (token.type == 'math') {
        final mathTex = token.content;
        spans.add(WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Math.tex(
              mathTex,
              mathStyle: MathStyle.text,
              textStyle: const TextStyle(fontSize: 16),
            ),
          ),
        ));
      } else if (token.type == 'bold') {
        spans.add(TextSpan(text: token.content, style: const TextStyle(fontWeight: FontWeight.bold)));
      } else if (token.type == 'italic') {
        spans.add(TextSpan(text: token.content, style: const TextStyle(fontStyle: FontStyle.italic)));
      } else if (token.type == 'code') {
        spans.add(WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Theme.of(ctx).colorScheme.surface.withOpacity(0.06),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              token.content,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 14),
            ),
          ),
        ));
      }

      index = token.end;
    }

    if (spans.isEmpty) {
      return Text(source.replaceAll(escapedDollarPlaceholder, r'$'), style: const TextStyle(fontSize: 16, height: 1.5));
    }

    return RichText(
      text: TextSpan(
        style: TextStyle(color: Theme.of(ctx).textTheme.bodyLarge?.color ?? Colors.black87, fontSize: 16, height: 1.5),
        children: spans,
      ),
    );
  }
}

class _Segment {
  final String text;
  final bool isCode;
  _Segment(this.text, {this.isCode = false});
}

class _TokenMatch {
  final String type;
  final int start;
  final int end;
  final String content;
  _TokenMatch(this.type, this.start, this.end, this.content);
}