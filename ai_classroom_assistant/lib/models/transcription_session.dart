class TranscriptionSession {
  final String id;
  final DateTime startTime;
  DateTime? endTime;
  final List<String> transcriptionChunks;
  final List<String> extractedTopics;
  String basicNotes;
  int wordCount;
  bool isRecording;

  TranscriptionSession({
    required this.id,
    required this.startTime,
    this.endTime,
    List<String>? transcriptionChunks,
    List<String>? extractedTopics,
    this.basicNotes = '',
    this.wordCount = 0,
    this.isRecording = false,
  })  : transcriptionChunks = transcriptionChunks ?? [],
        extractedTopics = extractedTopics ?? [];

  String get fullTranscription => transcriptionChunks.join(' ');

  void addTranscription(String text) {
    transcriptionChunks.add(text);
    _recalculateWordCount();
  }

  void _recalculateWordCount() {
    wordCount = fullTranscription.trim().isEmpty 
        ? 0 
        : fullTranscription.trim().split(RegExp(r'\s+')).length;
  }

  void addTopic(String topic) {
    if (!extractedTopics.contains(topic)) {
      extractedTopics.add(topic);
    }
  }

  void addToBasicNotes(String content) {
    if (basicNotes.isNotEmpty) {
      basicNotes += '\n\n$content';
    } else {
      basicNotes = content;
    }
  }

  void updateBasicNotes(String notes) {
    basicNotes = notes;
  }

  void endSession() {
    endTime = DateTime.now();
    isRecording = false;
  }
}