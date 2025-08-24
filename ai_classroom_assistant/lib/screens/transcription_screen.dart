import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/transcription_session.dart';
import '../services/speech_service.dart';
import '../services/ai_service.dart';
import '../widgets/glass_container.dart';
import 'topic_detail_screen.dart';
import 'notes_screen.dart';

class TranscriptionScreen extends StatefulWidget {
  const TranscriptionScreen({super.key});

  @override
  State<TranscriptionScreen> createState() => _TranscriptionScreenState();
}

class _TranscriptionScreenState extends State<TranscriptionScreen> {
  final SpeechService _speechService = SpeechService();
  TranscriptionSession? _currentSession;
  AIService? _aiService;
  
  bool _isListening = false;
  bool _singleSpeakerMode = true;
  String _educationLevel = 'Undergraduate';
  String _apiKey = '';
  AIProvider _selectedProvider = AIProvider.gemini;
  List<String> _extractedTopics = [];
  bool _isExtracting = false;

  @override
  void initState() {
    super.initState();
    _initializeSpeechService();
  }

  void _initializeSpeechService() {
    _speechService.onResult = _onSpeechResult;
    _speechService.onError = _onSpeechError;
    _speechService.onListeningStateChanged = (listening) {
      setState(() {
        _isListening = listening;
      });
    };
  }

  void _onSpeechResult(String result) {
    if (_currentSession != null && result.isNotEmpty) {
      setState(() {
        // Replace last chunk if it's partial, otherwise add new
        if (_currentSession!.transcriptionChunks.isNotEmpty) {
          _currentSession!.transcriptionChunks.removeLast();
        }
        _currentSession!.addTranscription(result);
      });
      
      // Auto-extract topics if word count >= 20
      if (_currentSession!.wordCount >= 20 && _aiService != null && !_isExtracting) {
        _extractTopics();
      }
    }
  }

  void _onSpeechError(String error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Speech error: $error')),
    );
  }

  Future<void> _startRecording() async {
    if (_apiKey.isEmpty) {
      _showApiKeyDialog();
      return;
    }

    _aiService = AIServiceFactory.create(_selectedProvider, _apiKey);
    
    final initialized = await _speechService.initialize();
    if (!initialized) return;

    setState(() {
      _currentSession = TranscriptionSession(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        startTime: DateTime.now(),
        isRecording: true,
      );
      _extractedTopics.clear();
    });

    await _speechService.startListening(singleSpeaker: _singleSpeakerMode);
  }

  Future<void> _stopRecording() async {
    await _speechService.stopListening();
    if (_currentSession != null) {
      setState(() {
        _currentSession!.endSession();
      });
    }
  }

  Future<void> _extractTopics() async {
    if (_isExtracting || _aiService == null || _currentSession == null) return;

    setState(() {
      _isExtracting = true;
    });

    try {
      final topics = await _aiService!.extractTopics(
        _currentSession!.fullTranscription,
        _educationLevel,
      );
      
      setState(() {
        _extractedTopics = topics;
        for (final topic in topics) {
          _currentSession!.addTopic(topic);
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to extract topics: $e')),
      );
    } finally {
      setState(() {
        _isExtracting = false;
      });
    }
  }

  void _showTopicDetails(String topic) {
    if (_aiService == null) return;
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TopicDetailScreen(
          topic: topic,
          aiService: _aiService!,
          educationLevel: _educationLevel,
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
              Text(
                'Enter ${_selectedProvider.name.toUpperCase()} API Key',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<AIProvider>(
                initialValue: _selectedProvider,
                decoration: const InputDecoration(
                  labelText: 'AI Provider',
                  border: OutlineInputBorder(),
                ),
                items: AIProvider.values
                    .where((provider) => AIServiceFactory.create(provider, 'test') != null)
                    .map((provider) => DropdownMenuItem(
                          value: provider,
                          child: Text(provider.name.toUpperCase()),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedProvider = value!;
                    _apiKey = '';
                  });
                },
              ),
              const SizedBox(height: 16),
              TextField(
                onChanged: (value) => _apiKey = value,
                decoration: InputDecoration(
                  hintText: _selectedProvider == AIProvider.gemini ? 'AIza...' : 'sk-...',
                  border: const OutlineInputBorder(),
                  labelText: 'API Key',
                ),
                obscureText: true,
              ),
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
                      if (_apiKey.isNotEmpty) {
                        _startRecording();
                      }
                    },
                    child: const Text('Save'),
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
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildHeader(),
                const SizedBox(height: 20),
                _buildControls(),
                const SizedBox(height: 20),
                Expanded(child: _buildTranscriptionView()),
                if (_extractedTopics.isNotEmpty) _buildTopicsView(),
                if (_currentSession != null && _currentSession!.wordCount > 0)
                  _buildNotesButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return GlassContainer(
      child: Row(
        children: [
          Icon(
            Icons.school,
            size: 32,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 12),
          const Text(
            'AI Classroom Assistant',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          Text(
            _selectedProvider.name.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          _buildStatusIndicator(),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _isListening 
              ? [Colors.green.withOpacity(0.8), Colors.green.withOpacity(0.6)]
              : [Colors.grey.withOpacity(0.8), Colors.grey.withOpacity(0.6)],
        ),
        borderRadius: BorderRadius.circular(16),
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
          const SizedBox(width: 6),
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
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _educationLevel,
                  decoration: const InputDecoration(
                    labelText: 'Education Level',
                    border: OutlineInputBorder(),
                  ),
                  items: ['High School', 'Undergraduate', 'Graduate', 'Professional']
                      .map((level) => DropdownMenuItem(
                            value: level,
                            child: Text(level),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _educationLevel = value!;
                    });
                  },
                ),
              ),
              const SizedBox(width: 16),
              Switch(
                value: _singleSpeakerMode,
                onChanged: (value) {
                  setState(() {
                    _singleSpeakerMode = value;
                  });
                },
              ),
              const Text('Single Speaker'),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isListening ? _stopRecording : _startRecording,
                  icon: Icon(_isListening ? Icons.stop : Icons.play_arrow),
                  label: Text(_isListening ? 'Stop Recording' : 'Start Recording'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
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
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ElevatedButton.icon(
                  onPressed: (_currentSession?.wordCount ?? 0) > 0 && !_isExtracting
                      ? _extractTopics
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  icon: _isExtracting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.auto_awesome, color: Colors.white),
                  label: const Text(
                    'Extract Now',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
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
          Row(
            children: [
              const Text(
                'Live Transcription',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              if (_currentSession != null)
                Text(
                  'Words: ${_currentSession!.wordCount}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
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
                child: Text(
                  _currentSession?.fullTranscription ?? 'Start recording to see transcription...',
                  style: const TextStyle(fontSize: 16, height: 1.5),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopicsView() {
    return GlassContainer(
      margin: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Extracted Topics',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _extractedTopics
                .map((topic) => GestureDetector(
                      onTap: () => _showTopicDetails(topic),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8, bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Theme.of(context).colorScheme.primaryContainer.withOpacity(0.8),
                              Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.lightbulb_outline,
                              size: 16,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              topic,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onPrimaryContainer,
                                fontWeight: FontWeight.w600,
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
      margin: const EdgeInsets.only(top: 16),
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
              padding: const EdgeInsets.all(18),
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

  @override
  void dispose() {
    _speechService.dispose();
    super.dispose();
  }
}