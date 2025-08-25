# AI Classroom Assistant

A comprehensive cross-platform Flutter app designed for educators and students, featuring real-time transcription, AI-powered topic extraction, document integration, and intelligent note generation.

## 🚀 Key Features

### 📝 Real-time Transcription
- **Live Speech-to-Text**: Local processing with instant feedback
- **Dual Speaker Modes**: Single or multi-speaker optimization
- **Word Count Tracking**: Real-time word counting with auto-extraction triggers
- **Partial Results**: See transcription as you speak

### 🤖 AI-Powered Intelligence
- **Multi-Provider Support**: Gemini (default), OpenAI, and Meta/Llama integration
- **Smart Topic Extraction**: Automatic extraction after 20 words or manual trigger
- **Education-Aware**: Tailored for High School, Undergraduate, Graduate, and Professional levels
- **Interactive Topic Details**: Tap any topic for comprehensive explanations with formulas and examples

### 📚 Document Integration (RAG)
- **File Upload**: Support for PDF and PowerPoint (PPTX) files
- **Vector Search**: Advanced document chunking and embedding-based retrieval
- **Context-Aware Topics**: Enhanced topic details using uploaded course materials
- **Document Management**: Easy upload, view, and clear functionality

### 📖 Advanced Notes System
- **Dual Note Types**: Basic (editable transcription) and AI-enhanced structured notes
- **Rich Text Rendering**: Full LaTeX math support, markdown formatting, code blocks
- **Interactive Editing**: Edit, save, and manage both note types
- **Comprehensive Formatting**: Headers, lists, formulas, examples, and study tips

### 💾 Export & Sharing
- **Multiple Formats**: Export as Text (.txt) or PDF (.pdf)
- **Cross-Platform Sharing**: Native sharing integration
- **Session Management**: Complete history with metadata and statistics
- **Batch Operations**: Manage multiple sessions efficiently

### ⚙️ Configuration & Settings
- **API Key Management**: Secure storage for multiple AI providers
- **Flexible Configuration**: Default provider, education level, speaker modes
- **Session Persistence**: Automatic saving and retrieval of all sessions
- **Privacy-First**: All data stored locally with optional cloud AI processing

### 🎨 Modern UI/UX
- **Glassmorphism Design**: Beautiful frosted glass aesthetic
- **Material 3**: Latest Material Design with dynamic theming
- **Smooth Animations**: Fluid transitions and micro-interactions
- **Responsive Layout**: Optimized for all screen sizes and orientations
- **Dark/Light Themes**: Automatic theme switching support

### 🌐 Cross-Platform Support
- **Universal Compatibility**: Android, iOS, Windows, macOS, Linux, and Web
- **Platform Optimization**: Native performance on each platform
- **Web HTTPS Support**: Secure microphone access for web deployment

## 🛠️ Development Setup

### Prerequisites
1. **Install Flutter**: Follow [Flutter installation guide](https://flutter.dev/docs/get-started/install)
2. **Platform Setup**: Configure for your target platforms (Android Studio, Xcode, etc.)
3. **Dependencies**: Ensure all platform-specific requirements are met

### Quick Start
```bash
# Clone and setup
git clone <repository-url>
cd ai_classroom_assistant
flutter pub get

# Run on different platforms
flutter run -d windows    # Windows desktop
flutter run -d macos     # macOS desktop  
flutter run -d linux     # Linux desktop
flutter run -d android   # Android device/emulator
flutter run -d ios       # iOS device/simulator
flutter run -d chrome --web-hostname localhost --web-port 8080  # Web with HTTPS
```

### Project Structure
```
lib/
├── models/           # Data models (TranscriptionSession)
├── screens/          # UI screens (6 main screens)
├── services/         # Business logic & API integration
│   ├── embeddings/   # Vector embedding providers
│   ├── vectorstore/  # Vector database integration
│   └── utils/        # Utility functions
└── widgets/          # Reusable UI components
```

### Key Dependencies
- **speech_to_text**: Local speech recognition
- **flutter_secure_storage**: Encrypted API key storage
- **syncfusion_flutter_pdf**: PDF processing and generation
- **flutter_markdown**: Rich text rendering with LaTeX
- **file_picker**: Cross-platform file selection
- **share_plus**: Native sharing integration
- **http**: AI provider API communication

## 🎯 Future Enhancements

### Planned Features
- **Offline AI**: Local LLM integration for privacy-first operation
- **Advanced RAG**: Improved document chunking and retrieval algorithms
- **Collaboration**: Real-time session sharing and collaborative note-taking
- **Voice Commands**: Voice-controlled app navigation and commands
- **Custom Models**: Support for fine-tuned educational AI models
- **Analytics Dashboard**: Learning progress tracking and insights
- **Plugin System**: Extensible architecture for custom integrations
- **Advanced Export**: LaTeX, Word, and presentation format exports

### Technical Roadmap
- **Performance**: Optimize for longer sessions and larger documents
- **Accessibility**: Enhanced screen reader and keyboard navigation support
- **Internationalization**: Multi-language UI and speech recognition
- **Cloud Sync**: Optional encrypted cloud backup and sync
- **API Extensions**: Support for additional AI providers and models

---

## 📄 License

This project is open source and available under the [MIT License](LICENSE).

## 🤝 Contributing

Contributions are welcome! Please read our contributing guidelines and submit pull requests for any improvements.

## 📞 Support

For issues, feature requests, or questions:
- Create an issue in the GitHub repository
- Check the troubleshooting section above
- Review the documentation and code comments

---

**Built with ❤️ using Flutter for the future of education technology**

## 🔑 API Configuration

The app supports multiple AI providers with secure key management:

### Gemini (Recommended Default)
1. **Get API Key**: Visit [Google AI Studio](https://makersuite.google.com/app/apikey)
2. **Free Tier**: Generous free usage limits
3. **Setup**: Go to Settings → API Keys → Enter Gemini key
4. **Model**: Uses latest Gemini 2.0 Flash for optimal performance

### OpenAI
1. **Get API Key**: Visit [OpenAI Platform](https://platform.openai.com/api-keys)
2. **Pricing**: Pay-per-use model with GPT-3.5-turbo
3. **Setup**: Settings → API Keys → Enter OpenAI key
4. **Features**: Excellent for detailed academic content

### Meta/Llama
1. **Get API Key**: Visit [Llama API](https://www.llama-api.com/)
2. **Model**: Uses Llama 3.1 70B for processing
3. **Setup**: Settings → API Keys → Enter Meta key
4. **Alternative**: Good fallback option

### Security & Privacy
- **Secure Storage**: All API keys encrypted using Flutter Secure Storage
- **Local Processing**: Speech recognition happens on-device
- **Data Privacy**: Transcriptions sent to AI providers only for enhancement
- **No Tracking**: No user data collection or analytics
- **Offline Capable**: Basic transcription works without internet

## 🔒 Permissions & Privacy

### Required Permissions
- **Microphone**: Essential for real-time speech transcription
- **Internet**: Required for AI processing and document upload
- **Storage**: Needed for session saving and file export
- **File Access**: Required for document upload (PDF/PPTX)

### Privacy Commitment
- **Local First**: All transcription and storage happens on your device
- **Minimal Data**: Only transcription text sent to AI providers when needed
- **No Tracking**: Zero analytics, telemetry, or user behavior tracking
- **Secure Keys**: API keys encrypted and stored locally only
- **Open Source**: Full transparency with complete source code access
- **User Control**: Complete control over data export and deletion

### Data Flow
1. **Speech → Device**: Audio processed locally, never uploaded
2. **Text → AI**: Only transcription text sent for topic extraction/notes
3. **Results → Device**: AI responses stored locally in encrypted format
4. **Export → User**: You control all data export and sharing

## ✅ Complete Feature Set

### Core Functionality
- ✅ **Real-time Speech Transcription** with partial/final result handling
- ✅ **Smart Word Counting** with 20-word auto-extraction threshold
- ✅ **Manual Topic Extraction** with instant trigger button
- ✅ **Multi-AI Provider Support** (Gemini, OpenAI, Meta/Llama)
- ✅ **Interactive Topic Details** with comprehensive explanations
- ✅ **Document Upload & RAG** (PDF/PPTX with vector search)
- ✅ **Dual Notes System** (Basic + AI-enhanced with rich formatting)
- ✅ **Advanced Export** (Text/PDF with cross-platform sharing)
- ✅ **Session Management** with complete history and statistics
- ✅ **Secure Settings** with encrypted API key storage
- ✅ **Education Level Adaptation** for all content generation
- ✅ **Modern Glassmorphism UI** with Material 3 design
- ✅ **Full Cross-Platform Support** (6 platforms)
- ✅ **LaTeX Math Rendering** in notes and topic details
- ✅ **Markdown Support** with code blocks and formatting
- ✅ **Error Handling & Retry Logic** for robust operation
- ✅ **Responsive Design** optimized for all devices

## 📋 Complete Usage Guide

### Initial Setup
1. **Configure Settings**: Set your preferred AI provider and education level
2. **Add API Keys**: Securely store keys for your chosen AI providers
3. **Upload Documents** (Optional): Add course materials for enhanced topic extraction

### Recording & Transcription
1. **Select Mode**: Choose single or multi-speaker transcription
2. **Start Recording**: Begin live speech-to-text capture
3. **Monitor Progress**: Watch real-time word count and transcription
4. **Auto-Extraction**: Topics automatically extract after 20 words
5. **Manual Control**: Use "Extract Now" button for immediate topic generation

### Exploring Content
1. **Interactive Topics**: Tap any extracted topic for detailed explanations
2. **Document Integration**: View relevant content from uploaded materials
3. **Rich Formatting**: Enjoy LaTeX formulas, examples, and structured information
4. **Add to Notes**: Directly add topic details to your session notes

### Notes & Export
1. **Generate Notes**: Create both basic and AI-enhanced structured notes
2. **Edit Content**: Modify and customize both note types as needed
3. **Export Options**: Save as Text or PDF with professional formatting
4. **Share Results**: Use native sharing for collaboration

### Session Management
1. **Auto-Save**: All sessions automatically saved with metadata
2. **Browse History**: Access previous sessions with statistics
3. **Manage Content**: View, edit, or delete past sessions
4. **Continuous Learning**: Build a comprehensive knowledge base over time

## 🧪 Development & Testing

### Web Development
For web testing with microphone access, use HTTPS:
```bash
flutter run -d chrome --web-hostname localhost --web-port 8080
```
Then navigate to `https://localhost:8080` and accept the self-signed certificate.

### Mobile Testing
**Android USB Debugging:**
```bash
# Enable Developer Options and USB Debugging
flutter run -d android
```

**Android Wireless Debugging:**
```bash
# Pair device first
adb pair <IP>:<PORT>
adb connect <IP>:<PORT>
flutter run -d android
```

**iOS Testing:**
```bash
# Requires Xcode and iOS development setup
flutter run -d ios
```

### Desktop Testing
```bash
# Windows
flutter run -d windows

# macOS
flutter run -d macos

# Linux
flutter run -d linux
```

### Performance Testing
- Test with various document sizes and types
- Verify memory usage during long recording sessions
- Check export functionality with large note content
- Test AI provider switching and error handling
- Validate cross-platform UI consistency

## 🔧 Troubleshooting

### Common Issues

**Microphone Problems**
- Ensure microphone permissions are granted in device settings
- Check if other apps are using the microphone
- Restart the app if speech recognition stops working

**API & Network Issues**
- Verify API keys are correctly entered in Settings
- Check internet connection for AI processing
- Ensure API accounts have sufficient credits/quota
- Try switching between AI providers if one fails

**Export & Storage**
- Confirm device has adequate storage space
- Check file permissions for document access
- Ensure sharing apps are installed for export functionality

**Document Upload Issues**
- Verify file format is PDF or PPTX
- Check file size limits (10MB maximum)
- Ensure document contains readable text content

**Performance Optimization**
- Close other resource-intensive apps during recording
- Use single-speaker mode for better performance
- Clear old sessions if storage becomes limited

### Platform-Specific Notes

**Web Version**
- Use HTTPS for microphone access: `https://localhost:8080`
- Accept browser security certificates when prompted
- Ensure browser supports Web Speech API

**Mobile Devices**
- Enable "Don't keep activities" in Developer Options for testing
- Use USB debugging or wireless ADB for development
- Grant all requested permissions for full functionality

**Desktop Platforms**
- Ensure microphone drivers are up to date
- Check system audio settings and default devices
- Run as administrator if file access issues occur