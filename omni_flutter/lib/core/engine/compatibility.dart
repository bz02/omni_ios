/// Compatibility between two people, scored through both traditions.
///
/// Commercially this is the most important screen in the app: it needs two
/// birthdays, so getting a result means inviting someone. Compatibility is how
/// a divination app grows without paying for installs.
library;

import 'soul_blueprint.dart';

/// One scored component of a match.
class MatchFactor {
  const MatchFactor({
    required this.label,
    required this.points,
    required this.maxPoints,
    required this.verdict,
    required this.tradition,
  });

  final String label;
  final int points;
  final int maxPoints;
  final String verdict;

  /// 'east' or 'west' — the UI groups by tradition so the user can see the two
  /// systems arguing.
  final String tradition;
}

class CompatibilityResult {
  const CompatibilityResult({
    required this.score,
    required this.easternScore,
    required this.westernScore,
    required this.factors,
    required this.headline,
    required this.greenFlag,
    required this.redFlag,
  });

  /// 0 to 100.
  final int score;
  final int easternScore;
  final int westernScore;
  final List<MatchFactor> factors;
  final String headline;
  final String greenFlag;
  final String redFlag;

  /// How far the two traditions disagree. A wide gap is the most interesting
  /// result the app can produce, and the one people screenshot.
  int get disagreement => (easternScore - westernScore).abs();

  String get band => switch (score) {
        >= 85 => 'Rare',
        >= 70 => 'Strong',
        >= 55 => 'Workable',
        >= 40 => 'Effortful',
        _ => 'Friction',
      };

  Map<String, dynamic> toJson() => {
        'score': score,
        'band': band,
        'eastern': easternScore,
        'western': westernScore,
        'disagreement': disagreement,
        'headline': headline,
        'greenFlag': greenFlag,
        'redFlag': redFlag,
        'factors': [
          for (final f in factors)
            {
              'tradition': f.tradition,
              'label': f.label,
              'points': '${f.points}/${f.maxPoints}',
              'verdict': f.verdict,
            }
        ],
      };
}

/// Scores two blueprints against each other.
CompatibilityResult computeCompatibility(SoulBlueprint a, SoulBlueprint b) {
  final factors = <MatchFactor>[];

  // ---- Eastern: branches first, then the five phases. ----

  // Year branches: the classic zodiac match everyone already half knows.
  final branchA = a.bazi.zodiacBranch;
  final branchB = b.bazi.zodiacBranch;
  int branchPoints;
  String branchVerdict;
  if (branchB == branchA.harmonizesWith) {
    branchPoints = 30;
    branchVerdict = '${branchA.animal} and ${branchB.animal} are a six-harmony '
        'pair — the strongest pairing in the cycle.';
  } else if (branchA.trine.contains(branchB)) {
    branchPoints = 25;
    branchVerdict = '${branchA.animal} and ${branchB.animal} share a trine — '
        'easy, instinctive understanding.';
  } else if (branchB == branchA.clashesWith) {
    branchPoints = 5;
    branchVerdict = '${branchA.animal} and ${branchB.animal} sit opposite each '
        'other — the classic clash. Not fatal, but nothing here is automatic.';
  } else if (branchA == branchB) {
    branchPoints = 18;
    branchVerdict = 'Same animal. You recognize each other instantly, '
        'including the parts you would rather not see.';
  } else {
    branchPoints = 15;
    branchVerdict = '${branchA.animal} and ${branchB.animal} are neutral — '
        'neither tradition-backed pull nor push.';
  }
  factors.add(MatchFactor(
    label: 'Zodiac branches 生肖',
    points: branchPoints,
    maxPoints: 30,
    verdict: branchVerdict,
    tradition: 'east',
  ));

  // Day masters: the pair of characters a Ba Zi match is actually read from.
  final dmA = a.bazi.dayMaster;
  final dmB = b.bazi.dayMaster;
  int dayMasterPoints;
  String dayMasterVerdict;
  if (dmA.element.generates == dmB.element) {
    dayMasterPoints = 28;
    dayMasterVerdict = '${dmA.element.english} feeds ${dmB.element.english}. '
        'You give and they grow — good, as long as you are not the only one '
        'giving.';
  } else if (dmB.element.generates == dmA.element) {
    dayMasterPoints = 28;
    dayMasterVerdict = '${dmB.element.english} feeds ${dmA.element.english}. '
        'They resource you. This is the direction that quietly sustains people.';
  } else if (dmA.element == dmB.element) {
    dayMasterPoints = 20;
    dayMasterVerdict = 'Two ${dmA.element.english} day masters. Deep mutual '
        'recognition, and competition over exactly the same things.';
  } else if (dmA.element.controls == dmB.element) {
    dayMasterPoints = 10;
    dayMasterVerdict = '${dmA.element.english} restrains '
        '${dmB.element.english}. You will feel like the sensible one; they will '
        'feel managed.';
  } else {
    dayMasterPoints = 10;
    dayMasterVerdict = '${dmB.element.english} restrains '
        '${dmA.element.english}. They set the terms more often than you notice.';
  }
  factors.add(MatchFactor(
    label: 'Day masters 日主',
    points: dayMasterPoints,
    maxPoints: 30,
    verdict: dayMasterVerdict,
    tradition: 'east',
  ));

  // Does each supply what the other is short of? The most practical Ba Zi test
  // of a partnership, and the one people find most convincing.
  var remedyPoints = 0;
  final aSuppliesB = a.bazi.dominantElement == b.remedialElement;
  final bSuppliesA = b.bazi.dominantElement == a.remedialElement;
  if (aSuppliesB && bSuppliesA) {
    remedyPoints = 40;
  } else if (aSuppliesB || bSuppliesA) {
    remedyPoints = 26;
  } else {
    remedyPoints = 12;
  }
  factors.add(MatchFactor(
    label: 'Missing pieces 补缺',
    points: remedyPoints,
    maxPoints: 40,
    verdict: switch ((aSuppliesB, bSuppliesA)) {
      (true, true) =>
        'You each carry a surplus of exactly the phase the other lacks. This is '
            'the configuration Chinese practice actually calls a good match.',
      (true, false) => 'You supply the '
          '${b.remedialElement.english} they are short of. The traffic runs one '
          'way.',
      (false, true) => 'They supply the '
          '${a.remedialElement.english} you are short of. The traffic runs one '
          'way, toward you.',
      _ => 'Neither of you fills the other gap. You will have to build what you '
          'need rather than receive it.',
    },
    tradition: 'east',
  ));

  // The three eastern factors are scaled to sum to 100.
  final easternScore = branchPoints + dayMasterPoints + remedyPoints;

  // ---- Western: Sun, Moon and element temperament. ----

  final sunAspect =
      aspectBetween(a.western.sun.longitude, b.western.sun.longitude);
  final sunPoints = switch (sunAspect?.aspect) {
    Aspect.trine => 34,
    Aspect.conjunction => 30,
    Aspect.sextile => 26,
    Aspect.opposition => 20,
    Aspect.square => 12,
    null => 18,
  };
  factors.add(MatchFactor(
    label: 'Sun to Sun',
    points: sunPoints,
    maxPoints: 34,
    verdict: sunAspect == null
        ? '${a.western.sun.sign.label} and ${b.western.sun.sign.label} form no '
            'major aspect. You are neither drawn together nor pushed apart by '
            'temperament; whatever happens, you will have to do on purpose.'
        : '${a.western.sun.sign.label} '
            '${sunAspect.aspect.label.toLowerCase()} '
            '${b.western.sun.sign.label} — ${sunAspect.aspect.gist}, '
            '${sunAspect.orb.toStringAsFixed(1)}° from exact.',
    tradition: 'west',
  ));

  var moonPoints = 20;
  var moonVerdict = 'One of you has no birth time on file, so the Moons are '
      'left out rather than guessed. Add a birth time for the emotional read.';
  final moonA = a.western.moon;
  final moonB = b.western.moon;
  if (moonA != null && moonB != null) {
    final moonAspect = aspectBetween(moonA.longitude, moonB.longitude);
    moonPoints = switch (moonAspect?.aspect) {
      Aspect.trine => 33,
      Aspect.conjunction => 30,
      Aspect.sextile => 25,
      Aspect.opposition => 18,
      Aspect.square => 10,
      null => 16,
    };
    moonVerdict = moonAspect == null
        ? '${moonA.sign.label} Moon and ${moonB.sign.label} Moon do not aspect '
            'each other. You process feeling on separate tracks.'
        : '${moonA.sign.label} Moon '
            '${moonAspect.aspect.label.toLowerCase()} ${moonB.sign.label} Moon '
            '— this is the one that decides whether living together works.';
  }
  factors.add(MatchFactor(
    label: 'Moon to Moon',
    points: moonPoints,
    maxPoints: 33,
    verdict: moonVerdict,
    tradition: 'west',
  ));

  final elementA = a.western.dominantElement;
  final elementB = b.western.dominantElement;
  final elementPoints = _westernElementPoints(elementA, elementB);
  factors.add(MatchFactor(
    label: 'Elemental temperament',
    points: elementPoints,
    maxPoints: 33,
    verdict: '${elementA.label} ${elementA.emoji} with ${elementB.label} '
        '${elementB.emoji} — ${_elementVerdict(elementA, elementB)}',
    tradition: 'west',
  ));

  final westernScore = sunPoints + moonPoints + elementPoints;

  // The two traditions are weighted equally. Neither gets to be the tiebreak,
  // because the disagreement between them is the product.
  final total = ((easternScore + westernScore) / 2).round().clamp(0, 100);

  final best = factors.reduce(
      (x, y) => x.points / x.maxPoints >= y.points / y.maxPoints ? x : y);
  final worst = factors.reduce(
      (x, y) => x.points / x.maxPoints <= y.points / y.maxPoints ? x : y);

  return CompatibilityResult(
    score: total,
    easternScore: easternScore,
    westernScore: westernScore,
    factors: factors,
    headline: _headline(total, easternScore, westernScore),
    greenFlag: best.verdict,
    redFlag: worst.verdict,
  );
}

int _westernElementPoints(WesternElement a, WesternElement b) {
  if (a == b) return 28;
  const compatible = {
    (WesternElement.fire, WesternElement.air),
    (WesternElement.air, WesternElement.fire),
    (WesternElement.earth, WesternElement.water),
    (WesternElement.water, WesternElement.earth),
  };
  if (compatible.contains((a, b))) return 33;
  const hard = {
    (WesternElement.fire, WesternElement.water),
    (WesternElement.water, WesternElement.fire),
    (WesternElement.earth, WesternElement.air),
    (WesternElement.air, WesternElement.earth),
  };
  if (hard.contains((a, b))) return 14;
  return 22;
}

String _elementVerdict(WesternElement a, WesternElement b) {
  if (a == b) return 'the same weather, which is comfortable and can get stale.';
  const pairs = {
    (WesternElement.fire, WesternElement.air): 'air feeds fire. Fast, loud, and '
        'nobody is bored.',
    (WesternElement.air, WesternElement.fire): 'air feeds fire. Fast, loud, and '
        'nobody is bored.',
    (WesternElement.earth, WesternElement.water): 'water shapes earth. Slow, '
        'durable, quietly deep.',
    (WesternElement.water, WesternElement.earth): 'water shapes earth. Slow, '
        'durable, quietly deep.',
    (WesternElement.fire, WesternElement.water): 'the hardest pairing there is. '
        'Real, but neither of you gets to stay as you are.',
    (WesternElement.water, WesternElement.fire): 'the hardest pairing there is. '
        'Real, but neither of you gets to stay as you are.',
    (WesternElement.earth, WesternElement.air): 'air moves, earth stays. You '
        'will argue about plans for the rest of your lives.',
    (WesternElement.air, WesternElement.earth): 'air moves, earth stays. You '
        'will argue about plans for the rest of your lives.',
  };
  return pairs[(a, b)] ?? 'workable with attention.';
}

String _headline(int total, int east, int west) {
  final gap = (east - west).abs();
  if (gap >= 25) {
    final favoured = east > west ? 'Chinese' : 'Western';
    final other = east > west ? 'Western' : 'Chinese';
    return 'The two traditions disagree about you. $favoured practice rates '
        'this well above what $other astrology sees — worth reading both '
        'columns before you decide anything.';
  }
  return switch (total) {
    >= 85 => 'Both systems rate this highly, which is rarer than it sounds.',
    >= 70 => 'Strong on both readings. The work here is maintenance, not repair.',
    >= 55 => 'Workable. Nothing is automatic, and nothing is against you.',
    >= 40 => 'This one takes deliberate effort from both sides.',
    _ => 'High friction on both readings. Real, sometimes. Easy, no.',
  };
}
