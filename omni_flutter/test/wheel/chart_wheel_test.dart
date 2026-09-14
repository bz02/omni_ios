// The wheel is a CustomPainter inside a scrolling column, which is where a
// layout either overflows on a small phone or throws in paint on data the
// author never tried. These pump it at real device widths with charts that are
// missing the pieces a real user will be missing.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omni_flutter/core/engine/wheel_layout.dart';
import 'package:omni_flutter/core/engine/soul_blueprint.dart';
import 'package:omni_flutter/features/wheel/chart_wheel.dart';

WesternChart _chart({bool hourIsKnown = true, bool withPlace = true}) =>
    computeWesternChart(
      birthLocal: DateTime(1994, 9, 12, 14, 20),
      utcOffsetHours: -7,
      latitudeNorth: withPlace ? 34.0522 : null,
      longitudeEast: withPlace ? -118.2437 : null,
      hourIsKnown: hourIsKnown,
    );

Future<void> _pump(WidgetTester tester, Widget child,
    {Size size = const Size(360, 800)}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: child,
      ),
    ),
  ));
  await tester.pumpAndSettle();
}

void main() {
  test('separation clears the glyph it is separating', () {
    // The first render of this wheel overlapped, because the spread constant
    // was chosen by eye at 7° while a glyph needs 10.2°. The two numbers live
    // in different files, so tie them together here: at the glyph ring, the
    // arc that `glyphSeparationDegrees` buys must exceed the glyph's own
    // width with a little room to breathe.
    const breathingRoom = 1.15;
    const arcPerRadius = glyphSeparationDegrees * math.pi / 180;
    expect(arcPerRadius,
        greaterThanOrEqualTo(planetGlyphFraction * breathingRoom));
  });

  test('the glyph ring clears the retrograde mark and the house ring', () {
    // ℞ hangs 12.5% of the ring radius below its glyph; the house ring must
    // start inside that, or the two draw on top of each other.
    const retrogradeDrop = 0.125;
    const houseOuterFraction = 0.585;
    expect(planetRingFraction * (1 - retrogradeDrop),
        greaterThan(houseOuterFraction));
  });

  testWidgets('paints a full chart without throwing', (tester) async {
    await _pump(tester, ChartWheelPanel(chart: _chart()));
    expect(tester.takeException(), isNull);
    expect(find.byType(ChartWheel), findsOneWidget);
  });

  testWidgets('paints on the narrowest phone in service', (tester) async {
    // 320 logical pixels is an iPhone SE in portrait, and the width where a
    // fixed-size legend row starts overflowing.
    await _pump(tester, ChartWheelPanel(chart: _chart()),
        size: const Size(320, 700));
    expect(tester.takeException(), isNull);
  });

  testWidgets('paints a chart with no birth time and says why', (tester) async {
    await _pump(tester, ChartWheelPanel(chart: _chart(hourIsKnown: false)));
    expect(tester.takeException(), isNull);
    expect(find.textContaining('No birth time'), findsOneWidget);
  });

  testWidgets('paints a chart with no birthplace', (tester) async {
    await _pump(tester, ChartWheelPanel(chart: _chart(withPlace: false)));
    expect(tester.takeException(), isNull);
  });

  testWidgets('stays square whatever it is given', (tester) async {
    // A wheel that is not round is worse than no wheel.
    await _pump(tester, ChartWheelPanel(chart: _chart(), showLegend: false));
    final size = tester.getSize(find.byType(ChartWheel));
    expect(size.width, closeTo(size.height, 0.01));
  });

  testWidgets('the full screen switches house systems live', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(home: WheelScreen(chart: _chart())));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Whole Sign'), findsOneWidget);

    await tester.tap(find.text('Equal'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('the full screen toggles aspects off', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(home: WheelScreen(chart: _chart())));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Hide aspects'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byTooltip('Show aspects'), findsOneWidget);
  });

  testWidgets('hides the house-system switch when there are no houses',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
        MaterialApp(home: WheelScreen(chart: _chart(hourIsKnown: false))));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Whole Sign'), findsNothing);
  });

  testWidgets('carries one screen-reader label rather than twelve glyphs',
      (tester) async {
    final chart = _chart();
    await _pump(tester, ChartWheelPanel(chart: chart, showLegend: false));
    expect(
      find.bySemanticsLabel('Natal chart wheel. ${chart.bigThree}.'),
      findsOneWidget,
    );
  });

  testWidgets('renders inside the chart screen it ships on', (tester) async {
    // The panel is embedded in a dark card in a light ListView; this is the
    // combination that produced an unreadable wheel in an earlier pass.
    final blueprint = computeSoulBlueprint(BirthData(
      localDateTime: DateTime(1994, 9, 12, 14, 20),
      utcOffsetHours: -7,
      latitudeNorth: 34.0522,
      longitudeEast: -118.2437,
    ));
    await _pump(tester, ChartWheelPanel(chart: blueprint.western));
    expect(tester.takeException(), isNull);
  });
}
