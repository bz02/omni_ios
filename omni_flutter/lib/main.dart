import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show ProviderScope;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'config/app_config.dart';
import 'core/analytics/analytics.dart';
import 'core/billing/entitlements.dart';
import 'core/billing/install_identity.dart';
import 'core/billing/purchase_service.dart';
import 'core/billing/stripe_checkout_service.dart';
import 'core/net/omni_api.dart';
import 'core/theme/modern_theme.dart';
import 'features/account/account_screen.dart';
import 'features/blueprint/blueprint_screen.dart';
import 'features/match/match_screen.dart';
import 'features/oracle/oracle_screen.dart';
import 'features/today/today_screen.dart';
import 'providers/app_state.dart';
import 'services/gemini_service.dart';
import 'services/user_service.dart';
import 'state/profile_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final preferences = await SharedPreferences.getInstance();

  final identity = InstallIdentity(preferences: preferences);
  await identity.load();

  final entitlements = EntitlementsController(preferences: preferences);
  final profile = ProfileController(preferences: preferences);
  await Future.wait([entitlements.load(), profile.load()]);

  final api = OmniApi();
  final analytics = createAnalytics(
    projectKey: AppConfig.analyticsKey,
    distinctId: identity.installId,
  );

  final purchases = chooseService(
    entitlements: entitlements,
    identity: identity,
    api: api,
    webReturnUrl: AppConfig.webReturnUrl,
  );
  unawaitedInitialise(purchases);

  // Stripe sends the browser back with the session id on the query string.
  // That id is the receipt, so this is where a web purchase actually lands.
  final returningSession = Uri.base.queryParameters['session_id'];
  if (purchases is StripeCheckoutService &&
      returningSession != null &&
      returningSession.isNotEmpty) {
    unawaited(_completeWebCheckout(purchases, analytics, returningSession));
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: entitlements),
        ChangeNotifierProvider.value(value: profile),
        ChangeNotifierProvider<PurchaseService>.value(value: purchases),
        Provider<Analytics>.value(value: analytics),
        Provider<InstallIdentity>.value(value: identity),
        Provider<OmniApi>.value(value: api),
        // The pet-era features still run on these. They are reachable from the
        // Oracle tab rather than the tab bar, so they keep working without
        // taking up room the two charts need.
        ChangeNotifierProvider(create: (_) => AppState()),
        ChangeNotifierProvider(create: (_) => UserService()),
        ChangeNotifierProvider(
            create: (_) => GeminiService(apiKey: AppConfig.geminiApiKey)),
      ],
      // The scanner and the spirit orb are built on Riverpod.
      child: const ProviderScope(child: OmniApp()),
    ),
  );
}

Future<void> _completeWebCheckout(
  StripeCheckoutService purchases,
  Analytics analytics,
  String sessionId,
) async {
  final result = await purchases.completePendingCheckout(sessionId);
  if (result.outcome == PurchaseOutcome.purchased) {
    analytics.track('purchase_completed_web', {'session': 'returned'});
  } else if (result.outcome == PurchaseOutcome.failed) {
    analytics.track('purchase_failed_web', {'reason': result.message ?? ''});
  }
}

/// Product queries can be slow and must never hold up first paint.
void unawaitedInitialise(PurchaseService service) {
  service.initialise();
}

class OmniApp extends StatelessWidget {
  const OmniApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Omni',
        theme: ModernTheme.themeData,
        debugShowCheckedModeBanner: false,
        home: const RootShell(),
      );
}

class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _index = 0;

  static const _tabs = <({Widget screen, IconData icon, IconData active, String label})>[
    (screen: TodayScreen(), icon: Icons.wb_twilight, active: Icons.wb_twilight, label: 'Today'),
    (screen: BlueprintScreen(), icon: Icons.donut_large_outlined, active: Icons.donut_large, label: 'Chart'),
    (screen: OracleScreen(), icon: Icons.style_outlined, active: Icons.style, label: 'Oracle'),
    (screen: MatchScreen(), icon: Icons.favorite_outline, active: Icons.favorite, label: 'Match'),
    (screen: AccountScreen(), icon: Icons.person_outline, active: Icons.person, label: 'You'),
  ];

  @override
  Widget build(BuildContext context) {
    // Until there is a birth record there is nothing to show on any tab but
    // the first, so the shell collapses to the onboarding prompt.
    final hasProfile = context.watch<ProfileController>().hasProfile;
    if (!hasProfile) return const TodayScreen();

    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [for (final tab in _tabs) tab.screen],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: ModernTheme.border)),
        ),
        child: BottomNavigationBar(
          currentIndex: _index,
          onTap: (index) => setState(() => _index = index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: ModernTheme.primary,
          unselectedItemColor: ModernTheme.textSub,
          selectedLabelStyle:
              const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          unselectedLabelStyle:
              const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
          elevation: 0,
          items: [
            for (final tab in _tabs)
              BottomNavigationBarItem(
                icon: Icon(tab.icon),
                activeIcon: Icon(tab.active),
                label: tab.label,
              ),
          ],
        ),
      ),
    );
  }
}
