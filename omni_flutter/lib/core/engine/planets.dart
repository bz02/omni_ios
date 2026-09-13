/// Positions of the planets.
///
/// An American astrology app without planets is not an astrology app. Sun,
/// Moon and Rising is the elevator summary; Mercury retrograde, Venus in your
/// seventh, Saturn return — that is the vocabulary the audience actually uses,
/// and the daily hook that brings them back.
///
/// **Why Keplerian elements rather than VSOP87.** The full series is more
/// accurate by orders of magnitude and needs thousands of hand-entered
/// coefficients to get there. Astrology needs a planet in the right sign and
/// the right direction of travel, which wants arcminutes, not milliarcseconds.
/// JPL's approximate elements deliver that from 250 numbers over 1800–2050,
/// and every one of them is checkable against a physical invariant — an inner
/// planet that wanders too far from the Sun, or an orbit with the wrong
/// period, fails a test rather than quietly shipping a wrong chart.
library;

import 'dart:math' as math;

import 'astro_math.dart';
import 'vsop87_earth.dart' show earthHeliocentricLongitude, earthSunDistanceAu;

const double _deg = math.pi / 180.0;

enum Planet {
  mercury('Mercury', '☿', 'how you think and talk'),
  venus('Venus', '♀', 'what you want and how you love'),
  mars('Mars', '♂', 'how you go after things'),
  jupiter('Jupiter', '♃', 'where you get lucky and overdo it'),
  saturn('Saturn', '♄', 'where the work is'),
  uranus('Uranus', '♅', 'where you break the pattern'),
  neptune('Neptune', '♆', 'where the fog is'),
  pluto('Pluto', '♇', 'what keeps being torn down and rebuilt');

  const Planet(this.label, this.glyph, this.gist);
  final String label;
  final String glyph;

  /// One line an American reader can act on, not a textbook definition.
  final String gist;

  /// The three that move fast enough to matter personally rather than
  /// generationally.
  bool get isPersonal =>
      this == Planet.mercury || this == Planet.venus || this == Planet.mars;
}

/// Mean orbital elements and their per-century rates.
///
/// From JPL's "Keplerian Elements for Approximate Positions of the Major
/// Planets", the 1800–2050 set. Angles in degrees, [a] in astronomical units.
class _Elements {
  const _Elements(
    this.a, this.aDot,
    this.e, this.eDot,
    this.i, this.iDot,
    this.meanLongitude, this.meanLongitudeDot,
    this.perihelion, this.perihelionDot,
    this.node, this.nodeDot,
  );

  final double a, aDot;
  final double e, eDot;
  final double i, iDot;
  final double meanLongitude, meanLongitudeDot;
  final double perihelion, perihelionDot;
  final double node, nodeDot;
}

const Map<Planet, _Elements> _elements = {
  Planet.mercury: _Elements(
    0.38709927, 0.00000037,
    0.20563593, 0.00001906,
    7.00497902, -0.00594749,
    252.25032350, 149472.67411175,
    77.45779628, 0.16047689,
    48.33076593, -0.12534081,
  ),
  Planet.venus: _Elements(
    0.72333566, 0.00000390,
    0.00677672, -0.00004107,
    3.39467605, -0.00078890,
    181.97909950, 58517.81538729,
    131.60246718, 0.00268329,
    76.67984255, -0.27769418,
  ),
  Planet.mars: _Elements(
    1.52371034, 0.00001847,
    0.09339410, 0.00007882,
    1.84969142, -0.00813131,
    -4.55343205, 19140.30268499,
    -23.94362959, 0.44441088,
    49.55953891, -0.29257343,
  ),
  Planet.jupiter: _Elements(
    5.20288700, -0.00011607,
    0.04838624, -0.00013253,
    1.30439695, -0.00183714,
    34.39644051, 3034.74612775,
    14.72847983, 0.21252668,
    100.47390909, 0.20469106,
  ),
  Planet.saturn: _Elements(
    9.53667594, -0.00125060,
    0.05386179, -0.00050991,
    2.48599187, 0.00193609,
    49.95424423, 1222.49362201,
    92.59887831, -0.41897216,
    113.66242448, -0.28867794,
  ),
  Planet.uranus: _Elements(
    19.18916464, -0.00196176,
    0.04725744, -0.00004397,
    0.77263783, -0.00242939,
    313.23810451, 428.48202785,
    170.95427630, 0.40805281,
    74.01692503, 0.04240589,
  ),
  Planet.neptune: _Elements(
    30.06992276, 0.00026291,
    0.00859048, 0.00005105,
    1.77004347, 0.00035372,
    -55.12002969, 218.45945325,
    44.96476227, -0.32241464,
    131.78422574, -0.00508664,
  ),
  Planet.pluto: _Elements(
    39.48211675, -0.00031596,
    0.24882730, 0.00005170,
    17.14001206, 0.00004818,
    238.92903833, 145.20780515,
    224.06891629, -0.04062942,
    110.30393684, -0.01183482,
  ),
};

/// Heliocentric ecliptic position, in astronomical units.
class _Heliocentric {
  const _Heliocentric(this.x, this.y, this.z);
  final double x, y, z;
}

_Heliocentric _heliocentricOf(Planet planet, double centuries) {
  final el = _elements[planet]!;

  final a = el.a + el.aDot * centuries;
  final e = el.e + el.eDot * centuries;
  final i = el.i + el.iDot * centuries;
  final l = el.meanLongitude + el.meanLongitudeDot * centuries;
  final perihelion = el.perihelion + el.perihelionDot * centuries;
  final node = el.node + el.nodeDot * centuries;

  final argumentOfPerihelion = perihelion - node;
  final meanAnomaly = normalizeDegrees(l - perihelion + 180.0) - 180.0;

  final eccentricAnomaly = _solveKepler(meanAnomaly, e);

  // Position in the orbital plane.
  final xOrbit = a * (math.cos(eccentricAnomaly * _deg) - e);
  final yOrbit =
      a * math.sqrt(1 - e * e) * math.sin(eccentricAnomaly * _deg);

  // Rotate into the ecliptic: argument of perihelion, then inclination, then
  // the ascending node.
  final cosW = math.cos(argumentOfPerihelion * _deg);
  final sinW = math.sin(argumentOfPerihelion * _deg);
  final cosO = math.cos(node * _deg);
  final sinO = math.sin(node * _deg);
  final cosI = math.cos(i * _deg);
  final sinI = math.sin(i * _deg);

  final x = (cosW * cosO - sinW * sinO * cosI) * xOrbit +
      (-sinW * cosO - cosW * sinO * cosI) * yOrbit;
  final y = (cosW * sinO + sinW * cosO * cosI) * xOrbit +
      (-sinW * sinO + cosW * cosO * cosI) * yOrbit;
  final z = sinW * sinI * xOrbit + cosW * sinI * yOrbit;

  return _Heliocentric(x, y, z);
}

/// Solves Kepler's equation for the eccentric anomaly, in degrees.
///
/// Newton's method. Mercury's eccentricity of 0.21 and Pluto's of 0.25 both
/// converge in a handful of steps; the iteration cap only exists so a bad
/// element can never hang the app.
double _solveKepler(double meanAnomalyDeg, double e) {
  final eStar = e / _deg;
  var eccentric = meanAnomalyDeg + eStar * math.sin(meanAnomalyDeg * _deg);

  for (var iteration = 0; iteration < 12; iteration++) {
    final delta = meanAnomalyDeg -
        (eccentric - eStar * math.sin(eccentric * _deg));
    final step = delta / (1 - e * math.cos(eccentric * _deg));
    eccentric += step;
    if (step.abs() < 1e-9) break;
  }
  return eccentric;
}

/// Apparent geocentric ecliptic longitude of [planet], in degrees.
///
/// [jdUt] is a Julian Day in UT.
double planetLongitude(Planet planet, double jdUt) {
  final jde = jdeFromJdUt(jdUt);
  final centuries = julianCenturies(jde);

  final body = _heliocentricOf(planet, centuries);

  // Earth's own position, reusing the high-accuracy solar series rather than
  // a second set of elements: the Sun's longitude is Earth's plus 180, and
  // Earth's ecliptic latitude is under an arcsecond.
  final earthLongitude = earthHeliocentricLongitude(jde) / _deg;
  final earthRadius = earthSunDistanceAu(jde);
  final earthX = earthRadius * math.cos(earthLongitude * _deg);
  final earthY = earthRadius * math.sin(earthLongitude * _deg);

  return normalizeDegrees(
    math.atan2(body.y - earthY, body.x - earthX) / _deg,
  );
}

/// Distance from Earth in astronomical units. Used to tell a planet's
/// retrograde loop from ordinary motion.
double planetDistance(Planet planet, double jdUt) {
  final jde = jdeFromJdUt(jdUt);
  final centuries = julianCenturies(jde);
  final body = _heliocentricOf(planet, centuries);

  final earthLongitude = earthHeliocentricLongitude(jde) / _deg;
  final earthRadius = earthSunDistanceAu(jde);
  final dx = body.x - earthRadius * math.cos(earthLongitude * _deg);
  final dy = body.y - earthRadius * math.sin(earthLongitude * _deg);
  final dz = body.z;
  return math.sqrt(dx * dx + dy * dy + dz * dz);
}

/// Apparent daily motion in ecliptic longitude, degrees per day.
///
/// Negative means retrograde. Measured over a symmetric two-day window, which
/// is wide enough to be free of rounding noise and narrow enough to catch the
/// day a planet stations.
double planetDailyMotion(Planet planet, double jdUt) {
  final before = planetLongitude(planet, jdUt - 1);
  final after = planetLongitude(planet, jdUt + 1);
  var delta = after - before;
  // Unwrap across 360.
  if (delta > 180) delta -= 360;
  if (delta < -180) delta += 360;
  return delta / 2.0;
}

bool isRetrograde(Planet planet, double jdUt) =>
    planetDailyMotion(planet, jdUt) < 0;

/// Everything the reading layer needs about one planet at one moment.
class PlanetPosition {
  const PlanetPosition({
    required this.planet,
    required this.longitude,
    required this.dailyMotion,
  });

  final Planet planet;
  final double longitude;
  final double dailyMotion;

  bool get isRetrograde => dailyMotion < 0;

  /// Within a hair of stationary — the days either side of a direction
  /// change, which astrologers read as the most charged part of a retrograde.
  bool get isStationary => dailyMotion.abs() < 0.01;

  String get motionLabel => isStationary
      ? 'stationary'
      : isRetrograde
          ? 'retrograde'
          : 'direct';

  Map<String, dynamic> toJson() => {
        'planet': planet.label,
        'longitude': longitude.toStringAsFixed(2),
        'motion': motionLabel,
      };
}

/// Positions of every planet at one instant.
Map<Planet, PlanetPosition> allPlanetPositions(double jdUt) => {
      for (final planet in Planet.values)
        planet: PlanetPosition(
          planet: planet,
          longitude: planetLongitude(planet, jdUt),
          dailyMotion: planetDailyMotion(planet, jdUt),
        ),
    };

/// The planets currently retrograde.
///
/// Mercury retrograde is a mainstream reference point in the United States in
/// a way no other transit is, so this is a first-class query rather than
/// something a caller has to assemble.
List<Planet> retrogradePlanets(double jdUt) => [
      for (final planet in Planet.values)
        if (isRetrograde(planet, jdUt)) planet,
    ];
