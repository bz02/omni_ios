// Transits are the daily hook, so the things worth testing are the ones a
// user would notice being wrong: a full moon on the wrong night, a Mercury
// retrograde that never ends, a Saturn return at the wrong age.

import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:omni_flutter/core/engine/astro_math.dart';
import 'package:omni_flutter/core/engine/houses.dart';
import 'package:omni_flutter/core/engine/transits.dart';
import 'package:omni_flutter/core/engine/western_chart.dart';

WesternChart _natal() => computeWesternChart(
      birthLocal: DateTime(1990, 7, 4, 8, 30),
      utcOffsetHours: -4,
      latitudeNorth: 40.7128,
      longitudeEast: -74.0060,
    );

void main() {
  group('moon phase', () {
    test('cycles through all eight phases in a lunar month', () {
      final seen = <MoonPhase>{};
      for (var day = 0; day < 30; day++) {
        seen.add(moonStateAt(julianDay(DateTime.utc(2026, 3, 1)) + day).phase);
      }
      expect(seen, hasLength(8));
    });

    test('illumination tracks the phase', () {
      for (var day = 0; day < 60; day++) {
        final state = moonStateAt(julianDay(DateTime.utc(2026, 1, 1)) + day);
        expect(state.illumination, inInclusiveRange(0.0, 1.0));
        if (state.phase == MoonPhase.fullMoon) {
          expect(state.illumination, greaterThan(0.85));
        }
        if (state.phase == MoonPhase.newMoon) {
          expect(state.illumination, lessThan(0.15));
        }
      }
    });

    test('a full moon happens about every 29.5 days', () {
      final fullMoons = <int>[];
      for (var day = 0; day < 200; day++) {
        final jd = julianDay(DateTime.utc(2026, 1, 1)) + day;
        final elongation = moonStateAt(jd).elongation;
        final next = moonStateAt(jd + 1).elongation;
        // The moment elongation passes 180.
        if (elongation < 180 && next >= 180) fullMoons.add(day);
      }
      expect(fullMoons.length, inInclusiveRange(6, 7));
      for (var i = 1; i < fullMoons.length; i++) {
        expect(fullMoons[i] - fullMoons[i - 1], inInclusiveRange(28, 31));
      }
    });

    test('at a new moon the Moon sits on the Sun', () {
      // Not "in the same sign": a new moon at 29° Aries puts the Moon a
      // fraction of a degree away but over the boundary into Taurus, which is
      // correct and would fail a same-sign assertion.
      var checked = 0;
      for (var day = 0; day < 400; day++) {
        final jd = julianDay(DateTime.utc(2026, 1, 1)) + day;
        final state = moonStateAt(jd);
        if (state.elongation > 3 && state.elongation < 357) continue;
        var gap = (lunarLongitude(jd) - solarLongitude(jd)).abs();
        if (gap > 180) gap = 360 - gap;
        expect(gap, lessThan(4));
        expect(state.phase, MoonPhase.newMoon);
        checked++;
      }
      expect(checked, greaterThan(5), reason: 'no new moons in 400 days?');
    });

    test('every phase carries something to do', () {
      for (final phase in MoonPhase.values) {
        expect(phase.gist, isNotEmpty);
        expect(phase.emoji, isNotEmpty);
      }
    });
  });

  group('houses', () {
    test('whole sign cusps land on sign boundaries', () {
      final cusps =
          houseCusps(ascendantLongitude: 137.4, system: HouseSystem.wholeSign);
      expect(cusps.first, 120.0);
      for (final cusp in cusps) {
        expect(cusp % 30, closeTo(0, 1e-9));
      }
    });

    test('equal cusps start exactly on the rising degree', () {
      final cusps =
          houseCusps(ascendantLongitude: 137.4, system: HouseSystem.equal);
      expect(cusps.first, closeTo(137.4, 1e-9));
      expect(cusps[6], closeTo(317.4, 1e-9));
    });

    test('every degree of the circle falls in exactly one house', () {
      for (final system in HouseSystem.values) {
        final cusps =
            houseCusps(ascendantLongitude: 137.4, system: system);
        final counts = <int, int>{};
        for (var degree = 0; degree < 360; degree++) {
          final house = houseOf(degree.toDouble(), cusps);
          expect(house, inInclusiveRange(1, 12));
          counts[house] = (counts[house] ?? 0) + 1;
        }
        expect(counts.keys, hasLength(12), reason: system.label);
        for (final count in counts.values) {
          expect(count, 30, reason: system.label);
        }
      }
    });

    test('the ascendant is always in the first house', () {
      for (var ascendant = 0.0; ascendant < 360; ascendant += 7) {
        for (final system in HouseSystem.values) {
          final cusps =
              houseCusps(ascendantLongitude: ascendant, system: system);
          expect(houseOf(ascendant, cusps), 1);
        }
      }
    });

    test('the midheaven culminates, so its right ascension is the sidereal '
        'time', () {
      // Self-consistency, but it is what catches a quadrant error, which is
      // the way this formula usually goes wrong.
      for (var hour = 0; hour < 24; hour += 3) {
        final jd = julianDay(DateTime.utc(2026, 5, 12, hour));
        const longitude = -74.0060;
        final mc = midheavenLongitude(jd: jd, longitudeEast: longitude);
        final obliquity = obliquityOfEcliptic(jd);
        final rightAscension = normalizeDegrees(
            _rightAscensionOf(mc, obliquity));
        final sidereal = localSiderealTime(jd, longitude);
        var gap = (rightAscension - sidereal).abs();
        if (gap > 180) gap = 360 - gap;
        expect(gap, lessThan(0.001), reason: 'hour $hour');
      }
    });

    test('every house has a meaning', () {
      expect(houseMeanings, hasLength(12));
      for (final meaning in houseMeanings) {
        expect(meaning, isNotEmpty);
      }
    });
  });

  group('the natal chart with planets', () {
    test('places all eight planets in signs and houses', () {
      final chart = _natal();
      expect(chart.planets, hasLength(8));
      for (final entry in chart.planets.entries) {
        expect(entry.value.house, inInclusiveRange(1, 12),
            reason: entry.key.label);
        expect(entry.value.formattedWithHouse, contains('house'));
      }
      expect(chart.midheaven, isNotNull);
      expect(chart.cusps, hasLength(12));
    });

    test('gives the big six an American reader expects', () {
      final six = _natal().bigSix;
      expect(six.keys,
          containsAll(['Sun', 'Moon', 'Rising', 'Mercury', 'Venus', 'Mars']));
    });

    test('Mercury is never more than a sign or two from the Sun', () {
      // The elongation bound again, but through the chart builder this time.
      final chart = _natal();
      var gap = (chart.planets[Planet.mercury]!.longitude -
              chart.sun.longitude)
          .abs();
      if (gap > 180) gap = 360 - gap;
      expect(gap, lessThan(28.5));
    });

    test('marks natal retrogrades', () {
      // Over a spread of birthdays some chart must have a retrograde planet:
      // the outer ones are retrograde around 40% of the time.
      var found = false;
      for (var month = 1; month <= 12; month++) {
        final chart = computeWesternChart(
          birthLocal: DateTime(1990, month, 15, 12),
          utcOffsetHours: 0,
          latitudeNorth: 40.7,
          longitudeEast: -74.0,
        );
        if (chart.natalRetrogrades.isNotEmpty) found = true;
      }
      expect(found, isTrue);
    });

    test('a chart with no birth place has no houses', () {
      final chart = computeWesternChart(
        birthLocal: DateTime(1990, 7, 4, 8, 30),
        utcOffsetHours: -4,
      );
      expect(chart.cusps, isNull);
      expect(chart.midheaven, isNull);
      // The planets are still known — only where they land is not.
      expect(chart.planets, hasLength(8));
      expect(chart.planets[Planet.venus]!.house, isNull);
    });
  });

  group('transits', () {
    test('are ordered with the slow planets on personal points first', () {
      final transits = transitsFor(natal: _natal(), jdUt: julianDay(
          DateTime.utc(2026, 5, 1)));
      for (var i = 1; i < transits.length; i++) {
        expect(transits[i - 1].weight,
            greaterThanOrEqualTo(transits[i].weight));
      }
    });

    test('stay inside the orb they were asked for', () {
      final transits = transitsFor(
          natal: _natal(), jdUt: julianDay(DateTime.utc(2026, 5, 1)),
          maxOrb: 3.0);
      for (final transit in transits) {
        expect(transit.orb, lessThanOrEqualTo(3.0));
      }
    });

    test('never report a planet conjunct its own natal place as a transit', () {
      // That is a return, and it is reported separately.
      for (var month = 1; month <= 12; month++) {
        final transits = transitsFor(
            natal: _natal(),
            jdUt: julianDay(DateTime.utc(2026, month, 1)));
        for (final transit in transits) {
          final isSelfConjunction =
              transit.transiting.label == transit.natalPoint &&
                  transit.aspect == Aspect.conjunction;
          expect(isSelfConjunction, isFalse);
        }
      }
    });

    test('carry a headline and a detail', () {
      final transits = transitsFor(
          natal: _natal(), jdUt: julianDay(DateTime.utc(2026, 5, 1)));
      for (final transit in transits) {
        expect(transit.headline, contains('Transiting'));
        expect(transit.detail, contains('from exact'));
      }
    });
  });

  group('planetary returns', () {
    test('the Saturn return lands around twenty-nine', () {
      // Saturn takes 29.46 years to come back, so scanning the birthday of
      // each year must find it in that window and not before.
      // Sampled monthly: Saturn covers 12 degrees a year and the orb is 10
      // degrees wide, so a yearly sample misses the window about one time in
      // five.
      final natal = _natal();
      final ages = <int>[];
      for (var month = 20 * 12; month <= 40 * 12; month++) {
        final age = month ~/ 12;
        final returns = returnsFor(
          natal: natal,
          jdUt: julianDay(DateTime.utc(1990 + age, 1 + month % 12, 15)),
          ageYears: age,
        );
        if (returns.any((r) => r.planet == Planet.saturn)) ages.add(age);
      }
      expect(ages, isNotEmpty);
      expect(ages.first, inInclusiveRange(27, 31));
    });

    test('the Jupiter return comes round about every twelve years', () {
      // Jupiter covers 30 degrees a year, so a yearly sample lands inside the
      // 10-degree orb only a third of the time. Monthly finds them all.
      final natal = _natal();
      final ages = <int>{};
      for (var month = 12; month <= 40 * 12; month++) {
        final age = month ~/ 12;
        final returns = returnsFor(
          natal: natal,
          jdUt: julianDay(DateTime.utc(1990 + age, 1 + month % 12, 15)),
          ageYears: age,
        );
        if (returns.any((r) => r.planet == Planet.jupiter)) ages.add(age);
      }
      final ordered = ages.toList()..sort();
      expect(ordered.length, greaterThanOrEqualTo(3));
      // Roughly every twelve years across the span.
      expect(ordered.last - ordered.first, greaterThanOrEqualTo(22));
    });

    test('a return is named with its ordinal', () {
      const first = PlanetaryReturn(planet: Planet.saturn, orb: 1, ordinal: 1);
      const second = PlanetaryReturn(planet: Planet.saturn, orb: 1, ordinal: 2);
      expect(first.label, 'Your Saturn return');
      expect(second.label, contains('second'));
      expect(first.detail, isNotEmpty);
    });
  });

  group('sky now', () {
    test('assembles the whole picture', () {
      final sky = skyNow(
          natal: _natal(), at: DateTime.utc(2026, 5, 1), ageYears: 35);
      expect(sky.headline, isNotEmpty);
      expect(sky.moon.phase, isNotNull);
      expect(sky.toJson()['moon'], contains('lit'));
    });

    test('leads with a Saturn return over anything else', () {
      // Whatever else is happening, this is the line the reader wants.
      final natal = _natal();
      for (var age = 27; age <= 31; age++) {
        final sky = skyNow(
            natal: natal,
            at: DateTime.utc(1990 + age, 7, 4),
            ageYears: age);
        if (sky.returns.any((r) => r.planet == Planet.saturn)) {
          expect(sky.headline, contains('Saturn return'));
          return;
        }
      }
    });

    test('does not repeat the headline in the list below it', () {
      for (var month = 1; month <= 12; month++) {
        final sky = skyNow(
            natal: _natal(),
            at: DateTime.utc(2026, month, 12),
            ageYears: 35);
        expect(sky.supportingTransits.map((t) => t.headline),
            isNot(contains(sky.headline)));
      }
    });

    test('reports Mercury retrograde when it is', () {
      var found = false;
      for (var day = 0; day < 400; day += 3) {
        final sky = skyNow(
          natal: _natal(),
          at: DateTime.utc(2026, 1, 1).add(Duration(days: day)),
          ageYears: 35,
        );
        if (sky.mercuryRetrograde) {
          found = true;
          expect(sky.retrogrades, contains(Planet.mercury));
        }
      }
      expect(found, isTrue);
    });
  });
}

/// Right ascension of an ecliptic longitude, for the Midheaven check.
double _rightAscensionOf(double longitude, double obliquity) {
  const toRadians = math.pi / 180.0;
  final y = math.cos(obliquity * toRadians) * math.sin(longitude * toRadians);
  final x = math.cos(longitude * toRadians);
  return math.atan2(y, x) / toRadians;
}
