import 'dart:convert';
import 'dart:typed_data';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/pet_analysis.dart';
import '../../../core/models/element.dart';
import '../../../config/app_config.dart';

part 'scanner_provider.g.dart';

@riverpod
class ScannerController extends _$ScannerController {
  late final GenerativeModel _visionModel;

  @override
  PetAnalysis? build() {
    _visionModel = GenerativeModel(
      model: 'gemini-3-flash-preview',
      apiKey: AppConfig.geminiApiKey,
      generationConfig: GenerationConfig(
        temperature: 1.0,
        maxOutputTokens: 500,
      ),
    );
    return null;
  }

  Future<void> analyzePet(Uint8List imageBytes) async {
    state = null; // Reset state

    final prompt = '''
You are an ancient Taoist Mystic analyzing a divine beast.

Examine this creature and determine:
1. Its Spiritual Archetype (e.g., "The Void Guardian", "Chaos General", "Silent Philosopher")
2. Its Element (Wood, Fire, Earth, Metal, or Water)
3. Its Power Level (1-100)
4. A sarcastic Roast about its personality

Return ONLY valid JSON in this exact format:
{
  "archetype": "The [Mystical Title]",
  "element": "[Wood/Fire/Earth/Metal/Water]",
  "power_level": 75,
  "roast": "Your witty observation here"
}
''';

    try {
      final response = await _visionModel.generateContent([
        Content.multi([
          TextPart(prompt),
          DataPart('image/jpeg', imageBytes),
        ])
      ]);

      final text = response.text ?? '';
      final json = _parseJsonFromText(text);
      
      state = PetAnalysis.fromJson(json);
    } catch (e) {
      // Fallback result on error
      state = PetAnalysis(
        archetype: 'The Unknowable',
        element: ChineseElement.water,
        powerLevel: 42,
        roast: 'This creature has blocked my psychic connection. Impressive.',
      );
    }
  }

  Map<String, dynamic> _parseJsonFromText(String text) {
    try {
      final jsonStart = text.indexOf('{');
      final jsonEnd = text.lastIndexOf('}') + 1;
      if (jsonStart >= 0 && jsonEnd > jsonStart) {
        final jsonStr = text.substring(jsonStart, jsonEnd);
        return jsonDecode(jsonStr) as Map<String, dynamic>;
      }
    } catch (e) {
      // Parse error
    }
    return {};
  }

  void reset() {
    state = null;
  }
}
