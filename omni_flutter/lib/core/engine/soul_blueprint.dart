/// The Soul Blueprint: one birth moment read through both traditions at once.
///
/// This is the product's reason to exist. Anyone can ship a Sun sign, and
/// plenty of apps ship a Chinese zodiac animal. Putting the two charts side by
/// side and naming where they agree and where they pull against each other is
/// the thing no competitor does, and it is the content a subscription is
/// actually paying for.
library;

import 'bazi.dart';
import 'western_chart.dart';

/// Re-exported so a caller building a blueprint needs only this one import.
export 'astro_math.dart' show ChartPrecision;
export 'bazi.dart';
export 'western_chart.dart';

/// Everything the engines need about a person. One input, two traditions.
class BirthData {
  const BirthData({
    required this.localDateTime,
    required this.utcOffsetHours,
    this.latitudeNorth,
    this.longitudeEast,
    this.placeName,
    this.timeIsKnown = true,
    this.displayName,
  });

  /// Wall-clock time at the birthplace.
  final DateTime localDateTime;

  /// The offset that clock was running on, including any summer time.
  final double utcOffsetHours;

  final double? latitudeNorth;
  final double? longitudeEast;
  final String? placeName;

  /// False when the user only knows the date. Half the audience does not know
  /// their birth time, and refusing to read for them is a conversion problem,
  /// so the engines degrade instead of failing.
  final bool timeIsKnown;

  final String? displayName;

  bool get placeIsKnown => latitudeNorth != null && longitudeEast != null;

  /// Stable key for caching and for seeding a day's fortune.
  String get fingerprint => [
        localDateTime.toIso8601String(),
        utcOffsetHours,
        latitudeNorth?.toStringAsFixed(2) ?? '-',
        longitudeEast?.toStringAsFixed(2) ?? '-',
        timeIsKnown,
      ].join('|');

  Map<String, dynamic> toJson() => {
        'localDateTime': localDateTime.toIso8601String(),
        'utcOffsetHours': utcOffsetHours,
        'latitudeNorth': latitudeNorth,
        'longitudeEast': longitudeEast,
        'placeName': placeName,
        'timeIsKnown': timeIsKnown,
        'displayName': displayName,
      };

  factory BirthData.fromJson(Map<String, dynamic> json) => BirthData(
        localDateTime: DateTime.parse(json['localDateTime'] as String),
        utcOffsetHours: (json['utcOffsetHours'] as num).toDouble(),
        latitudeNorth: (json['latitudeNorth'] as num?)?.toDouble(),
        longitudeEast: (json['longitudeEast'] as num?)?.toDouble(),
        placeName: json['placeName'] as String?,
        timeIsKnown: json['timeIsKnown'] as bool? ?? true,
        displayName: json['displayName'] as String?,
      );
}

/// One observation that only exists because both charts were computed.
class CrossInsight {
  const CrossInsight({
    required this.title,
    required this.body,
    required this.isTension,
  });

  final String title;
  final String body;

  /// True when the two systems disagree. Tensions make better copy than
  /// agreements and are what users screenshot, so the UI leads with them.
  final bool isTension;
}

/// Correspondence between the two elemental systems.
///
/// Fire, Earth and Water line up cleanly. Air has no exact Chinese counterpart;
/// Wood is the closest, sharing movement, growth and the Wind trigram. Metal
/// has no Western counterpart at all, which is itself worth telling the user.
WuXing? wuXingForWesternElement(WesternElement element) => switch (element) {
      WesternElement.fire => WuXing.fire,
      WesternElement.earth => WuXing.earth,
      WesternElement.water => WuXing.water,
      WesternElement.air => WuXing.wood,
    };

/// What each phase points at for luck: colours, He Tu numbers, direction.
class ElementAffinity {
  const ElementAffinity(this.colors, this.numbers, this.direction, this.season);
  final List<String> colors;
  final List<int> numbers;
  final String direction;
  final String season;

  static ElementAffinity of(WuXing element) => switch (element) {
        WuXing.wood =>
          const ElementAffinity(['green', 'teal'], [3, 8], 'East', 'spring'),
        WuXing.fire =>
          const ElementAffinity(['red', 'orange'], [2, 7], 'South', 'summer'),
        WuXing.earth => const ElementAffinity(
            ['ochre', 'sand'], [5, 10], 'Centre', 'late summer'),
        WuXing.metal =>
          const ElementAffinity(['white', 'gold'], [4, 9], 'West', 'autumn'),
        WuXing.water =>
          const ElementAffinity(['black', 'deep blue'], [1, 6], 'North', 'winter'),
      };
}

class SoulBlueprint {
  SoulBlueprint({
    required this.birth,
    required this.western,
    required this.bazi,
  });

  final BirthData birth;
  final WesternChart western;
  final BaziChart bazi;

  /// The one-line identity the app shows everywhere and users put in bios.
  String get signature =>
      '${western.sun.sign.label} Sun · ${bazi.dayMaster.element.english} '
      '${bazi.dayMaster.chinese} Day Master · ${bazi.zodiacAnimal}';

  /// The element the chart is short of, which is what lucky colours, numbers
  /// and directions are chosen to supply.
  WuXing get remedialElement =>
      bazi.missingElements.isNotEmpty
          ? bazi.missingElements.first
          : bazi.weakestElement;

  ElementAffinity get affinity => ElementAffinity.of(remedialElement);

  /// Do the two traditions point at the same element?
  bool get systemsAgree =>
      wuXingForWesternElement(western.dominantElement) == bazi.dominantElement;

  /// The full set of cross-system observations, tensions first.
  List<CrossInsight> get insights {
    final out = <CrossInsight>[];
    final westElement = western.dominantElement;
    final westAsWuXing = wuXingForWesternElement(westElement);
    final eastElement = bazi.dominantElement;

    if (systemsAgree) {
      out.add(CrossInsight(
        title: 'Both systems say ${eastElement.english}',
        body: 'Your Western chart leans ${westElement.label} and your Ba Zi is '
            'weighted toward ${eastElement.chinese} ${eastElement.english}. Two '
            'traditions built four thousand miles apart landed on the same '
            'read. Whatever that element means for you, it is not a coincidence '
            'of one chart.',
        isTension: false,
      ));
    } else if (westAsWuXing != null) {
      final relation = _relationLabel(westAsWuXing, eastElement);
      out.add(CrossInsight(
        title: '${westElement.label} outside, ${eastElement.english} underneath',
        body: 'The Western chart reads ${westElement.label} — that is how you '
            'come across. The Ba Zi is weighted to ${eastElement.chinese} '
            '${eastElement.english} — that is what you are running on. In the '
            'five-phase cycle these two $relation, which is exactly why people '
            'who know you well describe you differently from people who just '
            'met you.',
        isTension: true,
      ));
    }

    if (bazi.missingElements.isNotEmpty) {
      final missing = bazi.missingElements.first;
      out.add(CrossInsight(
        title: 'No ${missing.chinese} ${missing.english} in the chart',
        body: 'Not one of your eight characters carries '
            '${missing.chinese} ${missing.english}. In Chinese practice this is '
            'the single most discussed feature of a chart, and the fix is '
            'environmental rather than personal: '
            '${ElementAffinity.of(missing).colors.join(' and ')}, the '
            '${ElementAffinity.of(missing).direction.toLowerCase()} side of a '
            'room, the numbers '
            '${ElementAffinity.of(missing).numbers.join(' and ')}.',
        isTension: true,
      ));
    }

    if (missingElementsHaveWesternName) {
      out.add(const CrossInsight(
        title: 'Metal has no Western name',
        body: 'Western astrology runs on four elements; Chinese practice runs '
            'on five. Metal — precision, boundaries, the ability to cut — is '
            'the one with no counterpart in your Western chart at all. It is '
            'the part of you a Western reading structurally cannot see.',
        isTension: false,
      ));
    }

    final aspect = western.sunMoonAspect;
    if (aspect != null) {
      out.add(CrossInsight(
        title: 'Sun ${aspect.aspect.label.toLowerCase()} Moon',
        body: 'What you want and what you feel are in '
            '${aspect.aspect.gist} with each other '
            '(${aspect.orb.toStringAsFixed(1)}° from exact). Read alongside a '
            '${_strengthLabel(bazi.dayMasterStrength)} day master, that is the '
            'core tension of the chart.',
        isTension: aspect.aspect == Aspect.square ||
            aspect.aspect == Aspect.opposition,
      ));
    }

    final animal = bazi.zodiacBranch;
    out.add(CrossInsight(
      title: '${bazi.zodiacAnimal} meets ${western.sun.sign.label}',
      body: 'Your year branch is ${animal.chinese} '
          '(${animal.animal}) and your Sun is in ${western.sun.sign.label}. The '
          'branch that clashes with yours is '
          '${animal.clashesWith.chinese} ${animal.clashesWith.animal}, and the '
          'one that harmonises is ${animal.harmonizesWith.chinese} '
          '${animal.harmonizesWith.animal} — useful when you are working out '
          'why one colleague grates and another does not.',
      isTension: false,
    ));

    out.sort((a, b) => (b.isTension ? 1 : 0).compareTo(a.isTension ? 1 : 0));
    return out;
  }

  bool get missingElementsHaveWesternName =>
      bazi.missingElements.contains(WuXing.metal);

  /// Caveats worth showing rather than hiding. Saying "your Moon is on a cusp,
  /// check your birth certificate" builds more trust than a confident guess.
  List<String> get caveats => [
        if (!birth.timeIsKnown)
          'No birth time, so the Moon, the rising sign and the hour pillar are '
              'left out rather than guessed.',
        if (birth.timeIsKnown && !birth.placeIsKnown)
          'No birthplace, so the rising sign is left out.',
        for (final placement in western.cuspWarnings)
          '$placement sits within a degree of a sign boundary — worth checking '
              'your recorded birth time.',
        if (bazi.isNearTermBoundary)
          'Born within half an hour of a solar term, so the month pillar is '
              'sensitive to the exact minute.',
        if (bazi.trueSolarTimeApplied)
          'Times corrected to true solar time at the birthplace, as a Ba Zi '
              'practitioner would.',
      ];

  /// Compact context handed to the model. Keeping this small and structured
  /// matters: it is sent on every chat turn, so it is the dominant cost driver.
  Map<String, dynamic> promptContext() => {
        'western': western.toJson(),
        'bazi': bazi.toJson(),
        'signature': signature,
        'systemsAgree': systemsAgree,
        'remedialElement': remedialElement.english,
        'luckyColors': affinity.colors,
        'luckyNumbers': affinity.numbers,
        'luckyDirection': affinity.direction,
        'tensions': [
          for (final i in insights.where((i) => i.isTension)) i.title,
        ],
      };
}

String _relationLabel(WuXing a, WuXing b) {
  if (a == b) return 'are the same phase';
  if (a.generates == b) return 'feed each other';
  if (b.generates == a) return 'feed each other in the other direction';
  if (a.controls == b) return 'restrain one another';
  if (b.controls == a) return 'restrain one another';
  return 'sit apart in the cycle';
}

String _strengthLabel(double strength) {
  if (strength >= 0.62) return 'strong';
  if (strength <= 0.38) return 'weak';
  return 'balanced';
}

/// Builds both charts from one birth record.
SoulBlueprint computeSoulBlueprint(BirthData birth) {
  final western = computeWesternChart(
    birthLocal: birth.localDateTime,
    utcOffsetHours: birth.utcOffsetHours,
    latitudeNorth: birth.latitudeNorth,
    longitudeEast: birth.longitudeEast,
    hourIsKnown: birth.timeIsKnown,
  );

  final bazi = computeBaziChart(
    birthLocal: birth.localDateTime,
    utcOffsetHours: birth.utcOffsetHours,
    longitudeEast: birth.longitudeEast,
    hourIsKnown: birth.timeIsKnown,
  );

  return SoulBlueprint(birth: birth, western: western, bazi: bazi);
}
