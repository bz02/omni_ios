/// What the sky is doing right now, against the chart you were born with.
///
/// This is the daily hook. In the United States "Mercury is retrograde" and
/// "it's a full moon" are ordinary conversation, and a full moon landing on
/// someone's Venus is the kind of specific that gets screenshotted. A natal
/// chart is read once; transits are read every day, and that is what brings
/// people back and keeps a subscription alive.
library;

import 'dart:math' as math;

import 'astro_math.dart';
import 'planets.dart';
import 'western_chart.dart';

/// Re-exported so a caller building a transit view needs one import.
export 'houses.dart' show HouseSystem, houseMeanings;
export 'planets.dart' show Planet;

enum MoonPhase {
  newMoon('New Moon', '🌑', 'Start something. Nobody has to see it yet.'),
  waxingCrescent('Waxing Crescent', '🌒', 'Early momentum. Protect it.'),
  firstQuarter('First Quarter', '🌓', 'The first real obstacle. Push.'),
  waxingGibbous('Waxing Gibbous', '🌔', 'Refine. It is nearly there.'),
  fullMoon('Full Moon', '🌕', 'It comes to a head. Feelings included.'),
  waningGibbous('Waning Gibbous', '🌖', 'Share what you learned.'),
  lastQuarter('Last Quarter', '🌗', 'Cut what is not working.'),
  waningCrescent('Waning Crescent', '🌘', 'Rest. Do not start anything.');

  const MoonPhase(this.label, this.emoji, this.gist);
  final String label;
  final String emoji;
  final String gist;
}

class MoonState {
  const MoonState({
    required this.phase,
    required this.illumination,
    required this.elongation,
    required this.sign,
  });

  final MoonPhase phase;

  /// 0 at new, 1 at full.
  final double illumination;

  /// Degrees the Moon sits ahead of the Sun, 0 to 360.
  final double elongation;

  final ZodiacSign sign;

  String get illuminationLabel => '${(illumination * 100).round()}% lit';
}

/// The Moon's phase and sign at an instant.
MoonState moonStateAt(double jdUt) {
  final moon = lunarLongitude(jdUt);
  final sun = solarLongitude(jdUt);
  final elongation = normalizeDegrees(moon - sun);

  // Eight phases of 45 degrees each, centered on the four exact points, so
  // "Full Moon" covers the day either side rather than one instant nobody is
  // awake for.
  final phase = MoonPhase.values[((elongation + 22.5) ~/ 45) % 8];
  final illumination = (1 - math.cos(elongation * math.pi / 180.0)) / 2;

  return MoonState(
    phase: phase,
    illumination: illumination,
    elongation: elongation,
    sign: ZodiacSign.fromLongitude(moon),
  );
}

/// A transiting body making an aspect to a natal point.
class Transit {
  const Transit({
    required this.transiting,
    required this.natalPoint,
    required this.aspect,
    required this.orb,
    required this.isRetrograde,
    required this.weight,
  });

  final Planet transiting;

  /// 'Sun', 'Moon', 'Rising', 'Venus' and so on.
  final String natalPoint;

  final Aspect aspect;

  /// Degrees from exact. Smaller is stronger.
  final double orb;

  final bool isRetrograde;

  /// How much this matters, 0 to 1. A slow planet crossing a personal point
  /// is a chapter of someone's life; a fast one is a mood.
  final double weight;

  bool get isExact => orb < 1.0;

  String get headline =>
      'Transiting ${transiting.label} ${aspect.label.toLowerCase()} '
      'your $natalPoint';

  String get detail => '${transiting.gist}, meeting $natalPoint '
      '${aspect.gist}. ${orb.toStringAsFixed(1)}° from exact'
      '${isRetrograde ? ', retrograde' : ''}.';

  Map<String, dynamic> toJson() => {
        'transit': headline,
        'orb': orb.toStringAsFixed(1),
        'retrograde': isRetrograde,
      };
}

/// How much weight a transit carries.
///
/// Slow planets matter most: Saturn crossing your Sun is a couple of years of
/// your life, where the Moon crossing it is an afternoon. The Moon is left out
/// of transits entirely for that reason — it would drown everything else.
double _weightFor(Planet planet, String natalPoint, double orb) {
  final speed = switch (planet) {
    Planet.pluto || Planet.neptune || Planet.uranus => 1.0,
    Planet.saturn => 0.9,
    Planet.jupiter => 0.75,
    Planet.mars => 0.5,
    Planet.venus || Planet.mercury => 0.35,
  };
  final target = switch (natalPoint) {
    'Sun' || 'Moon' || 'Rising' => 1.0,
    'Midheaven' || 'Venus' || 'Mars' || 'Mercury' => 0.8,
    _ => 0.55,
  };
  // Tight orbs count for more, falling off linearly to the edge.
  final tightness = (1 - orb / 8).clamp(0.0, 1.0);
  return speed * target * tightness;
}

/// Every current transit to a natal chart, strongest first.
///
/// [maxOrb] defaults to six degrees, which is tighter than the natal orbs: a
/// transit list with everything in it is a list with nothing in it.
List<Transit> transitsFor({
  required WesternChart natal,
  required double jdUt,
  double maxOrb = 6.0,
  int limit = 8,
}) {
  final natalPoints = <String, double>{
    'Sun': natal.sun.longitude,
    if (natal.moon case final moon?) 'Moon': moon.longitude,
    if (natal.ascendant case final asc?) 'Rising': asc.longitude,
    if (natal.midheaven case final mc?) 'Midheaven': mc.longitude,
    for (final entry in natal.planets.entries)
      entry.key.label: entry.value.longitude,
  };

  final found = <Transit>[];
  for (final planet in Planet.values) {
    final longitude = planetLongitude(planet, jdUt);
    final retrograde = isRetrograde(planet, jdUt);

    for (final point in natalPoints.entries) {
      final match = aspectBetween(longitude, point.value);
      if (match == null || match.orb > maxOrb) continue;
      // A planet aspecting its own natal position by conjunction is a return,
      // which is reported separately and would otherwise crowd the list.
      if (planet.label == point.key && match.aspect == Aspect.conjunction) {
        continue;
      }

      found.add(Transit(
        transiting: planet,
        natalPoint: point.key,
        aspect: match.aspect,
        orb: match.orb,
        isRetrograde: retrograde,
        weight: _weightFor(planet, point.key, match.orb),
      ));
    }
  }

  found.sort((a, b) => b.weight.compareTo(a.weight));
  return found.take(limit).toList();
}

/// A planet coming back to where it was when you were born.
///
/// The Saturn return around age 29 is the one piece of technical astrology
/// that has fully crossed into American popular culture, so it gets named
/// rather than left inside the transit list.
class PlanetaryReturn {
  const PlanetaryReturn({
    required this.planet,
    required this.orb,
    required this.ordinal,
  });

  final Planet planet;
  final double orb;

  /// 1 for the first return, 2 for the second.
  final int ordinal;

  String get label => ordinal == 1
      ? 'Your ${planet.label} return'
      : 'Your ${_ordinalWord(ordinal)} ${planet.label} return';

  String get detail => switch (planet) {
        Planet.saturn => ordinal == 1
            ? 'Saturn is back where it was the day you were born, for the '
                'first time since. The classic reckoning: what you built on '
                'sand comes apart, and what you built properly stays.'
            : 'Saturn returns again. The second one is less about proving '
                'yourself and more about what you actually want to carry.',
        Planet.jupiter =>
          'Jupiter is back where it started. These come round every twelve '
              'years and tend to open a door.',
        _ => '${planet.label} has come back to its natal degree.',
      };

  static String _ordinalWord(int n) => switch (n) {
        2 => 'second',
        3 => 'third',
        _ => '${n}th',
      };
}

/// Returns in progress, for the planets slow enough for it to mean something.
List<PlanetaryReturn> returnsFor({
  required WesternChart natal,
  required double jdUt,
  required int ageYears,
  double maxOrb = 5.0,
}) {
  const periods = {Planet.jupiter: 11.86, Planet.saturn: 29.46};
  final found = <PlanetaryReturn>[];

  for (final entry in periods.entries) {
    final natalPlacement = natal.planets[entry.key];
    if (natalPlacement == null) continue;

    final match = aspectBetween(
        planetLongitude(entry.key, jdUt), natalPlacement.longitude);
    if (match == null ||
        match.aspect != Aspect.conjunction ||
        match.orb > maxOrb) {
      continue;
    }

    final ordinal = math.max(1, (ageYears / entry.value).round());
    found.add(PlanetaryReturn(
        planet: entry.key, orb: match.orb, ordinal: ordinal));
  }
  return found;
}

/// Everything happening overhead right now, assembled for one screen.
class SkyNow {
  const SkyNow({
    required this.moon,
    required this.retrogrades,
    required this.transits,
    required this.returns,
  });

  final MoonState moon;
  final List<Planet> retrogrades;
  final List<Transit> transits;
  final List<PlanetaryReturn> returns;

  bool get mercuryRetrograde => retrogrades.contains(Planet.mercury);

  /// The one line worth putting at the top.
  ///
  /// Ordered by what an American reader reacts to: a Saturn return outranks
  /// everything, then Mercury retrograde, then the Moon, then whatever the
  /// heaviest transit is.
  String get headline {
    if (returns.isNotEmpty) return returns.first.label;
    if (mercuryRetrograde) return 'Mercury is retrograde';
    if (moon.phase == MoonPhase.fullMoon) {
      return 'Full Moon in ${moon.sign.label}';
    }
    if (moon.phase == MoonPhase.newMoon) {
      return 'New Moon in ${moon.sign.label}';
    }
    if (transits.isNotEmpty) return transits.first.headline;
    return '${moon.phase.label} in ${moon.sign.label}';
  }

  /// Transits worth listing under the headline.
  ///
  /// When the headline is itself a transit, repeating it immediately below
  /// reads as a bug rather than emphasis.
  List<Transit> get supportingTransits =>
      transits.where((t) => t.headline != headline).toList();

  Map<String, dynamic> toJson() => {
        'headline': headline,
        'moon': '${moon.phase.label} in ${moon.sign.label}, '
            '${moon.illuminationLabel}',
        'retrograde': [for (final p in retrogrades) p.label],
        'transits': [for (final t in transits) t.toJson()],
        'returns': [for (final r in returns) r.label],
      };
}

SkyNow skyNow({
  required WesternChart natal,
  required DateTime at,
  required int ageYears,
}) {
  final jd = julianDay(at.toUtc());
  return SkyNow(
    moon: moonStateAt(jd),
    retrogrades: retrogradePlanets(jd),
    transits: transitsFor(natal: natal, jdUt: jd),
    returns: returnsFor(natal: natal, jdUt: jd, ageYears: ageYears),
  );
}
