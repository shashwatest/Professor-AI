# AI Classroom Assistant

A cross-platform Flutter app for real-time transcription and AI-powered topic extraction in classroom settings.

## Features

- **Real-time Speech Transcription**: Local speech-to-text with single/multi-speaker modes
- **AI Topic Extraction**: Automatic topic extraction after 20 words or manual trigger
- **Topic Details**: Tap topics to see structured information with formulas and examples
- **Notes Generation**: Basic transcription and AI-enhanced structured notes
- **Export Functionality**: Export notes as Text (.txt) or PDF (.pdf) files
- **Education Level Support**: Tailored responses for High School, Undergraduate, Graduate, and Professional levels
- **Glassmorphism UI**: Modern frosted glass design with smooth animations
- **Cross-platform**: Runs on Android, iOS, Windows, macOS, Linux, and Web

## Setup

1. **Install Flutter**: Follow [Flutter installation guide](https://flutter.dev/docs/get-started/install)

2. **Get dependencies**:
   ```bash
   flutter pub get
   ```

3. **Run the app**:
   ```bash
   # Desktop
   flutter run -d windows
   flutter run -d macos
   flutter run -d linux
   
   # Mobile
   flutter run -d android
   flutter run -d ios
   
   # Web (HTTPS for microphone access)
   flutter run -d chrome --web-port 8080 --web-hostname localhost
   ```

## Mobile Testing

To test on your mobile device:

1. **Enable Developer Options** on your Android device
2. **Enable USB Debugging** in Developer Options
3. **Connect device** via USB
4. **Run**: `flutter run -d android`

Or use wireless debugging:
1. **Enable Wireless Debugging** in Developer Options
2. **Pair device** with `adb pair <IP>:<PORT>`
3. **Connect**: `adb connect <IP>:<PORT>`
4. **Run**: `flutter run -d android`

## API Key Setup

The app supports multiple AI providers (Gemini is default):

**Gemini (Default)**:
1. Get your API key from [Google AI Studio](https://makersuite.google.com/app/apikey)
2. When you first start recording, the app will prompt for your API key
3. The key is stored securely on your device

**OpenAI**:
1. Get your API key from [OpenAI Platform](https://platform.openai.com/api-keys)
2. Select OpenAI in the provider dropdown when prompted
3. Enter your OpenAI API key

## Permissions

- **Microphone**: Required for speech transcription
- **Internet**: Required for AI API calls
- **Storage**: Required for exporting files

## Current Features

- ✅ Real-time speech transcription with improved responsiveness
- ✅ Word counting and 20-word threshold for auto-extraction
- ✅ Manual topic extraction trigger
- ✅ Gemini and OpenAI integration for topic extraction
- ✅ Tappable topic details with structured formatting
- ✅ Notes generation (basic and AI-enhanced)
- ✅ Export functionality (Text and PDF formats)
- ✅ Education level selection
- ✅ Enhanced glassmorphism UI theme
- ✅ Mobile-optimized interface
- ✅ Cross-platform support

## Usage Flow

1. **Select education level** and speaker mode
2. **Enter API key** when prompted (first time only)
3. **Start recording** - see live transcription
4. **Topics auto-extract** after 20 words OR click "Extract Now"
5. **Tap topics** to see detailed information
6. **Generate notes** anytime during or after recording
7. **Export notes** in Text or PDF format

## Testing

For web testing with microphone access, use HTTPS:
```bash
flutter run -d chrome --web-hostname localhost --web-port 8080
```

Then navigate to `https://localhost:8080` and accept the self-signed certificate.

## Troubleshooting

**Export Issues**: Ensure device has sufficient storage space
**Microphone Issues**: Check app permissions in device settings
**API Errors**: Verify API key is correct and has sufficient credits