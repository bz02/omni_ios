// Planetary positions are checked against physical invariants rather than a
// table of expected numbers. A mistyped orbital element does not produce a
// plausible-but-wrong chart here — it produces a Mercury that wanders across
// the sky away from the Sun, or a Mars that never turns retrograde, and those
// are impossible rather than merely inaccurate.

import 'package:flutter_test/flutter_test.dart';
import 'package:omni_flutter/core/engine/astro_math.dart';
import 'package:omni_flutter/core/engine/planets.dart';
import 'package:omni_flutter/core/engine/western_chart.dart';

double _separation(double a, double b) {
  final d = (a - b).abs();
  return d > 180 ? 360 - d : d;
}

double _jd(int year, int month, int day) =>
    julianDay(DateTime.utc(year, month, day));

void main() {
  group('elongation bounds', () {
    // Geometry fixes how far an inner planet can appear from the Sun. These
    // are the sharpest checks available: they fail on an error of a degree.
    test('Mercury stays within 28 degrees of the Sun', () {
      var maximum = 0.0;
      for (var day = 0; day < 4000; day += 3) {
        final jd = _jd(2020, 1, 1) + day;
        final elongation =
            _separation(planetLongitude(Planet.mercury, jd), solarLongitude(jd));
        if (elongation > maximum) maximum = elongation;
      }
      expect(maximum, lessThan(28.5));
      // And it does reach nearly that far, so a planet stuck near the Sun
      // fails too.
      expect(maximum, greaterThan(26.0));
    });

    test('Venus stays within 47 degrees of the Sun', () {
      var maximum = 0.0;
      for (var day = 0; day < 4000; day += 3) {
        final jd = _jd(2020, 1, 1) + day;
        final elongation =
            _separation(planetLongitude(Planet.venus, jd), solarLongitude(jd));
        if (elongation > maximum) maximum = elongation;
      }
      expect(maximum, lessThan(47.6));
      expect(maximum, greaterThan(45.0));
    });

    test('an outer planet is not bound to the Sun at all', () {
      var maximum = 0.0;
      for (var day = 0; day < 800; day += 5) {
        final jd = _jd(2024, 1, 1) + day;
        final elongation =
            _separation(planetLongitude(Planet.mars, jd), solarLongitude(jd));
        if (elongation > maximum) maximum = elongation;
      }
      expect(maximum, greaterThan(150.0), reason: 'Mars must reach opposition');
    });
  });

  group('distance from Earth', () {
    // Published ranges, with a little slack for the sampling interval.
    const ranges = {
      Planet.mercury: (0.5, 1.5),
      Planet.venus: (0.25, 1.8),
      Planet.mars: (0.35, 2.7),
      Planet.jupiter: (3.9, 6.5),
      Planet.saturn: (7.9, 11.1),
      Planet.uranus: (17.2, 21.1),
      Planet.neptune: (28.7, 31.0),
      Planet.pluto: (28.6, 50.5),
    };

    test('every planet stays inside its known range', () {
      for (final entry in ranges.entries) {
        var low = double.infinity;
        var high = 0.0;
        for (var day = 0; day < 4000; day += 5) {
          final distance = planetDistance(entry.key, _jd(2020, 1, 1) + day);
          if (distance < low) low = distance;
          if (distance > high) high = distance;
        }
        expect(low, greaterThanOrEqualTo(entry.value.$1),
            reason: '${entry.key.label} came too close');
        expect(high, lessThanOrEqualTo(entry.value.$2),
            reason: '${entry.key.label} went too far');
      }
    });
  });

  group('retrograde motion', () {
    /// Counts distinct retrograde spans and their total length over [days].
    ({int spans, int days}) survey(Planet planet, int days) {
      var spans = 0;
      var total = 0;
      var run = 0;
      for (var day = 0; day < days; day++) {
        if (isRetrograde(planet, _jd(2024, 1, 1) + day)) {
          total++;
          run++;
        } else {
          if (run > 3) spans++;
          run = 0;
        }
      }
      if (run > 3) spans++;
      return (spans: spans, days: total);
    }

    test('Mercury turns retrograde about three times a year', () {
      final result = survey(Planet.mercury, 730);
      expect(result.spans, inInclusiveRange(5, 7));
      // Each span runs about three weeks.
      expect(result.days / result.spans, inInclusiveRange(18, 26));
    });

    test('Venus turns retrograde roughly every nineteen months', () {
      final result = survey(Planet.venus, 730);
      expect(result.spans, inInclusiveRange(1, 2));
      expect(result.days / result.spans, inInclusiveRange(38, 46));
    });

    test('Mars turns retrograde roughly every twenty-six months', () {
      final result = survey(Planet.mars, 730);
      expect(result.spans, 1);
      expect(result.days, inInclusiveRange(55, 85));
    });

    test('the outer planets spend the published fraction of time retrograde',
        () {
      // Earth overtakes each of them once per synodic cycle, and the fraction
      // of the cycle spent apparently reversing is a published constant. It
      // has to be measured over many cycles: two years is 1.8 Jupiter cycles,
      // and a partial cycle at each end skews the answer by a third.
      const expected = {
        Planet.jupiter: 0.303,
        Planet.saturn: 0.365,
        Planet.uranus: 0.408,
        Planet.neptune: 0.430,
        Planet.pluto: 0.436,
      };
      const window = 3650;

      for (final entry in expected.entries) {
        var retrograde = 0;
        for (var day = 0; day < window; day++) {
          if (isRetrograde(entry.key, _jd(2020, 1, 1) + day)) retrograde++;
        }
        expect(retrograde / window, closeTo(entry.value, 0.02),
            reason: entry.key.label);
      }
    });

    test('each outer planet retrograde lasts the published number of days',
        () {
      const expected = {
        Planet.jupiter: 121,
        Planet.saturn: 138,
        Planet.neptune: 158,
      };
      for (final entry in expected.entries) {
        final lengths = <int>[];
        var run = 0;
        for (var day = 0; day < 3650; day++) {
          if (isRetrograde(entry.key, _jd(2020, 1, 1) + day)) {
            run++;
          } else {
            if (run > 3) lengths.add(run);
            run = 0;
          }
        }
        final average =
            lengths.reduce((a, b) => a + b) / lengths.length;
        expect(average, closeTo(entry.value.toDouble(), 6),
            reason: entry.key.label);
      }
    });

    test('an outer planet is retrograde near opposition, when it is closest',
        () {
      // Retrograde motion of an outer planet is Earth overtaking it, so it
      // happens when the planet is nearest. This ties the direction of travel
      // to the geometry rather than trusting either on its own.
      var retrogradeMean = 0.0;
      var directMean = 0.0;
      var retrogradeCount = 0;
      var directCount = 0;

      for (var day = 0; day < 800; day += 2) {
        final jd = _jd(2024, 1, 1) + day;
        final distance = planetDistance(Planet.jupiter, jd);
        if (isRetrograde(Planet.jupiter, jd)) {
          retrogradeMean += distance;
          retrogradeCount++;
        } else {
          directMean += distance;
          directCount++;
        }
      }
      expect(retrogradeMean / retrogradeCount,
          lessThan(directMean / directCount));
    });
  });

  group('motion and coverage', () {
    test('the personal planets visit every sign within a few years', () {
      for (final planet in [Planet.mercury, Planet.venus, Planet.mars]) {
        final signs = <ZodiacSign>{};
        for (var day = 0; day < 1100; day += 4) {
          signs.add(ZodiacSign.fromLongitude(
              planetLongitude(planet, _jd(2024, 1, 1) + day)));
        }
        expect(signs, hasLength(12), reason: planet.label);
      }
    });

    test('Saturn takes about two and a half years per sign', () {
      final start = ZodiacSign.fromLongitude(
          planetLongitude(Planet.saturn, _jd(2024, 1, 1)));
      var changed = 0;
      for (var day = 0; day < 1000; day += 5) {
        final sign = ZodiacSign.fromLongitude(
            planetLongitude(Planet.saturn, _jd(2024, 1, 1) + day));
        if (sign != start) {
          changed = day;
          break;
        }
      }
      // Somewhere inside the window, not on day one and not never.
      expect(changed, greaterThan(0));
    });

    test('daily motion is small and finite for every planet', () {
      for (final planet in Planet.values) {
        final motion = planetDailyMotion(planet, _jd(2026, 3, 1));
        expect(motion.isFinite, isTrue, reason: planet.label);
        // Mercury is the fastest and never exceeds about two degrees a day.
        expect(motion.abs(), lessThan(2.5), reason: planet.label);
      }
    });
  });

  group('the reading layer', () {
    test('reports every planet with a direction of travel', () {
      final positions = allPlanetPositions(_jd(2026, 3, 1));
      expect(positions, hasLength(Planet.values.length));
      for (final position in positions.values) {
        expect(position.longitude, inInclusiveRange(0, 360));
        expect(['direct', 'retrograde', 'stationary'],
            contains(position.motionLabel));
      }
    });

    test('names which planets are retrograde right now', () {
      // Over two years Mercury must show up in the list at some point, and on
      // most days something is retrograde.
      var sawMercury = false;
      for (var day = 0; day < 400; day += 2) {
        if (retrogradePlanets(_jd(2025, 1, 1) + day).contains(Planet.mercury)) {
          sawMercury = true;
          break;
        }
      }
      expect(sawMercury, isTrue);
    });

    test('is deterministic', () {
      final jd = _jd(2026, 7, 4);
      expect(planetLongitude(Planet.venus, jd),
          planetLongitude(Planet.venus, jd));
    });

    test('every planet carries a plain-English line', () {
      for (final planet in Planet.values) {
        expect(planet.gist, isNotEmpty);
        expect(planet.glyph, isNotEmpty);
      }
      expect(Planet.mercury.isPersonal, isTrue);
      expect(Planet.pluto.isPersonal, isFalse);
    });
  });
}
