import '../../../core/models/element.dart';

/// Pet Analysis Result from Gemini Vision
class PetAnalysis {
  final String archetype;
  final ChineseElement element;
  final int powerLevel;
  final String roast;

  const PetAnalysis({
    required this.archetype,
    required this.element,
    required this.powerLevel,
    required this.roast,
  });

  factory PetAnalysis.fromJson(Map<String, dynamic> json) {
    return PetAnalysis(
      archetype: json['archetype'] as String? ?? 'Unknown Beast',
      element: _parseElement(json['element'] as String?),
      powerLevel: json['power_level'] as int? ?? 50,
      roast: json['roast'] as String? ?? 'This creature defies analysis.',
    );
  }

  static ChineseElement _parseElement(String? elementStr) {
    if (elementStr == null) return ChineseElement.earth;
    final lower = elementStr.toLowerCase();
    if (lower.contains('wood')) return ChineseElement.wood;
    if (lower.contains('fire')) return ChineseElement.fire;
    if (lower.contains('earth')) return ChineseElement.earth;
    if (lower.contains('metal')) return ChineseElement.metal;
    if (lower.contains('water')) return ChineseElement.water;
    return ChineseElement.earth;
  }

  Map<String, dynamic> toJson() {
    return {
      'archetype': archetype,
      'element': element.name,
      'power_level': powerLevel,
      'roast': roast,
    };
  }
}
