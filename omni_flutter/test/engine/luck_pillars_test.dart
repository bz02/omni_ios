import 'package:flutter_test/flutter_test.dart';
import 'package:omni_flutter/core/engine/luck_pillars.dart';
import 'package:omni_flutter/core/engine/soul_blueprint.dart';

BirthData _birth(int y, int m, int d, [int hour = 12]) => BirthData(
      localDateTime: DateTime(y, m, d, hour),
      utcOffsetHours: 8,
      latitudeNorth: 39.9042,
      longitudeEast: 116.4074,
      placeName: 'Beijing, China',
    );

void main() {
  group('direction of the cycle', () {
    test('matches the classical rule in all four cases', () {
      // Yang year with yang polarity, or yin with yin, runs forward.
      expect(
          luckRunsForward(
              yearStemIsYang: true, polarity: ChartPolarity.yang), isTrue);
      expect(
          luckRunsForward(
              yearStemIsYang: false, polarity: ChartPolarity.yin), isTrue);
      // The mixed cases run backward.
      expect(
          luckRunsForward(
              yearStemIsYang: true, polarity: ChartPolarity.yin), isFalse);
      expect(
          luckRunsForward(
              yearStemIsYang: false, polarity: ChartPolarity.yang), isFalse);
    });

    test('the two polarities give opposite sequences from the same chart', () {
      final birth = _birth(1990, 5, 20);
      final chart = computeSoulBlueprint(birth).bazi;

      final yang = computeLuckCycle(
          birth: birth, chart: chart, polarity: ChartPolarity.yang);
      final yin = computeLuckCycle(
          birth: birth, chart: chart, polarity: ChartPolarity.yin);

      expect(yang.runsForward, isNot(yin.runsForward));
      expect(yang.pillars.first.pillar.chinese,
          isNot(yin.pillars.first.pillar.chinese));
    });
  });

  group('starting age', () {
    test('is measured from a solar term at three days to the year', () {
      final birth = _birth(1990, 5, 20);
      final chart = computeSoulBlueprint(birth).bazi;
      final cycle = computeLuckCycle(
          birth: birth, chart: chart, polarity: ChartPolarity.yang);

      // Whichever term it is measured against, the gap is under a month, so
      // the cycle always opens inside the first ten years.
      expect(cycle.startAgeMonths, inInclusiveRange(0, 120));
      expect(cycle.startAgeYears, lessThan(11));
    });

    test('forward and reverse split the same solar month between them', () {
      // The two directions measure to opposite ends of the same term window,
      // so their distances must add up to that window: about 30 days, which is
      // 120 months of reckoned age.
      final birth = _birth(1990, 5, 20);
      final chart = computeSoulBlueprint(birth).bazi;

      final forward = computeLuckCycle(
          birth: birth, chart: chart, polarity: ChartPolarity.yang);
      final reverse = computeLuckCycle(
          birth: birth, chart: chart, polarity: ChartPolarity.yin);
      final total = forward.runsForward
          ? forward.startAgeMonths + reverse.startAgeMonths
          : reverse.startAgeMonths + forward.startAgeMonths;

      expect(total, inInclusiveRange(115, 128));
    });

    test('a birth just after a term opens starts the cycle almost at zero '
        'when running backward', () {
      // Start of Spring 2024 falls at 16:27 Beijing time on 4 February.
      final birth = BirthData(
        localDateTime: DateTime(2024, 2, 4, 17, 30),
        utcOffsetHours: 8,
      );
      final chart = computeSoulBlueprint(birth).bazi;
      final cycle = computeLuckCycle(
          birth: birth,
          chart: chart,
          polarity: chart.year.stem.isYang ? ChartPolarity.yin : ChartPolarity.yang);

      expect(cycle.runsForward, isFalse);
      // An hour past the term is a fifth of a day, well under a month of age.
      expect(cycle.startAgeMonths, lessThanOrEqualTo(1));
    });

    test('names the term it was measured against', () {
      final birth = _birth(1990, 5, 20);
      final chart = computeSoulBlueprint(birth).bazi;
      final cycle = computeLuckCycle(
          birth: birth, chart: chart, polarity: ChartPolarity.yang);
      expect(cycle.anchorTerm.chinese, isNotEmpty);
      expect(cycle.startDescription, isNotEmpty);
    });
  });

  group('the pillars themselves', () {
    final birth = _birth(1990, 5, 20);
    final chart = computeSoulBlueprint(birth).bazi;

    test('step one place along the sexagenary cycle per decade', () {
      final cycle = computeLuckCycle(
          birth: birth, chart: chart, polarity: ChartPolarity.yang);
      final step = cycle.runsForward ? 1 : -1;

      var expected = chart.month.sexagenaryIndex;
      for (final pillar in cycle.pillars) {
        expected = ((expected + step) % 60 + 60) % 60;
        expect(pillar.pillar.sexagenaryIndex, expected);
      }
    });

    test('cover ten years each with no gap', () {
      final cycle = computeLuckCycle(
          birth: birth, chart: chart, polarity: ChartPolarity.yang, count: 9);
      expect(cycle.pillars, hasLength(9));
      for (var i = 1; i < cycle.pillars.length; i++) {
        expect(cycle.pillars[i].startAgeMonths -
            cycle.pillars[i - 1].startAgeMonths, 120);
        expect(cycle.pillars[i].startYear - cycle.pillars[i - 1].startYear, 10);
      }
    });

    test('an age resolves to exactly one period', () {
      final cycle = computeLuckCycle(
          birth: birth, chart: chart, polarity: ChartPolarity.yang);
      for (var age = cycle.startAgeYears; age < cycle.startAgeYears + 90;
          age += 3) {
        final matches =
            cycle.pillars.where((p) => p.containsAge(age)).toList();
        expect(matches.length, lessThanOrEqualTo(1),
            reason: 'age $age matched ${matches.length} periods');
      }
    });

    test('carries a ten god for each decade', () {
      final cycle = computeLuckCycle(
          birth: birth, chart: chart, polarity: ChartPolarity.yang);
      for (final pillar in cycle.pillars) {
        expect(pillar.tenGod.chinese, isNotEmpty);
        expect(pillar.ageRange, contains('–'));
      }
    });
  });

  group('year pillars', () {
    test('match the published sexagenary years', () {
      expect(yearPillarFor(1984).chinese, '甲子');
      expect(yearPillarFor(2024).chinese, '甲辰');
      expect(yearPillarFor(2023).chinese, '癸卯');
      expect(yearPillarFor(1999).chinese, '己卯');
    });

    test('repeat every sixty years', () {
      for (var year = 1900; year < 2000; year += 7) {
        expect(yearPillarFor(year).chinese, yearPillarFor(year + 60).chinese);
      }
    });
  });

  group('annual forecast', () {
    final birth = _birth(1990, 5, 20);
    final blueprint = computeSoulBlueprint(birth);
    final cycle = computeLuckCycle(
        birth: birth, chart: blueprint.bazi, polarity: ChartPolarity.yang);

    test('scores inside the published band and shows its working', () {
      for (var year = 2025; year <= 2040; year++) {
        final forecast = computeAnnualForecast(
            blueprint: blueprint, cycle: cycle, year: year);
        expect(forecast.score, inInclusiveRange(5, 99));
        expect(forecast.factors, isNotEmpty);
        expect(forecast.headline, isNotEmpty);
        expect(forecast.band, isNotEmpty);
      }
    });

    test('is deterministic', () {
      final a = computeAnnualForecast(
          blueprint: blueprint, cycle: cycle, year: 2027);
      final b = computeAnnualForecast(
          blueprint: blueprint, cycle: cycle, year: 2027);
      expect(a.score, b.score);
      expect(a.factors, b.factors);
    });

    test('flags the year of your own animal', () {
      // The birth-year branch comes round every twelve years.
      final natal = blueprint.bazi.year.branch;
      final ownAnimalYear = List.generate(12, (i) => 2025 + i)
          .firstWhere((y) => yearPillarFor(y).branch == natal);

      final forecast = computeAnnualForecast(
          blueprint: blueprint, cycle: cycle, year: ownAnimalYear);
      expect(forecast.factors.join(), contains('本命年'));
    });

    test('flags the clash year', () {
      final clash = blueprint.bazi.year.branch.clashesWith;
      final clashYear = List.generate(12, (i) => 2025 + i)
          .firstWhere((y) => yearPillarFor(y).branch == clash);

      final forecast = computeAnnualForecast(
          blueprint: blueprint, cycle: cycle, year: clashYear);
      expect(forecast.factors.join(), contains('冲太岁'));
    });

    test('names the decade a year belongs to', () {
      final forecast = computeAnnualForecast(
          blueprint: blueprint, cycle: cycle, year: 2030);
      expect(forecast.governingLuck, isNotNull);
      expect(forecast.governingLuck!.containsYear(2030), isTrue);
    });

    test('years vary rather than all landing on the same score', () {
      final scores = {
        for (var year = 2025; year <= 2044; year++)
          computeAnnualForecast(
              blueprint: blueprint, cycle: cycle, year: year).score,
      };
      expect(scores.length, greaterThan(5));
    });
  });

  group('months of a year', () {
    test('are twelve, opening on the twelve major solar terms', () {
      final months = monthsOfYear(
        year: 2026,
        yearStem: yearPillarFor(2026).stem,
        dayMaster: computeSoulBlueprint(_birth(1990, 5, 20)).bazi.dayMaster,
      );
      expect(months, hasLength(12));
      expect(months.first.term.chinese, '立春');
      expect(months.first.pillar.branch.chinese, '寅');
      // Consecutive months step one place along the cycle.
      for (var i = 1; i < months.length; i++) {
        final previous = months[i - 1].pillar.sexagenaryIndex;
        expect(months[i].pillar.sexagenaryIndex, (previous + 1) % 60);
      }
    });
  });
}
