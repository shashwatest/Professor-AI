import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/transcription_session.dart';
import '../models/extracted_content_item.dart';
import '../services/speech_service.dart';
import '../services/ai_service.dart';
import '../services/transcription_trigger.dart';
import '../widgets/glass_container.dart';
import '../widgets/noise_cancellation_warning_dialog.dart';
import 'topic_detail_screen.dart';
import 'notes_screen.dart';
import '../services/session_storage_service.dart';
import '../services/error_handler_service.dart';
import '../services/settings_service.dart';
import '../services/document_service.dart';
import '../services/embeddings/embeddings_service.dart';
import 'document_upload_screen.dart';

class CurrentSessionScreen extends StatefulWidget {
  final VoidCallback? onNavigateToSettings;
  
  const CurrentSessionScreen({
    super.key,
    this.onNavigateToSettings,
  });

  @override
  State<CurrentSessionScreen> createState() => _CurrentSessionScreenState();
}

class _CurrentSessionScreenState extends State<CurrentSessionScreen> {
  final SpeechService _speechService = SpeechService();
  final TranscriptionTrigger _transcriptionTrigger = TranscriptionTrigger();
  TranscriptionSession? _currentSession;
  AIService? _aiService;

  bool _isListening = false;
  String _educationLevel = 'Undergraduate';
  String _apiKey = '';
  AIProvider _selectedProvider = AIProvider.gemini;
  List<ExtractedContentItem> _extractedContent = [];
  bool _isExtracting = false;

  // live transcript (combined committed + partial) emitted by SpeechService
  String _liveTranscript = '';

  @override
  void initState() {
    super.initState();
    _initializeSpeechService();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      _selectedProvider = await SettingsService.getDefaultProvider();
      _educationLevel = await SettingsService.getEducationLevel();

      final apiKey = await SettingsService.getAPIKey(_selectedProvider);
      if (apiKey != null) {
        _apiKey = apiKey;
      }

      // Refresh embeddings provider when settings change
      await EmbeddingsService.refreshDocumentServiceProvider();

      setState(() {});
    } catch (e) {
      // ignore and use defaults
    }
  }

  void _initializeSpeechService() {
    // prefer the combined transcript callback to avoid duplication issues
    _speechService.onTranscriptChanged = _onTranscriptChanged;
    _speechService.onError = _onSpeechError;
    _speechService.onListeningStateChanged = (listening) {
      if (!mounted) return;
      setState(() {
        _isListening = listening;
      });
    };
  }

  // Called with the service-managed combined transcript (committed + partial)
  void _onTranscriptChanged(String combined) {
    if (!mounted) return;
    
    setState(() {
      _liveTranscript = combined;
      if (_currentSession != null) {
        // Replace stored transcription with the latest combined text to keep
        // session.fullTranscription / wordCount accurate.
        _currentSession!.transcriptionChunks.clear();
        if (combined.trim().isNotEmpty) {
          _currentSession!.addTranscription(combined.trim());
        }
      }
    });

    // Auto-extract topics using trigger logic
    if (_currentSession != null &&
        _aiService != null &&
        !_isExtracting &&
        _transcriptionTrigger.shouldTrigger(_currentSession!.wordCount)) {
      _extractTopics();
    }
  }

  void _onSpeechError(String error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Speech error: $error')),
    );
  }

  Future<void> _startRecording() async {
    // Show noise cancellation warning if needed
    await NoiseCancellationWarningDialog.showIfNeeded(context);
    
    // Check API key for selected provider
    final apiKey = await SettingsService.getAPIKey(_selectedProvider);
    if (apiKey == null || apiKey.isEmpty) {
      _showApiKeyDialog();
      return;
    }

    _apiKey = apiKey;
    _aiService = AIServiceFactory.create(_selectedProvider, _apiKey);

    final initialized = await _speechService.initialize();
    if (!initialized) return;

    setState(() {
      _currentSession = TranscriptionSession(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        startTime: DateTime.now(),
        isRecording: true,
      );
      _extractedContent.clear();
      _liveTranscript = '';
      _transcriptionTrigger.reset(); // Reset trigger for new session
    });

    // Start listening. resetSessionText ensures internal transcript starts fresh.
    await _speechService.startListening(
      resetSessionText: true,
      pauseFor: const Duration(milliseconds: 700),
      listenFor: const Duration(hours: 2),
      onDevice: false,
    );
  }

  Future<void> _stopRecording() async {
    await _speechService.stopListening();
    if (_currentSession != null) {
      setState(() {
        _currentSession!.endSession();
      });

      // Save session to history
      try {
        await SessionStorageService.saveSession(_currentSession!);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Session saved successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Session saved locally: ${ErrorHandlerService.getErrorMessage(e)}')),
        );
      }
    }
  }

  Future<void> _extractTopics() async {
    if (_isExtracting || _aiService == null || _currentSession == null) return;

    setState(() {
      _isExtracting = true;
    });

    try {
      final topics = await ErrorHandlerService.withRetry(
        () => _aiService!.extractTopics(
          _currentSession!.fullTranscription,
          _educationLevel,
        ),
        shouldRetry: ErrorHandlerService.shouldRetryNetworkError,
      );

      setState(() {
        _extractedContent = ExtractedContentProcessor.processAIResponse(topics);
        for (final item in _extractedContent) {
          _currentSession!.addTopic(item.content);
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ErrorHandlerService.getErrorMessage(e)),
          action: SnackBarAction(
            label: 'Retry',
            onPressed: _extractTopics,
          ),
        ),
      );
    } finally {
      setState(() {
        _isExtracting = false;
      });
    }
  }

  void _showContentDetails(ExtractedContentItem item) {
    if (_aiService == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TopicDetailScreen(
          topic: item.content,
          aiService: _aiService!,
          educationLevel: _educationLevel,
          onAddToNotes: (content) {
            if (_currentSession != null) {
              _currentSession!.addToBasicNotes(content);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Added to notes')),
              );
            }
          },
        ),
      ),
    );
  }

  void _showApiKeyDialog() {
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
                'API Key Required',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text('Please set up your API keys in Settings to start recording.'),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      // Navigate to settings using the callback
                      widget.onNavigateToSettings?.call();
                    },
                    child: const Text('Open Settings'),
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildSessionInfo(),
                const SizedBox(height: 20),
                _buildDocumentSection(),
                const SizedBox(height: 20),
                _buildControls(),
                const SizedBox(height: 20),
                _buildTranscriptionView(),
                if (_extractedContent.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  _buildContentView(),
                ],
                if (_currentSession != null && _currentSession!.wordCount > 0) ...[
                  const SizedBox(height: 20),
                  _buildNotesButton(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSessionInfo() {
    return GlassContainer(
      child: Row(
        children: [
          _buildStatusIndicator(),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _currentSession != null ? 'Active Session' : 'No Active Session',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (_currentSession != null) ...[
                  Text(
                    'Started: ${_formatTime(_currentSession!.startTime)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  Text(
                    'Words: ${_currentSession!.wordCount}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
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
              _selectedProvider.name.toUpperCase(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentSection() {
    return GlassContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.description,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Context Document',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DocumentUploadScreen(),
                  ),
                ).then((_) => setState(() {})),
                icon: const Icon(Icons.upload_file, size: 18),
                label: const Text('Upload'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (DocumentService.hasDocument) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: Theme.of(context).colorScheme.primary,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      DocumentService.currentDocumentName ?? 'Document uploaded',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      DocumentService.clearDocument();
                      setState(() {});
                    },
                    child: const Text('Remove'),
                  ),
                ],
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Upload course materials to enhance AI analysis accuracy',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _isListening
              ? [Colors.green.withOpacity(0.8), Colors.green.withOpacity(0.6)]
              : [Colors.grey.withOpacity(0.8), Colors.grey.withOpacity(0.6)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (_isListening ? Colors.green : Colors.grey).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _isListening ? Icons.mic : Icons.mic_off,
            size: 16,
            color: Colors.white,
          ),
          const SizedBox(width: 8),
          Text(
            _isListening ? 'Recording' : 'Stopped',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControls() {
    return GlassContainer(
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _isListening
                      ? [Colors.red.withOpacity(0.8), Colors.red.withOpacity(0.6)]
                      : [Colors.green.withOpacity(0.8), Colors.green.withOpacity(0.6)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: (_isListening ? Colors.red : Colors.green).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: _isListening ? _stopRecording : _startRecording,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.all(18),
                ),
                icon: Icon(
                  _isListening ? Icons.stop : Icons.play_arrow,
                  color: Colors.white,
                  size: 24,
                ),
                label: Text(
                  _isListening ? 'Stop Recording' : 'Start Recording',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.secondary.withOpacity(0.8),
                  Theme.of(context).colorScheme.tertiary.withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: ElevatedButton.icon(
              onPressed: (_currentSession?.wordCount ?? 0) > 0 && !_isExtracting ? _extractTopics : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              ),
              icon: _isExtracting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
              label: const Text(
                'Extract Now',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTranscriptionView() {
    return GlassContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Live Transcription',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            height: 300,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
              ),
            ),
            child: SingleChildScrollView(
              child: Text(
                _liveTranscript.isNotEmpty 
                    ? _liveTranscript 
                    : 'Start recording to see live transcription...',
                style: TextStyle(
                  fontSize: 16,
                  height: 1.6,
                  color: _liveTranscript.isNotEmpty 
                      ? Theme.of(context).colorScheme.onSurface
                      : Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentView() {
    return GlassContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Extracted Content',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _extractedContent
                .map((item) => GestureDetector(
                      onTap: () => _showContentDetails(item),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: item.getBackgroundColor(context),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: item.getThemeColor(context).withOpacity(0.5),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: item.getThemeColor(context).withOpacity(0.2),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              item.icon,
                              size: 16,
                              color: item.getThemeColor(context),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                item.displayText,
                                style: TextStyle(
                                  color: item.getThemeColor(context),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.3, end: 0);
  }

  Widget _buildNotesButton() {
    return GlassContainer(
      child: SizedBox(
        width: double.infinity,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary.withOpacity(0.8),
                Theme.of(context).colorScheme.secondary.withOpacity(0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ElevatedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => NotesScreen(
                  session: _currentSession!,
                  aiService: _aiService,
                  educationLevel: _educationLevel,
                ),
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              padding: const EdgeInsets.all(20),
            ),
            icon: const Icon(Icons.note_add, color: Colors.white, size: 24),
            label: const Text(
              'Generate Notes',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.3, end: 0);
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _speechService.dispose();
    super.dispose();
  }
}