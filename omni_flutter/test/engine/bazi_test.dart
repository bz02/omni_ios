import 'package:flutter_test/flutter_test.dart';
import 'package:omni_flutter/core/engine/bazi.dart';

BaziChart _chart(int y, int mo, int d, int h, int mi, double tz,
        {double? longitude, bool trueSolar = false, bool hourKnown = true}) =>
    computeBaziChart(
      birthLocal: DateTime(y, mo, d, h, mi),
      utcOffsetHours: tz,
      longitudeEast: longitude,
      hourIsKnown: hourKnown,
      useTrueSolarTime: trueSolar,
    );

void main() {
  group('reference chart', () {
    // 1 January 2000, noon, Beijing. Year is still Ji-Mao because Start of
    // Spring has not arrived; the month is the Zi month because the date falls
    // between Major Snow and Minor Cold; the day pillar follows the Julian Day
    // Number rule anchored on two independently published dates.
    final chart = _chart(2000, 1, 1, 12, 0, 8);

    test('all four pillars', () {
      expect(chart.year.chinese, '己卯');
      expect(chart.month.chinese, '丙子');
      expect(chart.day.chinese, '戊午');
      expect(chart.hour!.chinese, '戊午');
    });

    test('derived attributes', () {
      expect(chart.zodiacAnimal, 'Rabbit');
      expect(chart.solarTerm, SolarTerm.daxue);
      expect(chart.dayMaster, HeavenlyStem.wu);
      expect(chart.year.naYin.chinese, '城头土');
    });
  });

  group('day pillar anchors', () {
    test('1 October 1949 is Jia-Zi', () {
      expect(_chart(1949, 10, 1, 12, 0, 8).day.chinese, '甲子');
    });

    test('1 January 2000 is Wu-Wu', () {
      expect(_chart(2000, 1, 1, 12, 0, 8).day.chinese, '戊午');
    });

    test('sixty consecutive days give sixty distinct pillars', () {
      final seen = <String>{};
      for (var i = 0; i < 60; i++) {
        seen.add(computeBaziChart(
          birthLocal: DateTime(2024, 1, 1).add(Duration(days: i)),
          utcOffsetHours: 8,
          hourIsKnown: false,
        ).day.chinese);
      }
      expect(seen.length, 60);
    });

    test('the cycle repeats after exactly sixty days', () {
      final a = computeBaziChart(
          birthLocal: DateTime(2024, 1, 1),
          utcOffsetHours: 8,
          hourIsKnown: false);
      final b = computeBaziChart(
          birthLocal: DateTime(2024, 1, 1).add(const Duration(days: 60)),
          utcOffsetHours: 8,
          hourIsKnown: false);
      expect(a.day.chinese, b.day.chinese);
    });
  });

  group('year turns over at Start of Spring, not 1 January', () {
    // Start of Spring 2024 falls at 16:27 Beijing time on 4 February.
    test('a birth that morning still belongs to the previous year', () {
      final chart = _chart(2024, 2, 4, 9, 0, 8);
      expect(chart.year.chinese, '癸卯');
      expect(chart.month.branch, EarthlyBranch.chou);
    });

    test('a birth that evening belongs to the new year', () {
      final chart = _chart(2024, 2, 4, 17, 0, 8);
      expect(chart.year.chinese, '甲辰');
      expect(chart.month.branch, EarthlyBranch.yin);
    });

    test('both share the same day pillar', () {
      expect(_chart(2024, 2, 4, 9, 0, 8).day.chinese,
          _chart(2024, 2, 4, 17, 0, 8).day.chinese);
    });

    test('births close to the boundary are flagged', () {
      expect(_chart(2024, 2, 4, 16, 40, 8).isNearTermBoundary, isTrue);
      expect(_chart(2024, 6, 1, 12, 0, 8).isNearTermBoundary, isFalse);
    });

    test('2 February 1984 belongs to the Pig year', () {
      final chart = _chart(1984, 2, 2, 10, 0, 8);
      expect(chart.year.chinese, '癸亥');
      expect(chart.zodiacAnimal, 'Pig');
    });
  });

  group('hour pillar', () {
    test('the sexagenary day rolls at 23:00', () {
      expect(_chart(2000, 1, 1, 22, 0, 8).day.chinese, '戊午');
      expect(_chart(2000, 1, 1, 23, 30, 8).day.chinese, '己未');
    });

    test('late Zi hour follows the rolled day stem', () {
      expect(_chart(2000, 1, 1, 23, 30, 8).hour!.chinese, '甲子');
    });

    test('each two-hour block maps to its branch', () {
      expect(_chart(2024, 6, 1, 0, 30, 8).hour!.branch, EarthlyBranch.zi);
      expect(_chart(2024, 6, 1, 1, 30, 8).hour!.branch, EarthlyBranch.chou);
      expect(_chart(2024, 6, 1, 12, 30, 8).hour!.branch, EarthlyBranch.wu);
    });
  });

  group('true solar time', () {
    test('shifts a Kashgar birth off the Beijing clock', () {
      // Kashgar runs on Beijing time but sits 44 degrees west of the zone
      // meridian, close to three hours of real Sun.
      final civil = _chart(1990, 6, 15, 8, 0, 8, longitude: 75.99);
      final solar =
          _chart(1990, 6, 15, 8, 0, 8, longitude: 75.99, trueSolar: true);
      expect(solar.trueSolarTimeApplied, isTrue);
      expect(civil.hour!.chinese, isNot(solar.hour!.chinese));
    });

    test('is a no-op without a longitude', () {
      expect(_chart(1990, 6, 15, 8, 0, 8, trueSolar: true).trueSolarTimeApplied,
          isFalse);
    });

    test('equation of time stays within a quarter hour', () {
      for (var day = 0; day < 365; day += 10) {
        final jd = 2460310.5 + day;
        expect(equationOfTime(jd).abs(), lessThan(17));
      }
    });
  });

  group('ten gods', () {
    test('classify against a Jia day master', () {
      expect(tenGodFor(HeavenlyStem.jia, HeavenlyStem.jia), TenGod.friend);
      expect(tenGodFor(HeavenlyStem.jia, HeavenlyStem.yi), TenGod.robWealth);
      expect(tenGodFor(HeavenlyStem.jia, HeavenlyStem.bing), TenGod.eatingGod);
      expect(tenGodFor(HeavenlyStem.jia, HeavenlyStem.ding),
          TenGod.hurtingOfficer);
      expect(tenGodFor(HeavenlyStem.jia, HeavenlyStem.wu),
          TenGod.indirectWealth);
      expect(tenGodFor(HeavenlyStem.jia, HeavenlyStem.ji), TenGod.directWealth);
      expect(tenGodFor(HeavenlyStem.jia, HeavenlyStem.geng),
          TenGod.sevenKillings);
      expect(
          tenGodFor(HeavenlyStem.jia, HeavenlyStem.xin), TenGod.directOfficer);
      expect(tenGodFor(HeavenlyStem.jia, HeavenlyStem.ren),
          TenGod.indirectResource);
      expect(
          tenGodFor(HeavenlyStem.jia, HeavenlyStem.gui), TenGod.directResource);
    });
  });

  group('branch relationships', () {
    test('clash pairs sit six apart', () {
      expect(EarthlyBranch.zi.clashesWith, EarthlyBranch.wu);
      expect(EarthlyBranch.yin.clashesWith, EarthlyBranch.shen);
      for (final b in EarthlyBranch.values) {
        expect(b.clashesWith.clashesWith, b);
      }
    });

    test('six harmonies are mutual', () {
      expect(EarthlyBranch.zi.harmonizesWith, EarthlyBranch.chou);
      for (final b in EarthlyBranch.values) {
        expect(b.harmonizesWith.harmonizesWith, b);
      }
    });

    test('trines are the four-month triangles', () {
      expect(EarthlyBranch.yin.trine,
          containsAll([EarthlyBranch.wu, EarthlyBranch.xu]));
      expect(EarthlyBranch.shen.trine,
          containsAll([EarthlyBranch.zi, EarthlyBranch.chen]));
    });
  });

  group('five phases', () {
    test('generating and controlling cycles are consistent', () {
      for (final e in WuXing.values) {
        expect(e.generates.generatedBy, e);
        expect(e.controls.controlledBy, e);
      }
    });

    test('element weights include hidden stems', () {
      final chart = _chart(2000, 1, 1, 12, 0, 8);
      final total =
          chart.elementWeights.values.fold<double>(0, (a, b) => a + b);
      // Four visible stems plus weighted hidden stems.
      expect(total, greaterThan(8));
      expect(chart.missingElements, contains(WuXing.metal));
      expect(chart.dominantElement, WuXing.earth);
    });

    test('day master strength is a fraction', () {
      final s = _chart(2000, 1, 1, 12, 0, 8).dayMasterStrength;
      expect(s, inInclusiveRange(0.0, 1.0));
    });
  });

  group('na yin', () {
    test('covers the whole sexagenary cycle in thirty pairs', () {
      expect(const Pillar(HeavenlyStem.jia, EarthlyBranch.zi).naYin.chinese,
          '海中金');
      expect(const Pillar(HeavenlyStem.yi, EarthlyBranch.chou).naYin.chinese,
          '海中金');
      expect(const Pillar(HeavenlyStem.bing, EarthlyBranch.yin).naYin.chinese,
          '炉中火');
      expect(const Pillar(HeavenlyStem.gui, EarthlyBranch.hai).naYin.chinese,
          '大海水');
    });

    test('every valid pillar resolves', () {
      for (var i = 0; i < 60; i++) {
        final pillar = Pillar(HeavenlyStem.values[i % 10],
            EarthlyBranch.values[i % 12]);
        expect(pillar.sexagenaryIndex, i);
        expect(pillar.naYin.chinese, isNotEmpty);
      }
    });
  });

  test('an unknown birth time still yields three pillars', () {
    final chart = _chart(1995, 7, 20, 0, 0, -4, hourKnown: false);
    expect(chart.hour, isNull);
    expect(chart.hourIsKnown, isFalse);
    expect(chart.pillars, hasLength(3));
    expect(chart.tenGods.containsKey('hour'), isFalse);
  });
}
