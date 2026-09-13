import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show ProviderScope;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'config/app_config.dart';
import 'core/billing/entitlements.dart';
import 'core/billing/purchase_service.dart';
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

  final entitlements = EntitlementsController(preferences: preferences);
  final profile = ProfileController(preferences: preferences);
  await Future.wait([entitlements.load(), profile.load()]);

  // Without a store account configured, a debug build falls back to a
  // sandbox that grants purchases locally so the paywall and every gate
  // behind it can be exercised. Release builds always talk to the real store.
  final purchases = chooseService(
    entitlements: entitlements,
    useSandbox: !AppConfig.usesBackendProxy,
  );
  unawaitedInitialise(purchases);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: entitlements),
        ChangeNotifierProvider.value(value: profile),
        ChangeNotifierProvider<PurchaseService>.value(value: purchases),
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
