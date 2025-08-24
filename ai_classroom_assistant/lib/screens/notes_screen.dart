import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:share_plus/share_plus.dart';
import '../models/transcription_session.dart';
import '../services/ai_service.dart';
import '../services/export_service.dart';
import '../services/error_handler_service.dart';
import '../widgets/glass_container.dart';

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
  String? _aiNotes;
  bool _isGeneratingAI = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
        _isGeneratingAI = false;
      });
    } catch (e) {
      setState(() {
        _error = ErrorHandlerService.getErrorMessage(e);
        _isGeneratingAI = false;
      });
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
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Exported as text file')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Export failed: $e')),
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
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Exported as PDF')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Export failed: $e')),
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
              Theme.of(context).colorScheme.primary.withOpacity(0.1),
              Theme.of(context).colorScheme.secondary.withOpacity(0.1),
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
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Class Notes',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Text(
            widget.session.startTime.toString().split(' ')[0],
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
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
                  'Raw Transcription',
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
                      onPressed: () => _exportNotes(
                        widget.session.fullTranscription,
                        'Basic',
                      ),
                      icon: const Icon(Icons.download),
                      tooltip: 'Export Notes',
                    ),
                    IconButton(
                      onPressed: () => _shareNotes(
                        widget.session.fullTranscription,
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
                child: SingleChildScrollView(
                  child: SelectableText(
                    widget.session.fullTranscription.isEmpty
                        ? 'No transcription available'
                        : widget.session.fullTranscription,
                    style: const TextStyle(fontSize: 16, height: 1.5),
                  ),
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
                        onPressed: () => _exportNotes(_aiNotes!, 'AI Enhanced'),
                        icon: const Icon(Icons.download),
                        tooltip: 'Export Notes',
                      ),
                      IconButton(
                        onPressed: () => _shareNotes(_aiNotes!, 'AI Enhanced'),
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
                  child: SingleChildScrollView(
                    child: SelectableText(
                      _aiNotes!,
                      style: const TextStyle(fontSize: 16, height: 1.5),
                    ),
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
    super.dispose();
  }
}