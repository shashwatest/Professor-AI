# AI Classroom Assistant

A sophisticated cross-platform Flutter app for real-time transcription and AI-powered topic extraction in classroom settings. Features a beautiful glassmorphism UI with advanced speech recognition and intelligent content analysis.

## ✨ Key Features

### 🎤 **Advanced Speech Recognition**
- **Real-time Speech Transcription**: Optimized speech-to-text with persistent transcript support
- **Cross-Recording Continuity**: Transcription preserves content across stop/start cycles
- **Platform-Optimized**: Different timeout behaviors for Android vs Web platforms
- **Noise Cancellation Guidance**: Built-in recommendations for optimal audio quality

### 🤖 **AI-Powered Analysis**
- **Intelligent Topic Extraction**: Automatic extraction after 20 words or manual trigger
- **Multi-Provider Support**: Gemini (default), OpenAI and Meta integration
- **Education Level Adaptation**: Tailored responses for High School, Undergraduate, Graduate, and Professional levels
- **Context-Aware Processing**: Enhanced accuracy with document upload support

### 📚 **Document Integration**
- **RAG (Retrieval-Augmented Generation)**: Upload course materials for enhanced AI analysis
- **Vector Store Integration**: Intelligent document chunking and similarity search
- **Context Enhancement**: AI responses informed by uploaded course content
- **Multiple Format Support**: PDF, text, and document processing

### 📝 **Advanced Notes System**
- **Dual Note Types**: Basic transcription and AI-enhanced structured notes
- **Real-time Generation**: Create notes during or after recording sessions
- **Smart Formatting**: Automatic structuring with headings, bullet points, and summaries
- **Session Persistence**: Notes saved and accessible across app sessions

### 💾 **Export & Sharing**
- **Multiple Formats**: Export as Text (.txt) or PDF (.pdf) files
- **Cross-Platform Export**: Optimized for web download and mobile sharing
- **Glassmorphism Export Dialogs**: Beautiful, themed export interface
- **Batch Operations**: Export multiple sessions or note types

### 🎨 **Glassmorphism UI Design**
- **Consistent Theme**: Beautiful frosted glass design throughout the app
- **Modern Animations**: Smooth transitions and micro-interactions
- **Responsive Design**: Optimized for mobile, tablet, and desktop
- **Accessibility**: High contrast ratios and readable typography
- **Dark Theme Integration**: Seamless dark/light theme support

### 🔧 **Performance & Optimization**
- **Memory Efficient**: Optimized transcript management and resource usage
- **Singleton Architecture**: Efficient service management and state preservation
- **Caching System**: Smart caching for API keys, settings, and frequent operations
- **Error Handling**: Comprehensive error management with user-friendly feedback

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

## 🔑 API Key Setup

The app supports multiple AI providers with secure local storage:

### **Gemini (Recommended)**
1. Get your API key from [Google AI Studio](https://makersuite.google.com/app/apikey)
2. When you first start recording, the app will prompt for your API key
3. The key is stored securely on your device using Flutter Secure Storage

### **OpenAI**
1. Get your API key from [OpenAI Platform](https://platform.openai.com/api-keys)
2. Go to Settings → AI Provider → Select OpenAI
3. Enter your OpenAI API key in the secure input field

### **Security Features**
- 🔒 **Secure Storage**: API keys encrypted and stored locally
- 🔄 **Auto-Caching**: Keys cached for seamless experience
- ⚙️ **Easy Management**: Change providers and keys anytime in Settings
- 🛡️ **Privacy First**: No keys transmitted except to chosen AI provider

## Permissions

- **Microphone**: Required for speech transcription
- **Internet**: Required for AI API calls
- **Storage**: Required for exporting files

## 🚀 Latest Updates & Features

### **v2.0 - Major Performance & UI Overhaul**

#### **🎤 Speech Recognition Improvements**
- ✅ **Optimized Speech Service**: Singleton pattern with memory-efficient transcript management
- ✅ **Persistent Transcription**: Content preserved across recording sessions
- ✅ **Platform-Aware Timeouts**: Different behaviors for Android vs Web platforms
- ✅ **Enhanced Error Handling**: Better user feedback and recovery mechanisms
- ✅ **Noise Cancellation Guidance**: Interactive dialog with device-specific instructions

#### **🎨 Complete Glassmorphism UI Redesign**
- ✅ **Unified Design Language**: All dialogs, notifications, and UI elements now use glassmorphism
- ✅ **Custom Glass Components**: Beautiful frosted glass containers throughout
- ✅ **Enhanced Notifications**: Custom GlassSnackBar system with themed variants
- ✅ **Modern Dialogs**: Redesigned confirmation dialogs with glass effects
- ✅ **Smooth Animations**: Micro-interactions and transitions for better UX

#### **📚 Document Integration & RAG System**
- ✅ **Document Upload**: Support for course materials and reference documents
- ✅ **RAG Implementation**: Retrieval-Augmented Generation for context-aware AI responses
- ✅ **Vector Store**: Intelligent document chunking and similarity search
- ✅ **Context Enhancement**: AI analysis informed by uploaded content
- ✅ **RAG System Testing**: Built-in diagnostics for embeddings and vector store

#### **⚡ Performance Optimizations**
- ✅ **Memory Management**: Efficient resource usage and cleanup
- ✅ **Caching System**: Smart caching for settings, API keys, and operations
- ✅ **State Preservation**: AutomaticKeepAliveClientMixin for better performance
- ✅ **Optimized Builds**: Reduced bundle size and faster compilation
- ✅ **Error Recovery**: Robust error handling with retry mechanisms

#### **🔧 Developer Experience**
- ✅ **Code Cleanup**: Removed 1500+ lines of redundant code
- ✅ **Simplified Architecture**: Streamlined services and components
- ✅ **Better Documentation**: Comprehensive code comments and structure
- ✅ **Testing Support**: Built-in debugging and diagnostic tools

## 📱 Usage Flow

### **Getting Started**
1. **🎓 Configure Settings**: Select education level and AI provider in Settings
2. **🔑 Setup API Key**: Enter your API key when prompted (secure one-time setup)
3. **📄 Upload Documents** (Optional): Add course materials for enhanced AI analysis

### **Recording & Analysis**
4. **🎤 Start Recording**: Tap the record button to begin live transcription
5. **📝 Live Transcription**: Watch real-time speech-to-text with word counting
6. **🤖 Topic Extraction**: Automatic after 20 words OR manual "Extract Now"
7. **🔍 Explore Topics**: Tap extracted topics for detailed explanations and examples

### **Notes & Export**
8. **📚 Generate Notes**: Create basic transcription or AI-enhanced structured notes
9. **💾 Save Sessions**: Sessions automatically saved to history
10. **📤 Export Content**: Export notes as Text or PDF with beautiful glass dialogs

### **Advanced Features**
- **🔄 Session Continuity**: Stop/start recording while preserving transcription
- **📊 RAG Integration**: Enhanced AI responses using uploaded documents
- **⚙️ Settings Management**: Customize providers, education levels, and preferences
- **📈 Session History**: Access and manage all previous recording sessions

## Testing

For web testing with microphone access, use HTTPS:
```bash
flutter run -d chrome --web-hostname localhost --web-port 8080
```

Then navigate to `https://localhost:8080` and accept the self-signed certificate.

## 🏗️ Technical Architecture

### **Core Services**
- **SpeechService**: Singleton-based speech recognition with optimized transcript management
- **AIService**: Multi-provider AI integration with factory pattern
- **DocumentService**: RAG implementation with vector store and embeddings
- **SettingsService**: Secure storage for user preferences and API keys
- **SessionStorageService**: Persistent session management and history

### **UI Components**
- **GlassContainer**: Reusable glassmorphism container component
- **GlassSnackBar**: Custom notification system with themed variants
- **Responsive Layouts**: Adaptive UI for different screen sizes and platforms

### **Performance Features**
- **Memory Optimization**: StringBuffer for efficient text concatenation
- **Caching System**: Smart caching for expensive operations
- **State Management**: AutomaticKeepAliveClientMixin for performance
- **Resource Cleanup**: Proper disposal patterns to prevent memory leaks

### **Security & Privacy**
- **Local Storage**: All data stored locally on device
- **Encrypted Keys**: API keys secured with Flutter Secure Storage
- **No Data Collection**: Privacy-first approach with no telemetry
- **Offline Capable**: Core functionality works without internet (except AI features)

## 🛠️ Troubleshooting

### **Common Issues & Solutions**

#### **🎤 Speech Recognition**
- **Recording stops automatically on Android**: This is normal behavior due to system power management
- **Recording continues indefinitely on Web**: Expected behavior - web platforms are more permissive
- **Microphone not working**: Check app permissions in device settings
- **Poor transcription quality**: Follow the noise cancellation guidance dialog

#### **🤖 AI Integration**
- **API Errors**: Verify API key is correct and has sufficient credits/quota
- **Slow responses**: Check internet connection and API provider status
- **Context not working**: Ensure documents are uploaded and RAG system is active

#### **💾 Export & Storage**
- **Export failures**: Ensure device has sufficient storage space
- **PDF generation issues**: Try exporting as text first, then convert
- **File sharing problems**: Check device sharing permissions

#### **🎨 UI & Performance**
- **Slow animations**: Reduce animation scale in device developer options
- **Memory issues**: Restart app if experiencing performance degradation
- **Theme inconsistencies**: Force restart app to reload theme properly

### **🔧 Advanced Diagnostics**
- **RAG System Test**: Use the built-in RAG diagnostics in Document Upload screen
- **Speech Service Status**: Check initialization status in app logs
- **API Provider Testing**: Test different providers in Settings

### **📞 Getting Help**
- Check device compatibility and Flutter version requirements
- Ensure all permissions are granted for optimal functionality
- Review API provider documentation for quota and usage limits

## 🤝 Contributing

We welcome contributions! Here's how you can help:

### **Development Setup**
1. Fork the repository
2. Create a feature branch: `git checkout -b feature/amazing-feature`
3. Make your changes and test thoroughly
4. Commit with descriptive messages: `git commit -m 'Add amazing feature'`
5. Push to your branch: `git push origin feature/amazing-feature`
6. Open a Pull Request

### **Areas for Contribution**
- 🌐 **Internationalization**: Add support for more languages
- 🎨 **UI/UX**: Enhance the glassmorphism design system
- 🤖 **AI Providers**: Add support for more AI services
- 📱 **Platform Features**: Platform-specific optimizations
- 🧪 **Testing**: Improve test coverage and automation
- 📚 **Documentation**: Enhance user guides and API docs

## 📊 Project Status

### **Current Version**: v2.0
- ✅ **Stable**: Core functionality tested across platforms
- ✅ **Production Ready**: Suitable for classroom and educational use
- ✅ **Actively Maintained**: Regular updates and improvements
- ✅ **Cross-Platform**: Full support for mobile, desktop, and web

### **Roadmap**
- 🔄 **Real-time Collaboration**: Multi-user session support
- 🎯 **Advanced Analytics**: Learning insights and progress tracking
- 🔊 **Audio Enhancements**: Noise reduction and audio processing
- 🌍 **Offline AI**: Local AI models for privacy-focused usage
- 📊 **Dashboard**: Teacher/instructor management interface

---

**Built with ❤️ using Flutter | Designed for Education | Privacy-First Approach**