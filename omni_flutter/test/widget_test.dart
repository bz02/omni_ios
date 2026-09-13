// Smoke tests for the shell.
//
// These exist mostly to compile everything reachable from `main.dart` — a
// broken widget tree is otherwise only discovered on a device — and to hold
// the two flows that carry the money: onboarding through to a chart, and a
// blocked feature through to the paywall.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show ProviderScope;
import 'package:flutter_test/flutter_test.dart';
import 'package:omni_flutter/core/billing/entitlements.dart';
import 'package:omni_flutter/core/billing/purchase_service.dart';
import 'package:omni_flutter/core/engine/soul_blueprint.dart';
import 'package:omni_flutter/features/paywall/paywall_screen.dart';
import 'package:omni_flutter/main.dart';
import 'package:omni_flutter/providers/app_state.dart';
import 'package:omni_flutter/services/gemini_service.dart';
import 'package:omni_flutter/services/user_service.dart';
import 'package:omni_flutter/state/profile_controller.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _sampleBirth = BirthData(
  localDateTime: DateTime(1994, 9, 12, 14, 20),
  utcOffsetHours: -7,
  latitudeNorth: 34.0522,
  longitudeEast: -118.2437,
  placeName: 'Los Angeles, United States',
);

Future<
    ({
      Widget app,
      EntitlementsController entitlements,
      ProfileController profile,
    })> _harness({BirthData? birth}) async {
  SharedPreferences.setMockInitialValues({});
  final preferences = await SharedPreferences.getInstance();

  final entitlements = EntitlementsController(preferences: preferences);
  final profile = ProfileController(preferences: preferences);
  await entitlements.load();
  await profile.load();
  if (birth != null) await profile.setBirth(birth);

  final purchases = SandboxPurchaseService(entitlements: entitlements);

  return (
    app: MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: entitlements),
        ChangeNotifierProvider.value(value: profile),
        ChangeNotifierProvider<PurchaseService>.value(value: purchases),
        ChangeNotifierProvider(create: (_) => AppState()),
        ChangeNotifierProvider(create: (_) => UserService()),
        ChangeNotifierProvider(create: (_) => GeminiService(apiKey: '')),
      ],
      child: const ProviderScope(child: OmniApp()),
    ),
    entitlements: entitlements,
    profile: profile,
  );
}

/// Sizes the test view like a phone. The default 800x600 is nothing like the
/// device these screens are laid out for, and off-screen widgets in a list are
/// never built, so a wrong viewport turns into confusing missing-widget errors.
void _usePhoneViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

/// Scrolls [target] into view within the nearest scrollable, then settles.
Future<void> _reveal(WidgetTester tester, Finder target) async {
  await tester.scrollUntilVisible(target, 200,
      scrollable: find.byType(Scrollable).first);
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('a new install lands on the onboarding prompt', (tester) async {
    _usePhoneViewport(tester);
    final harness = await _harness();
    await tester.pumpWidget(harness.app);
    await tester.pumpAndSettle();

    expect(find.text('Two charts, one you'), findsOneWidget);
    expect(find.text('Start'), findsOneWidget);
    // No tab bar until there is something to put in the tabs.
    expect(find.byType(BottomNavigationBar), findsNothing);
  });

  testWidgets('with a birth record the shell shows all five tabs',
      (tester) async {
    _usePhoneViewport(tester);
    final harness = await _harness(birth: _sampleBirth);
    await tester.pumpWidget(harness.app);
    await tester.pumpAndSettle();

    expect(find.byType(BottomNavigationBar), findsOneWidget);
    for (final label in ['Today', 'Chart', 'Oracle', 'Match', 'You']) {
      expect(find.text(label), findsOneWidget);
    }
  });

  testWidgets('the daily screen shows a score and can explain it',
      (tester) async {
    _usePhoneViewport(tester);
    final harness = await _harness(birth: _sampleBirth);
    await tester.pumpWidget(harness.app);
    await tester.pumpAndSettle();

    final fortune = harness.profile.today!;
    expect(find.text('${fortune.score}'), findsOneWidget);
    expect(find.text('宜'), findsOneWidget);
    expect(find.text('忌'), findsOneWidget);

    final why = find.text('Why ${fortune.score}?');
    await _reveal(tester, why);
    await tester.tap(why);
    await tester.pumpAndSettle();
    expect(find.text('baseline'), findsOneWidget);
  });

  testWidgets('the chart tab renders both traditions', (tester) async {
    _usePhoneViewport(tester);
    final harness = await _harness(birth: _sampleBirth);
    await tester.pumpWidget(harness.app);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Chart'));
    await tester.pumpAndSettle();

    expect(find.text('Natal chart'), findsOneWidget);
    expect(find.text('WEST'), findsOneWidget);

    await _reveal(tester, find.text('Four pillars 四柱'));
    expect(find.text('Four pillars 四柱'), findsOneWidget);

    await _reveal(tester, find.text('Five phases 五行'));
    expect(find.text('Five phases 五行'), findsOneWidget);

    await _reveal(tester, find.text('WHERE THE TWO MEET'));
    expect(find.text('WHERE THE TWO MEET'), findsOneWidget);
  });

  testWidgets('a free user sees the locked insights and can open the paywall',
      (tester) async {
    _usePhoneViewport(tester);
    final harness = await _harness(birth: _sampleBirth);
    await tester.pumpWidget(harness.app);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Chart'));
    await tester.pumpAndSettle();

    final locked = find.textContaining('more readings of your chart');
    await _reveal(tester, locked);
    await tester.tap(locked);
    await tester.pumpAndSettle();

    expect(find.text('OMNI PLUS'), findsOneWidget);
    // Renewal terms and a restore button are both required by review, and both
    // live in the pinned footer rather than the scrolling body.
    expect(find.textContaining('Renews automatically'), findsOneWidget);
    expect(find.text('Restore'), findsOneWidget);

    await _reveal(tester, find.text('Annual'));
    expect(find.text('Annual'), findsOneWidget);
  });

  testWidgets('buying unlocks the rest of the chart', (tester) async {
    _usePhoneViewport(tester);
    final harness = await _harness(birth: _sampleBirth);
    await tester.pumpWidget(harness.app);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Chart'));
    await tester.pumpAndSettle();

    final locked = find.textContaining('more readings of your chart');
    await _reveal(tester, locked);
    await tester.tap(locked);
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ElevatedButton, 'Start 7 days free'));
    await tester.pumpAndSettle();

    expect(harness.entitlements.isSubscribed, isTrue);
    expect(find.textContaining('more readings of your chart'), findsNothing);
  });

  testWidgets('the oracle draws both a spread and a hexagram', (tester) async {
    _usePhoneViewport(tester);
    final harness = await _harness(birth: _sampleBirth);
    await tester.pumpWidget(harness.app);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Oracle'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Should I take the job?');
    await tester.tap(find.text('Draw'));
    await tester.pumpAndSettle();

    expect(find.text('Ask again'), findsOneWidget);
    await _reveal(tester, find.textContaining('TAROT'));
    expect(find.textContaining('TAROT'), findsOneWidget);
    await _reveal(tester, find.text('I CHING · THREE COINS'));
    expect(find.text('I CHING · THREE COINS'), findsOneWidget);
  });

  testWidgets('the free oracle allowance runs out into the paywall',
      (tester) async {
    _usePhoneViewport(tester);
    final harness = await _harness(birth: _sampleBirth);
    for (var i = 0; i < freeDailyAllowance[PremiumFeature.oracle]!; i++) {
      await harness.entitlements.recordUse(PremiumFeature.oracle);
    }

    await tester.pumpWidget(harness.app);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Oracle'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Draw'));
    await tester.pumpAndSettle();

    expect(find.text('OMNI PLUS'), findsOneWidget);
    expect(find.text('Unlock unlimited oracle draws'), findsOneWidget);
    // Extra draws are deliberately not sold for coins: cheap one-off draws
    // would undercut the subscription for exactly the users who use the app
    // most. Coins buy long-form reports only.
    expect(find.textContaining('Jade Coins'), findsNothing);
  });

  testWidgets('the match tab is empty until someone is added', (tester) async {
    _usePhoneViewport(tester);
    final harness = await _harness(birth: _sampleBirth);
    await tester.pumpWidget(harness.app);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Match'));
    await tester.pumpAndSettle();

    expect(find.text('Two charts, two people'), findsOneWidget);
  });

  testWidgets('a saved person shows a score from both traditions',
      (tester) async {
    _usePhoneViewport(tester);
    final harness = await _harness(birth: _sampleBirth);
    await harness.profile.addPerson(SavedPerson(
      id: 'p1',
      name: 'Wen',
      birth: BirthData(
        localDateTime: DateTime(1991, 3, 3, 6),
        utcOffsetHours: 8,
        latitudeNorth: 31.2304,
        longitudeEast: 121.4737,
        placeName: 'Shanghai, China',
      ),
    ));

    await tester.pumpWidget(harness.app);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Match'));
    await tester.pumpAndSettle();

    expect(find.text('Wen'), findsOneWidget);
    await tester.tap(find.text('Wen'));
    await tester.pumpAndSettle();

    expect(find.text('東 Chinese'), findsOneWidget);
    expect(find.text('西 Western'), findsOneWidget);
    expect(find.text('GREEN FLAG'), findsOneWidget);
  });

  testWidgets('the account tab states the plan and the disclaimer',
      (tester) async {
    _usePhoneViewport(tester);
    final harness = await _harness(birth: _sampleBirth);
    await tester.pumpWidget(harness.app);
    await tester.pumpAndSettle();

    await tester.tap(find.text('You'));
    await tester.pumpAndSettle();

    expect(find.text('Free plan'), findsOneWidget);
    expect(find.textContaining('0 Jade Coins'), findsOneWidget);
    await _reveal(tester, find.textContaining('not medical, legal'));
    expect(find.textContaining('not medical, legal'), findsOneWidget);
  });

  testWidgets('the birth form previews a chart before it is saved',
      (tester) async {
    _usePhoneViewport(tester);
    final harness = await _harness();
    await tester.pumpWidget(harness.app);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Start'));
    await tester.pumpAndSettle();

    expect(find.text('Your birth moment'), findsOneWidget);
    // No city yet, so no preview and no way forward.
    expect(find.text('PREVIEW'), findsNothing);

    await tester.tap(find.text('Choose a city'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('New York').first);
    await tester.pumpAndSettle();

    await _reveal(tester, find.text('PREVIEW'));
    expect(find.text('PREVIEW'), findsOneWidget);

    await tester.tap(find.text('Read my chart'));
    await tester.pumpAndSettle();

    expect(harness.profile.hasProfile, isTrue);
    expect(find.byType(BottomNavigationBar), findsOneWidget);
  });

  testWidgets('paywall opened directly offers all three plans', (tester) async {
    _usePhoneViewport(tester);
    final harness = await _harness(birth: _sampleBirth);
    await tester.pumpWidget(harness.app);
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(BottomNavigationBar));
    PaywallScreen.show(context);
    await tester.pumpAndSettle();

    await _reveal(tester, find.text('Monthly'));
    expect(find.text('Monthly'), findsOneWidget);
    expect(find.text('Annual'), findsOneWidget);
    await _reveal(tester, find.text('Lifetime'));
    expect(find.text('Lifetime'), findsOneWidget);
    expect(find.text('Save 58%'), findsOneWidget);
  });
}
