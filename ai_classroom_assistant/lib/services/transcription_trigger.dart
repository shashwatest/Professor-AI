class TranscriptionTrigger {
  int _lastProcessedWordCount = 0;
  int _triggerInterval = 20;
  
  /// Sets the word count interval for triggering content extraction
  void setTriggerInterval(int interval) {
    _triggerInterval = interval;
  }
  
  /// Checks if content extraction should be triggered based on word count
  bool shouldTrigger(int currentWordCount) {
    if (currentWordCount >= _lastProcessedWordCount + _triggerInterval) {
      _lastProcessedWordCount = currentWordCount;
      return true;
    }
    return false;
  }
  
  /// Resets the trigger state (call when starting new session)
  void reset() {
    _lastProcessedWordCount = 0;
  }
  
  /// Gets the current trigger interval
  int get triggerInterval => _triggerInterval;
  
  /// Gets the last processed word count
  int get lastProcessedWordCount => _lastProcessedWordCount;
  
  /// Gets words remaining until next trigger
  int wordsUntilNextTrigger(int currentWordCount) {
    final nextTrigger = _lastProcessedWordCount + _triggerInterval;
    return (nextTrigger - currentWordCount).clamp(0, _triggerInterval);
  }
}