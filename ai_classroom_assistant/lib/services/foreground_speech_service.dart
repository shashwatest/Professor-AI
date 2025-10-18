import 'dart:async';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

class ForegroundSpeechService {
  static bool _isRunning = false;

  static bool get isRunning => _isRunning;

  static Future<void> initialize() async {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'speech_recording_channel',
        channelName: 'Speech Recording',
        channelDescription: 'Recording audio for transcription',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(5000),
        autoRunOnBoot: false,
        autoRunOnMyPackageReplaced: false,
        allowWakeLock: true,
        allowWifiLock: false,
      ),
    );
  }

  static Future<bool> start() async {
    if (_isRunning) return true;

    try {
      await FlutterForegroundTask.startService(
        serviceId: 256,
        notificationTitle: 'Recording Active',
        notificationText: 'Transcribing audio...',
        callback: startCallback,
      );
      _isRunning = true;
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> stop() async {
    if (!_isRunning) return true;

    try {
      await FlutterForegroundTask.stopService();
      _isRunning = false;
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<void> updateNotification(String text) async {
    if (_isRunning) {
      await FlutterForegroundTask.updateService(
        notificationTitle: 'Recording Active',
        notificationText: text,
      );
    }
  }
}

@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(SpeechTaskHandler());
}

class SpeechTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {}

  @override
  void onRepeatEvent(DateTime timestamp) {}

  @override
  Future<void> onDestroy(DateTime timestamp) async {}

  @override
  void onNotificationButtonPressed(String id) {}

  @override
  void onNotificationPressed() {
    FlutterForegroundTask.launchApp('/');
  }
}
