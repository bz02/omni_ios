/// Low-level astronomical math shared by the Western chart and the Chinese
/// four-pillars engine.
///
/// Everything here is pure Dart with no Flutter dependency so it can be
/// verified with `dart test`. Measured accuracy:
///   * solar longitude  — under one arcsecond; solar terms land within about
///     twenty seconds of the published times
///   * lunar longitude  — around 0.3 degrees, so a Moon within half a degree of
///     a cusp may be reported one sign off
///   * ascendant        — limited by the clock time the user typed, not by the
///     math (one minute of clock is a quarter degree of ascendant)
library;

import 'dart:math' as math;

import 'vsop87_earth.dart';

const double _deg2rad = math.pi / 180.0;

double _sinDeg(double deg) => math.sin(deg * _deg2rad);
double _cosDeg(double deg) => math.cos(deg * _deg2rad);
double _tanDeg(double deg) => math.tan(deg * _deg2rad);

/// Wraps an angle into `[0, 360)`.
double normalizeDegrees(double deg) {
  final wrapped = deg % 360.0;
  return wrapped < 0 ? wrapped + 360.0 : wrapped;
}

/// Julian Day for an instant in UTC (Meeus, *Astronomical Algorithms* ch. 7).
double julianDay(DateTime utc) {
  assert(utc.isUtc, 'julianDay expects a UTC instant');
  var year = utc.year;
  var month = utc.month;
  final dayFraction = utc.day +
      (utc.hour +
              utc.minute / 60.0 +
              utc.second / 3600.0 +
              utc.millisecond / 3600000.0) /
          24.0;

  if (month <= 2) {
    year -= 1;
    month += 12;
  }

  // Gregorian calendar correction. Every date this app can produce is
  // post-1583, so the Julian-calendar branch is intentionally omitted.
  final a = (year / 100).floor();
  final b = 2 - a + (a / 4).floor();

  return (365.25 * (year + 4716)).floor() +
      (30.6001 * (month + 1)).floor() +
      dayFraction +
      b -
      1524.5;
}

/// Inverse of [julianDay], to UTC.
DateTime dateFromJulianDay(double jd) {
  final ms = ((jd - 2440587.5) * 86400000.0).round();
  return DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);
}

/// Julian centuries since J2000.0.
double julianCenturies(double jd) => (jd - 2451545.0) / 36525.0;

/// Julian Day Number of the *local* civil date — the integer used to index the
/// sexagenary day cycle. Deliberately ignores the time of day.
int julianDayNumberOfLocalDate(int year, int month, int day) {
  var y = year;
  var m = month;
  if (m <= 2) {
    y -= 1;
    m += 12;
  }
  final a = (y / 100).floor();
  final b = 2 - a + (a / 4).floor();
  // +0.5 then floor gives the JDN whose day starts at the preceding midnight.
  return (365.25 * (y + 4716)).floor() +
      (30.6001 * (m + 1)).floor() +
      day +
      b -
      1524;
}

/// Mean obliquity of the ecliptic, in degrees.
double obliquityOfEcliptic(double jd) {
  final t = julianCenturies(jd);
  return 23.439291 - 0.0130042 * t - 1.64e-7 * t * t + 5.04e-7 * t * t * t;
}

/// Converts a Julian Day in UT to a Julian Ephemeris Day in TT.
double jdeFromJdUt(double jdUt) {
  final year = dateFromJulianDay(jdUt).year + 0.5;
  return jdUt + deltaTSeconds(year) / 86400.0;
}

/// Apparent geocentric ecliptic longitude of the Sun in degrees, for a Julian
/// Ephemeris Day (TT).
///
/// This one function does double duty: it gives the Western Sun sign and, by
/// solving for exact multiples of 15 degrees, the twenty-four Chinese solar
/// terms that decide which month pillar a birth falls in.
double apparentSolarLongitudeTT(double jde) {
  // Heliocentric longitude of the Earth, flipped to give the geocentric Sun.
  final theta = earthHeliocentricLongitude(jde) / _deg2rad + 180.0;

  // VSOP87's dynamical ecliptic to the FK5 system. The latitude-dependent part
  // of the correction is under a hundredth of an arcsecond for the Sun.
  final lambda = theta - 0.09033 / 3600.0;

  // Nutation, then aberration scaled by the current Earth-Sun distance.
  final aberration = -20.4898 / 3600.0 / earthSunDistanceAu(jde);
  return normalizeDegrees(lambda + nutationInLongitude(jde) + aberration);
}

/// Apparent solar longitude for a Julian Day expressed in UT.
double solarLongitude(double jdUt) =>
    apparentSolarLongitudeTT(jdeFromJdUt(jdUt));

/// Geocentric ecliptic longitude of the Moon, in degrees.
///
/// Abbreviated series (Meeus ch. 47, largest terms only): roughly 0.3 degrees
/// of error, so a Moon sitting within half a degree of a cusp may be reported
/// one sign off. [ChartPrecision] exposes that caveat to the UI.
double lunarLongitude(double jdUt) {
  final t = julianCenturies(jdeFromJdUt(jdUt));
  final longitude = 218.32 +
      481267.8813 * t +
      6.29 * _sinDeg(134.9 + 477198.85 * t) -
      1.27 * _sinDeg(259.2 - 413335.38 * t) +
      0.66 * _sinDeg(235.7 + 890534.23 * t) +
      0.21 * _sinDeg(269.9 + 954397.70 * t) -
      0.19 * _sinDeg(357.5 + 35999.05 * t) -
      0.11 * _sinDeg(186.6 + 966404.05 * t);
  return normalizeDegrees(longitude);
}

/// Greenwich mean sidereal time in degrees.
double greenwichMeanSiderealTime(double jd) {
  final t = julianCenturies(jd);
  final theta = 280.46061837 +
      360.98564736629 * (jd - 2451545.0) +
      0.000387933 * t * t -
      t * t * t / 38710000.0;
  return normalizeDegrees(theta);
}

/// Local sidereal time in degrees. [longitudeEast] is positive east of
/// Greenwich (so New York is about -74).
double localSiderealTime(double jd, double longitudeEast) =>
    normalizeDegrees(greenwichMeanSiderealTime(jd) + longitudeEast);

/// Ecliptic longitude of the ascendant — the degree of the zodiac rising on the
/// eastern horizon, which is what "rising sign" means.
///
/// [latitude] is positive north. Above the polar circles the ascendant is not
/// always defined; the caller should fall back to the Sun sign there.
double ascendantLongitude({
  required double jd,
  required double latitudeNorth,
  required double longitudeEast,
}) {
  final ramc = localSiderealTime(jd, longitudeEast);
  final eps = obliquityOfEcliptic(jd);

  // Clamp latitude away from the poles so tan() stays finite.
  final lat = latitudeNorth.clamp(-89.5, 89.5).toDouble();

  final y = _cosDeg(ramc);
  final x = -(_sinDeg(ramc) * _cosDeg(eps) + _tanDeg(lat) * _sinDeg(eps));
  return normalizeDegrees(math.atan2(y, x) / _deg2rad);
}

/// Solves for the instant when the Sun reaches [targetLongitude] degrees,
/// searching forward from [afterUtc] within [searchDays].
///
/// Used to find solar terms (the Sun at exact multiples of 15 degrees). Bisects
/// on the *unwrapped* angular difference so the 360-to-0 rollover is handled.
DateTime? solveSolarLongitude(
  double targetLongitude, {
  required DateTime afterUtc,
  double searchDays = 400,
  double toleranceSeconds = 1,
}) {
  double diff(double jd) {
    // Signed difference in (-180, 180]: negative before the target.
    var d = solarLongitude(jd) - targetLongitude;
    d = (d + 180.0) % 360.0;
    if (d < 0) d += 360.0;
    return d - 180.0;
  }

  var lo = julianDay(afterUtc.toUtc());
  final limit = lo + searchDays;

  // Step forward in half-day increments until the difference crosses zero from
  // negative to positive. Half a day is short enough that the Sun (about 1
  // degree per day) cannot skip past the target.
  const step = 0.5;
  var fLo = diff(lo);
  while (lo < limit) {
    final hi = lo + step;
    final fHi = diff(hi);
    if (fLo <= 0 && fHi > 0) {
      var a = lo;
      var b = hi;
      final tolDays = toleranceSeconds / 86400.0;
      while (b - a > tolDays) {
        final mid = (a + b) / 2;
        if (diff(mid) <= 0) {
          a = mid;
        } else {
          b = mid;
        }
      }
      return dateFromJulianDay((a + b) / 2);
    }
    lo = hi;
    fLo = fHi;
  }
  return null;
}

/// How much to trust a computed chart, so the UI can be honest instead of
/// pretending to a precision the inputs do not support.
enum ChartPrecision {
  /// Birth time and place both supplied — every placement is meaningful.
  full,

  /// Birth time supplied but no place; the ascendant is omitted.
  noBirthPlace,

  /// No birth time; the Moon and the ascendant are omitted, and the hour pillar
  /// is unknown.
  dateOnly,
}
