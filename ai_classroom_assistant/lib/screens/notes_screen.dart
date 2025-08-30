// lib/screens/notes_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:share_plus/share_plus.dart';
import 'package:markdown/markdown.dart' as md;

import '../models/transcription_session.dart';
import '../services/ai_service.dart';
import '../services/export_service.dart';
import '../services/error_handler_service.dart';
import '../widgets/glass_container.dart';
import '../widgets/glass_snackbar.dart';

class NotesScreen extends StatefulWidget {
  final TranscriptionSession session;
  final AIService? aiService;
  final String educationLevel;

  const NotesScreen({
    super.key,
    required this.session,
    this.aiService,
    required this.educationLevel,
  });

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  late TextEditingController _basicNotesController;
  late TextEditingController _aiNotesController;
  String? _aiNotes;
  bool _isGeneratingAI = false;
  bool _isEditingBasic = false;
  bool _isEditingAI = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _basicNotesController = TextEditingController(
      text: widget.session.basicNotes.isEmpty ? widget.session.fullTranscription : widget.session.basicNotes,
    );
    _aiNotesController = TextEditingController();
  }

  Future<void> _generateAINotes() async {
    if (widget.aiService == null) return;

    setState(() {
      _isGeneratingAI = true;
      _error = null;
    });

    try {
      final notes = await ErrorHandlerService.withRetry(
        () => widget.aiService!.generateEnhancedNotes(
          widget.session.fullTranscription,
          widget.educationLevel,
        ),
        shouldRetry: ErrorHandlerService.shouldRetryNetworkError,
      );
      setState(() {
        _aiNotes = notes;
        _aiNotesController.text = notes;
        _isGeneratingAI = false;
      });
    } catch (e) {
      setState(() {
        _error = ErrorHandlerService.getErrorMessage(e);
        _isGeneratingAI = false;
      });
    }
  }

  void _saveBasicNotes() {
    widget.session.updateBasicNotes(_basicNotesController.text);
    setState(() {
      _isEditingBasic = false;
    });
    if (mounted) {
      GlassSnackBar.showSuccess(
        context,
        message: 'Basic notes saved',
      );
    }
  }

  void _saveAINotes() {
    _aiNotes = _aiNotesController.text;
    setState(() {
      _isEditingAI = false;
    });
    if (mounted) {
      GlassSnackBar.showSuccess(
        context,
        message: 'AI notes saved',
      );
    }
  }

  void _shareNotes(String content, String type) {
    final sessionDate = widget.session.startTime.toString().split(' ')[0];
    Share.share(
      content,
      subject: 'Class Notes - $type - $sessionDate',
    );
  }

  void _exportNotes(String content, String type) async {
    final sessionDate = widget.session.startTime.toString().split(' ')[0];
    final filename = 'Class_Notes_${type}_$sessionDate';

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: GlassContainer(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Export Format',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text('Choose export format:'),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      try {
                        await ExportService.exportAsText(content, filename);
                        if (mounted) {
                          GlassSnackBar.showSuccess(
                            context,
                            message: 'Exported as text file',
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          GlassSnackBar.showError(
                            context,
                            message: 'Export failed: $e',
                          );
                        }
                      }
                    },
                    child: const Text('Text (.txt)'),
                  ),
                  TextButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      try {
                        await ExportService.exportAsPDF(content, filename);
                        if (mounted) {
                          GlassSnackBar.showSuccess(
                            context,
                            message: 'Exported as PDF',
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          GlassSnackBar.showError(
                            context,
                            message: 'Export failed: $e',
                          );
                        }
                      }
                    },
                    child: const Text('PDF (.pdf)'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

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
                    _buildBasicNotes(),
                    _buildAINotes(),
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
              Icons.note_add,
              color: Theme.of(context).colorScheme.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Learning Notes',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
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
              widget.session.startTime.toString().split(' ')[0],
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
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
          tabs: const [
            Tab(
              icon: Icon(Icons.text_snippet),
              text: 'Basic Notes',
            ),
            Tab(
              icon: Icon(Icons.auto_awesome),
              text: 'AI Enhanced',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicNotes() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: GlassContainer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Basic Notes',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: () => setState(() {
                        _isEditingBasic = !_isEditingBasic;
                        if (!_isEditingBasic) _saveBasicNotes();
                      }),
                      icon: Icon(_isEditingBasic ? Icons.save : Icons.edit),
                      tooltip: _isEditingBasic ? 'Save' : 'Edit',
                    ),
                    IconButton(
                      onPressed: () => _exportNotes(
                        _basicNotesController.text,
                        'Basic',
                      ),
                      icon: const Icon(Icons.download),
                      tooltip: 'Export Notes',
                    ),
                    IconButton(
                      onPressed: () => _shareNotes(
                        _basicNotesController.text,
                        'Basic',
                      ),
                      icon: const Icon(Icons.share),
                      tooltip: 'Share Notes',
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Words: ${widget.session.wordCount} • Duration: ${_formatDuration()}',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                  ),
                ),
                child: _isEditingBasic
                    ? TextField(
                        controller: _basicNotesController,
                        maxLines: null,
                        expands: true,
                        textAlignVertical: TextAlignVertical.top,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Add your notes here...',
                        ),
                        style: const TextStyle(fontSize: 16, height: 1.5),
                      )
                    : SingleChildScrollView(
                        child: _renderRobustContent(context, _basicNotesController.text.isEmpty ? 'No notes available' : _basicNotesController.text),
                      ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildAINotes() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: GlassContainer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'AI Enhanced Notes',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (_aiNotes != null)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: () => setState(() {
                          _isEditingAI = !_isEditingAI;
                          if (!_isEditingAI) _saveAINotes();
                        }),
                        icon: Icon(_isEditingAI ? Icons.save : Icons.edit),
                        tooltip: _isEditingAI ? 'Save' : 'Edit',
                      ),
                      IconButton(
                        onPressed: () => _exportNotes(_aiNotesController.text.isNotEmpty ? _aiNotesController.text : _aiNotes!, 'AI Enhanced'),
                        icon: const Icon(Icons.download),
                        tooltip: 'Export Notes',
                      ),
                      IconButton(
                        onPressed: () => _shareNotes(_aiNotesController.text.isNotEmpty ? _aiNotesController.text : _aiNotes!, 'AI Enhanced'),
                        icon: const Icon(Icons.share),
                        tooltip: 'Share Notes',
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (_aiNotes == null && !_isGeneratingAI && widget.aiService != null)
              Center(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.primary.withOpacity(0.8),
                        Theme.of(context).colorScheme.secondary.withOpacity(0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    onPressed: _generateAINotes,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.all(16),
                    ),
                    icon: const Icon(Icons.auto_awesome, color: Colors.white),
                    label: const Text(
                      'Generate AI Notes',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              )
            else if (_isGeneratingAI)
              const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Generating enhanced notes...'),
                  ],
                ),
              )
            else if (_error != null)
              Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Failed to generate notes',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: _generateAINotes,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              )
            else if (_aiNotes != null)
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                    ),
                  ),
                  child: _isEditingAI
                      ? TextField(
                          controller: _aiNotesController,
                          maxLines: null,
                          expands: true,
                          textAlignVertical: TextAlignVertical.top,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Edit AI notes...',
                          ),
                          style: const TextStyle(fontSize: 16, height: 1.5),
                        )
                      : SingleChildScrollView(
                          child: _renderRobustContent(context, _aiNotes!),
                        ),
                ),
              )
            else
              const Center(
                child: Text('AI service not available'),
              ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  String _formatDuration() {
    if (widget.session.endTime == null) return 'Ongoing';

    final duration = widget.session.endTime!.difference(widget.session.startTime);
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;

    return '${minutes}m ${seconds}s';
  }

  @override
  void dispose() {
    _tabController.dispose();
    _basicNotesController.dispose();
    _aiNotesController.dispose();
    super.dispose();
  }

  // ---------------- Robust renderer helpers ----------------

  /// Top-level renderer: splits by fenced code blocks to protect them,
  /// then handles block-math ($$..$$) and inline math ($..$).
  Widget _renderRobustContent(BuildContext ctx, String content) {
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

    final widgets = <Widget>[];
    for (final part in parts) {
      if (part.isCode) {
        // Render code blocks with MarkdownBody so triple-backtick blocks show nicely
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

      // Split by block math
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

  /// Splits a non-code chunk into paragraph-like blocks and returns widgets.
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

    // Headings
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

    // List item
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

    // Plain paragraph: if there is no inline math, render with MarkdownBody so links and inline styling work.
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

    // Otherwise build inline rich text (handles inline math)
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
    // Try/catch for malformed LaTeX; fallback to monospace raw text
    try {
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
    } catch (e) {
      // Fallback display if Math.tex fails
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(ctx).colorScheme.surface.withOpacity(0.04),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white.withOpacity(0.04)),
          ),
          child: SelectableText(
            trimmed,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 14),
          ),
        ),
      );
    }
  }

  /// Build RichText supporting inline math ($...$), bold (**...**), italic (_..._), and inline `code`.
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
        // inline math with fallback
        try {
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
        } catch (e) {
          spans.add(WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: Theme.of(ctx).colorScheme.surface.withOpacity(0.06),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                mathTex,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 14),
              ),
            ),
          ));
        }
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












// import 'package:flutter/material.dart';
// import 'package:flutter_animate/flutter_animate.dart';
// import 'package:share_plus/share_plus.dart';
// import '../models/transcription_session.dart';
// import '../services/ai_service.dart';
// import '../services/export_service.dart';
// import '../services/error_handler_service.dart';
// import '../widgets/glass_container.dart';

// class NotesScreen extends StatefulWidget {
//   final TranscriptionSession session;
//   final AIService? aiService;
//   final String educationLevel;

//   const NotesScreen({
//     super.key,
//     required this.session,
//     this.aiService,
//     required this.educationLevel,
//   });

//   @override
//   State<NotesScreen> createState() => _NotesScreenState();
// }

// class _NotesScreenState extends State<NotesScreen> with TickerProviderStateMixin {
//   late TabController _tabController;
//   late TextEditingController _basicNotesController;
//   late TextEditingController _aiNotesController;
//   String? _aiNotes;
//   bool _isGeneratingAI = false;
//   bool _isEditingBasic = false;
//   bool _isEditingAI = false;
//   String? _error;

//   @override
//   void initState() {
//     super.initState();
//     _tabController = TabController(length: 2, vsync: this);
//     _basicNotesController = TextEditingController(text: widget.session.basicNotes.isEmpty ? widget.session.fullTranscription : widget.session.basicNotes);
//     _aiNotesController = TextEditingController();
//   }

//   Future<void> _generateAINotes() async {
//     if (widget.aiService == null) return;

//     setState(() {
//       _isGeneratingAI = true;
//       _error = null;
//     });

//     try {
//       final notes = await ErrorHandlerService.withRetry(
//         () => widget.aiService!.generateEnhancedNotes(
//           widget.session.fullTranscription,
//           widget.educationLevel,
//         ),
//         shouldRetry: ErrorHandlerService.shouldRetryNetworkError,
//       );
//       setState(() {
//         _aiNotes = notes;
//         _aiNotesController.text = notes;
//         _isGeneratingAI = false;
//       });
//     } catch (e) {
//       setState(() {
//         _error = ErrorHandlerService.getErrorMessage(e);
//         _isGeneratingAI = false;
//       });
//     }
//   }

//   void _saveBasicNotes() {
//     widget.session.updateBasicNotes(_basicNotesController.text);
//     setState(() {
//       _isEditingBasic = false;
//     });
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(content: Text('Basic notes saved')),
//     );
//   }

//   void _saveAINotes() {
//     _aiNotes = _aiNotesController.text;
//     setState(() {
//       _isEditingAI = false;
//     });
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(content: Text('AI notes saved')),
//     );
//   }

//   void _shareNotes(String content, String type) {
//     final sessionDate = widget.session.startTime.toString().split(' ')[0];
//     Share.share(
//       content,
//       subject: 'Class Notes - $type - $sessionDate',
//     );
//   }

//   void _exportNotes(String content, String type) async {
//     final sessionDate = widget.session.startTime.toString().split(' ')[0];
//     final filename = 'Class_Notes_${type}_$sessionDate';
    
//     showDialog(
//       context: context,
//       builder: (context) => Dialog(
//         backgroundColor: Colors.transparent,
//         child: GlassContainer(
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               const Text(
//                 'Export Format',
//                 style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//               ),
//               const SizedBox(height: 12),
//               const Text('Choose export format:'),
//               const SizedBox(height: 20),
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.end,
//                 children: [
//           TextButton(
//             onPressed: () async {
//               Navigator.pop(context);
//               try {
//                 await ExportService.exportAsText(content, filename);
//                 if (mounted) {
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     const SnackBar(content: Text('Exported as text file')),
//                   );
//                 }
//               } catch (e) {
//                 if (mounted) {
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     SnackBar(content: Text('Export failed: $e')),
//                   );
//                 }
//               }
//             },
//             child: const Text('Text (.txt)'),
//           ),
//           TextButton(
//             onPressed: () async {
//               Navigator.pop(context);
//               try {
//                 await ExportService.exportAsPDF(content, filename);
//                 if (mounted) {
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     const SnackBar(content: Text('Exported as PDF')),
//                   );
//                 }
//               } catch (e) {
//                 if (mounted) {
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     SnackBar(content: Text('Export failed: $e')),
//                   );
//                 }
//               }
//             },
//             child: const Text('PDF (.pdf)'),
//           ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Container(
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topLeft,
//             end: Alignment.bottomRight,
//             colors: [
//               Theme.of(context).colorScheme.primary.withOpacity(0.1),
//               Theme.of(context).colorScheme.secondary.withOpacity(0.1),
//             ],
//           ),
//         ),
//         child: SafeArea(
//           child: Column(
//             children: [
//               _buildHeader(),
//               _buildTabBar(),
//               Expanded(
//                 child: TabBarView(
//                   controller: _tabController,
//                   children: [
//                     _buildBasicNotes(),
//                     _buildAINotes(),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildHeader() {
//     return GlassContainer(
//       margin: const EdgeInsets.all(16),
//       child: Row(
//         children: [
//           IconButton(
//             onPressed: () => Navigator.pop(context),
//             icon: const Icon(Icons.arrow_back),
//           ),
//           const SizedBox(width: 8),
//           const Expanded(
//             child: Text(
//               'Class Notes',
//               style: TextStyle(
//                 fontSize: 20,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//           ),
//           Text(
//             widget.session.startTime.toString().split(' ')[0],
//             style: TextStyle(
//               fontSize: 12,
//               color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildTabBar() {
//     return GlassContainer(
//       margin: const EdgeInsets.symmetric(horizontal: 16),
//       child: Container(
//         decoration: BoxDecoration(
//           borderRadius: BorderRadius.circular(16),
//           border: Border.all(
//             color: Colors.white.withOpacity(0.2),
//           ),
//         ),
//         child: TabBar(
//           controller: _tabController,
//           indicator: BoxDecoration(
//             borderRadius: BorderRadius.circular(12),
//             gradient: LinearGradient(
//               colors: [
//                 Theme.of(context).colorScheme.primary.withOpacity(0.3),
//                 Theme.of(context).colorScheme.secondary.withOpacity(0.3),
//               ],
//             ),
//           ),
//           tabs: const [
//             Tab(
//               icon: Icon(Icons.text_snippet),
//               text: 'Basic Notes',
//             ),
//             Tab(
//               icon: Icon(Icons.auto_awesome),
//               text: 'AI Enhanced',
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildBasicNotes() {
//     return Padding(
//       padding: const EdgeInsets.all(16.0),
//       child: GlassContainer(
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 const Text(
//                   'Basic Notes',
//                   style: TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 const Spacer(),
//                 Row(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     IconButton(
//                       onPressed: () => setState(() {
//                         _isEditingBasic = !_isEditingBasic;
//                         if (!_isEditingBasic) _saveBasicNotes();
//                       }),
//                       icon: Icon(_isEditingBasic ? Icons.save : Icons.edit),
//                       tooltip: _isEditingBasic ? 'Save' : 'Edit',
//                     ),
//                     IconButton(
//                       onPressed: () => _exportNotes(
//                         _basicNotesController.text,
//                         'Basic',
//                       ),
//                       icon: const Icon(Icons.download),
//                       tooltip: 'Export Notes',
//                     ),
//                     IconButton(
//                       onPressed: () => _shareNotes(
//                         _basicNotesController.text,
//                         'Basic',
//                       ),
//                       icon: const Icon(Icons.share),
//                       tooltip: 'Share Notes',
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//             const SizedBox(height: 8),
//             Text(
//               'Words: ${widget.session.wordCount} • Duration: ${_formatDuration()}',
//               style: TextStyle(
//                 color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
//                 fontSize: 12,
//               ),
//             ),
//             const SizedBox(height: 16),
//             Expanded(
//               child: Container(
//                 width: double.infinity,
//                 padding: const EdgeInsets.all(16),
//                 decoration: BoxDecoration(
//                   color: Theme.of(context).colorScheme.surface.withOpacity(0.5),
//                   borderRadius: BorderRadius.circular(8),
//                   border: Border.all(
//                     color: Colors.white.withOpacity(0.2),
//                   ),
//                 ),
//                 child: _isEditingBasic
//                     ? TextField(
//                         controller: _basicNotesController,
//                         maxLines: null,
//                         expands: true,
//                         textAlignVertical: TextAlignVertical.top,
//                         decoration: const InputDecoration(
//                           border: InputBorder.none,
//                           hintText: 'Add your notes here...',
//                         ),
//                         style: const TextStyle(fontSize: 16, height: 1.5),
//                       )
//                     : SingleChildScrollView(
//                         child: SelectableText(
//                           _basicNotesController.text.isEmpty
//                               ? 'No notes available'
//                               : _basicNotesController.text,
//                           style: const TextStyle(fontSize: 16, height: 1.5),
//                         ),
//                       ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     ).animate().fadeIn(duration: 300.ms);
//   }

//   Widget _buildAINotes() {
//     return Padding(
//       padding: const EdgeInsets.all(16.0),
//       child: GlassContainer(
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 const Text(
//                   'AI Enhanced Notes',
//                   style: TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 const Spacer(),
//                 if (_aiNotes != null)
//                   Row(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       IconButton(
//                         onPressed: () => setState(() {
//                           _isEditingAI = !_isEditingAI;
//                           if (!_isEditingAI) _saveAINotes();
//                         }),
//                         icon: Icon(_isEditingAI ? Icons.save : Icons.edit),
//                         tooltip: _isEditingAI ? 'Save' : 'Edit',
//                       ),
//                       IconButton(
//                         onPressed: () => _exportNotes(_aiNotesController.text.isNotEmpty ? _aiNotesController.text : _aiNotes!, 'AI Enhanced'),
//                         icon: const Icon(Icons.download),
//                         tooltip: 'Export Notes',
//                       ),
//                       IconButton(
//                         onPressed: () => _shareNotes(_aiNotesController.text.isNotEmpty ? _aiNotesController.text : _aiNotes!, 'AI Enhanced'),
//                         icon: const Icon(Icons.share),
//                         tooltip: 'Share Notes',
//                       ),
//                     ],
//                   ),
//               ],
//             ),
//             const SizedBox(height: 16),
//             if (_aiNotes == null && !_isGeneratingAI && widget.aiService != null)
//               Center(
//                 child: Container(
//                   decoration: BoxDecoration(
//                     gradient: LinearGradient(
//                       colors: [
//                         Theme.of(context).colorScheme.primary.withOpacity(0.8),
//                         Theme.of(context).colorScheme.secondary.withOpacity(0.8),
//                       ],
//                     ),
//                     borderRadius: BorderRadius.circular(12),
//                     boxShadow: [
//                       BoxShadow(
//                         color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
//                         blurRadius: 6,
//                         offset: const Offset(0, 2),
//                       ),
//                     ],
//                   ),
//                   child: ElevatedButton.icon(
//                     onPressed: _generateAINotes,
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Colors.transparent,
//                       shadowColor: Colors.transparent,
//                       padding: const EdgeInsets.all(16),
//                     ),
//                     icon: const Icon(Icons.auto_awesome, color: Colors.white),
//                     label: const Text(
//                       'Generate AI Notes',
//                       style: TextStyle(
//                         color: Colors.white,
//                         fontWeight: FontWeight.w600,
//                       ),
//                     ),
//                   ),
//                 ),
//               )
//             else if (_isGeneratingAI)
//               const Center(
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     CircularProgressIndicator(),
//                     SizedBox(height: 16),
//                     Text('Generating enhanced notes...'),
//                   ],
//                 ),
//               )
//             else if (_error != null)
//               Center(
//                 child: Column(
//                   children: [
//                     Icon(
//                       Icons.error_outline,
//                       size: 48,
//                       color: Theme.of(context).colorScheme.error,
//                     ),
//                     const SizedBox(height: 16),
//                     Text(
//                       'Failed to generate notes',
//                       style: TextStyle(
//                         color: Theme.of(context).colorScheme.error,
//                       ),
//                     ),
//                     const SizedBox(height: 8),
//                     ElevatedButton.icon(
//                       onPressed: _generateAINotes,
//                       icon: const Icon(Icons.refresh),
//                       label: const Text('Retry'),
//                     ),
//                   ],
//                 ),
//               )
//             else if (_aiNotes != null)
//               Expanded(
//                 child: Container(
//                   width: double.infinity,
//                   padding: const EdgeInsets.all(16),
//                   decoration: BoxDecoration(
//                     color: Theme.of(context).colorScheme.surface.withOpacity(0.5),
//                     borderRadius: BorderRadius.circular(8),
//                     border: Border.all(
//                       color: Colors.white.withOpacity(0.2),
//                     ),
//                   ),
//                   child: _isEditingAI
//                       ? TextField(
//                           controller: _aiNotesController,
//                           maxLines: null,
//                           expands: true,
//                           textAlignVertical: TextAlignVertical.top,
//                           decoration: const InputDecoration(
//                             border: InputBorder.none,
//                             hintText: 'Edit AI notes...',
//                           ),
//                           style: const TextStyle(fontSize: 16, height: 1.5),
//                         )
//                       : SingleChildScrollView(
//                           child: SelectableText(
//                             _aiNotes!,
//                             style: const TextStyle(fontSize: 16, height: 1.5),
//                           ),
//                         ),
//                 ),
//               )
//             else
//               const Center(
//                 child: Text('AI service not available'),
//               ),
//           ],
//         ),
//       ),
//     ).animate().fadeIn(duration: 300.ms);
//   }

//   String _formatDuration() {
//     if (widget.session.endTime == null) return 'Ongoing';
    
//     final duration = widget.session.endTime!.difference(widget.session.startTime);
//     final minutes = duration.inMinutes;
//     final seconds = duration.inSeconds % 60;
    
//     return '${minutes}m ${seconds}s';
//   }

//   @override
//   void dispose() {
//     _tabController.dispose();
//     _basicNotesController.dispose();
//     _aiNotesController.dispose();
//     super.dispose();
//   }
// }