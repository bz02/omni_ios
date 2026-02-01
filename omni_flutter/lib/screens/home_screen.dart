import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/gemini_service.dart';
import '../services/user_service.dart';
import '../core/theme/modern_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _loading = false;
  String? _dailyVibe;
  String? _todaysWisdom;
  String? _ootd;

  @override
  void initState() {
    super.initState();
    _loadDailyContent();
  }

  Future<void> _loadDailyContent() async {
    setState(() => _loading = true);
    
    // Load all daily content in parallel
    await Future.wait([
      _loadDailyVibe(),
      _loadWisdom(),
      _loadOOTD(),
    ]);
    
    setState(() => _loading = false);
  }

  Future<void> _loadDailyVibe() async {
    final gemini = context.read<GeminiService>();
    final vibe = await gemini.getDailyVibe();
    if (mounted) {
      setState(() => _dailyVibe = vibe);
    }
  }

  Future<void> _loadWisdom() async {
    final gemini = context.read<GeminiService>();
    final wisdom = await gemini.getTodaysWisdom();
    if (mounted) {
      setState(() => _todaysWisdom = wisdom);
    }
  }

  Future<void> _loadOOTD() async {
    final gemini = context.read<GeminiService>();
    final outfit = await gemini.getOutfitOfTheDay();
    if (mounted) {
      setState(() => _ootd = outfit);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ModernTheme.background,
      body: SafeArea(
        child: _loading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation(ModernTheme.primary),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Loading insights...',
                      style: ModernTheme.body.copyWith(color: ModernTheme.textSub),
                    ),
                  ],
                ),
              )
            : RefreshIndicator(
                onRefresh: _loadDailyContent,
                color: ModernTheme.primary,
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Good Morning',
                              style: ModernTheme.body,
                            ),
                            Text(
                              'Daily Insights',
                              style: ModernTheme.header,
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: ModernTheme.primary.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.notifications_none, color: ModernTheme.primary),
                        ),
                      ],
                    ).animate().fadeIn().slideY(begin: -0.2, end: 0),
                    
                    const SizedBox(height: 32),

                    // Daily Vibe
                    if (_dailyVibe != null)
                      _buildModernCard(
                        title: 'Daily Vibe',
                        content: _dailyVibe!,
                        icon: Icons.auto_awesome,
                        accentColor: ModernTheme.primary,
                        delay: 200,
                      ),

                    // Today's Wisdom
                    if (_todaysWisdom != null)
                      _buildModernCard(
                        title: 'Wisdom',
                        content: '"$_todaysWisdom"',
                        icon: Icons.lightbulb_outline,
                        accentColor: const Color(0xFFF59E0B), // Amber for wisdom
                        delay: 400,
                        isItalic: true,
                      ),

                    // OOTD
                    if (_ootd != null)
                      _buildModernCard(
                        title: 'Outfit Idea',
                        content: _ootd!,
                        icon: Icons.checkroom,
                        accentColor: ModernTheme.secondary,
                        delay: 600,
                      ),
                      
                    const SizedBox(height: 40),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildModernCard({
    required String title,
    required String content,
    required IconData icon,
    required Color accentColor,
    required int delay,
    bool isItalic = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(24),
      decoration: ModernTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: accentColor, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: ModernTheme.subHeader.copyWith(fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            content,
            style: ModernTheme.body.copyWith(
              fontStyle: isItalic ? FontStyle.italic : FontStyle.normal,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: delay.ms).slideY(begin: 0.1, end: 0);
  }
}
