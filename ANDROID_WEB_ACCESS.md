# How to Access Web App from Android Device

## Method 1: Local Network Access (For Testing)

### Step 1: Build and Run Web App
```bash
cd "c:\Users\Suman\Desktop\Useful\Project\Professor AmazonQ\ai_classroom_assistant"
flutter run -d web-server --web-port 8080 --web-hostname 0.0.0.0
```

### Step 2: Find Your Computer's IP Address
On Windows:
```bash
ipconfig
```
Look for "IPv4 Address" under your active network adapter (e.g., `192.168.1.100`)

### Step 3: Access from Android
1. Make sure your Android device is on the **same WiFi network** as your computer
2. Open Chrome on your Android device
3. Go to: `http://YOUR_COMPUTER_IP:8080`
   - Example: `http://192.168.1.100:8080`
4. Grant microphone permission when prompted
5. Test recording with long pauses!

---

## Method 2: Deploy to Free Hosting (For Production)

### Option A: Firebase Hosting (Recommended)

#### Step 1: Build for Production
```bash
flutter build web --release
```

#### Step 2: Install Firebase CLI
```bash
npm install -g firebase-tools
```

#### Step 3: Deploy
```bash
cd "c:\Users\Suman\Desktop\Useful\Project\Professor AmazonQ\ai_classroom_assistant"
firebase login
firebase init hosting
# Select build/web as public directory
firebase deploy
```

You'll get a URL like: `https://your-app.web.app`

#### Step 4: Access from Anywhere
- Open the URL on any device
- Works on Android, iOS, desktop
- HTTPS enabled (required for microphone access)

---

### Option B: Netlify (Easiest)

#### Step 1: Build
```bash
flutter build web --release
```

#### Step 2: Deploy
1. Go to https://app.netlify.com/drop
2. Drag and drop the `build/web` folder
3. Get instant URL like: `https://your-app.netlify.app`

#### Step 3: Access from Android
- Open the URL in Chrome on Android
- Grant microphone permission
- Start recording!

---

### Option C: Vercel

#### Step 1: Install Vercel CLI
```bash
npm install -g vercel
```

#### Step 2: Deploy
```bash
cd "c:\Users\Suman\Desktop\Useful\Project\Professor AmazonQ\ai_classroom_assistant"
flutter build web --release
cd build/web
vercel --prod
```

Get URL like: `https://your-app.vercel.app`

---

## Method 3: Install as PWA (Progressive Web App)

Once deployed (using Method 2), you can install it as an app:

### On Android:
1. Open the web app URL in Chrome
2. Tap the menu (⋮) > "Add to Home screen"
3. The app icon appears on your home screen
4. Opens like a native app!

### Benefits:
- ✅ Works offline (after first load)
- ✅ Full-screen experience
- ✅ Appears in app drawer
- ✅ No app store needed

---

## Recommended Workflow:

### For Testing:
1. Use **Method 1** (local network)
2. Test on your Android device
3. Verify continuous recording works

### For Production:
1. Use **Method 2B** (Netlify - easiest)
2. Deploy in 2 minutes
3. Share URL with users
4. Optional: Install as PWA

---

## Troubleshooting:

### Can't access local server from Android?
- Check firewall settings on your computer
- Make sure both devices are on same WiFi
- Try disabling Windows Firewall temporarily

### Microphone not working on web?
- Must use HTTPS (local http://localhost works, but http://IP doesn't)
- For testing over network, use Method 2 (deploy to hosting)
- Chrome/Edge required (best support)

### "Not secure" warning?
- This happens with http:// on non-localhost
- Deploy to hosting (Method 2) for HTTPS
- HTTPS is required for microphone access on non-localhost

---

## Quick Start (Recommended):

```bash
# 1. Build
flutter build web --release

# 2. Deploy to Netlify (drag & drop build/web folder)
# Visit: https://app.netlify.com/drop

# 3. Open URL on Android Chrome

# 4. Test continuous recording!
```

That's it! 🚀
