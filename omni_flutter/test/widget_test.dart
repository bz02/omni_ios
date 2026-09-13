// Smoke tests for the shell.
//
// These exist mostly to compile everything reachable from `main.dart` — a
// broken widget tree is otherwise only discovered on a device — and to hold
// the two flows that carry the money: onboarding through to a chart, and a
// blocked feature through to the paywall.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show ProviderScope;
import 'package:flutter_test/flutter_test.dart';
import 'package:omni_flutter/core/analytics/analytics.dart';
import 'package:omni_flutter/core/billing/entitlements.dart';
import 'package:omni_flutter/core/billing/products.dart';
import 'package:omni_flutter/core/billing/purchase_service.dart';
import 'package:omni_flutter/core/engine/luck_pillars.dart';
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
      RecordingAnalytics analytics,
    })> _harness({BirthData? birth}) async {
  SharedPreferences.setMockInitialValues({});
  final preferences = await SharedPreferences.getInstance();

  final entitlements = EntitlementsController(preferences: preferences);
  final profile = ProfileController(preferences: preferences);
  await entitlements.load();
  await profile.load();
  if (birth != null) await profile.setBirth(birth);

  final purchases = SandboxPurchaseService(entitlements: entitlements);
  final analytics = RecordingAnalytics();

  return (
    app: MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: entitlements),
        ChangeNotifierProvider.value(value: profile),
        ChangeNotifierProvider<PurchaseService>.value(value: purchases),
        Provider<Analytics>.value(value: analytics),
        ChangeNotifierProvider(create: (_) => AppState()),
        ChangeNotifierProvider(create: (_) => UserService()),
        ChangeNotifierProvider(create: (_) => GeminiService(apiKey: '')),
      ],
      child: const ProviderScope(child: OmniApp()),
    ),
    entitlements: entitlements,
    profile: profile,
    analytics: analytics,
  );
}

/// Captures events so tests can assert the funnel fires, without sending
/// anything anywhere.
class RecordingAnalytics extends Analytics {
  final List<({String event, Map<String, Object?> properties})> events = [];

  @override
  void track(String event, [Map<String, Object?> properties = const {}]) {
    events.add((event: event, properties: properties));
  }

  bool sawEvent(String name) => events.any((e) => e.event == name);

  Map<String, Object?>? propertiesFor(String name) =>
      events.where((e) => e.event == name).firstOrNull?.properties;
}

/// Sizes the test view like a phone. The default 800x600 is nothing like the
/// device these screens are laid out for, and off-screen widgets in a list are
/// never built, so a wrong viewport turns into confusing missing-widget errors.
void _usePhoneViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

/// Scrolls [target] into view, then settles.
///
/// [inSheet] scrolls the modal sheet's own list rather than the page behind
/// it, which is still mounted and would otherwise be scrolled instead.
Future<void> _reveal(WidgetTester tester, Finder target,
    {bool inSheet = false}) async {
  await tester.scrollUntilVisible(
    target,
    200,
    scrollable:
        inSheet ? find.byType(Scrollable).last : find.byType(Scrollable).first,
  );
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

  group('timeline', () {
    testWidgets('asks which way the cycle runs before showing it',
        (tester) async {
      _usePhoneViewport(tester);
      final harness = await _harness(birth: _sampleBirth);
      await tester.pumpWidget(harness.app);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Chart'));
      await tester.pumpAndSettle();

      final entry = find.text('Your decades 大运');
      await _reveal(tester, entry);
      await tester.tap(entry);
      await tester.pumpAndSettle();

      // Direction changes every decade of the reading, so it is asked rather
      // than guessed.
      expect(find.text('Which way does your cycle run?'), findsOneWidget);
      expect(find.text('Yang'), findsOneWidget);
      expect(find.text('Yin'), findsOneWidget);
    });

    testWidgets('shows the decades and this year once a polarity is chosen',
        (tester) async {
      _usePhoneViewport(tester);
      final harness = await _harness(birth: _sampleBirth);
      await harness.profile.setPolarity(ChartPolarity.yang);

      await tester.pumpWidget(harness.app);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Chart'));
      await tester.pumpAndSettle();

      final entry = find.text('Your decades 大运');
      await _reveal(tester, entry);
      await tester.tap(entry);
      await tester.pumpAndSettle();

      expect(find.text('THE DECADES 大运'), findsOneWidget);
      await _reveal(tester, find.text('YEAR BY YEAR 流年'));
      expect(find.text('YEAR BY YEAR 流年'), findsOneWidget);

      final cycle = harness.profile.luckCycle!;
      // Every decade is listed, with the current one marked on the header.
      expect(cycle.pillars, hasLength(9));
    });

    testWidgets('the years ahead are gated and open the paywall',
        (tester) async {
      _usePhoneViewport(tester);
      final harness = await _harness(birth: _sampleBirth);
      await harness.profile.setPolarity(ChartPolarity.yin);

      await tester.pumpWidget(harness.app);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Chart'));
      await tester.pumpAndSettle();

      final entry = find.text('Your decades 大运');
      await _reveal(tester, entry);
      await tester.tap(entry);
      await tester.pumpAndSettle();

      final locked = find.text('The next nine years');
      await _reveal(tester, locked);
      await tester.tap(locked);
      await tester.pumpAndSettle();

      expect(find.text('OMNI PLUS'), findsOneWidget);
      expect(harness.analytics.propertiesFor('paywall_shown')?['trigger'],
          'yearAhead');
      // Priced in coins as well, since it is a one-off report.
      await _reveal(tester, find.textContaining('Jade Coins'), inSheet: true);
      expect(find.textContaining('Jade Coins'), findsOneWidget);
    });

    testWidgets('a subscriber sees the years without a paywall',
        (tester) async {
      _usePhoneViewport(tester);
      final harness = await _harness(birth: _sampleBirth);
      await harness.profile.setPolarity(ChartPolarity.yang);
      await harness.entitlements.syncFromStore(
          tier: Tier.plus, expiresAt: DateTime.now().add(const Duration(days: 30)));

      await tester.pumpWidget(harness.app);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Chart'));
      await tester.pumpAndSettle();

      final entry = find.text('Your decades 大运');
      await _reveal(tester, entry);
      await tester.tap(entry);
      await tester.pumpAndSettle();

      expect(find.text('The next nine years'), findsNothing);
      final nextYear = DateTime.now().year + 1;
      await _reveal(tester, find.textContaining('$nextYear ·'));
      expect(find.textContaining('$nextYear ·'), findsOneWidget);
    });
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

  testWidgets('the funnel records the paywall trigger and the purchase',
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

    // Which feature sent them here is what decides the free tier's size.
    expect(harness.analytics.propertiesFor('paywall_shown')?['trigger'],
        'fullBlueprint');

    await tester.tap(find.widgetWithText(ElevatedButton, 'Start 7 days free'));
    await tester.pumpAndSettle();

    expect(harness.analytics.sawEvent('purchase_started'), isTrue);
    expect(harness.analytics.propertiesFor('purchase_completed')?['product_id'],
        'omni.plus.annual');
    // A conversion is not also a dismissal.
    expect(harness.analytics.sawEvent('paywall_dismissed'), isFalse);
  });

  testWidgets('running out of free draws is recorded before the paywall',
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

    expect(harness.analytics.propertiesFor('quota_exhausted')?['feature'],
        'oracle');
  });

  testWidgets('completing onboarding is recorded with what was supplied',
      (tester) async {
    _usePhoneViewport(tester);
    final harness = await _harness();
    await tester.pumpWidget(harness.app);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Start'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Choose a city'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('New York').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Read my chart'));
    await tester.pumpAndSettle();

    expect(harness.analytics.sawEvent('onboarding_started'), isTrue);
    final props = harness.analytics.propertiesFor('onboarding_completed');
    expect(props?['has_birth_place'], isTrue);
    // The form defaults to no birth time, and half the audience never has one.
    expect(props?['has_birth_time'], isFalse);
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
