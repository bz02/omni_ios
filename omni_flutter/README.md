# Omni Flutter App

> **AI-Powered Energy Management Platform** 🔮  
> Cross-platform iOS & Android from a single codebase

## 🎯 Project Overview

Flutter implementation of the Omni app with all MVP features:
- **Onboarding**: Energy DNA & Soul ID generation
- **Daily Vibe**: Energy score, OOTD, daily wisdom
- **Viral Features**: Pet Psychic + The Roast
- **Chat Engine**: 3 free messages/day with AI responses

## 🚀 Getting Started

### Prerequisites
- Flutter SDK 3.0+
- Dart 3.0+
- iOS/Android development tools

### Installation

1. **Install Flutter** (if not already installed):
```bash
# Via Homebrew (macOS)
brew install --cask flutter

# Verify installation
flutter doctor

# Accept licenses
flutter doctor --android-licenses
```

2. **Get Dependencies**:
```bash
cd omni_flutter
flutter pub get
```

3. **Run on iOS**:
```bash
flutter run -d iphone
# Or open iOS simulator first, then:
flutter run
```

4. **Run on Android**:
```bash
flutter run -d android
```

## 📁 Project Structure

```
omni_flutter/
├── lib/
│   ├── main.dart                    # App entry point
│   ├── models/
│   │   ├── user_profile.dart        # User, DNA, Soul ID models
│   │   └── chat_models.dart         # Chat & Daily Vibe models
│   ├── providers/
│   │   └── app_state.dart           # Global state management
│   ├── screens/
│   │   ├── onboarding_screen.dart   # Birthday + Pet input
│   │   ├── home_screen.dart         # Bottom navigation
│   │   ├── profile_screen.dart      # Energy DNA display
│   │   ├── daily_vibe_screen.dart   # Daily energy + OOTD
│   │   ├── chat_screen.dart         # AI chat interface
│   │   ├── viral_hub_screen.dart    # Viral features hub
│   │   ├── pet_psychic_screen.dart  # Pet photo reading
│   │   └── the_roast_screen.dart    # Zodiac roasts
│   └── widgets/
│       ├── energy_score_card.dart   # Animated progress ring
│       ├── energy_dna_card.dart     # DNA display card
│       └── soul_id_card.dart        # Soul ID display card
├── pubspec.yaml                     # Dependencies
└── README.md
```

## 🎨 Features

### Onboarding
- Date picker for birthday
- Pet name/type input
- Auto-generates Energy DNA (based on birth day odd/even)
- Creates unique Soul ID for pet

### Daily Vibe
- **Energy Score**: Animated circular progress (0-100%)
- **OOTD**: Color + style recommendations
- **Advice**: Daily wisdom with sass

### Viral Hooks
- **Pet Psychic**: Upload photo → Get roast reading
- **The Roast**: Select zodiac → "Why you're single" report

### Chat
- Message bubble UI
- 3-message daily limit
- Keyword-aware responses (love, work, tired)
- Mix of Eastern/Western/Sassy wisdom

## 📦 Dependencies

```yaml
provider: ^6.1.1          # State management
image_picker: ^1.0.7      # Photo selection
intl: ^0.18.1             # Date formatting
shared_preferences: ^2.2.2 # Local storage
```

## 🧪 Testing

```bash
# Run app in debug mode
flutter run

# Build for release (iOS)
flutter build ios --release

# Build for release (Android)
flutter build apk --release
```

## 🔧 Configuration

### iOS Permissions
Already included in project. For manual setup, add to `ios/Runner/Info.plist`:
```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>Omni needs access to analyze your pet's energy</string>
```

### Android Permissions
Add to `android/app/src/main/AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
```

## 🎯 Next Steps

- [ ] Push notifications for daily vibe
- [ ] Real AI API integration (OpenAI/Gemini)
- [ ] Social sharing functionality
- [ ] User authentication
- [ ] Cloud sync with Firebase

## 🤝 Comparison: Flutter vs Swift

| Feature | Flutter | SwiftUI |
|---------|---------|---------|
| Platforms | iOS + Android | iOS only |
| Language | Dart | Swift |
| Hot Reload | ✅ Yes | ✅ Yes |
| Performance | ~Native | Native |
| UI | Material/Cupertino | iOS Native |

---

**Built with Flutter for cross-platform excellence** 🚀
