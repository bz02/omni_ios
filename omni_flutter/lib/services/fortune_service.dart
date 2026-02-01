import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../core/models/element.dart';
import '../core/models/ba_gua.dart';

/// Fortune telling service using Wu Xing and Ba Gua
class FortuneService extends ChangeNotifier {
  final GenerativeModel _model;
  final GenerativeModel _imageModel;
  
  FortuneService({required String apiKey}) 
      : _model = GenerativeModel(
          model: 'gemini-2.0-flash-exp',
          apiKey: apiKey,
          generationConfig: GenerationConfig(
            temperature: 0.9,
            maxOutputTokens: 1000,
          ),
        ),
        _imageModel = GenerativeModel(
          model: 'gemini-2.0-flash-exp',
          apiKey: apiKey,
        );
  
  /// Generate personalized fortune reading
  Future<String> generateFortune({
    required DateTime birthDate,
    required ChineseElement element,
    required BaGua trigram,
  }) async {
    final age = DateTime.now().year - birthDate.year;
    
    final prompt = '''
You are a wise, compassionate fortune teller combining ancient Chinese wisdom (五行八卦) with modern spirituality.

User Profile:
- Birth Year: ${birthDate.year}
- Current Age: $age
- Element: ${element.displayName}
- Trigram: ${trigram.displayName} ${trigram.symbol} (${trigram.chineseName})

Create an uplifting, personalized fortune reading that:
1. Validates their unique energy and soul path
2. Highlights their natural strengths and gifts  
3. Offers gentle guidance for current challenges
4. Provides specific insights for:
   💕 Love & Relationships
   💼 Career & Success
   🌟 Personal Growth
   🔮 This Year's Fortune
5. Ends with an empowering affirmation

Tone: Warm, mystical, hopeful - like a wise older sister who truly sees them
Length: 350-450 words
Format: Flowing paragraphs with emoji section markers

Make it deeply personal and emotionally resonant. They should feel seen, understood, and hopeful.
''';
    
    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      return response.text ?? _getFallbackFortune(element, trigram);
    } catch (e) {
      return _getFallbackFortune(element, trigram);
    }
  }
  
  /// Generate mystical artwork prompt for Gemini image generation
  String getMysticalImagePrompt({
    required ChineseElement element,
    required BaGua trigram,
  }) {
    return '''
Create an ethereal, mystical artwork representing ${element.displayName} element energy,
featuring ${trigram.displayName} ${trigram.symbol} symbolism.

Style: Dreamy watercolor, soft pastels
Colors: Lavender, rose quartz, moonlight blue, peach glow, pearl white
Elements: Floating particles, gentle glowing aura, celestial background
Mood: Feminine, magical, peaceful, Instagram aesthetic
Details: Soft gradients, bokeh lights, delicate sparkles

The image should evoke:
- Self-discovery and inner wisdom
- Hope and gentle empowerment  
- Mystical beauty and wonder
- Emotional resonance for young women

Format: Vertical composition suitable for mobile wallpaper
''';
  }
  
  String _getFallbackFortune(ChineseElement element, BaGua trigram) {
    return '''
✨ Your Cosmic Identity ✨

${trigram.description}

With ${element.displayName} energy flowing through you, you possess ${element.description.toLowerCase()}

💕 Love & Relationships
Your ${trigram.displayName} nature attracts authentic connections. Trust in the magnetic pull of your true self.

💼 Career & Success  
${element.displayName} element gives you unique gifts. Channel your ${trigram.traits.toLowerCase()} energy into work that lights you up.

🌟 Personal Growth
This is your time to bloom. Embrace both your strength and softness - they are not opposites, but partners in your evolution.

🔮 This Year's Fortune
The universe is conspiring in your favor. Stay open to unexpected blessings and trust your intuition.

"You are exactly who you need to be, with all the magic you need within you." ✨
''';
  }
}
