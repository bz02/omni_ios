/// Chinese four-pillars (Ba Zi) engine.
///
/// The two things toy implementations get wrong, and this one does not:
///   1. The year pillar turns over at Start of Spring, not on 1 January.
///   2. The month pillar turns over on the twelve major solar terms, which are
///      instants when the Sun reaches an exact multiple of 30 degrees measured
///      from 315 — not on calendar month boundaries.
///
/// Both fall out of [solarLongitude], so the same ephemeris backs the Western
/// chart and the Eastern one.
library;

import 'dart:math' as math;

import 'astro_math.dart';
import 'vsop87_earth.dart' show nutationInLongitude;

/// The five phases. Kept separate from the older `ChineseElement` in
/// `core/models` so the engine stays dependency-free; [WuXing.legacyName] maps
/// back for the existing UI.
enum WuXing {
  wood('木', 'Wood'),
  fire('火', 'Fire'),
  earth('土', 'Earth'),
  metal('金', 'Metal'),
  water('水', 'Water');

  const WuXing(this.chinese, this.english);
  final String chinese;
  final String english;

  String get legacyName => english.toLowerCase();

  /// The phase this one produces in the generating cycle.
  WuXing get generates => switch (this) {
        WuXing.wood => WuXing.fire,
        WuXing.fire => WuXing.earth,
        WuXing.earth => WuXing.metal,
        WuXing.metal => WuXing.water,
        WuXing.water => WuXing.wood,
      };

  /// The phase this one restrains in the controlling cycle.
  WuXing get controls => switch (this) {
        WuXing.wood => WuXing.earth,
        WuXing.earth => WuXing.water,
        WuXing.water => WuXing.fire,
        WuXing.fire => WuXing.metal,
        WuXing.metal => WuXing.wood,
      };

  WuXing get generatedBy =>
      WuXing.values.firstWhere((e) => e.generates == this);

  WuXing get controlledBy =>
      WuXing.values.firstWhere((e) => e.controls == this);
}

/// The ten heavenly stems.
enum HeavenlyStem {
  jia('甲', 'Jia', WuXing.wood, true),
  yi('乙', 'Yi', WuXing.wood, false),
  bing('丙', 'Bing', WuXing.fire, true),
  ding('丁', 'Ding', WuXing.fire, false),
  wu('戊', 'Wu', WuXing.earth, true),
  ji('己', 'Ji', WuXing.earth, false),
  geng('庚', 'Geng', WuXing.metal, true),
  xin('辛', 'Xin', WuXing.metal, false),
  ren('壬', 'Ren', WuXing.water, true),
  gui('癸', 'Gui', WuXing.water, false);

  const HeavenlyStem(this.chinese, this.pinyin, this.element, this.isYang);
  final String chinese;
  final String pinyin;
  final WuXing element;
  final bool isYang;
}

/// The twelve earthly branches, with their zodiac animals and hidden stems.
enum EarthlyBranch {
  zi('子', 'Zi', 'Rat', '鼠', WuXing.water, true),
  chou('丑', 'Chou', 'Ox', '牛', WuXing.earth, false),
  yin('寅', 'Yin', 'Tiger', '虎', WuXing.wood, true),
  mao('卯', 'Mao', 'Rabbit', '兔', WuXing.wood, false),
  chen('辰', 'Chen', 'Dragon', '龙', WuXing.earth, true),
  si('巳', 'Si', 'Snake', '蛇', WuXing.fire, false),
  wu('午', 'Wu', 'Horse', '马', WuXing.fire, true),
  wei('未', 'Wei', 'Goat', '羊', WuXing.earth, false),
  shen('申', 'Shen', 'Monkey', '猴', WuXing.metal, true),
  you('酉', 'You', 'Rooster', '鸡', WuXing.metal, false),
  xu('戌', 'Xu', 'Dog', '狗', WuXing.earth, true),
  hai('亥', 'Hai', 'Pig', '猪', WuXing.water, false);

  const EarthlyBranch(this.chinese, this.pinyin, this.animal, this.animalChinese,
      this.element, this.isYang);
  final String chinese;
  final String pinyin;
  final String animal;
  final String animalChinese;
  final WuXing element;
  final bool isYang;

  /// Stems concealed inside the branch, strongest first. These carry most of
  /// the elemental weight in a real reading, which is why a chart cannot be
  /// scored from the visible characters alone.
  List<HeavenlyStem> get hiddenStems => switch (this) {
        EarthlyBranch.zi => const [HeavenlyStem.gui],
        EarthlyBranch.chou =>
          const [HeavenlyStem.ji, HeavenlyStem.gui, HeavenlyStem.xin],
        EarthlyBranch.yin =>
          const [HeavenlyStem.jia, HeavenlyStem.bing, HeavenlyStem.wu],
        EarthlyBranch.mao => const [HeavenlyStem.yi],
        EarthlyBranch.chen =>
          const [HeavenlyStem.wu, HeavenlyStem.yi, HeavenlyStem.gui],
        EarthlyBranch.si =>
          const [HeavenlyStem.bing, HeavenlyStem.geng, HeavenlyStem.wu],
        EarthlyBranch.wu => const [HeavenlyStem.ding, HeavenlyStem.ji],
        EarthlyBranch.wei =>
          const [HeavenlyStem.ji, HeavenlyStem.ding, HeavenlyStem.yi],
        EarthlyBranch.shen =>
          const [HeavenlyStem.geng, HeavenlyStem.ren, HeavenlyStem.wu],
        EarthlyBranch.you => const [HeavenlyStem.xin],
        EarthlyBranch.xu =>
          const [HeavenlyStem.wu, HeavenlyStem.xin, HeavenlyStem.ding],
        EarthlyBranch.hai => const [HeavenlyStem.ren, HeavenlyStem.jia],
      };

  /// The branch six positions away, the classic clash pair.
  EarthlyBranch get clashesWith =>
      EarthlyBranch.values[(index + 6) % 12];

  /// The six-harmony partner.
  EarthlyBranch get harmonizesWith =>
      EarthlyBranch.values[(13 - index) % 12];

  /// The other two branches of the same four-month trine.
  List<EarthlyBranch> get trine => [
        EarthlyBranch.values[(index + 4) % 12],
        EarthlyBranch.values[(index + 8) % 12],
      ];
}

/// The ten gods: how another stem relates to the day master.
enum TenGod {
  friend('比肩', 'Friend'),
  robWealth('劫财', 'Rob Wealth'),
  eatingGod('食神', 'Eating God'),
  hurtingOfficer('伤官', 'Hurting Officer'),
  directWealth('正财', 'Direct Wealth'),
  indirectWealth('偏财', 'Indirect Wealth'),
  directOfficer('正官', 'Direct Officer'),
  sevenKillings('七杀', 'Seven Killings'),
  directResource('正印', 'Direct Resource'),
  indirectResource('偏印', 'Indirect Resource');

  const TenGod(this.chinese, this.english);
  final String chinese;
  final String english;
}

/// Classifies [other] against the [dayMaster].
TenGod tenGodFor(HeavenlyStem dayMaster, HeavenlyStem other) {
  final samePolarity = dayMaster.isYang == other.isYang;
  final me = dayMaster.element;
  final it = other.element;

  if (it == me) return samePolarity ? TenGod.friend : TenGod.robWealth;
  if (it == me.generates) {
    return samePolarity ? TenGod.eatingGod : TenGod.hurtingOfficer;
  }
  if (it == me.controls) {
    return samePolarity ? TenGod.indirectWealth : TenGod.directWealth;
  }
  if (it == me.controlledBy) {
    return samePolarity ? TenGod.sevenKillings : TenGod.directOfficer;
  }
  return samePolarity ? TenGod.indirectResource : TenGod.directResource;
}

/// One of the four pillars.
class Pillar {
  const Pillar(this.stem, this.branch);
  final HeavenlyStem stem;
  final EarthlyBranch branch;

  String get chinese => '${stem.chinese}${branch.chinese}';
  String get pinyin => '${stem.pinyin} ${branch.pinyin}';

  /// Index in the sixty-term sexagenary cycle.
  int get sexagenaryIndex {
    for (var i = 0; i < 60; i++) {
      if (i % 10 == stem.index && i % 12 == branch.index) return i;
    }
    throw StateError('stem/branch pair is not on the sexagenary cycle');
  }

  /// The Na Yin sound-element, the poetic label people actually remember
  /// ("Sea Gold", "Furnace Fire").
  NaYin get naYin => _naYinTable[sexagenaryIndex ~/ 2];

  @override
  String toString() => chinese;
}

class NaYin {
  const NaYin(this.chinese, this.english, this.element);
  final String chinese;
  final String english;
  final WuXing element;
}

const List<NaYin> _naYinTable = [
  NaYin('海中金', 'Sea Gold', WuXing.metal),
  NaYin('炉中火', 'Furnace Fire', WuXing.fire),
  NaYin('大林木', 'Great Forest Wood', WuXing.wood),
  NaYin('路旁土', 'Roadside Earth', WuXing.earth),
  NaYin('剑锋金', 'Sword Metal', WuXing.metal),
  NaYin('山头火', 'Mountaintop Fire', WuXing.fire),
  NaYin('涧下水', 'Stream Water', WuXing.water),
  NaYin('城头土', 'City Wall Earth', WuXing.earth),
  NaYin('白蜡金', 'White Wax Metal', WuXing.metal),
  NaYin('杨柳木', 'Willow Wood', WuXing.wood),
  NaYin('泉中水', 'Spring Water', WuXing.water),
  NaYin('屋上土', 'Rooftop Earth', WuXing.earth),
  NaYin('霹雳火', 'Thunderbolt Fire', WuXing.fire),
  NaYin('松柏木', 'Pine and Cypress Wood', WuXing.wood),
  NaYin('长流水', 'Long Flowing Water', WuXing.water),
  NaYin('沙中金', 'Sand Metal', WuXing.metal),
  NaYin('山下火', 'Foothill Fire', WuXing.fire),
  NaYin('平地木', 'Plain Wood', WuXing.wood),
  NaYin('壁上土', 'Wall Earth', WuXing.earth),
  NaYin('金箔金', 'Gold Foil Metal', WuXing.metal),
  NaYin('覆灯火', 'Lantern Fire', WuXing.fire),
  NaYin('天河水', 'Heavenly River Water', WuXing.water),
  NaYin('大驿土', 'Post Road Earth', WuXing.earth),
  NaYin('钗钏金', 'Hairpin Metal', WuXing.metal),
  NaYin('桑柘木', 'Mulberry Wood', WuXing.wood),
  NaYin('大溪水', 'Great Brook Water', WuXing.water),
  NaYin('沙中土', 'Sand Earth', WuXing.earth),
  NaYin('天上火', 'Heavenly Fire', WuXing.fire),
  NaYin('石榴木', 'Pomegranate Wood', WuXing.wood),
  NaYin('大海水', 'Great Sea Water', WuXing.water),
];

/// The twelve major solar terms that open a Ba Zi month, in order from Start of
/// Spring. The Sun's apparent longitude at each is `315 + 30 * index`, mod 360.
enum SolarTerm {
  lichun('立春', 'Start of Spring', EarthlyBranch.yin),
  jingzhe('惊蛰', 'Awakening of Insects', EarthlyBranch.mao),
  qingming('清明', 'Clear and Bright', EarthlyBranch.chen),
  lixia('立夏', 'Start of Summer', EarthlyBranch.si),
  mangzhong('芒种', 'Grain in Ear', EarthlyBranch.wu),
  xiaoshu('小暑', 'Minor Heat', EarthlyBranch.wei),
  liqiu('立秋', 'Start of Autumn', EarthlyBranch.shen),
  bailu('白露', 'White Dew', EarthlyBranch.you),
  hanlu('寒露', 'Cold Dew', EarthlyBranch.xu),
  lidong('立冬', 'Start of Winter', EarthlyBranch.hai),
  daxue('大雪', 'Major Snow', EarthlyBranch.zi),
  xiaohan('小寒', 'Minor Cold', EarthlyBranch.chou);

  const SolarTerm(this.chinese, this.english, this.branch);
  final String chinese;
  final String english;
  final EarthlyBranch branch;

  double get solarLongitudeDegrees => (315.0 + 30.0 * index) % 360.0;
}

/// Everything the reading layer needs about one birth moment.
class BaziChart {
  BaziChart({
    required this.year,
    required this.month,
    required this.day,
    required this.hour,
    required this.hourIsKnown,
    required this.elementWeights,
    required this.solarTerm,
    required this.minutesFromTermBoundary,
    required this.trueSolarTimeApplied,
  });

  final Pillar year;
  final Pillar month;
  final Pillar day;
  final Pillar? hour;

  /// False when the user did not supply a birth time. The other three pillars
  /// are still valid; only the hour pillar and its ten god are unavailable.
  final bool hourIsKnown;

  /// Weighted count of each phase across visible and hidden stems.
  final Map<WuXing, double> elementWeights;

  /// The solar term whose window the birth falls in.
  final SolarTerm solarTerm;

  /// How far the birth sits from the nearest month boundary. Under about half
  /// an hour and the month pillar is sensitive to the accuracy of the recorded
  /// birth time, which is worth telling the user.
  final double minutesFromTermBoundary;

  final bool trueSolarTimeApplied;

  /// The day stem — the single character a Ba Zi reading is built around.
  HeavenlyStem get dayMaster => day.stem;

  EarthlyBranch get zodiacBranch => year.branch;
  String get zodiacAnimal => year.branch.animal;

  bool get isNearTermBoundary => minutesFromTermBoundary.abs() < 30;

  List<Pillar> get pillars => [year, month, day, if (hour != null) hour!];

  /// Ten gods for the three non-day pillars, keyed by pillar name.
  Map<String, TenGod> get tenGods => {
        'year': tenGodFor(dayMaster, year.stem),
        'month': tenGodFor(dayMaster, month.stem),
        if (hour != null) 'hour': tenGodFor(dayMaster, hour!.stem),
      };

  /// Phase with the greatest weight.
  WuXing get dominantElement => elementWeights.entries
      .reduce((a, b) => a.value >= b.value ? a : b)
      .key;

  /// Phase with the least weight — in practice the one a reading tells the user
  /// to "feed", and the hook for lucky colours and directions.
  WuXing get weakestElement => elementWeights.entries
      .reduce((a, b) => a.value <= b.value ? a : b)
      .key;

  /// Phases entirely absent from the chart. Traditionally the most talked-about
  /// feature of a chart ("you are missing Water").
  List<WuXing> get missingElements => WuXing.values
      .where((e) => (elementWeights[e] ?? 0) < 0.01)
      .toList();

  /// Rough day-master strength on 0..1: how much of the chart supports the day
  /// master (same phase, or the phase that produces it) versus drains it.
  double get dayMasterStrength {
    final total = elementWeights.values.fold<double>(0, (a, b) => a + b);
    if (total <= 0) return 0.5;
    final me = dayMaster.element;
    final supporting =
        (elementWeights[me] ?? 0) + (elementWeights[me.generatedBy] ?? 0);
    return (supporting / total).clamp(0.0, 1.0);
  }

  Map<String, dynamic> toJson() => {
        'year': year.chinese,
        'month': month.chinese,
        'day': day.chinese,
        'hour': hour?.chinese,
        'dayMaster': '${dayMaster.chinese} ${dayMaster.pinyin}',
        'dayMasterElement': dayMaster.element.english,
        'dayMasterStrength': dayMasterStrength.toStringAsFixed(2),
        'zodiac': zodiacAnimal,
        'naYin': '${year.naYin.chinese} ${year.naYin.english}',
        'solarTerm': '${solarTerm.chinese} ${solarTerm.english}',
        'elements': {
          for (final e in WuXing.values)
            e.english: (elementWeights[e] ?? 0).toStringAsFixed(2),
        },
        'missing': missingElements.map((e) => e.english).toList(),
        'dominant': dominantElement.english,
        'weakest': weakestElement.english,
        'tenGods': {
          for (final e in tenGods.entries)
            e.key: '${e.value.chinese} ${e.value.english}',
        },
      };
}

/// Weight given to each hidden stem by rank. The principal stem carries the
/// branch's own phase; the remainder are residues of the previous season.
const List<double> _hiddenStemWeights = [1.0, 0.35, 0.2];

/// Computes the four pillars for a birth moment.
///
/// [birthLocal] is wall-clock time at the birthplace and [utcOffsetHours] is the
/// offset that clock was running on (so 1990-05-01 08:00 in Beijing is
/// `DateTime(1990, 5, 1, 8)` with an offset of 8).
///
/// When [longitudeEast] is supplied the clock is corrected to true solar time,
/// which is what a practitioner does by hand: a birth in Kashgar on Beijing
/// time is nearly three hours off the Sun, easily enough to change the hour
/// pillar.
BaziChart computeBaziChart({
  required DateTime birthLocal,
  required double utcOffsetHours,
  double? longitudeEast,
  bool hourIsKnown = true,
  bool useTrueSolarTime = true,
}) {
  final utc = DateTime.utc(
    birthLocal.year,
    birthLocal.month,
    birthLocal.day,
    birthLocal.hour,
    birthLocal.minute,
  ).subtract(Duration(
      milliseconds: (utcOffsetHours * 3600000).round()));

  final jdUtc = julianDay(utc);

  // Reckoning clock: either the civil clock as given, or corrected to the Sun.
  final applyTrueSolar =
      useTrueSolarTime && longitudeEast != null && hourIsKnown;
  var reckoning = birthLocal;
  if (applyTrueSolar) {
    final offsetMinutes =
        (longitudeEast - utcOffsetHours * 15.0) * 4.0 + equationOfTime(jdUtc);
    reckoning = birthLocal.add(Duration(seconds: (offsetMinutes * 60).round()));
  }

  // --- Year pillar: turns over at Start of Spring, not 1 January. ---
  // Compared as instants in UTC, so the answer does not depend on which clock
  // the birth was recorded against.
  final lichun = solveSolarLongitude(
    SolarTerm.lichun.solarLongitudeDegrees,
    afterUtc: DateTime.utc(utc.year, 1, 1),
    searchDays: 70,
  )!;
  final baziYear = utc.isBefore(lichun) ? utc.year - 1 : utc.year;

  final yearStem = HeavenlyStem.values[((baziYear - 4) % 10 + 10) % 10];
  final yearBranch = EarthlyBranch.values[((baziYear - 4) % 12 + 12) % 12];
  final yearPillar = Pillar(yearStem, yearBranch);

  // --- Month pillar: from the Sun's longitude, i.e. the true solar term. ---
  final lambda = solarLongitude(jdUtc);
  final termIndex = (((lambda - 315.0) % 360.0 + 360.0) % 360.0) ~/ 30;
  final term = SolarTerm.values[termIndex];
  final monthBranch = term.branch;

  // Five Tigers rule: the stem of the Tiger month follows the year stem.
  final monthStemIndex = ((yearStem.index % 5) * 2 + 2 + termIndex) % 10;
  final monthPillar = Pillar(HeavenlyStem.values[monthStemIndex], monthBranch);

  final boundaryMinutes = _minutesToNearestTermBoundary(utc, lambda);

  // --- Day pillar: straight off the Julian Day Number. ---
  // The sexagenary day rolls at 23:00 in the Zi Ping tradition, so a late
  // evening birth already belongs to the next day's stem and branch.
  var dayDate = DateTime(reckoning.year, reckoning.month, reckoning.day);
  if (hourIsKnown && reckoning.hour >= 23) {
    dayDate = dayDate.add(const Duration(days: 1));
  }
  final jdn =
      julianDayNumberOfLocalDate(dayDate.year, dayDate.month, dayDate.day);
  final dayStem = HeavenlyStem.values[(jdn + 9) % 10];
  final dayBranch = EarthlyBranch.values[(jdn + 1) % 12];
  final dayPillar = Pillar(dayStem, dayBranch);

  // --- Hour pillar: two-hour branch, stem from the Five Rats rule. ---
  Pillar? hourPillar;
  if (hourIsKnown) {
    final branchIndex = ((reckoning.hour + 1) ~/ 2) % 12;
    final hourStemIndex = ((dayStem.index % 5) * 2 + branchIndex) % 10;
    hourPillar = Pillar(
      HeavenlyStem.values[hourStemIndex],
      EarthlyBranch.values[branchIndex],
    );
  }

  return BaziChart(
    year: yearPillar,
    month: monthPillar,
    day: dayPillar,
    hour: hourPillar,
    hourIsKnown: hourIsKnown,
    elementWeights: _weighElements(
        [yearPillar, monthPillar, dayPillar, if (hourPillar != null) hourPillar]),
    solarTerm: term,
    minutesFromTermBoundary: boundaryMinutes,
    trueSolarTimeApplied: applyTrueSolar,
  );
}

/// Signed minutes from the opening of the current solar-term month, or to the
/// next one, whichever is closer.
double _minutesToNearestTermBoundary(DateTime utc, double lambda) {
  final degreesIntoMonth = ((lambda - 315.0) % 30.0 + 30.0) % 30.0;
  // The Sun covers roughly 0.9856 degrees a day.
  const minutesPerDegree = 24 * 60 / 0.9856;
  final since = degreesIntoMonth * minutesPerDegree;
  final until = (30.0 - degreesIntoMonth) * minutesPerDegree;
  return since <= until ? since : -until;
}

Map<WuXing, double> _weighElements(List<Pillar> pillars) {
  final weights = {for (final e in WuXing.values) e: 0.0};
  for (final p in pillars) {
    // A visible stem counts for a full unit.
    weights[p.stem.element] = weights[p.stem.element]! + 1.0;
    final hidden = p.branch.hiddenStems;
    for (var i = 0; i < hidden.length; i++) {
      final w = _hiddenStemWeights[i.clamp(0, _hiddenStemWeights.length - 1)];
      weights[hidden[i].element] = weights[hidden[i].element]! + w;
    }
  }
  return weights;
}

/// Equation of time in minutes: apparent solar time minus mean solar time.
///
/// This is the second half of the true-solar-time correction. It swings by
/// roughly plus or minus a quarter of an hour across the year, which is enough
/// to move a birth into the neighbouring two-hour branch.
double equationOfTime(double jdUt) {
  final jde = jdeFromJdUt(jdUt);
  final tau = julianCenturies(jde) / 10.0;

  // Sun's mean longitude (Meeus 28.2).
  final l0 = normalizeDegrees(280.4664567 +
      360007.6982779 * tau +
      0.03032028 * tau * tau +
      tau * tau * tau / 49931.0 -
      tau * tau * tau * tau / 15300.0 -
      tau * tau * tau * tau * tau / 2000000.0);

  final lambda = apparentSolarLongitudeTT(jde);
  final eps = obliquityOfEcliptic(jde);
  final alpha = _rightAscensionDegrees(lambda, eps);

  var e = l0 - 0.0057183 - alpha + nutationInLongitude(jde) * _cosDeg(eps);
  // Fold into (-180, 180]; the raw difference is near a multiple of 360.
  e = ((e + 180.0) % 360.0 + 360.0) % 360.0 - 180.0;
  return e * 4.0;
}

/// Apparent right ascension of a point on the ecliptic, in degrees.
double _rightAscensionDegrees(double lambdaDeg, double epsDeg) {
  final y = _cosDeg(epsDeg) * _sinDeg(lambdaDeg);
  final x = _cosDeg(lambdaDeg);
  return normalizeDegrees(math.atan2(y, x) * 180.0 / math.pi);
}

double _sinDeg(double d) => math.sin(d * math.pi / 180.0);
double _cosDeg(double d) => math.cos(d * math.pi / 180.0);
