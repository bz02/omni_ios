# Omni iOS App

> **AI-Powered Energy Management Platform** 🔮  
> Combining Pet Psychic Analysis, Daily Vibe Checks, and Eastern/Western Wisdom

## 🎯 Project Overview

Omni is an iOS application designed for the US market that creates a unique "Energy Management" experience by blending:
- **Pet + Roast Culture**: Viral hooks through Pet Psychic readings and personality roasts
- **Daily Engagement**: Morning energy scores, lucky outfit recommendations, and actionable advice
- **AI Chat Engine**: Free daily consultations mixing Eastern mysticism with Western logic

## 📱 MVP Features

### A. Onboarding (Energy DNA)
- Collect user birthday + pet information (name, type, photo)
- Generate personalized **Energy DNA** (e.g., "Solar Flare", "Void Walker")
- Create pet's **Soul ID** with archetype and personality

### B. Viral Hooks
- **Pet Psychic** 🔮: Upload pet photo → Get roast/reading
- **The Roast** 🔥: Zodiac-based "Why You're Single" report

### C. Daily Vibe Check
- Energy Score (0-100%) with animated progress ring
- OOTD (Outfit of the Day) color & style recommendations
- One-liner actionable wisdom

### D. Omni-Chat (Lite)
- Free 3 messages per day
- AI responses blending Eastern wisdom + Western logic + Sass
- Keyword-based smart replies

## 🏗️ Project Structure

```
Omni/
├── OmniApp.swift                    # App entry point
├── Shared/
│   ├── AppState.swift               # Global state management
│   └── Models/
│       └── EnergyProfile.swift      # Data models (User, Pet, DNA, Soul ID)
├── Features/
│   ├── Onboarding/
│   │   └── OnboardingView.swift     # Birthday + Pet input form
│   ├── Home/
│   │   └── HomeView.swift           # TabView navigation + Profile cards
│   ├── Retention/
│   │   └── DailyVibeView.swift      # Daily energy score + OOTD + advice
│   ├── Viral/
│   │   └── ViralViews.swift         # Pet Psychic + The Roast
│   └── Chat/
│       └── ChatView.swift           # Chat interface with message limits
```

## 🚀 Getting Started

### Prerequisites
- Xcode 14.0+
- iOS 16.0+ deployment target
- Swift 5.7+

### Installation

1. **Create New Xcode Project**:
   - Open Xcode
   - File → New → Project
   - Choose "App" template (iOS)
   - Product Name: `Omni`
   - Interface: SwiftUI
   - Language: Swift

2. **Add Source Files**:
   - Drag the `Omni/` folder structure into your Xcode project
   - Replace the auto-generated `OmniApp.swift` with our version
   - Ensure all `.swift` files are added to the target

3. **Configure Info.plist** (if using camera):
   - Add `NSPhotoLibraryUsageDescription`
   - Value: "Omni needs access to your photos to analyze your pet's energy"

4. **Build & Run**:
   ```bash
   # Via Xcode: Cmd + R
   # Or via command line (if using xcodeproj):
   xcodebuild -project Omni.xcodeproj -scheme Omni -destination 'platform=iOS Simulator,name=iPhone 15 Pro'
   ```

## 🎨 Design Philosophy

- **Vibrant Gradients**: Purple/Pink for mystical vibes, Orange/Red for roasts
- **Animated Components**: Circular progress rings, smooth transitions
- **Glassmorphism**: Semi-transparent cards with blurs
- **Emoji-First**: Heavy use of emojis for personality (🔮🔥⚡️👗)

## 🧪 Testing Flow

1. Launch app → Onboarding appears
2. Enter birthday, pet name, pet type
3. Tap "Generate Energy DNA" → Navigate to Home
4. **Daily Tab**: See energy score, OOTD, advice
5. **Viral Tab**: Try Pet Psychic (upload photo) or The Roast (select zodiac)
6. **Chat Tab**: Send 3 messages, verify 4th is blocked
7. **Profile Tab**: View Energy DNA and Soul ID cards

## 📝 Future Enhancements (Post-MVP)

- Push notifications for Daily Vibe at 8 AM
- Social sharing for viral content (UIActivityViewController)
- Premium tier: Unlimited chat, advanced readings
- Real AI integration (OpenAI API, Google Gemini)
- User authentication & cloud sync

## 🤝 Contributing

This is an MVP built for validation. For production:
- Implement proper persistence (UserDefaults → Core Data/CloudKit)
- Add analytics (Firebase, Mixpanel)
- Integrate real AI APIs
- A/B test viral hooks for conversion

## 📄 License

Proprietary - Omni Energy Management Platform

---

Built with ❤️ and ✨ for the AI Era
