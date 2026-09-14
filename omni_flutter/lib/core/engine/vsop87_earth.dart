/// Truncated VSOP87D series for the heliocentric ecliptic longitude of the
/// Earth, plus the Delta-T model needed to turn dynamical time into UTC.
///
/// Only the longitude (L) series is carried; the latitude and radius series are
/// not needed to place the Sun in a sign or to solve for a solar term. Accuracy
/// of this truncation is roughly one arcsecond over 1900-2100, which is about
/// twenty seconds of clock time on a solar-term boundary.
///
/// Each row is `[amplitude (1e-8 rad), phase (rad), frequency (rad/millennium)]`
/// and contributes `amplitude * cos(phase + frequency * tau)`.
library;

import 'dart:math' as math;

const List<List<double>> _l0 = [
  [175347046, 0, 0],
  [3341656, 4.6692568, 6283.0758500],
  [34894, 4.62610, 12566.15170],
  [3497, 2.7441, 5753.3849],
  [3418, 2.8289, 3.5231],
  [3136, 3.6277, 77713.7715],
  [2676, 4.4181, 7860.4194],
  [2343, 6.1352, 3930.2097],
  [1324, 0.7425, 11506.7698],
  [1273, 2.0371, 529.6910],
  [1199, 1.1096, 1577.3435],
  [990, 5.233, 5884.927],
  [902, 2.045, 26.298],
  [857, 3.508, 398.149],
  [780, 1.179, 5223.694],
  [753, 2.533, 5507.553],
  [505, 4.583, 18849.228],
  [492, 4.205, 775.523],
  [357, 2.920, 0.067],
  [317, 5.849, 11790.629],
  [284, 1.899, 796.298],
  [271, 0.315, 10977.079],
  [243, 0.345, 5486.778],
  [206, 4.806, 2544.314],
  [205, 1.869, 5573.143],
  [202, 2.458, 6069.777],
  [156, 0.833, 213.299],
  [132, 3.411, 2942.463],
  [126, 1.083, 20.775],
  [115, 0.645, 0.980],
  [103, 0.636, 4694.003],
  [102, 0.976, 15720.839],
  [102, 4.267, 7.114],
  [99, 6.21, 2146.17],
  [98, 0.68, 155.42],
  [86, 5.98, 161000.69],
  [85, 1.30, 6275.96],
  [85, 3.67, 71430.70],
  [80, 1.81, 17260.15],
  [79, 3.04, 12036.46],
  [75, 1.76, 5088.63],
  [74, 3.50, 3154.69],
  [74, 4.68, 801.82],
  [70, 0.83, 9437.76],
  [62, 3.98, 8827.39],
  [61, 1.82, 7084.90],
  [57, 2.78, 6286.60],
  [56, 4.39, 14143.50],
  [56, 3.47, 6279.55],
  [52, 0.19, 12139.55],
  [52, 1.33, 1748.02],
  [51, 0.28, 5856.48],
  [49, 0.49, 1194.45],
  [41, 5.37, 8429.24],
  [41, 2.40, 19651.05],
  [39, 6.17, 10447.39],
  [37, 6.04, 10213.29],
  [37, 2.57, 1059.38],
  [36, 1.71, 2352.87],
  [36, 1.78, 6812.77],
  [33, 0.59, 17789.85],
  [30, 0.44, 83996.85],
  [30, 2.74, 1349.87],
  [25, 3.16, 4690.48],
];

const List<List<double>> _l1 = [
  [628331966747, 0, 0],
  [206059, 2.678235, 6283.075850],
  [4303, 2.6351, 12566.1517],
  [425, 1.590, 3.523],
  [119, 5.796, 26.298],
  [109, 2.966, 1577.344],
  [93, 2.59, 18849.23],
  [72, 1.14, 529.69],
  [68, 1.87, 398.15],
  [67, 4.41, 5507.55],
  [59, 2.89, 5223.69],
  [56, 2.17, 155.42],
  [45, 0.40, 796.30],
  [36, 0.47, 775.52],
  [29, 2.65, 7.11],
  [21, 5.34, 0.98],
  [19, 1.85, 5486.78],
  [19, 4.97, 213.30],
  [17, 2.99, 6275.96],
  [16, 0.03, 2544.31],
  [16, 1.43, 2146.17],
  [15, 1.21, 10977.08],
  [12, 2.83, 1748.02],
  [12, 3.26, 5088.63],
  [12, 5.27, 1194.45],
  [12, 2.08, 4694.00],
  [11, 0.77, 553.57],
  [10, 1.30, 6286.60],
  [10, 4.24, 1349.87],
  [9, 2.70, 242.73],
  [9, 5.64, 951.72],
  [8, 5.30, 2352.87],
  [6, 2.65, 9437.76],
  [6, 4.67, 4690.48],
];

const List<List<double>> _l2 = [
  [52919, 0, 0],
  [8720, 1.0721, 6283.0758],
  [309, 0.867, 12566.152],
  [27, 0.05, 3.52],
  [16, 5.19, 26.30],
  [16, 3.68, 155.42],
  [10, 0.76, 18849.23],
  [9, 2.06, 77713.77],
  [7, 0.83, 775.52],
  [5, 4.66, 1577.34],
  [4, 1.03, 7.11],
  [4, 3.44, 5573.14],
  [3, 5.14, 796.30],
  [3, 6.05, 5507.55],
  [3, 1.19, 242.73],
  [3, 6.12, 529.69],
  [3, 0.31, 398.15],
  [3, 2.28, 553.57],
  [2, 4.38, 5223.69],
  [2, 3.75, 0.98],
];

const List<List<double>> _l3 = [
  [289, 5.844, 6283.076],
  [35, 0, 0],
  [17, 5.49, 12566.15],
  [3, 5.20, 155.42],
  [1, 4.72, 3.52],
  [1, 5.30, 18849.23],
  [1, 5.97, 242.73],
];

const List<List<double>> _l4 = [
  [114, 3.142, 0],
  [8, 4.13, 6283.08],
  [1, 3.84, 12566.15],
];

const List<List<double>> _l5 = [
  [1, 3.14, 0],
];

double _series(List<List<double>> terms, double tau) {
  var sum = 0.0;
  for (final t in terms) {
    sum += t[0] * math.cos(t[1] + t[2] * tau);
  }
  return sum;
}

/// Heliocentric ecliptic longitude of the Earth in radians, referred to the
/// mean dynamical ecliptic and equinox of date. [jde] is a Julian Ephemeris Day
/// (i.e. in TT, not UT).
double earthHeliocentricLongitude(double jde) {
  final tau = (jde - 2451545.0) / 365250.0;
  final l = _series(_l0, tau) +
      _series(_l1, tau) * tau +
      _series(_l2, tau) * math.pow(tau, 2) +
      _series(_l3, tau) * math.pow(tau, 3) +
      _series(_l4, tau) * math.pow(tau, 4) +
      _series(_l5, tau) * math.pow(tau, 5);
  return l / 1e8;
}

/// Earth-Sun distance in astronomical units.
///
/// Taken from the orbital elements rather than the VSOP87 R series: the result
/// is only used to scale aberration (a 20.5 arcsecond effect), where four
/// significant figures are ample.
double earthSunDistanceAu(double jde) {
  final t = (jde - 2451545.0) / 36525.0;
  final m = (357.52911 + 35999.05029 * t - 0.0001537 * t * t) * math.pi / 180.0;
  final e = 0.016708634 - 0.000042037 * t - 0.0000001267 * t * t;
  final c = ((1.914602 - 0.004817 * t - 0.000014 * t * t) * math.sin(m) +
          (0.019993 - 0.000101 * t) * math.sin(2 * m) +
          0.000289 * math.sin(3 * m)) *
      math.pi /
      180.0;
  final nu = m + c;
  return 1.000001018 * (1 - e * e) / (1 + e * math.cos(nu));
}

/// Nutation in longitude, in degrees (leading terms of the IAU 1980 series;
/// residual below one arcsecond).
double nutationInLongitude(double jde) {
  final t = (jde - 2451545.0) / 36525.0;
  const d2r = math.pi / 180.0;
  // Mean elongation of the Moon from the Sun.
  final d = (297.85036 + 445267.111480 * t - 0.0019142 * t * t) * d2r;
  // Mean anomaly of the Sun.
  final m = (357.52772 + 35999.050340 * t - 0.0001603 * t * t) * d2r;
  // Mean anomaly of the Moon.
  final mp = (134.96298 + 477198.867398 * t + 0.0086972 * t * t) * d2r;
  // Moon's argument of latitude.
  final f = (93.27191 + 483202.017538 * t - 0.0036825 * t * t) * d2r;
  // Longitude of the ascending node of the Moon's mean orbit.
  final omega = (125.04452 - 1934.136261 * t + 0.0020708 * t * t) * d2r;

  // Arcseconds.
  final dPsi = -17.1996 * math.sin(omega) +
      0.2062 * math.sin(2 * omega) +
      -1.3187 * math.sin(2 * (f - d + omega)) +
      0.1426 * math.sin(m) +
      -0.2274 * math.sin(2 * (f + omega)) +
      0.0712 * math.sin(mp) +
      -0.0517 * math.sin(2 * (f - d + omega) + m) +
      -0.0386 * math.sin(2 * f + omega) +
      -0.0301 * math.sin(mp + 2 * (f + omega)) +
      0.0217 * math.sin(2 * (f - d + omega) - m);
  return dPsi / 3600.0;
}

/// Difference TT - UT1 in seconds (Espenak & Meeus polynomials).
///
/// Needed because the ephemeris runs on dynamical time while users type civil
/// clock times. Around the present epoch this is about seventy seconds.
double deltaTSeconds(double decimalYear) {
  final y = decimalYear;
  if (y < 1600) {
    // Deep history is irrelevant for birth charts; hold the 1600 value.
    return 120.0;
  } else if (y < 1700) {
    final t = y - 1600;
    return 120 - 0.9808 * t - 0.01532 * t * t + t * t * t / 7129.0;
  } else if (y < 1800) {
    final t = y - 1700;
    return 8.83 +
        0.1603 * t -
        0.0059285 * t * t +
        0.00013336 * t * t * t -
        t * t * t * t / 1174000.0;
  } else if (y < 1860) {
    final t = y - 1800;
    return 13.72 -
        0.332447 * t +
        0.0068612 * t * t +
        0.0041116 * t * t * t -
        0.00037436 * math.pow(t, 4) +
        0.0000121272 * math.pow(t, 5) -
        0.0000001699 * math.pow(t, 6) +
        0.000000000875 * math.pow(t, 7);
  } else if (y < 1900) {
    final t = y - 1860;
    return 7.62 +
        0.5737 * t -
        0.251754 * t * t +
        0.01680668 * t * t * t -
        0.0004473624 * math.pow(t, 4) +
        math.pow(t, 5) / 233174.0;
  } else if (y < 1920) {
    final t = y - 1900;
    return -2.79 +
        1.494119 * t -
        0.0598939 * t * t +
        0.0061966 * t * t * t -
        0.000197 * math.pow(t, 4);
  } else if (y < 1941) {
    final t = y - 1920;
    return 21.20 + 0.84493 * t - 0.076100 * t * t + 0.0020936 * t * t * t;
  } else if (y < 1961) {
    final t = y - 1950;
    return 29.07 + 0.407 * t - t * t / 233.0 + t * t * t / 2547.0;
  } else if (y < 1986) {
    final t = y - 1975;
    return 45.45 + 1.067 * t - t * t / 260.0 - t * t * t / 718.0;
  } else if (y < 2005) {
    final t = y - 2000;
    return 63.86 +
        0.3345 * t -
        0.060374 * t * t +
        0.0017275 * t * t * t +
        0.000651814 * math.pow(t, 4) +
        0.00002373599 * math.pow(t, 5);
  } else if (y < 2050) {
    final t = y - 2000;
    return 62.92 + 0.32217 * t + 0.005589 * t * t;
  } else if (y < 2150) {
    return -20 + 32 * math.pow((y - 1820) / 100.0, 2) - 0.5628 * (2150 - y);
  }
  final u = (y - 1820) / 100.0;
  return -20 + 32 * u * u;
}
