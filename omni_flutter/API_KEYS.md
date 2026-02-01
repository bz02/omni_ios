# API Keys Configuration

## Gemini API Key
To use the app with real AI features, you need to add your Gemini API key.

### Option 1: Environment Variable
```bash
export GEMINI_API_KEY="your-api-key-here"
flutter run
```

### Option 2: Direct in Code (for development only)
1. Open `lib/services/gemini_service.dart`
2. Replace `YOUR_API_KEY_HERE` with your actual key
3. **Never commit this to git!**

### Get Your API Key
1. Go to https://makersuite.google.com/app/apikey
2. Click "Create API Key"
3. Copy the key

## Firebase (Optional - for production)
For persistent storage, you'll need Firebase:
1. Create project at https://console.firebase.google.com
2. Add iOS/Android apps
3. Download `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)
4. Follow Firebase Flutter setup guide

---

**Security Note**: Never commit API keys to version control. Add `.env` file to `.gitignore`.
