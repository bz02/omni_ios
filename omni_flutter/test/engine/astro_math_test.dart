import 'package:flutter_test/flutter_test.dart';
import 'package:omni_flutter/core/engine/astro_math.dart';

/// Published times are from the Astronomical Almanac / Purple Mountain
/// Observatory. They are the reason this file exists: a divination app that
/// silently computes the wrong sign is worse than one that admits uncertainty.
void main() {
  group('julian day', () {
    test('J2000 epoch', () {
      expect(julianDay(DateTime.utc(2000, 1, 1, 12)), closeTo(2451545.0, 1e-9));
    });

    test('round trips through dateFromJulianDay', () {
      final d = DateTime.utc(1987, 4, 10, 19, 21);
      expect(dateFromJulianDay(julianDay(d)).difference(d).inSeconds.abs(),
          lessThanOrEqualTo(1));
    });

    test('day numbers advance by one per calendar day across a month end', () {
      expect(julianDayNumberOfLocalDate(2024, 3, 1) -
              julianDayNumberOfLocalDate(2024, 2, 29),
          1);
    });
  });

  group('solar longitude', () {
    test('matches the Meeus worked example for 1992 October 13.0 TD', () {
      // Meeus works this date twice. The abbreviated method gives 199.90730
      // degrees; the VSOP87 method gives 199.90600. This engine implements the
      // second, and the eight solar-term times below corroborate it: an error
      // of even five arcseconds would show up there as seven minutes of clock
      // time, and it does not.
      expect(apparentSolarLongitudeTT(2448908.5), closeTo(199.90600, 0.001));
    });

    test('solves equinoxes, solstices and solar terms within a minute', () {
      final references = <(double, DateTime, String)>[
        (0, DateTime.utc(2024, 3, 20, 3, 6), 'March equinox 2024'),
        (90, DateTime.utc(2024, 6, 20, 20, 51), 'June solstice 2024'),
        (180, DateTime.utc(2024, 9, 22, 12, 44), 'September equinox 2024'),
        (270, DateTime.utc(2024, 12, 21, 9, 21), 'December solstice 2024'),
        (0, DateTime.utc(2000, 3, 20, 7, 35), 'March equinox 2000'),
        (270, DateTime.utc(2000, 12, 21, 13, 37), 'December solstice 2000'),
        (315, DateTime.utc(2024, 2, 4, 8, 27), 'Start of Spring 2024'),
        (315, DateTime.utc(2025, 2, 3, 14, 10), 'Start of Spring 2025'),
      ];

      for (final (longitude, published, label) in references) {
        final solved = solveSolarLongitude(longitude,
            afterUtc: published.subtract(const Duration(days: 20)));
        expect(solved, isNotNull, reason: '$label did not converge');
        expect(solved!.difference(published).inSeconds.abs(), lessThan(60),
            reason: '$label off by ${solved.difference(published)}');
      }
    });

    test('advances about a degree a day', () {
      final a = solarLongitude(julianDay(DateTime.utc(2024, 5, 1)));
      final b = solarLongitude(julianDay(DateTime.utc(2024, 5, 2)));
      expect(b - a, closeTo(0.9856, 0.05));
    });
  });

  group('lunar longitude', () {
    test('matches Meeus example 47.a within the truncation error', () {
      expect(lunarLongitude(2448724.5), closeTo(133.162655, 0.5));
    });

    test('returns to the same longitude after one sidereal month', () {
      final a = lunarLongitude(2451545.0);
      final b = lunarLongitude(2451545.0 + 27.321582);
      var drift = (b - a).abs();
      if (drift > 180) drift = 360 - drift;
      expect(drift, lessThan(3.0));
    });
  });

  group('ascendant', () {
    // At sunrise the Sun is on the eastern horizon, so it must sit on the
    // ascendant. This is a physical identity, independent of any reference
    // table, and it catches sign errors in the latitude and sidereal terms.
    test('coincides with the Sun at sunrise in the northern hemisphere', () {
      final jd = julianDay(DateTime.utc(2024, 6, 21, 9, 25)); // NYC sunrise
      final gap = _separation(
        ascendantLongitude(
            jd: jd, latitudeNorth: 40.7128, longitudeEast: -74.0060),
        solarLongitude(jd),
      );
      expect(gap, lessThan(2.0));
    });

    test('coincides with the Sun at sunrise in the southern hemisphere', () {
      final jd = julianDay(DateTime.utc(2024, 6, 20, 21, 0)); // Sydney sunrise
      final gap = _separation(
        ascendantLongitude(
            jd: jd, latitudeNorth: -33.8688, longitudeEast: 151.2093),
        solarLongitude(jd),
      );
      expect(gap, lessThan(2.5));
    });

    test('passes through all twelve signs in a day', () {
      final signs = <int>{};
      for (var hour = 0; hour < 24; hour++) {
        final jd = julianDay(DateTime.utc(2024, 3, 20, hour));
        signs.add((ascendantLongitude(
                    jd: jd, latitudeNorth: 40.7, longitudeEast: -74.0) /
                30)
            .floor());
      }
      expect(signs.length, 12);
    });

    test('stays finite at extreme latitudes', () {
      final jd = julianDay(DateTime.utc(2024, 1, 15, 6));
      final asc = ascendantLongitude(
          jd: jd, latitudeNorth: 89.9, longitudeEast: 20.0);
      expect(asc.isFinite, isTrue);
      expect(asc, inInclusiveRange(0, 360));
    });
  });

  test('normalizeDegrees wraps negatives and multiples', () {
    expect(normalizeDegrees(-10), closeTo(350, 1e-9));
    expect(normalizeDegrees(730), closeTo(10, 1e-9));
    expect(normalizeDegrees(360), closeTo(0, 1e-9));
  });
}

double _separation(double a, double b) {
  var gap = (a - b).abs();
  if (gap > 180) gap = 360 - gap;
  return gap;
}
