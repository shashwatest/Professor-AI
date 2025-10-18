# Foreground Service Implementation - Setup Instructions

## What Was Implemented

Solution 2: Foreground Service with Wake Lock to prevent Android from stopping the microphone access.

## Changes Made

### 1. Dependencies Added
- `flutter_foreground_task: ^8.11.0` in `pubspec.yaml`

### 2. Android Permissions Added (AndroidManifest.xml)
- `FOREGROUND_SERVICE`
- `FOREGROUND_SERVICE_MICROPHONE`
- `WAKE_LOCK`
- `POST_NOTIFICATIONS`

### 3. New Files Created
- `lib/services/foreground_speech_service.dart` - Manages foreground service

### 4. Files Modified
- `lib/services/speech_service.dart` - Integrated with foreground service
- `lib/main.dart` - Initialize foreground task
- `lib/screens/app_shell.dart` - Added WithForegroundTask wrapper
- `android/app/src/main/kotlin/.../MainActivity.kt` - Handle foreground task lifecycle
- `android/app/src/main/AndroidManifest.xml` - Added permissions and service declaration

## Next Steps

### 1. Install Dependencies
Run this command in your terminal:
```bash
cd "c:\Users\Suman\Desktop\Useful\Project\Professor AmazonQ\ai_classroom_assistant"
flutter pub get
```

### 2. Request Notification Permission
The app will now show a persistent notification when recording. On Android 13+, you need to grant notification permission.

### 3. Test the Implementation
1. Build and run the app on your Android device
2. Start recording
3. You should see a persistent notification saying "Recording Active"
4. The microphone should stay active even during long pauses
5. The notification will disappear when you stop recording

## How It Works

1. **Foreground Service**: When recording starts, a foreground service is launched with a persistent notification
2. **Wake Lock**: The service requests a wake lock to prevent the system from killing the process
3. **Microphone Service Type**: The service is declared as a microphone service type, giving it priority
4. **No Auto-Stop**: The recording will continue indefinitely until manually stopped

## Expected Behavior

- ✅ Recording continues during long pauses (no 8-10 second timeout)
- ✅ Persistent notification shows recording status
- ✅ Full transcript preservation
- ✅ No device hanging (controlled by Android's foreground service system)
- ✅ Better battery management than background services

## Troubleshooting

If the issue persists:
1. Check that notification permission is granted
2. Verify the app is not in battery optimization mode (Settings > Apps > AI Classroom Assistant > Battery > Unrestricted)
3. Check Android logs for any errors: `adb logcat | grep -i speech`

## Alternative: If This Doesn't Work

If the foreground service doesn't solve the issue, we may need to:
1. Implement a hybrid approach with manual restart prompts
2. Switch to Google Cloud Speech-to-Text API with streaming
3. Use a native Android implementation with custom SpeechRecognizer handling
