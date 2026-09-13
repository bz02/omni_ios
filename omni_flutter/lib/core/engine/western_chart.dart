/// Western natal chart: the three placements a reading is actually built on —
/// Sun, Moon and Ascendant — computed from the same ephemeris that drives the
/// Chinese pillars.
///
/// Houses and the outer planets are deliberately out of scope for v1. Three
/// accurate placements beat twelve guessed ones, and the synthesis with the
/// Eastern chart is where this product differentiates.
library;

import 'astro_math.dart';
import 'houses.dart';
import 'planets.dart';

enum WesternElement {
  fire('Fire', '🔥'),
  earth('Earth', '🌍'),
  air('Air', '💨'),
  water('Water', '💧');

  const WesternElement(this.label, this.emoji);
  final String label;
  final String emoji;
}

enum Modality {
  cardinal('Cardinal', 'starts things'),
  fixed('Fixed', 'holds things'),
  mutable('Mutable', 'changes things');

  const Modality(this.label, this.gist);
  final String label;
  final String gist;
}

enum ZodiacSign {
  aries('Aries', '♈', '白羊座', WesternElement.fire, Modality.cardinal, 'Mars'),
  taurus('Taurus', '♉', '金牛座', WesternElement.earth, Modality.fixed, 'Venus'),
  gemini('Gemini', '♊', '双子座', WesternElement.air, Modality.mutable, 'Mercury'),
  cancer('Cancer', '♋', '巨蟹座', WesternElement.water, Modality.cardinal, 'Moon'),
  leo('Leo', '♌', '狮子座', WesternElement.fire, Modality.fixed, 'Sun'),
  virgo('Virgo', '♍', '处女座', WesternElement.earth, Modality.mutable, 'Mercury'),
  libra('Libra', '♎', '天秤座', WesternElement.air, Modality.cardinal, 'Venus'),
  scorpio('Scorpio', '♏', '天蝎座', WesternElement.water, Modality.fixed, 'Pluto'),
  sagittarius(
      'Sagittarius', '♐', '射手座', WesternElement.fire, Modality.mutable, 'Jupiter'),
  capricorn(
      'Capricorn', '♑', '摩羯座', WesternElement.earth, Modality.cardinal, 'Saturn'),
  aquarius('Aquarius', '♒', '水瓶座', WesternElement.air, Modality.fixed, 'Uranus'),
  pisces('Pisces', '♓', '双鱼座', WesternElement.water, Modality.mutable, 'Neptune');

  const ZodiacSign(this.label, this.glyph, this.chinese, this.element,
      this.modality, this.ruler);
  final String label;
  final String glyph;
  final String chinese;
  final WesternElement element;
  final Modality modality;
  final String ruler;

  /// The sign containing an ecliptic longitude.
  static ZodiacSign fromLongitude(double longitude) =>
      ZodiacSign.values[(normalizeDegrees(longitude) ~/ 30) % 12];
}

/// A single placement: which sign, and how far into it.
class Placement {
  const Placement(this.longitude, {this.house, this.dailyMotion});

  /// Ecliptic longitude in degrees, 0 to 360.
  final double longitude;

  /// 1 to 12, once houses have been computed. Null for a chart with no birth
  /// time or place, where houses cannot be known.
  final int? house;

  /// Degrees per day. Negative means retrograde. Null for the angles, which
  /// are not bodies and do not travel.
  final double? dailyMotion;

  bool get isRetrograde => (dailyMotion ?? 0) < 0;

  String get houseMeaning =>
      house == null ? '' : houseMeanings[house! - 1];

  ZodiacSign get sign => ZodiacSign.fromLongitude(longitude);

  /// Degrees into the sign, 0 to 30.
  double get degreeInSign => normalizeDegrees(longitude) % 30.0;

  /// Distance in degrees to the nearer sign boundary.
  double get degreesToCusp {
    final d = degreeInSign;
    return d < 15 ? d : 30 - d;
  }

  /// Within a degree of a boundary, so a slightly wrong birth time or the
  /// engine's own lunar error could put this in the neighboring sign.
  bool get isOnCusp => degreesToCusp < 1.0;

  String get formatted =>
      '${degreeInSign.floor()}° ${sign.label} ${sign.glyph}'
      '${isRetrograde ? ' ℞' : ''}';

  String get formattedWithHouse =>
      house == null ? formatted : '$formatted · house $house';

  @override
  String toString() => formatted;
}

/// Aspect between two placements. Only the five Ptolemaic aspects, which is
/// what a human-readable reading uses.
enum Aspect {
  conjunction('Conjunction', 0, 8, 'fused'),
  sextile('Sextile', 60, 6, 'easy'),
  square('Square', 90, 8, 'friction'),
  trine('Trine', 120, 8, 'flow'),
  opposition('Opposition', 180, 8, 'pull');

  const Aspect(this.label, this.exactDegrees, this.orb, this.gist);
  final String label;
  final int exactDegrees;
  final int orb;
  final String gist;
}

/// The aspect between two longitudes, or null if they are unaspected.
({Aspect aspect, double orb})? aspectBetween(double a, double b) {
  var separation = (normalizeDegrees(a) - normalizeDegrees(b)).abs();
  if (separation > 180) separation = 360 - separation;
  for (final aspect in Aspect.values) {
    final delta = (separation - aspect.exactDegrees).abs();
    if (delta <= aspect.orb) return (aspect: aspect, orb: delta);
  }
  return null;
}

class WesternChart {
  const WesternChart({
    required this.sun,
    required this.moon,
    required this.ascendant,
    required this.precision,
    this.planets = const {},
    this.midheaven,
    this.cusps,
    this.houseSystem = HouseSystem.wholeSign,
  });

  /// Mercury through Pluto. Empty only if a caller asked for a bare chart.
  ///
  /// The audience talks about their Mercury and their Venus placements the way
  /// they talk about their Sun sign, so these are not an advanced feature.
  final Map<Planet, Placement> planets;

  /// The degree culminating due south at birth — the tenth-house cusp, and the
  /// point people mean by "career point". Null without a birth time or place.
  final Placement? midheaven;

  /// Twelve house cusps in ecliptic longitude. Null without a birth time or
  /// place, because houses turn a full circle every day.
  final List<double>? cusps;

  final HouseSystem houseSystem;

  final Placement sun;

  /// Null when no birth time was given — the Moon can cross a sign in a single
  /// day, so a date alone cannot pin it.
  final Placement? moon;

  /// Null when the birth time or place is unknown. The ascendant moves a whole
  /// sign every two hours.
  final Placement? ascendant;

  final ChartPrecision precision;

  /// The classic three-line summary.
  String get bigThree {
    final parts = <String>['${sun.sign.label} Sun'];
    if (moon != null) parts.add('${moon!.sign.label} Moon');
    if (ascendant != null) parts.add('${ascendant!.sign.label} Rising');
    return parts.join(' · ');
  }

  /// The three placements plus the personal planets — the "big six" an
  /// American reader expects to be told.
  Map<String, Placement> get bigSix => {
        'Sun': sun,
        if (moon != null) 'Moon': moon!,
        if (ascendant != null) 'Rising': ascendant!,
        if (planets[Planet.mercury] case final p?) 'Mercury': p,
        if (planets[Planet.venus] case final p?) 'Venus': p,
        if (planets[Planet.mars] case final p?) 'Mars': p,
      };

  /// Planets travelling backwards at birth. A natal retrograde is a thing
  /// people identify with, so it is surfaced rather than buried.
  List<Planet> get natalRetrogrades => [
        for (final entry in planets.entries)
          if (entry.value.isRetrograde) entry.key,
      ];

  /// Element balance across the placements that are actually known.
  Map<WesternElement, int> get elementBalance {
    final counts = {for (final e in WesternElement.values) e: 0};
    for (final p in [sun, moon, ascendant]) {
      if (p == null) continue;
      counts[p.sign.element] = counts[p.sign.element]! + 1;
    }
    return counts;
  }

  WesternElement get dominantElement =>
      elementBalance.entries.reduce((a, b) => a.value >= b.value ? a : b).key;

  /// Sun-Moon aspect, the one relationship in a three-body chart worth naming:
  /// it describes whether what someone wants and what they feel agree.
  ({Aspect aspect, double orb})? get sunMoonAspect =>
      moon == null ? null : aspectBetween(sun.longitude, moon!.longitude);

  /// Placements sitting within a degree of a sign boundary, so the UI can say
  /// so rather than assert a sign it is not sure of.
  List<String> get cuspWarnings => [
        if (sun.isOnCusp) 'Sun',
        if (moon?.isOnCusp ?? false) 'Moon',
        if (ascendant?.isOnCusp ?? false) 'Rising',
      ];

  Map<String, dynamic> toJson() => {
        'sun': sun.formatted,
        'moon': moon?.formatted,
        'rising': ascendant?.formatted,
        'bigThree': bigThree,
        'dominantElement': dominantElement.label,
        'modality': sun.sign.modality.label,
        'sunMoonAspect': sunMoonAspect == null
            ? null
            : '${sunMoonAspect!.aspect.label} '
                '(${sunMoonAspect!.orb.toStringAsFixed(1)}°)',
        'midheaven': midheaven?.formatted,
        'planets': {
          for (final entry in planets.entries)
            entry.key.label: entry.value.formattedWithHouse,
        },
        'natalRetrogrades': [
          for (final planet in natalRetrogrades) planet.label,
        ],
        'houseSystem': houseSystem.label,
        'precision': precision.name,
      };
}

/// Computes a natal chart.
///
/// [birthLocal] is wall-clock time at the birthplace; [utcOffsetHours] is the
/// offset that clock ran on. Latitude and longitude are the birthplace, north
/// and east positive.
WesternChart computeWesternChart({
  required DateTime birthLocal,
  required double utcOffsetHours,
  double? latitudeNorth,
  double? longitudeEast,
  bool hourIsKnown = true,
  HouseSystem houseSystem = HouseSystem.wholeSign,
}) {
  // With no birth time, noon is the least-wrong assumption for the Sun: it caps
  // the error at half a day, which only matters within half a degree of a cusp.
  final local = hourIsKnown
      ? birthLocal
      : DateTime(birthLocal.year, birthLocal.month, birthLocal.day, 12);

  final utc = DateTime.utc(
    local.year,
    local.month,
    local.day,
    local.hour,
    local.minute,
  ).subtract(Duration(milliseconds: (utcOffsetHours * 3600000).round()));

  final jd = julianDay(utc);
  final sun = Placement(solarLongitude(jd));

  final hasPlace = latitudeNorth != null && longitudeEast != null;
  final precision = !hourIsKnown
      ? ChartPrecision.dateOnly
      : (hasPlace ? ChartPrecision.full : ChartPrecision.noBirthPlace);

  final ascendant = hourIsKnown && hasPlace
      ? ascendantLongitude(
          jd: jd,
          latitudeNorth: latitudeNorth,
          longitudeEast: longitudeEast,
        )
      : null;

  // Houses turn a full circle every day, so they need both a time and a place.
  final cusps = ascendant == null
      ? null
      : houseCusps(ascendantLongitude: ascendant, system: houseSystem);

  int? houseFor(double longitude) =>
      cusps == null ? null : houseOf(longitude, cusps);

  final moonLongitude = hourIsKnown ? lunarLongitude(jd) : null;
  final mcLongitude = ascendant == null || !hasPlace
      ? null
      : midheavenLongitude(jd: jd, longitudeEast: longitudeEast);

  return WesternChart(
    sun: Placement(sun.longitude, house: houseFor(sun.longitude)),
    moon: moonLongitude == null
        ? null
        : Placement(moonLongitude, house: houseFor(moonLongitude)),
    ascendant: ascendant == null ? null : Placement(ascendant, house: 1),
    midheaven: mcLongitude == null
        ? null
        : Placement(mcLongitude, house: houseFor(mcLongitude)),
    cusps: cusps,
    houseSystem: houseSystem,
    planets: {
      for (final entry in allPlanetPositions(jd).entries)
        entry.key: Placement(
          entry.value.longitude,
          house: houseFor(entry.value.longitude),
          dailyMotion: entry.value.dailyMotion,
        ),
    },
    precision: precision,
  );
}
