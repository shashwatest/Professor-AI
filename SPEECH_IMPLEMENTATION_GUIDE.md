# Speech Recognition Implementation Guide

## Two Solutions Implemented

### Solution 1: Web Speech API (Recommended - Free & No Timeout)
**For Web/PWA deployment**

#### How It Works:
- Uses browser's built-in Web Speech API
- Continuous recognition with no timeouts
- Free (no API costs)
- Works on Chrome, Edge, Safari

#### To Use:
1. Build for web:
   ```bash
   flutter build web
   ```

2. Deploy to any web hosting (Firebase Hosting, Netlify, Vercel, etc.)

3. Access from any device's browser

4. Optional: Install as PWA for app-like experience

#### Advantages:
- ✅ No 8-10 second timeout
- ✅ Completely free
- ✅ No API keys needed
- ✅ Works on mobile browsers too
- ✅ Continuous transcription

#### Limitations:
- ⚠️ Requires internet connection
- ⚠️ Only works in browsers (not native app)

---

### Solution 2: Google Cloud Speech-to-Text (For Android App)
**For native Android deployment**

#### Setup Steps:

1. **Create Google Cloud Project**
   - Go to https://console.cloud.google.com
   - Create new project
   - Enable "Cloud Speech-to-Text API"

2. **Create Service Account**
   - Go to IAM & Admin > Service Accounts
   - Create service account
   - Grant "Cloud Speech Client" role
   - Create JSON key and download it

3. **Add Service Account to App**
   - Store the JSON key securely in your app
   - Use `GoogleCloudSpeechService` instead of `SpeechService`

4. **Update Settings Screen**
   - Add field for Google Cloud service account JSON
   - Store it securely using `flutter_secure_storage`

#### Cost:
- First 60 minutes/month: FREE
- After that: $0.006 per 15 seconds (~$1.44/hour)
- Typical classroom use: $5-10/month

#### Advantages:
- ✅ No timeout - continuous streaming
- ✅ Better accuracy than device recognition
- ✅ Works in native Android app
- ✅ Real-time partial results

#### Limitations:
- ⚠️ Requires internet connection
- ⚠️ Costs money after free tier
- ⚠️ Requires Google Cloud setup

---

## Recommendation

### For Testing/Development:
**Use Web Version** - Deploy as web app and test in browser. This is the fastest way to verify continuous transcription works.

### For Production:
**Option A (Recommended)**: Deploy as Progressive Web App (PWA)
- Free, no timeouts, works on all devices
- Users access via browser
- Can be "installed" for app-like experience

**Option B**: Use Google Cloud Speech-to-Text for Android
- Native app experience
- Costs ~$5-10/month for typical use
- Requires Google Cloud setup

**Option C (Best of Both)**: Offer both
- Web version for free users
- Android app with Google Cloud for premium users

---

## Next Steps

### To Test Web Version:
```bash
cd "c:\Users\Suman\Desktop\Useful\Project\Professor AmazonQ\ai_classroom_assistant"
flutter run -d chrome
```

### To Test Android with Google Cloud:
1. Complete Google Cloud setup above
2. Integrate `GoogleCloudSpeechService` into `CurrentSessionScreen`
3. Build and test: `flutter build apk`

---

## Files Modified/Created

### New Files:
- `lib/services/speech_service_web.dart` - Web Speech API implementation
- `lib/services/google_cloud_speech_service.dart` - Google Cloud implementation
- `lib/services/speech_service_mobile.dart` - Renamed from speech_service.dart

### Modified Files:
- `lib/services/speech_service.dart` - Now a conditional export
- `pubspec.yaml` - Added google_speech and sound_stream packages

### No Changes Needed:
- `lib/screens/current_session_screen.dart` - Works with both implementations
- All other files remain unchanged
