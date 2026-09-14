/// The daily reading: energy score, what the day favors and what it does not,
/// lucky color, number and direction.
///
/// The score is derived, not rolled. Two properties matter commercially:
///
///   * **Stable.** Opening the app three times on one day gives one answer. A
///     user who catches a fortune app re-rolling its own numbers never trusts
///     it again, and never subscribes.
///   * **Explainable.** Every point traces back to a named relationship
///     between the day's pillar and the user's chart, so the app can show its
///     working. That is the whole trust argument against a random-number
///     competitor.
library;

import 'soul_blueprint.dart';

/// A single contribution to the day's score, kept so the UI can show why.
class FortuneFactor {
  const FortuneFactor(this.label, this.points, this.detail);
  final String label;
  final int points;
  final String detail;

  String get signed => points >= 0 ? '+$points' : '$points';
}

class DailyFortune {
  const DailyFortune({
    required this.date,
    required this.score,
    required this.dayPillar,
    required this.factors,
    required this.favorable,
    required this.unfavorable,
    required this.luckyColor,
    required this.luckyNumber,
    required this.luckyDirection,
    required this.outfitNote,
    required this.headline,
  });

  final DateTime date;

  /// 5 to 99. Never 0 and never 100: an absolute verdict reads as a gimmick.
  final int score;

  final Pillar dayPillar;
  final List<FortuneFactor> factors;

  /// The almanac's yi and ji — what the day supports and what it resists.
  final List<String> favorable;
  final List<String> unfavorable;

  final String luckyColor;
  final int luckyNumber;
  final String luckyDirection;
  final String outfitNote;
  final String headline;

  String get band => switch (score) {
        >= 85 => 'Exceptional',
        >= 70 => 'Strong',
        >= 55 => 'Steady',
        >= 40 => 'Mixed',
        >= 25 => 'Low',
        _ => 'Difficult',
      };

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String().split('T').first,
        'score': score,
        'band': band,
        'dayPillar': dayPillar.chinese,
        'headline': headline,
        'favorable': favorable,
        'unfavorable': unfavorable,
        'luckyColor': luckyColor,
        'luckyNumber': luckyNumber,
        'luckyDirection': luckyDirection,
        'outfitNote': outfitNote,
        'why': [
          for (final f in factors) '${f.signed} ${f.label} — ${f.detail}',
        ],
      };
}

/// What each ten god relationship says the day is good and bad for. This is the
/// almanac's yi/ji reframed for someone who has never seen one.
const Map<TenGod, ({List<String> yes, List<String> no, String headline})>
    _tenGodGuidance = {
  TenGod.friend: (
    yes: ['team work', 'asking peers for help', 'training', 'anything shared'],
    no: ['splitting a bill unevenly', 'going it alone on something big'],
    headline: 'A day that works better with other people in it.',
  ),
  TenGod.robWealth: (
    yes: ['competing', 'negotiating hard', 'physical effort'],
    no: ['lending money', 'joint purchases', 'leaving valuables around'],
    headline: 'Competitive energy. Keep your resources close.',
  ),
  TenGod.eatingGod: (
    yes: ['making something', 'cooking', 'good food', 'easy socialising'],
    no: ['overindulging', 'saying yes to everything'],
    headline: 'Output flows easily today. Make something.',
  ),
  TenGod.hurtingOfficer: (
    yes: ['performing', 'pitching', 'saying the unsaid thing', 'creative risk'],
    no: ['arguing with your boss', 'formal complaints', 'sarcasm in writing'],
    headline: 'Sharp and expressive. Aim it at work, not at people.',
  ),
  TenGod.directWealth: (
    yes: ['money admin', 'invoicing', 'signing', 'steady earning'],
    no: ['gambling', 'impulse buys'],
    headline: 'Money behaves today. Do the boring financial thing.',
  ),
  TenGod.indirectWealth: (
    yes: ['side income', 'networking', 'opportunistic moves', 'travel'],
    no: ['betting the main thing on a hunch'],
    headline: 'Opportunity is loose in the air. Chase one, not five.',
  ),
  TenGod.directOfficer: (
    yes: ['interviews', 'reporting up', 'paperwork', 'anything official'],
    no: ['bending a rule', 'skipping the process'],
    headline: 'Structure favors you. Play it straight and it pays.',
  ),
  TenGod.sevenKillings: (
    yes: ['hard decisions', 'confrontation you have prepared for', 'exercise'],
    no: ['picking a fight', 'signing under pressure', 'driving tired'],
    headline: 'Pressure day. Meet it deliberately or it meets you.',
  ),
  TenGod.directResource: (
    yes: ['studying', 'resting', 'asking a mentor', 'medical appointments'],
    no: ['pushing through exhaustion', 'refusing help'],
    headline: 'Support is available. Take it instead of grinding.',
  ),
  TenGod.indirectResource: (
    yes: ['research', 'solo work', 'strange ideas', 'planning'],
    no: ['overthinking a message before sending it', 'isolating'],
    headline: 'Inward and analytical. Good for thinking, bad for brooding.',
  ),
};

/// Computes the fortune for [date] against a blueprint.
///
/// [date] is taken as a local calendar date; only the date part is used.
DailyFortune computeDailyFortune({
  required SoulBlueprint blueprint,
  required DateTime date,
  double utcOffsetHours = 0,
}) {
  final day = DateTime(date.year, date.month, date.day);

  // The day's own pillar, computed the same way as a birth chart's.
  final dayChart = computeBaziChart(
    birthLocal: DateTime(day.year, day.month, day.day, 12),
    utcOffsetHours: utcOffsetHours,
    hourIsKnown: false,
  );
  final dayPillar = dayChart.day;
  final natal = blueprint.bazi;

  final factors = <FortuneFactor>[];
  var score = 50;

  // 1. How the day's stem relates to the user's day master.
  final relation = tenGodFor(natal.dayMaster, dayPillar.stem);
  final relationPoints = switch (relation) {
    TenGod.directResource => 10,
    TenGod.indirectResource => 6,
    TenGod.eatingGod => 8,
    TenGod.hurtingOfficer => -2,
    TenGod.directWealth => 7,
    TenGod.indirectWealth => 5,
    TenGod.directOfficer => 3,
    TenGod.sevenKillings => -8,
    TenGod.friend => 5,
    TenGod.robWealth => -3,
  };
  score += relationPoints;
  factors.add(FortuneFactor(
    '${relation.chinese} ${relation.english}',
    relationPoints,
    "today's stem ${dayPillar.stem.chinese} against your day master "
        '${natal.dayMaster.chinese}',
  ));

  // 2. How the day's branch sits with the user's day branch.
  final natalBranch = natal.day.branch;
  final dayBranch = dayPillar.branch;
  int branchPoints;
  String branchLabel;
  if (dayBranch == natalBranch.clashesWith) {
    branchPoints = -15;
    branchLabel = 'Clash 六冲';
  } else if (dayBranch == natalBranch.harmonizesWith) {
    branchPoints = 12;
    branchLabel = 'Harmony 六合';
  } else if (natalBranch.trine.contains(dayBranch)) {
    branchPoints = 8;
    branchLabel = 'Trine 三合';
  } else if (dayBranch == natalBranch) {
    branchPoints = 3;
    branchLabel = 'Same branch';
  } else {
    branchPoints = 0;
    branchLabel = 'Neutral branch';
  }
  score += branchPoints;
  factors.add(FortuneFactor(
    branchLabel,
    branchPoints,
    "today's branch ${dayBranch.chinese} against your day branch "
        '${natalBranch.chinese}',
  ));

  // 3. Does the day supply the element the chart is short of?
  final needed = blueprint.remedialElement;
  if (dayPillar.stem.element == needed || dayBranch.element == needed) {
    score += 8;
    factors.add(FortuneFactor(
      'Feeds your ${needed.english}',
      8,
      'the day carries ${needed.chinese} ${needed.english}, which your chart '
          'runs short of',
    ));
  } else if (dayPillar.stem.element == needed.controlledBy) {
    score -= 5;
    factors.add(FortuneFactor(
      'Drains your ${needed.english}',
      -5,
      '${dayPillar.stem.element.chinese} restrains the phase you most need',
    ));
  }

  // 4. Western transit: where today's Sun sits against the natal Sun.
  final transitSun = computeWesternChart(
    birthLocal: DateTime(day.year, day.month, day.day, 12),
    utcOffsetHours: utcOffsetHours,
    hourIsKnown: false,
  ).sun;
  final aspect =
      aspectBetween(transitSun.longitude, blueprint.western.sun.longitude);
  if (aspect != null) {
    final aspectPoints = switch (aspect.aspect) {
      Aspect.conjunction => 6,
      Aspect.trine => 8,
      Aspect.sextile => 4,
      Aspect.square => -6,
      Aspect.opposition => -4,
    };
    score += aspectPoints;
    factors.add(FortuneFactor(
      'Sun ${aspect.aspect.label.toLowerCase()} natal Sun',
      aspectPoints,
      'transiting Sun in ${transitSun.sign.label}, '
          '${aspect.orb.toStringAsFixed(1)}° from exact',
    ));
  }

  // 5. A small deterministic spread so scores are not all clustered. Derived
  // from the chart and the date, so it is the same every time it is computed.
  final jitter = (_stableHash('${blueprint.birth.fingerprint}|'
              '${day.toIso8601String()}') %
          9) -
      4;
  score += jitter;

  final guidance = _tenGodGuidance[relation]!;
  final affinity = blueprint.affinity;
  final clamped = score.clamp(5, 99);

  // Pick from the lucky lists deterministically rather than at random.
  final pick = _stableHash(day.toIso8601String());
  final luckyColor = affinity.colors[pick % affinity.colors.length];
  final luckyNumber = affinity.numbers[pick % affinity.numbers.length];

  return DailyFortune(
    date: day,
    score: clamped,
    dayPillar: dayPillar,
    factors: factors,
    favorable: guidance.yes,
    unfavorable: [
      ...guidance.no,
      if (branchPoints <= -15)
        'signing anything today — your branch is in clash',
    ],
    luckyColor: luckyColor,
    luckyNumber: luckyNumber,
    luckyDirection: affinity.direction,
    outfitNote: _outfitNote(clamped, luckyColor, needed),
    headline: guidance.headline,
  );
}

String _outfitNote(int score, String color, WuXing needed) {
  final anchor = 'a $color piece somewhere visible';
  if (score >= 80) {
    return 'Dress like you expect to be seen — $anchor, and lean into it.';
  }
  if (score >= 60) {
    return 'Clean lines, one strong choice. $anchor.';
  }
  if (score >= 40) {
    return 'Comfort first, but keep $anchor to hold the '
        '${needed.english.toLowerCase()} in.';
  }
  return 'Armour, not display. Dark base, $anchor, nothing that invites '
      'attention.';
}

/// A small stable hash. `String.hashCode` is not guaranteed to be consistent
/// across runs or platforms, and a fortune that changes when the app restarts
/// would defeat the point.
int _stableHash(String input) {
  var hash = 2166136261;
  for (final unit in input.codeUnits) {
    hash ^= unit;
    hash = (hash * 16777619) & 0x7fffffff;
  }
  return hash;
}
