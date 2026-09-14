/// Luck pillars (大运) and the annual forecast (流年).
///
/// This is the headline premium content in Chinese practice, and the reason a
/// subscription is worth more than a daily score: it says which decade of your
/// life you are standing in and what the coming year does to it.
///
/// Two things have to be right or the whole thing is decoration:
///
///   1. **Direction.** The cycle runs forward or backward depending on the
///      polarity of the birth year together with the person's own, so half of
///      all charts get the opposite sequence.
///   2. **The starting age.** It is not a birthday. It is the distance from
///      the birth moment to a solar term, converted at three days to the year
///      — so it needs the real term instants, which the ephemeris already
///      gives us.
library;

import 'astro_math.dart';
import 'soul_blueprint.dart';

/// Which polarity a person is read as for the direction of the cycle.
///
/// Classical texts frame this as male and female. What the rule actually uses
/// is a yang/yin pairing against the birth year, so the engine takes the
/// polarity directly and lets the interface decide how to ask — including not
/// asking, and showing both directions instead.
enum ChartPolarity {
  yang('Yang', '阳'),
  yin('Yin', '阴');

  const ChartPolarity(this.english, this.chinese);
  final String english;
  final String chinese;
}

/// Yang year with yang polarity, or yin with yin, runs forward. The mixed
/// cases run backward.
bool luckRunsForward({
  required bool yearStemIsYang,
  required ChartPolarity polarity,
}) =>
    yearStemIsYang == (polarity == ChartPolarity.yang);

/// One ten-year period.
class LuckPillar {
  const LuckPillar({
    required this.pillar,
    required this.startAgeMonths,
    required this.index,
    required this.tenGod,
    required this.startYear,
  });

  final Pillar pillar;

  /// Age in whole months when this period opens. Months matter: a cycle that
  /// starts at 7 years 4 months is normal, and rounding it to 7 moves every
  /// subsequent decade.
  final int startAgeMonths;

  /// 0 for the first period after the starting age.
  final int index;

  /// How this period's stem relates to the day master — the one-word summary
  /// of what the decade is about.
  final TenGod tenGod;

  /// Calendar year the period opens in.
  final int startYear;

  int get startAgeYears => startAgeMonths ~/ 12;
  int get endAgeYears => startAgeYears + 10;
  int get endYear => startYear + 10;

  String get ageRange => '$startAgeYears–$endAgeYears';

  bool containsAge(int ageYears) =>
      ageYears >= startAgeYears && ageYears < endAgeYears;

  bool containsYear(int year) => year >= startYear && year < endYear;

  Map<String, dynamic> toJson() => {
        'pillar': pillar.chinese,
        'ages': ageRange,
        'years': '$startYear–$endYear',
        'tenGod': '${tenGod.chinese} ${tenGod.english}',
        'element': pillar.stem.element.english,
      };
}

/// The whole cycle for one chart.
class LuckCycle {
  const LuckCycle({
    required this.pillars,
    required this.runsForward,
    required this.startAgeMonths,
    required this.polarity,
    required this.anchorTerm,
  });

  final List<LuckPillar> pillars;
  final bool runsForward;

  /// Age at which the first period opens.
  final int startAgeMonths;

  final ChartPolarity polarity;

  /// The solar term the starting age was measured against, so the reading can
  /// show its working rather than asserting a number.
  final SolarTerm anchorTerm;

  int get startAgeYears => startAgeMonths ~/ 12;
  int get startAgeRemainderMonths => startAgeMonths % 12;

  String get startDescription => startAgeRemainderMonths == 0
      ? '$startAgeYears'
      : '$startAgeYears years $startAgeRemainderMonths months';

  /// The period covering [age], or null before the cycle opens.
  LuckPillar? pillarForAge(int age) {
    for (final pillar in pillars) {
      if (pillar.containsAge(age)) return pillar;
    }
    return null;
  }

  LuckPillar? pillarForYear(int year) {
    for (final pillar in pillars) {
      if (pillar.containsYear(year)) return pillar;
    }
    return null;
  }

  Map<String, dynamic> toJson() => {
        'direction': runsForward ? 'forward' : 'reverse',
        'polarity': polarity.english,
        'startsAt': startDescription,
        'measuredFrom': '${anchorTerm.chinese} ${anchorTerm.english}',
        'pillars': [for (final p in pillars) p.toJson()],
      };
}

/// Computes the luck cycle.
///
/// [count] periods are returned, which at ten years each is a whole life at
/// nine or ten.
LuckCycle computeLuckCycle({
  required BirthData birth,
  required BaziChart chart,
  required ChartPolarity polarity,
  int count = 9,
}) {
  final forward = luckRunsForward(
    yearStemIsYang: chart.year.stem.isYang,
    polarity: polarity,
  );

  final utc = _toUtc(birth);
  final (anchor, days) = _distanceToAnchorTerm(utc, forward);

  // Three days of real time stand for one year of life, so one day is exactly
  // four months. Working in months keeps that exact instead of carrying a
  // fraction of a year around.
  final startAgeMonths = (days * 4).round().clamp(0, 120);

  final monthIndex = chart.month.sexagenaryIndex;
  final pillars = <LuckPillar>[];
  for (var i = 0; i < count; i++) {
    final step = forward ? i + 1 : -(i + 1);
    final index = ((monthIndex + step) % 60 + 60) % 60;
    final pillar = Pillar(
      HeavenlyStem.values[index % 10],
      EarthlyBranch.values[index % 12],
    );
    final startMonths = startAgeMonths + i * 120;
    pillars.add(LuckPillar(
      pillar: pillar,
      startAgeMonths: startMonths,
      index: i,
      tenGod: tenGodFor(chart.dayMaster, pillar.stem),
      startYear: birth.localDateTime.year + startMonths ~/ 12,
    ));
  }

  return LuckCycle(
    pillars: pillars,
    runsForward: forward,
    startAgeMonths: startAgeMonths,
    polarity: polarity,
    anchorTerm: anchor,
  );
}

/// Days between the birth and the solar term the cycle is measured against:
/// the next one when the cycle runs forward, the one just passed when it runs
/// backward.
(SolarTerm, double) _distanceToAnchorTerm(DateTime utc, bool forward) {
  final lambda = solarLongitude(julianDay(utc));
  final currentIndex = (((lambda - 315.0) % 360.0 + 360.0) % 360.0) ~/ 30;

  if (forward) {
    final next = SolarTerm.values[(currentIndex + 1) % 12];
    final instant = solveSolarLongitude(
      next.solarLongitudeDegrees,
      afterUtc: utc,
      searchDays: 40,
    )!;
    return (next, instant.difference(utc).inMinutes / 1440.0);
  }

  final current = SolarTerm.values[currentIndex];
  // The current term opened at most about 31 days ago.
  final instant = solveSolarLongitude(
    current.solarLongitudeDegrees,
    afterUtc: utc.subtract(const Duration(days: 40)),
    searchDays: 45,
  )!;
  return (current, utc.difference(instant).inMinutes / 1440.0);
}

DateTime _toUtc(BirthData birth) => DateTime.utc(
      birth.localDateTime.year,
      birth.localDateTime.month,
      birth.localDateTime.day,
      birth.timeIsKnown ? birth.localDateTime.hour : 12,
      birth.timeIsKnown ? birth.localDateTime.minute : 0,
    ).subtract(
        Duration(milliseconds: (birth.utcOffsetHours * 3600000).round()));

/// A single year, scored the same explainable way as a day.
class AnnualForecast {
  const AnnualForecast({
    required this.year,
    required this.pillar,
    required this.tenGod,
    required this.score,
    required this.factors,
    required this.governingLuck,
    required this.headline,
  });

  final int year;
  final Pillar pillar;
  final TenGod tenGod;

  /// 5 to 99, on the same scale as the daily score.
  final int score;

  final List<String> factors;

  /// The ten-year period this year falls inside, if the cycle has opened.
  final LuckPillar? governingLuck;

  final String headline;

  String get band => switch (score) {
        >= 85 => 'Exceptional',
        >= 70 => 'Strong',
        >= 55 => 'Steady',
        >= 40 => 'Mixed',
        >= 25 => 'Demanding',
        _ => 'Hard',
      };

  Map<String, dynamic> toJson() => {
        'year': year,
        'pillar': pillar.chinese,
        'score': score,
        'band': band,
        'tenGod': '${tenGod.chinese} ${tenGod.english}',
        'luckPillar': governingLuck?.pillar.chinese,
        'headline': headline,
        'why': factors,
      };
}

/// The sexagenary pillar of a calendar year, reckoned from Start of Spring.
Pillar yearPillarFor(int year) => Pillar(
      HeavenlyStem.values[((year - 4) % 10 + 10) % 10],
      EarthlyBranch.values[((year - 4) % 12 + 12) % 12],
    );

/// Scores [year] against a chart and its luck cycle.
AnnualForecast computeAnnualForecast({
  required SoulBlueprint blueprint,
  required LuckCycle cycle,
  required int year,
}) {
  final chart = blueprint.bazi;
  final pillar = yearPillarFor(year);
  final tenGod = tenGodFor(chart.dayMaster, pillar.stem);
  final luck = cycle.pillarForYear(year);

  final factors = <String>[];
  var score = 50;

  // 1. The year's stem against the day master.
  final stemPoints = switch (tenGod) {
    TenGod.directResource => 10,
    TenGod.indirectResource => 6,
    TenGod.eatingGod => 8,
    TenGod.hurtingOfficer => -4,
    TenGod.directWealth => 8,
    TenGod.indirectWealth => 6,
    TenGod.directOfficer => 4,
    TenGod.sevenKillings => -9,
    TenGod.friend => 4,
    TenGod.robWealth => -4,
  };
  score += stemPoints;
  factors.add('${_sign(stemPoints)} ${tenGod.chinese} ${tenGod.english} — '
      "the year's stem ${pillar.stem.chinese} against your day master "
      '${chart.dayMaster.chinese}');

  // 2. The year branch against the birth-year branch. This is the one people
  // already know: the year that clashes with your own animal, and the year of
  // your own animal, which folklore treats as the difficult one rather than
  // the lucky one.
  final natalYear = chart.year.branch;
  if (pillar.branch == natalYear) {
    score -= 6;
    factors.add('-6 Your own animal year 本命年 — traditionally an exposed '
        'year rather than a lucky one');
  } else if (pillar.branch == natalYear.clashesWith) {
    score -= 12;
    factors.add('-12 Clash with your year branch 冲太岁 — '
        '${pillar.branch.chinese} against ${natalYear.chinese}');
  } else if (pillar.branch == natalYear.harmonizesWith) {
    score += 10;
    factors.add('+10 Six harmony with your year branch 六合');
  } else if (natalYear.trine.contains(pillar.branch)) {
    score += 7;
    factors.add('+7 Trine with your year branch 三合');
  }

  // 3. The year branch against the day branch — the one that shows up in
  // private life rather than in public circumstances.
  final dayBranch = chart.day.branch;
  if (pillar.branch == dayBranch.clashesWith) {
    score -= 8;
    factors.add('-8 Clash with your day branch — unsettled at home');
  } else if (pillar.branch == dayBranch.harmonizesWith) {
    score += 6;
    factors.add('+6 Harmony with your day branch');
  }

  // 4. Does the year supply the phase the chart is short of?
  final needed = blueprint.remedialElement;
  if (pillar.stem.element == needed || pillar.branch.element == needed) {
    score += 9;
    factors.add('+9 Carries ${needed.chinese} ${needed.english}, the phase '
        'your chart runs short of');
  }

  // 5. The decade the year sits in. A luck pillar that supports the day master
  // lifts every year inside it, which is exactly what "a good decade" means.
  if (luck != null) {
    final luckElement = luck.pillar.stem.element;
    final me = chart.dayMaster.element;
    if (luckElement == me || luckElement == me.generatedBy) {
      score += 8;
      factors.add('+8 Inside a ${luck.pillar.chinese} decade, which feeds '
          'your ${me.english} day master');
    } else if (luckElement == me.controlledBy) {
      score -= 7;
      factors.add('-7 Inside a ${luck.pillar.chinese} decade, which presses '
          'on your ${me.english} day master');
    }
    if (pillar.branch == luck.pillar.branch.clashesWith) {
      score -= 6;
      factors.add('-6 The year clashes with the decade itself');
    }
  } else {
    factors.add('The luck cycle has not opened yet at this age');
  }

  return AnnualForecast(
    year: year,
    pillar: pillar,
    tenGod: tenGod,
    score: score.clamp(5, 99),
    factors: factors,
    governingLuck: luck,
    headline: _annualHeadline(tenGod, score),
  );
}

/// Twelve months of a year, so the report has shape rather than one number.
///
/// A month's branch comes from the solar terms, the same as a birth chart's,
/// which is why a Ba Zi month runs from about the fourth of one month to the
/// fourth of the next rather than on calendar boundaries.
List<({SolarTerm term, Pillar pillar, TenGod tenGod})> monthsOfYear({
  required int year,
  required HeavenlyStem yearStem,
  required HeavenlyStem dayMaster,
}) {
  final out = <({SolarTerm term, Pillar pillar, TenGod tenGod})>[];
  for (var i = 0; i < 12; i++) {
    final term = SolarTerm.values[i];
    // Five Tigers rule, the same one the birth chart uses.
    final stem = HeavenlyStem.values[((yearStem.index % 5) * 2 + 2 + i) % 10];
    final pillar = Pillar(stem, term.branch);
    out.add((
      term: term,
      pillar: pillar,
      tenGod: tenGodFor(dayMaster, stem),
    ));
  }
  return out;
}

String _annualHeadline(TenGod tenGod, int score) => switch (tenGod) {
      TenGod.directResource ||
      TenGod.indirectResource =>
        'A year that gives you something: study, mentors, rest, recovery.',
      TenGod.eatingGod =>
        'An output year. Whatever you make this year travels further than usual.',
      TenGod.hurtingOfficer =>
        'Expressive and sharp. Brilliant work, and a temper with authority.',
      TenGod.directWealth =>
        'Steady money. The year rewards the unglamorous financial move.',
      TenGod.indirectWealth =>
        'Opportunity in motion — deals, travel, side income. Pick one.',
      TenGod.directOfficer =>
        'Structure and standing. Titles, contracts, and being seen doing it right.',
      TenGod.sevenKillings =>
        'A pressure year. It makes people, and it does not ask first.',
      TenGod.friend ||
      TenGod.robWealth =>
        'A year decided by the people around you, for better and worse.',
    };

String _sign(int points) => points >= 0 ? '+$points' : '$points';
