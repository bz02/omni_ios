/// Geometry for the chart wheel.
///
/// The wheel is the single most screenshotted object in this category, and the
/// thing that makes one look amateur is glyph collision: Sun, Mercury and
/// Venus sit within a few degrees of each other constantly, and drawing each
/// one at its true longitude stacks them into an unreadable blot. Commercial
/// software nudges them apart by hand-tuned rules that reorder placements —
/// which is worse than overlapping, because a reader counts glyphs left to
/// right to read the order of a stellium.
///
/// So the spreading here is a solved problem rather than a heuristic:
/// minimize the total squared displacement subject to every neighboring pair
/// being at least [minSeparation] apart, with the cyclic order untouched. That
/// is isotonic regression, and the pool-adjacent-violators algorithm returns
/// its exact optimum in linear time. The three properties a reader depends on
/// — order preserved, nothing overlapping, nothing moved further than it had
/// to be — are then invariants a test can check, not intentions.
///
/// Kept free of Flutter so the geometry is testable without a render surface.
library;

import 'astro_math.dart';
import 'planets.dart';
import 'western_chart.dart';

/// Something the wheel draws a glyph for: a planet, a light, or an angle.
class WheelBody {
  const WheelBody({
    required this.label,
    required this.glyph,
    required this.longitude,
    this.isRetrograde = false,
    this.isAngle = false,
  });

  final String label;
  final String glyph;
  final double longitude;
  final bool isRetrograde;

  /// Angles (the Ascendant and Midheaven) are drawn but never aspected: they
  /// are directions, not bodies, and an "aspect" to one is just a restatement
  /// of the house placement already shown.
  final bool isAngle;

  ZodiacSign get sign => ZodiacSign.fromLongitude(longitude);
}

/// A body and the angle its glyph is actually drawn at, once collisions have
/// been resolved. The two differ by [displacement], which the wheel draws as a
/// short leader line so the reader can still see the true degree.
class PlacedGlyph {
  const PlacedGlyph({required this.body, required this.displayLongitude});

  final WheelBody body;
  final double displayLongitude;

  /// Signed degrees the glyph was nudged, in the range -180 to 180.
  double get displacement {
    var d = displayLongitude - body.longitude;
    while (d > 180) {
      d -= 360;
    }
    while (d < -180) {
      d += 360;
    }
    return d;
  }

  /// Worth drawing a leader line for. Below this the line is shorter than the
  /// glyph and reads as a smudge.
  bool get isDisplaced => displacement.abs() > 0.75;
}

/// One aspect line across the middle of the wheel.
class AspectLine {
  const AspectLine({
    required this.from,
    required this.to,
    required this.aspect,
    required this.orb,
  });

  final WheelBody from;
  final WheelBody to;
  final Aspect aspect;
  final double orb;

  /// 1.0 when exact, falling to 0 at the edge of orb. The wheel fades wide
  /// aspects rather than hiding them, because an 7°-wide square is real and a
  /// reader who cannot see it will think the chart is wrong.
  double get strength => (1.0 - orb / aspect.orb).clamp(0.0, 1.0);
}

/// Everything the painter needs, with no astronomy left in it.
class WheelLayout {
  const WheelLayout({
    required this.glyphs,
    required this.aspects,
    required this.rotationLongitude,
    required this.cusps,
    required this.hasHouses,
  });

  final List<PlacedGlyph> glyphs;
  final List<AspectLine> aspects;

  /// The longitude pinned to the nine o'clock position. The Ascendant when
  /// there is one, because that is the convention every reader has seen; 0°
  /// Aries otherwise, so a chart with no birth time still draws.
  final double rotationLongitude;

  /// Twelve cusps, or twelve sign boundaries when houses are unknown.
  final List<double> cusps;

  /// False when there was no birth time or place, in which case [cusps] are
  /// sign boundaries and must not be labeled as houses.
  final bool hasHouses;

  /// Degrees counterclockwise from the three o'clock position.
  ///
  /// The Ascendant sits at nine o'clock and longitude increases
  /// counterclockwise, which puts the Midheaven near the top and the fourth
  /// house at the bottom — the orientation of every printed chart.
  double screenAngle(double longitude) =>
      normalizeDegrees(180.0 + (longitude - rotationLongitude));
}

/// How far apart two glyphs have to be, in degrees of the wheel, before they
/// stop touching.
///
/// This is not a taste value: a glyph drawn at [planetGlyphFraction] of the
/// ring radius occupies `planetGlyphFraction` radians of arc, so the angle it
/// needs is fixed by that ratio and nothing else — which makes it scale-free,
/// the same at a 150px thumbnail as at a 1080px share card. The test
/// `separation clears the glyph it is separating` re-derives it, so retuning
/// the font size without retuning this fails rather than quietly overlaps.
const double glyphSeparationDegrees = 11.0;

/// Nudges glyphs apart until no two are within [minSeparation] degrees,
/// preserving cyclic order and moving them as little as possible.
///
/// Returns display longitudes in the input order.
List<double> spreadGlyphs(
  List<double> longitudes, {
  double minSeparation = glyphSeparationDegrees,
}) {
  final n = longitudes.length;
  if (n == 0) return const [];
  if (n == 1) return [normalizeDegrees(longitudes.first)];

  // More glyphs than the circle can hold at the requested spacing. Even
  // spacing is the only feasible answer, and it is exactly feasible.
  final separation =
      minSeparation > 360.0 / n ? 360.0 / n : minSeparation;

  final order = List<int>.generate(n, (i) => i)
    ..sort((a, b) => normalizeDegrees(longitudes[a])
        .compareTo(normalizeDegrees(longitudes[b])));

  // Cut the circle at its widest gap and solve the resulting line. Cutting
  // anywhere else would push glyphs across the seam and reorder them.
  var cutAfter = n - 1;
  var widest = -1.0;
  for (var i = 0; i < n; i++) {
    final here = normalizeDegrees(longitudes[order[i]]);
    final next = normalizeDegrees(longitudes[order[(i + 1) % n]]);
    final gap = normalizeDegrees(next - here);
    if (gap > widest) {
      widest = gap;
      cutAfter = i;
    }
  }

  // Unwrap into a strictly increasing sequence starting after the cut.
  final x = <double>[];
  final index = <int>[];
  for (var k = 0; k < n; k++) {
    final i = order[(cutAfter + 1 + k) % n];
    index.add(i);
    final value = normalizeDegrees(longitudes[i]);
    x.add(k == 0 || value >= x.last ? value : value + 360.0);
  }

  // The constraint x'[k+1] >= x'[k] + separation becomes "non-decreasing"
  // after subtracting k * separation, so the optimum is an isotonic
  // regression on y.
  final y = [for (var k = 0; k < n; k++) x[k] - k * separation];
  final fitted = _poolAdjacentViolators(y);
  var out = [for (var k = 0; k < n; k++) fitted[k] + k * separation];

  // The line solution ignores the seam. Pooling can widen the arc into it, so
  // check, and fall back to even spacing — which trivially satisfies every
  // constraint including the seam — rather than ship an overlap.
  final seam = 360.0 - (out.last - out.first);
  if (seam < separation - 1e-9) {
    final spacing = 360.0 / n;
    var offset = 0.0;
    for (var k = 0; k < n; k++) {
      offset += x[k] - k * spacing;
    }
    offset /= n;
    out = [for (var k = 0; k < n; k++) offset + k * spacing];
  }

  final result = List<double>.filled(n, 0);
  for (var k = 0; k < n; k++) {
    result[index[k]] = normalizeDegrees(out[k]);
  }
  return result;
}

/// Least-squares fit of a non-decreasing sequence to [values].
List<double> _poolAdjacentViolators(List<double> values) {
  final sums = <double>[];
  final counts = <int>[];
  for (final value in values) {
    var sum = value;
    var count = 1;
    // Absorb every block to the left whose mean now exceeds this one. Each
    // block is merged at most once, so the whole pass is linear.
    while (sums.isNotEmpty && sums.last / counts.last > sum / count) {
      sum += sums.removeLast();
      count += counts.removeLast();
    }
    sums.add(sum);
    counts.add(count);
  }
  return [
    for (var b = 0; b < sums.length; b++)
      for (var i = 0; i < counts[b]; i++) sums[b] / counts[b],
  ];
}

/// The bodies a wheel draws, in the order a reader expects to find them in a
/// legend: lights, personal planets, social, outer, then the angles.
List<WheelBody> wheelBodies(WesternChart chart) => [
      WheelBody(label: 'Sun', glyph: '☉', longitude: chart.sun.longitude),
      if (chart.moon case final moon?)
        WheelBody(label: 'Moon', glyph: '☽', longitude: moon.longitude),
      for (final planet in Planet.values)
        if (chart.planets[planet] case final p?)
          WheelBody(
            label: planet.label,
            glyph: planet.glyph,
            longitude: p.longitude,
            isRetrograde: p.isRetrograde,
          ),
      if (chart.ascendant case final asc?)
        WheelBody(
          label: 'Ascendant',
          glyph: 'AC',
          longitude: asc.longitude,
          isAngle: true,
        ),
      if (chart.midheaven case final mc?)
        WheelBody(
          label: 'Midheaven',
          glyph: 'MC',
          longitude: mc.longitude,
          isAngle: true,
        ),
    ];

/// Builds the whole layout for a chart.
WheelLayout layoutWheel(
  WesternChart chart, {
  double minSeparation = glyphSeparationDegrees,
}) {
  final bodies = wheelBodies(chart);
  final spread = spreadGlyphs(
    [for (final b in bodies) b.longitude],
    minSeparation: minSeparation,
  );

  final aspects = <AspectLine>[];
  for (var i = 0; i < bodies.length; i++) {
    if (bodies[i].isAngle) continue;
    for (var j = i + 1; j < bodies.length; j++) {
      if (bodies[j].isAngle) continue;
      final found = aspectBetween(bodies[i].longitude, bodies[j].longitude);
      if (found == null) continue;
      aspects.add(AspectLine(
        from: bodies[i],
        to: bodies[j],
        aspect: found.aspect,
        orb: found.orb,
      ));
    }
  }
  // Tightest last, so the strongest lines paint over the weakest.
  aspects.sort((a, b) => b.orb.compareTo(a.orb));

  final hasHouses = chart.cusps != null;
  return WheelLayout(
    glyphs: [
      for (var i = 0; i < bodies.length; i++)
        PlacedGlyph(body: bodies[i], displayLongitude: spread[i]),
    ],
    aspects: aspects,
    rotationLongitude: chart.ascendant?.longitude ?? 0.0,
    cusps: chart.cusps ?? [for (var i = 0; i < 12; i++) i * 30.0],
    hasHouses: hasHouses,
  );
}
