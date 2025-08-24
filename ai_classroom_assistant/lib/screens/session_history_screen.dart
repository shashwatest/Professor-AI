import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/transcription_session.dart';
import '../services/session_storage_service.dart';
import '../services/ai_service.dart';
import '../widgets/glass_container.dart';
import 'notes_screen.dart';

class SessionHistoryScreen extends StatefulWidget {
  final AIService? aiService;
  final String educationLevel;

  const SessionHistoryScreen({
    super.key,
    this.aiService,
    required this.educationLevel,
  });

  @override
  State<SessionHistoryScreen> createState() => _SessionHistoryScreenState();
}

class _SessionHistoryScreenState extends State<SessionHistoryScreen> {
  List<TranscriptionSession> _sessions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    try {
      final sessions = await SessionStorageService.getSessions();
      setState(() {
        _sessions = sessions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load sessions: $e')),
        );
      }
    }
  }

  Future<void> _deleteSession(String sessionId) async {
    try {
      await SessionStorageService.deleteSession(sessionId);
      await _loadSessions();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Session deleted')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete session: $e')),
        );
      }
    }
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
              Expanded(child: _buildSessionsList()),
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
              'Session History',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Text(
            '${_sessions.length} sessions',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionsList() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_sessions.isEmpty) {
      return Center(
        child: GlassContainer(
          margin: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.history,
                size: 64,
                color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'No sessions yet',
                style: TextStyle(
                  fontSize: 18,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Start recording to create your first session',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _sessions.length,
      itemBuilder: (context, index) {
        final session = _sessions[index];
        return _buildSessionCard(session, index);
      },
    );
  }

  Widget _buildSessionCard(TranscriptionSession session, int index) {
    final date = session.startTime.toString().split(' ')[0];
    final time = session.startTime.toString().split(' ')[1].substring(0, 5);
    final duration = session.endTime != null
        ? session.endTime!.difference(session.startTime)
        : Duration.zero;

    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary.withOpacity(0.8),
                Theme.of(context).colorScheme.secondary.withOpacity(0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.school,
            color: Colors.white,
          ),
        ),
        title: Text(
          'Class Session',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$date at $time'),
            const SizedBox(height: 4),
            Row(
              children: [
                Text('${session.wordCount} words'),
                const SizedBox(width: 16),
                if (duration.inMinutes > 0)
                  Text('${duration.inMinutes}m ${duration.inSeconds % 60}s'),
                const SizedBox(width: 16),
                if (session.extractedTopics.isNotEmpty)
                  Text('${session.extractedTopics.length} topics'),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'view',
              child: const Row(
                children: [
                  Icon(Icons.visibility),
                  SizedBox(width: 8),
                  Text('View Notes'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Theme.of(context).colorScheme.error),
                  const SizedBox(width: 8),
                  Text(
                    'Delete',
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ],
              ),
            ),
          ],
          onSelected: (value) {
            if (value == 'view') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => NotesScreen(
                    session: session,
                    aiService: widget.aiService,
                    educationLevel: widget.educationLevel,
                  ),
                ),
              );
            } else if (value == 'delete') {
              _showDeleteConfirmation(session);
            }
          },
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NotesScreen(
                session: session,
                aiService: widget.aiService,
                educationLevel: widget.educationLevel,
              ),
            ),
          );
        },
      ),
    ).animate(delay: Duration(milliseconds: index * 100))
        .fadeIn(duration: 300.ms)
        .slideX(begin: 0.2, end: 0);
  }

  void _showDeleteConfirmation(TranscriptionSession session) {
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
                'Delete Session',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text('Are you sure you want to delete this session? This action cannot be undone.'),
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
                      _deleteSession(session.id);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.error,
                    ),
                    child: const Text('Delete', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}