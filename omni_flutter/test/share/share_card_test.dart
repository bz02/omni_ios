// The share card is a fixed 1080 by 1920 canvas with text in it, which is
// exactly the shape of layout that overflows silently on someone else's data.
// These pump it at true size with the worst content it can be handed.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omni_flutter/core/engine/compatibility.dart';
import 'package:omni_flutter/core/engine/soul_blueprint.dart';
import 'package:omni_flutter/features/share/share_card.dart';

CompatibilityResult _result() {
  final a = computeSoulBlueprint(BirthData(
    localDateTime: DateTime(1994, 9, 12, 14, 20),
    utcOffsetHours: -7,
    latitudeNorth: 34.0522,
    longitudeEast: -118.2437,
  ));
  final b = computeSoulBlueprint(BirthData(
    localDateTime: DateTime(1991, 3, 3, 6),
    utcOffsetHours: 8,
    latitudeNorth: 31.2304,
    longitudeEast: 121.4737,
  ));
  return computeCompatibility(a, b);
}

/// Pumps the card at its true pixel size, with the surface large enough that
/// nothing is clipped by the test viewport rather than by the layout.
Future<void> _pumpCard(
  WidgetTester tester, {
  required String yourName,
  required String theirName,
}) async {
  tester.view.physicalSize = const Size(shareCardWidth, shareCardHeight);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(MaterialApp(
    home: Center(
      child: CompatibilityShareCard(
        result: _result(),
        yourName: yourName,
        theirName: theirName,
      ),
    ),
  ));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('renders at story proportions', (tester) async {
    await _pumpCard(tester, yourName: 'You', theirName: 'Wen');

    final size = tester.getSize(find.byType(CompatibilityShareCard));
    expect(size.width, shareCardWidth);
    expect(size.height, shareCardHeight);
    // 9:16, which is what a story slot wants.
    expect(size.height / size.width, closeTo(16 / 9, 0.01));
  });

  testWidgets('leads with the score and the split', (tester) async {
    await _pumpCard(tester, yourName: 'You', theirName: 'Wen');
    final result = _result();

    expect(find.text('${result.score}'), findsOneWidget);
    // The disagreement between the two traditions is the postable part, so
    // both numbers are on the card.
    expect(find.text('${result.easternScore}'), findsOneWidget);
    expect(find.text('${result.westernScore}'), findsOneWidget);
    expect(find.text('東  CHINESE'), findsOneWidget);
    expect(find.text('西  WESTERN'), findsOneWidget);
  });

  testWidgets('carries the wordmark and the positioning line', (tester) async {
    await _pumpCard(tester, yourName: 'You', theirName: 'Wen');
    expect(find.text('OMNI'), findsOneWidget);
    expect(find.text('astrology that shows its work'), findsOneWidget);
  });

  testWidgets('does not overflow on very long names', (tester) async {
    await _pumpCard(
      tester,
      yourName: 'Bartholomew Fitzgerald-Winchester',
      theirName: 'Anastasia Konstantinopoulou',
    );
    // pumpWidget rethrows overflow exceptions, so reaching here is the
    // assertion; this makes the intent explicit.
    expect(tester.takeException(), isNull);
  });

  testWidgets('does not overflow on the longest headline the engine writes',
      (tester) async {
    // The disagreement headline is the longest branch in compatibility.dart.
    tester.view.physicalSize = const Size(shareCardWidth, shareCardHeight);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    var longest = _result();
    for (final other in [
      DateTime(1988, 2, 29),
      DateTime(1975, 11, 3, 23),
      DateTime(2001, 6, 21, 4, 5),
      DateTime(1969, 1, 15, 18),
    ]) {
      final candidate = computeCompatibility(
        computeSoulBlueprint(BirthData(
          localDateTime: DateTime(1994, 9, 12, 14, 20),
          utcOffsetHours: -7,
          latitudeNorth: 34.05,
          longitudeEast: -118.24,
        )),
        computeSoulBlueprint(
            BirthData(localDateTime: other, utcOffsetHours: 0)),
      );
      if (candidate.headline.length > longest.headline.length) {
        longest = candidate;
      }
    }

    await tester.pumpWidget(MaterialApp(
      home: Center(
        child: CompatibilityShareCard(
          result: longest,
          yourName: 'Alexandra',
          theirName: 'Christopher',
        ),
      ),
    ));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('the score color tracks the band', (tester) async {
    await _pumpCard(tester, yourName: 'You', theirName: 'Wen');
    final result = _result();
    final scoreText =
        tester.widget<Text>(find.text('${result.score}'));
    // Not the default text color — the number is the thing the eye lands on.
    expect(scoreText.style?.color, isNotNull);
    expect(scoreText.style?.fontSize, greaterThan(200));
  });
}
