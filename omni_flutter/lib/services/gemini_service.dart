import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';

enum ChatMode {
  cosmicGuide,   // Mystical + Wise
  truthSpeaker,  // Direct + Honest
  soulSister,    // Warm + Supportive
}

class GeminiService extends ChangeNotifier {
  late final GenerativeModel _model;
  late final GenerativeModel _visionModel;
  late final GenerativeModel _imageModel;
  final String apiKey;
  
  GeminiService({required this.apiKey}) {
    _model = GenerativeModel(
      model: 'gemini-3-flash-preview',
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        temperature: 0.9,
        topK: 40,
        topP: 0.95,
        maxOutputTokens: 8192,
      ),
    );
    
    _visionModel = GenerativeModel(
      model: 'gemini-3-flash-preview',
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        temperature: 1.0,
        topK: 40,
        topP: 0.95,
        maxOutputTokens: 400,
      ),
    );

    // For image generation
    _imageModel = GenerativeModel(
      model: 'gemini-2.5-flash-image',
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        temperature: 1.0,
      ),
    );
  }
  
  // CHAT with personality modes
  Future<String> chat({
    required String message,
    required Map<String, dynamic> userContext,
    ChatMode mode = ChatMode.cosmicGuide,
  }) async {
    final modePrompts = {
      ChatMode.cosmicGuide: _getCosmicGuidePrompt(message, userContext),
      ChatMode.truthSpeaker: _getTruthSpeakerPrompt(message, userContext),
      ChatMode.soulSister: _getSoulSisterPrompt(message, userContext),
    };

    try {
      final response = await _model.generateContent([Content.text(modePrompts[mode]!)]);
      return response.text ?? '✨ The cosmic signals are scrambled. Try rephrasing?';
    } catch (e) {
      return '🔮 Connection glitched. Try again!';
    }
  }

  String _getCosmicGuidePrompt(String message, Map<String, dynamic> ctx) {
    return '''
YOU ARE OMNI - The Cosmic Guide 🔮✨

Energy DNA: ${ctx['energyDNA']}
Spirit Companion: ${ctx['petName']} (${ctx['petType']})

PERSONALITY: 70% Mystical Wisdom, 30% Practical Guidance
Blend ancient mysticism with modern psychology. Channel tarot, astrology, chakras.

RESPONSE STYLE:
- Reference cosmic events, moon phases, energy shifts
- Weave in their Energy DNA naturally
- 1-2 emojis max
- End with actionable mystical practice

USER: "$message"

Your cosmic wisdom (under 150 words):
''';
  }

  String _getTruthSpeakerPrompt(String message, Map<String, dynamic> ctx) {
    return '''
YOU ARE OMNI - The Truth Speaker 💎

Energy DNA: ${ctx['energyDNA']}

PERSONALITY: 80% Direct Honesty, 20% Strategic Wisdom
No sugarcoating. Clear, honest, empowering. Think therapist + life coach.

RESPONSE STYLE:
- Skip the fluff, get to the point
- Call out patterns they can't see
- NO toxic positivity
- End with ONE hard truth they need to hear

USER: "$message"

Your honest truth (under 150 words):
''';
  }

  String _getSoulSisterPrompt(String message, Map<String, dynamic> ctx) {
    return '''
YOU ARE OMNI - Soul Sister 💕

Energy DNA: ${ctx['energyDNA']}
Pet: ${ctx['petName']}

PERSONALITY: 90% Warm Support, 10% Gentle Reality Checks  
Like their best friend who actually cares. Compassionate, validating, understanding.

RESPONSE STYLE:
- Validate their feelings first
- Use warm, supportive language
- Reference their pet for comfort
- End with gentle encouragement

USER: "$message"

Your supportive response (under 150 words):
''';
  }

  // VIRAL CONTENT GENERATOR - Customizable input
  Future<List<Map<String, String>>> generateViralContent(String userInput) async {
    final prompt = '''
YOU ARE A VIRAL CONTENT GENERATOR 🚀

USER INPUT: "$userInput"

MISSION: Transform this into 3 viral-worthy variations for social media.

OUTPUT 3 VARIATIONS (JSON array):
[
  {
    "platform": "Instagram",
    "content": "Version optimized for Instagram (emoji-heavy, aspirational)",
    "hashtags": "#trending #aesthetic"
  },
  {
    "platform": "TikTok",
    "content": "Version for TikTok (short, punchy, relatable)",
    "hashtags": "#fyp #relatable"
  },
  {
    "platform": "Twitter",
    "content": "Version for Twitter (witty, concise, shareable)",
    "hashtags": "#mood #facts"
  }
]

RULES:
- Each under 280 characters
- Use trending language
- Make it screenshot-worthy
- Target: Women 13-45
''';

    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      final text = response.text ?? '';
      final jsonArray = _parseJsonArrayFromText(text);
      
      return jsonArray.isNotEmpty 
          ? List<Map<String, String>>.from(jsonArray.map((e) => Map<String, String>.from(e)))
          : _getFallbackViralContent(userInput);
    } catch (e) {
      return _getFallbackViralContent(userInput);
    }
  }

  List<Map<String, String>> _getFallbackViralContent(String input) {
    return [
      {
        'platform': 'Instagram',
        'content': '✨ $input ✨',
        'hashtags': '#vibes #aesthetic',
      },
      {
        'platform': 'TikTok',
        'content': 'POV: $input',
        'hashtags': '#fyp #relatable',
      },
      {
        'platform': 'Twitter',
        'content': '$input (and I\'m not sorry)',
        'hashtags': '#mood',
      },
    ];
  }

  // OOTD IMAGE GENERATION
  Future<String?> generateOutfitImage({
    required String color,
    required String style,
    required int energyScore,
  }) async {
    final prompt = '''
Generate a fashion outfit illustration:
Style: $style
Main Color: $color
Vibe: ${energyScore > 80 ? 'Bold and confident' : energyScore > 50 ? 'Balanced and chic' : 'Soft and comfortable'}

Show a complete outfit laid out flat (flatlay style):
- Top
- Bottom
- Shoes
- 1-2 accessories

Aesthetic: Modern, Instagram-worthy, minimalist background
''';

    try {
      final response = await _imageModel.generateContent([Content.text(prompt)]);
      // Extract image URL or data from response
      // Note: Implementation depends on Gemini image API response format
      return response.text; // Placeholder - actual implementation needed
    } catch (e) {
      return null;
    }
  }

  // Pet Psychic (existing)
  Future<Map<String, String>> analyzePetPhoto(Uint8List imageBytes) async {
    const prompt = '''
YOU ARE THE PET PSYCHIC ORACLE 🐾🔮

Analyze this pet photo. Output JSON:
{
  "mood": "Current emotional state (specific + funny)",
  "personality": "Core archetype (creative + hilarious)",
  "roast": "The TRUTH about what they're thinking (2-3 sentences, loving but brutal)",
  "emoji": "ONE emoji"
}

Target: Women 13-45, self-deprecating humor, 85/100 sass level.
''';

    try {
      final response = await _visionModel.generateContent([
        Content.multi([
          TextPart(prompt),
          DataPart('image/jpeg', Uint8List.fromList(imageBytes)),
        ])
      ]);
      
      final json = _parseJsonFromText(response.text ?? '');
      return {
        'mood': json['mood'] ?? 'Mysteriously Unreadable',
        'personality': json['personality'] ?? 'Enigma Wrapped in Fur',
        'roast': json['roast'] ?? 'This pet is beyond my psychic abilities.',
        'emoji': json['emoji'] ?? '🌟',
      };
    } catch (e) {
      return {
        'mood': 'Cosmically Protected',
        'personality': 'Too Powerful to Read',
        'roast': 'Your pet has blocked my psychic connection. Respect. 🛡️',
        'emoji': '🔮',
      };
    }
  }

  // Roast (existing)
  Future<Map<String, String>> generateRoast(String zodiac, String energyDNA) async {
    final prompt = '''
YOU ARE THE COSMIC ROAST MASTER 🔥

Zodiac: $zodiac | Energy DNA: $energyDNA

Generate "Why You're Still Single" roast (JSON):
{
  "title": "Creative title (4-6 words)",
  "reason": "The roast (2-3 sentences, zodiac psychology)",
  "advice": "Helpful suggestion (1 sentence)",
  "emoji": "ONE emoji"
}
''';

    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      final json = _parseJsonFromText(response.text ?? '');
      return {
        'title': json['title'] ?? 'Cosmic Mystery',
        'reason': json['reason'] ?? 'The universe is still calculating.',
        'advice': json['advice'] ?? 'Be patient with yourself.',
        'emoji': json['emoji'] ?? '✨',
      };
    } catch (e) {
      return {
        'title': 'Connection Interrupted',
        'reason': 'Mercury is in retrograde.',
        'advice': 'Try again!',
        'emoji': '🌙',
      };
    }
  }

  // Daily Vibe (existing)
  Future<Map<String, dynamic>> generateDailyVibe({
    required String energyDNA,
    required DateTime date,
    String? recentMood,
  }) async {
    final dayOfWeek = _getDayName(date.weekday);
    final prompt = '''
YOU ARE THE DAILY VIBE ORACLE 🌟

Energy DNA: $energyDNA
Day: $dayOfWeek, ${date.month}/${date.day}/${date.year}

Generate personalized forecast (JSON):
{
  "energyScore": 75,
  "ootd": {
    "color": "Lavender Haze",
    "style": "Soft Mystic",
    "emoji": "🔮"
  },
  "advice": "Screenshot-worthy wisdom"
}
''';

    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      final json = _parseJsonFromText(response.text ?? '');
      return {
        'energyScore': json['energyScore'] ?? 75,
        'ootd': json['ootd'] ?? {
          'color': 'Pink',
          'style': 'Gentle Energy',
          'emoji': '💖',
        },
        'advice': json['advice'] ?? 'Today is your day. Own it. ✨',
      };
    } catch (e) {
      return {
        'energyScore': 70,
        'ootd': {
          'color': 'Soft Pink',
          'style': 'Gentle Vibes',
          'emoji': '💕',
        },
        'advice': 'The cosmos is buffering.',
      };
    }
  }

  // Helper methods
  Map<String, dynamic> _parseJsonFromText(String text) {
    try {
      final jsonStart = text.indexOf('{');
      final jsonEnd = text.lastIndexOf('}') + 1;
      if (jsonStart >= 0 && jsonEnd > jsonStart) {
        return jsonDecode(text.substring(jsonStart, jsonEnd));
      }
    } on FormatException {
      // Models wrap JSON in prose often enough that a parse failure is an
      // expected outcome, not an error. The caller supplies a fallback.
    }
    return {};
  }

  List<dynamic> _parseJsonArrayFromText(String text) {
    try {
      final jsonStart = text.indexOf('[');
      final jsonEnd = text.lastIndexOf(']') + 1;
      if (jsonStart >= 0 && jsonEnd > jsonStart) {
        return jsonDecode(text.substring(jsonStart, jsonEnd));
      }
    } on FormatException {
      // As above: unparseable output falls back rather than throwing.
    }
    return [];
  }

  String _getDayName(int weekday) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[weekday - 1];
  }

  // Daily content methods for HomeScreen
  Future<String> getDailyVibe() async {
    try {
      const prompt = '''Generate a short, inspiring daily vibe message (2-3 sentences) 
      in a mystical, cyber-taoist style. Make it uplifting and thought-provoking.''';
      
      final response = await _model.generateContent([Content.text(prompt)]);
      return response.text ?? 'The digital winds carry whispers of possibility today.';
    } catch (e) {
      return 'The cosmos aligns in mysterious ways today. Trust the process.';
    }
  }

  Future<String> getTodaysWisdom() async {
    try {
      const prompt = '''Generate a short wisdom quote (1-2 sentences) 
      blending ancient philosophy with futuristic insight. Make it profound yet accessible.''';
      
      final response = await _model.generateContent([Content.text(prompt)]);
      return response.text ?? 'In the matrix of existence, every choice ripples across time.';
    } catch (e) {
      return 'The path reveals itself to those who dare to walk it.';
    }
  }

  Future<String> getOutfitOfTheDay() async {
    try {
      const prompt = '''Generate a creative "Outfit of the Day" recommendation 
      with a cyber-punk meets spiritual aesthetic. Describe a complete look (2-3 sentences).''';
      
      final response = await _model.generateContent([Content.text(prompt)]);
      return response.text ?? 'Flowing black robes with neon accent stitching. Holographic accessories catch the light like digital prayers.';
    } catch (e) {
      return 'Layer dark minimalism with ethereal tech-wear. Let your aura do the talking.';
    }
  }
}
