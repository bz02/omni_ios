import '../../../core/models/element.dart';

/// Affinity Calculator for Element Compatibility
/// Based on Wu Xing (Five Elements) cycle
class AffinityCalculator {
  static String calculateAffinity(ChineseElement userElement, ChineseElement petElement) {
    final key = (userElement, petElement);
    
    return _affinityMap[key] ?? _defaultAffinities(userElement, petElement);
  }

  static const Map<(ChineseElement, ChineseElement), String> _affinityMap = {
    // Generating Cycle (Productive)
    (ChineseElement.wood, ChineseElement.fire): 
        "The Provider → You feed their chaos with endless energy. They're high maintenance but worth it.",
    
    (ChineseElement.fire, ChineseElement.earth): 
        "The Creator → Your passion solidifies their stability. Perfect team.",
    
    (ChineseElement.earth, ChineseElement.metal): 
        "The Forger → Your grounding shapes their precision. Natural partnership.",
    
    (ChineseElement.metal, ChineseElement.water): 
        "The Source → Your structure flows into their adaptability. Magical combo.",
    
    (ChineseElement.water, ChineseElement.wood): 
        "The Nurturer → Your wisdom grows their creativity. Pure harmony.",
    
    // Overcoming Cycle (Destructive)
    (ChineseElement.wood, ChineseElement.earth): 
        "The Drain → You extract all their resources. Emotionally exhausting for both.",
    
    (ChineseElement.earth, ChineseElement.water): 
        "The Dam → You block their flow. Frustration levels: maximum.",
    
    (ChineseElement.water, ChineseElement.fire): 
        "The Wet Blanket → You literally extinguish their fun. Party killer.",
    
    (ChineseElement.fire, ChineseElement.metal): 
        "The Melter → You break down their boundaries. Intense but unstable.",
    
    (ChineseElement.metal, ChineseElement.wood): 
        "The Disciplinarian → You chop down their creativity. Strict parent vibes.",
    
    // Same Element
    (ChineseElement.wood, ChineseElement.wood): 
        "Twin Flames → Too much growth energy. You'll compete for sunlight.",
    
    (ChineseElement.fire, ChineseElement.fire): 
        "Double Trouble → Combined chaos level: catastrophic. Amazing or disaster, no in-between.",
    
    (ChineseElement.earth, ChineseElement.earth): 
        "Rock Solid → So stable it's boring. You'll never fight but also never surprise each other.",
    
    (ChineseElement.metal, ChineseElement.metal): 
        "The Robots → Peak efficiency, zero spontaneity. Perfectly programmed.",
    
    (ChineseElement.water, ChineseElement.water): 
        "The Deep End  → Emotional ocean. You'll drown in feelings together.",
  };

  static String _defaultAffinities(ChineseElement userElement, ChineseElement petElement) {
    return "The Unknowable → This combination defies ancient wisdom. Proceed with caution.";
  }
}
