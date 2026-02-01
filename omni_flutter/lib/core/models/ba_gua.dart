/// Ba Gua (八卦) - Eight Trigrams model
/// Each trigram represents cosmic forces and personality traits
enum BaGua {
  qian,  // ☰ 乾 Heaven - Creative, leadership
  kun,   // ☷ 坤 Earth - Receptive, nurturing
  zhen,  // ☳ 震 Thunder - Arousing, bold
  xun,   // ☴ 巽 Wind - Gentle, flexible
  kan,   // ☵ 坎 Water - Deep, mysterious
  li,    // ☲ 離 Fire - Clinging, passionate
  gen,   // ☶ 艮 Mountain - Stillness, contemplative
  dui,   // ☱ 兌 Lake - Joyful, expressive
}

extension BaGuaExtension on BaGua {
  /// Unicode trigram symbol
  String get symbol {
    switch (this) {
      case BaGua.qian:
        return '☰';
      case BaGua.kun:
        return '☷';
      case BaGua.zhen:
        return '☳';
      case BaGua.xun:
        return '☴';
      case BaGua.kan:
        return '☵';
      case BaGua.li:
        return '☲';
      case BaGua.gen:
        return '☶';
      case BaGua.dui:
        return '☱';
    }
  }
  
  /// Chinese name
  String get chineseName {
    switch (this) {
      case BaGua.qian:
        return '乾';
      case BaGua.kun:
        return '坤';
      case BaGua.zhen:
        return '震';
      case BaGua.xun:
        return '巽';
      case BaGua.kan:
        return '坎';
      case BaGua.li:
        return '離';
      case BaGua.gen:
        return '艮';
      case BaGua.dui:
        return '兌';
    }
  }
  
  /// English name
  String get displayName {
    switch (this) {
      case BaGua.qian:
        return 'Heaven';
      case BaGua.kun:
        return 'Earth';
      case BaGua.zhen:
        return 'Thunder';
      case BaGua.xun:
        return 'Wind';
      case BaGua.kan:
        return 'Water';
      case BaGua.li:
        return 'Fire';
      case BaGua.gen:
        return 'Mountain';
      case BaGua.dui:
        return 'Lake';
    }
  }
  
  /// Core personality traits
  String get traits {
    switch (this) {
      case BaGua.qian:
        return 'Creative, Strong, Leadership';
      case BaGua.kun:
        return 'Receptive, Nurturing, Supportive';
      case BaGua.zhen:
        return 'Bold, Dynamic, Initiating';
      case BaGua.xun:
        return 'Gentle, Flexible, Penetrating';
      case BaGua.kan:
        return 'Deep, Mysterious, Flowing';
      case BaGua.li:
        return 'Passionate, Bright, Clinging';
      case BaGua.gen:
        return 'Still, Contemplative, Grounded';
      case BaGua.dui:
        return 'Joyful, Expressive, Social';
    }
  }
  
  /// Life aspect this trigram governs
  String get lifeAspect {
    switch (this) {
      case BaGua.qian:
        return 'Career & Ambition';
      case BaGua.kun:
        return 'Relationships & Family';
      case BaGua.zhen:
        return 'Action & Movement';
      case BaGua.xun:
        return 'Wealth & Influence';
      case BaGua.kan:
        return 'Wisdom & Intuition';
      case BaGua.li:
        return 'Recognition & Fame';
      case BaGua.gen:
        return 'Knowledge & Spirituality';
      case BaGua.dui:
        return 'Joy & Creativity';
    }
  }
  
  /// Detailed description for fortune reading
  String get description {
    switch (this) {
      case BaGua.qian:
        return 'You carry the energy of Heaven - pure creative force. Natural born leaders are drawn to you, and you have the strength to manifest your visions into reality.';
      case BaGua.kun:
        return 'You embody the nurturing energy of Earth. Your capacity for understanding and supporting others is your greatest gift. You create safe spaces where people can grow.';
      case BaGua.zhen:
        return 'Thunder energy flows through you - sudden, powerful, awakening. You\'re not afraid to shake things up and initiate bold new beginnings.';
      case BaGua.xun:
        return 'Like Wind, you move gently but persistently. Your subtle influence penetrates deeply, and your flexibility allows you to adapt to any situation gracefully.';
      case BaGua.kan:
        return 'You possess the mysterious depth of Water. Your intuition runs deep, and you understand the hidden currents beneath life\'s surface. Trust your inner knowing.';
      case BaGua.li:
        return 'Fire burns bright within you - passionate, illuminating, magnetic. You naturally attract others and have the gift of bringing light to darkness.';
      case BaGua.gen:
        return 'Mountain energy gives you stillness and contemplation. You find power in quiet reflection and possess wisdom that comes from looking within.';
      case BaGua.dui:
        return 'Lake energy makes you joyful and  expressive. You bring pleasure and laughter wherever you go, and your openness invites authentic connection.';
    }
  }
  
  /// Calculate trigram from birth month and day
  static BaGua fromBirthDate(int month, int day) {
    // Simplified calculation based on month + day modulo 8
    final index = (month + day) % 8;
    return BaGua.values[index];
  }
}
