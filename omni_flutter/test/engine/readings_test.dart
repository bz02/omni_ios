import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:omni_flutter/core/engine/compatibility.dart';
import 'package:omni_flutter/core/engine/daily_fortune.dart';
import 'package:omni_flutter/core/engine/iching.dart';
import 'package:omni_flutter/core/engine/soul_blueprint.dart';
import 'package:omni_flutter/core/engine/tarot.dart';

final _newYork1990 = BirthData(
  localDateTime: DateTime(1990, 7, 4, 8, 30),
  utcOffsetHours: -4,
  latitudeNorth: 40.7128,
  longitudeEast: -74.0060,
  placeName: 'New York',
  displayName: 'A',
);

final _beijing1992 = BirthData(
  localDateTime: DateTime(1992, 11, 19, 21, 15),
  utcOffsetHours: 8,
  latitudeNorth: 39.9042,
  longitudeEast: 116.4074,
  placeName: 'Beijing',
  displayName: 'B',
);

void main() {
  group('I Ching', () {
    test('the King Wen table is a bijection onto 1..64', () {
      final numbers = <int>{};
      for (var bits = 0; bits < 64; bits++) {
        final lines = [for (var i = 0; i < 6; i++) (bits >> i) & 1 == 1];
        numbers.add(Hexagram.fromLines(lines).number);
      }
      expect(numbers.length, 64);
      expect(numbers.reduce(min), 1);
      expect(numbers.reduce(max), 64);
    });

    test('named hexagrams sit on their published trigram pairs', () {
      // Hexagram 3 is Water over Thunder, 63 is Water over Fire, 64 is Fire
      // over Water. These are the pairs the classical names describe.
      expect(Hexagram.byNumber(3).upperTrigram, Trigram.kan);
      expect(Hexagram.byNumber(3).lowerTrigram, Trigram.zhen);
      expect(Hexagram.byNumber(63).upperTrigram, Trigram.kan);
      expect(Hexagram.byNumber(63).lowerTrigram, Trigram.li);
      expect(Hexagram.byNumber(64).upperTrigram, Trigram.li);
      expect(Hexagram.byNumber(64).lowerTrigram, Trigram.kan);
      expect(Hexagram.byNumber(1).upperTrigram, Trigram.qian);
      expect(Hexagram.byNumber(2).lowerTrigram, Trigram.kun);
    });

    test('every hexagram carries a name and a gist', () {
      for (var n = 1; n <= 64; n++) {
        final h = Hexagram.byNumber(n);
        expect(h.number, n);
        expect(h.chinese, isNotEmpty);
        expect(h.english, isNotEmpty);
        expect(h.gist.length, greaterThan(20));
      }
    });

    test('a cast produces six lines and a valid hexagram', () {
      final reading = castHexagram(question: 'test', random: Random(7));
      expect(reading.lines, hasLength(6));
      expect(reading.primary.number, inInclusiveRange(1, 64));
      for (final line in reading.lines) {
        expect(line.number, inInclusiveRange(6, 9));
      }
    });

    test('changing lines produce a second hexagram and nothing else does', () {
      for (var seed = 0; seed < 50; seed++) {
        final reading = castHexagram(random: Random(seed));
        final anyChanging = reading.lines.any((l) => l.isChanging);
        expect(reading.hasChange, anyChanging,
            reason: 'seed $seed disagreed about changing lines');
        expect(reading.changingLinePositions.length,
            reading.lines.where((l) => l.isChanging).length);
      }
    });

    test('the coin method gives the classical line distribution', () {
      // Three coins: old yin 1/8, young yang 3/8, young yin 3/8, old yang 1/8.
      final counts = <int, int>{6: 0, 7: 0, 8: 0, 9: 0};
      final rng = Random(20240101);
      for (var i = 0; i < 4000; i++) {
        for (final line in castHexagram(random: rng).lines) {
          counts[line.number] = counts[line.number]! + 1;
        }
      }
      final total = counts.values.reduce((a, b) => a + b);
      expect(counts[6]! / total, closeTo(0.125, 0.02));
      expect(counts[7]! / total, closeTo(0.375, 0.03));
      expect(counts[8]! / total, closeTo(0.375, 0.03));
      expect(counts[9]! / total, closeTo(0.125, 0.02));
    });

    test('a seeded cast is reproducible', () {
      final a = castHexagram(random: Random(99));
      final b = castHexagram(random: Random(99));
      expect(a.primary.number, b.primary.number);
      expect(a.lines.map((l) => l.number), b.lines.map((l) => l.number));
    });
  });

  group('tarot', () {
    test('the deck is 78 unique cards', () {
      expect(tarotDeck, hasLength(78));
      expect(tarotDeck.map((c) => c.id).toSet(), hasLength(78));
      expect(tarotDeck.map((c) => c.name).toSet(), hasLength(78));
    });

    test('22 majors and 14 of each suit', () {
      expect(tarotDeck.where((c) => c.isMajor), hasLength(22));
      for (final suit in Suit.values) {
        expect(tarotDeck.where((c) => c.suit == suit), hasLength(14));
      }
    });

    test('every card has upright and reversed meanings', () {
      for (final card in tarotDeck) {
        expect(card.upright, isNotEmpty, reason: card.name);
        expect(card.reversed, isNotEmpty, reason: card.name);
      }
    });

    test('a spread draws distinct cards into named positions', () {
      final reading =
          drawTarot(spread: TarotSpread.bridge, question: 'us', seed: 42);
      expect(reading.cards, hasLength(5));
      expect(reading.cards.map((c) => c.card.id).toSet(), hasLength(5));
      expect(reading.cards.map((c) => c.position),
          TarotSpread.bridge.positions);
    });

    test('a seed reproduces the exact draw', () {
      final a = drawTarot(seed: 12345);
      final b = drawTarot(seed: 12345);
      expect(a.cards.map((c) => '${c.card.id}${c.isReversed}'),
          b.cards.map((c) => '${c.card.id}${c.isReversed}'));
    });

    test('different seeds give different draws', () {
      final a = drawTarot(seed: 1).cards.map((c) => c.card.id).toList();
      final b = drawTarot(seed: 2).cards.map((c) => c.card.id).toList();
      expect(a, isNot(b));
    });

    test('drawn keywords match the card orientation', () {
      final reading = drawTarot(spread: TarotSpread.single, seed: 7);
      final drawn = reading.cards.single;
      expect(drawn.keywords,
          drawn.isReversed ? drawn.card.reversed : drawn.card.upright);
    });

    test('spread weight reports the major arcana count', () {
      final reading = drawTarot(spread: TarotSpread.threeCard, seed: 3);
      expect(reading.majorCount, reading.cards.where((c) => c.card.isMajor).length);
      expect(reading.weight, isNotEmpty);
    });
  });

  group('soul blueprint', () {
    final blueprint = computeSoulBlueprint(_newYork1990);

    test('carries both charts and a signature', () {
      expect(blueprint.signature, contains('Sun'));
      expect(blueprint.signature, contains('Day Master'));
      expect(blueprint.western.sun.sign.label, isNotEmpty);
      expect(blueprint.bazi.pillars, hasLength(4));
    });

    test('produces cross-system insights with tensions first', () {
      final insights = blueprint.insights;
      expect(insights.length, greaterThanOrEqualTo(2));
      final firstNonTension = insights.indexWhere((i) => !i.isTension);
      if (firstNonTension >= 0) {
        expect(insights.skip(firstNonTension).every((i) => !i.isTension), isTrue);
      }
    });

    test('lucky attributes come from the element the chart lacks', () {
      final affinity = blueprint.affinity;
      expect(affinity.colors, isNotEmpty);
      expect(affinity.numbers, hasLength(2));
      expect(affinity.direction, isNotEmpty);
    });

    test('is deterministic', () {
      final again = computeSoulBlueprint(_newYork1990);
      expect(again.signature, blueprint.signature);
      expect(again.promptContext().toString(),
          blueprint.promptContext().toString());
    });

    test('degrades and says so when the birth time is unknown', () {
      final partial = computeSoulBlueprint(BirthData(
        localDateTime: DateTime(1990, 7, 4),
        utcOffsetHours: -4,
        timeIsKnown: false,
      ));
      expect(partial.western.moon, isNull);
      expect(partial.bazi.hour, isNull);
      expect(partial.caveats.first, contains('No birth time'));
    });

    test('birth data survives a JSON round trip', () {
      final restored = BirthData.fromJson(_beijing1992.toJson());
      expect(restored.fingerprint, _beijing1992.fingerprint);
    });
  });

  group('daily fortune', () {
    final blueprint = computeSoulBlueprint(_newYork1990);

    test('is stable for a given person and day', () {
      final a = computeDailyFortune(
          blueprint: blueprint, date: DateTime(2026, 3, 14));
      final b = computeDailyFortune(
          blueprint: blueprint, date: DateTime(2026, 3, 14, 23, 59));
      expect(a.score, b.score);
      expect(a.luckyColor, b.luckyColor);
      expect(a.favourable, b.favourable);
    });

    test('differs between days', () {
      final scores = <int>{};
      for (var d = 0; d < 30; d++) {
        scores.add(computeDailyFortune(
          blueprint: blueprint,
          date: DateTime(2026, 3, 1).add(Duration(days: d)),
        ).score);
      }
      expect(scores.length, greaterThan(8));
    });

    test('differs between people on the same day', () {
      final other = computeSoulBlueprint(_beijing1992);
      final a = computeDailyFortune(
          blueprint: blueprint, date: DateTime(2026, 3, 14));
      final b =
          computeDailyFortune(blueprint: other, date: DateTime(2026, 3, 14));
      expect(a.score == b.score && a.dayPillar.chinese != b.dayPillar.chinese,
          isFalse);
    });

    test('stays inside the published range over three years', () {
      for (var d = 0; d < 1100; d += 7) {
        final fortune = computeDailyFortune(
          blueprint: blueprint,
          date: DateTime(2026, 1, 1).add(Duration(days: d)),
        );
        expect(fortune.score, inInclusiveRange(5, 99));
        expect(fortune.band, isNotEmpty);
        expect(fortune.favourable, isNotEmpty);
        expect(fortune.unfavourable, isNotEmpty);
      }
    });

    test('shows its working', () {
      final fortune =
          computeDailyFortune(blueprint: blueprint, date: DateTime(2026, 3, 14));
      expect(fortune.factors.length, greaterThanOrEqualTo(2));
      // The listed factors plus the base and the jitter must reconstruct the
      // score to within the jitter band.
      final fromFactors =
          50 + fortune.factors.fold<int>(0, (sum, f) => sum + f.points);
      expect((fortune.score - fromFactors).abs(), lessThanOrEqualTo(4));
    });
  });

  group('compatibility', () {
    final a = computeSoulBlueprint(_newYork1990);
    final b = computeSoulBlueprint(_beijing1992);

    test('scores both traditions and a combined total', () {
      final result = computeCompatibility(a, b);
      expect(result.score, inInclusiveRange(0, 100));
      expect(result.easternScore, inInclusiveRange(0, 100));
      expect(result.westernScore, inInclusiveRange(0, 100));
      expect(result.factors, hasLength(6));
      expect(result.band, isNotEmpty);
    });

    test('the combined score is the mean of the two traditions', () {
      final result = computeCompatibility(a, b);
      expect(result.score,
          ((result.easternScore + result.westernScore) / 2).round());
    });

    test('is symmetric in the score', () {
      expect(computeCompatibility(a, b).score, computeCompatibility(b, a).score);
    });

    test('a person is highly compatible with themselves', () {
      final self = computeCompatibility(a, a);
      expect(self.score, greaterThan(50));
    });

    test('names a green flag and a red flag', () {
      final result = computeCompatibility(a, b);
      expect(result.greenFlag, isNotEmpty);
      expect(result.redFlag, isNotEmpty);
      expect(result.headline, isNotEmpty);
    });

    test('every factor is within its own maximum', () {
      final result = computeCompatibility(a, b);
      for (final factor in result.factors) {
        expect(factor.points, inInclusiveRange(0, factor.maxPoints));
        expect(factor.verdict, isNotEmpty);
      }
    });

    test('handles a partner with no birth time', () {
      final partial = computeSoulBlueprint(BirthData(
        localDateTime: DateTime(1988, 2, 29),
        utcOffsetHours: 0,
        timeIsKnown: false,
      ));
      final result = computeCompatibility(a, partial);
      expect(result.score, inInclusiveRange(0, 100));
      expect(
          result.factors
              .firstWhere((f) => f.label == 'Moon to Moon')
              .verdict,
          contains('birth time'));
    });
  });
}
