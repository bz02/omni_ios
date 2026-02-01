/// Chinese Five Elements
enum ChineseElement {
  wood,
  fire,
  earth,
  metal,
  water;

  String get displayName {
    switch (this) {
      case ChineseElement.wood:
        return '木 Wood';
      case ChineseElement.fire:
        return '火 Fire';
      case ChineseElement.earth:
        return '土 Earth';
      case ChineseElement.metal:
        return '金 Metal';
      case ChineseElement.water:
        return '水 Water';
    }
  }

  String get description {
    switch (this) {
      case ChineseElement.wood:
        return 'Growth, flexibility, creativity';
      case ChineseElement.fire:
        return 'Energy, passion, transformation';
      case ChineseElement.earth:
        return 'Stability, nourishment, grounding';
      case ChineseElement.metal:
        return 'Precision, strength, structure';
      case ChineseElement.water:
        return 'Flow, wisdom, adaptability';
    }
  }

  /// Get element from birth year (Chinese Zodiac)
  static ChineseElement getElementFromYear(int year) {
    final digit = year % 10;
    switch (digit) {
      case 0:
      case 1:
        return ChineseElement.metal;
      case 2:
      case 3:
        return ChineseElement.water;
      case 4:
      case 5:
        return ChineseElement.wood;
      case 6:
      case 7:
        return ChineseElement.fire;
      case 8:
      case 9:
        return ChineseElement.earth;
      default:
        return ChineseElement.earth;
    }
  }
}
