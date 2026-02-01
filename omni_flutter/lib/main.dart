import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as provider_pkg;
import 'core/theme/modern_theme.dart';
import 'config/app_config.dart';

// Original screens
import 'screens/home_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/profile_screen.dart';

// Features
import 'features/scanner/ui/scanner_screen.dart';
import 'features/audio/ui/spirit_orb_screen.dart';
import 'features/fortune/ui/fortune_input_screen.dart';

// Services  
import 'services/user_service.dart';
import 'services/gemini_service.dart';
import 'providers/app_state.dart';

void main() {
  runApp(
    provider_pkg.MultiProvider(
      providers: [
        provider_pkg.ChangeNotifierProvider(create: (_) => AppState()),
        provider_pkg.ChangeNotifierProvider(create: (_) => UserService()),
        provider_pkg.ChangeNotifierProvider(create: (_) => GeminiService(apiKey: AppConfig.geminiApiKey)),
      ],
      child: const ProviderScope(
        child: OmniCyberApp(),
      ),
    ),
  );
}

class OmniCyberApp extends StatelessWidget {
  const OmniCyberApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Omni - Modern Edition',
      theme: ModernTheme.themeData,
      debugShowCheckedModeBanner: false,
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),           // 0: HOME
    FortuneInputScreen(),   // 1: DESTINY  
    ChatScreen(),           // 2: CHAT
    ScannerScreen(),        // 3: SCAN
    ProfileScreen(),        // 4: PROFILE
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: ModernTheme.border)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: ModernTheme.primary,
          unselectedItemColor: ModernTheme.textSub,
          selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.auto_awesome_outlined),
              activeIcon: Icon(Icons.auto_awesome),
              label: 'Destiny',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline),
              activeIcon: Icon(Icons.chat_bubble),
              label: 'Chat',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.camera_alt_outlined),
              activeIcon: Icon(Icons.camera_alt),
              label: 'Scan',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
