/// Houses and the Midheaven.
///
/// Houses are where a chart stops being about temperament and starts being
/// about your life: which sign your Venus is in says what you want, which
/// house it is in says where you go looking for it. Americans who read
/// astrology expect them.
///
/// **Whole Sign and Equal only, on purpose.** Placidus is the default in most
/// commercial software, and it is an approximation solved by iteration that is
/// easy to get subtly wrong and impossible for a user to check. Whole Sign is
/// exact, needs no approximation, and is what a large part of contemporary
/// American astrology has moved back to. Shipping a quietly wrong Placidus
/// would be worse than offering two systems that are right.
///
/// The Midheaven is computed exactly either way, because it is the one angle
/// people ask about by name.
library;

import 'dart:math' as math;

import 'astro_math.dart';

const double _deg = math.pi / 180.0;

enum HouseSystem {
  wholeSign(
    'Whole Sign',
    'Each house is one entire sign. The oldest system, and the one most '
        'contemporary astrologers have gone back to.',
  ),
  equal(
    'Equal',
    'Twelve exact 30° slices starting from your rising degree.',
  );

  const HouseSystem(this.label, this.explanation);
  final String label;
  final String explanation;
}

/// What each house covers, in language someone can act on.
const List<String> houseMeanings = [
  'You — body, presence, the first impression',
  'Money, possessions, what you value',
  'Siblings, neighbors, how you communicate',
  'Home, family, where you come from',
  'Romance, creativity, play, children',
  'Work, routine, health, service',
  'Partnership, marriage, open enemies',
  'Sex, death, other people’s money, what is shared',
  'Travel, belief, higher study, meaning',
  'Career, reputation, public standing',
  'Friends, groups, hopes for the future',
  'The unconscious, retreat, what is hidden',
];

/// Ecliptic longitude of the Midheaven — the degree culminating due south.
///
/// This is the tenth-house cusp in most systems and the point people mean when
/// they talk about their "career point".
double midheavenLongitude({required double jd, required double longitudeEast}) {
  final ramc = localSiderealTime(jd, longitudeEast);
  final obliquity = obliquityOfEcliptic(jd);

  final mc = math.atan2(
        math.sin(ramc * _deg),
        math.cos(ramc * _deg) * math.cos(obliquity * _deg),
      ) /
      _deg;
  return normalizeDegrees(mc);
}

/// The twelve house cusps, in ecliptic longitude, starting with the first.
List<double> houseCusps({
  required double ascendantLongitude,
  required HouseSystem system,
}) {
  switch (system) {
    case HouseSystem.wholeSign:
      // The first house is the whole sign the ascendant falls in, so cusps sit
      // on sign boundaries.
      final start = (normalizeDegrees(ascendantLongitude) ~/ 30) * 30.0;
      return [for (var i = 0; i < 12; i++) normalizeDegrees(start + i * 30.0)];
    case HouseSystem.equal:
      final start = normalizeDegrees(ascendantLongitude);
      return [for (var i = 0; i < 12; i++) normalizeDegrees(start + i * 30.0)];
  }
}

/// Which house (1 to 12) a longitude falls in.
int houseOf(double longitude, List<double> cusps) {
  final target = normalizeDegrees(longitude);
  for (var i = 0; i < 12; i++) {
    final start = cusps[i];
    final end = cusps[(i + 1) % 12];
    // Each house spans 30 degrees in both supported systems, so the only
    // subtlety is the one that wraps past 360.
    if (start <= end) {
      if (target >= start && target < end) return i + 1;
    } else {
      if (target >= start || target < end) return i + 1;
    }
  }
  return 1;
}
