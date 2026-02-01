import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/app_state.dart';
import '../models/user_profile.dart'; // Added mock model import
import '../core/theme/modern_theme.dart';
import '../features/audio/ui/spirit_orb_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final user = appState.currentUser;

    // Use mock data if user is null
    final displayUser = user ?? UserProfile(
      dateOfBirth: DateTime(2000, 1, 1),
      petName: 'Mystic Seeker',
      petType: 'Spirit',
      energyDNA: EnergyDNA(
        type: 'Cosmic Stardust',
        description: 'You are made of star stuff, connected to the infinite.',
        colorHex: 0xFF9B7EBD,
      ),
      soulID: SoulID(
        id: 'OMNI-777',
        archetype: 'The Dreamer',
        quote: 'The universe is not outside of you. Look inside yourself; everything that you want, you already are.',
      ),
    );

    return Scaffold(
      backgroundColor: ModernTheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Profile',
                    style: ModernTheme.header,
                  ),
                  IconButton(
                    icon: Icon(Icons.edit_outlined, color: ModernTheme.textMain),
                    onPressed: () => _showEditProfileDialog(context, appState),
                  ),
                ],
              ).animate().fadeIn().slideY(begin: -0.2, end: 0),

              const SizedBox(height: 32),

              // Hero Card (Avatar + Identity)
              Container(
                padding: const EdgeInsets.all(32),
                decoration: ModernTheme.cardDecoration.copyWith(
                  gradient: LinearGradient(
                    colors: [ModernTheme.primary, Color(0xFF818CF8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  // Override border/shadow for hero
                  boxShadow: [
                    BoxShadow(
                      color: ModernTheme.primary.withOpacity(0.3),
                      blurRadius: 30,
                      offset: const Offset(0, 15),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 20,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          displayUser.petName.isNotEmpty ? displayUser.petName.substring(0, 1).toUpperCase() : '✨',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            color: ModernTheme.primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      displayUser.petName,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      displayUser.energyDNA?.type ?? 'Unknown Energy',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        displayUser.soulID?.id ?? 'OMNI-0000',
                        style: GoogleFonts.robotoMono(
                          fontSize: 12,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0),

              const SizedBox(height: 32),

              Text(
                'Tools',
                style: ModernTheme.subHeader,
              ).animate().fadeIn(delay: 400.ms),

              const SizedBox(height: 16),

              // Modern Tool Grid
              Row(
                children: [
                  Expanded(
                    child: _buildToolCard(
                      title: 'Spirit Orb',
                      icon: Icons.graphic_eq,
                      color: ModernTheme.secondary,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const SpiritOrbScreen()),
                        );
                      },
                      delay: 500,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildToolCard(
                      title: 'Settings',
                      icon: Icons.settings_outlined,
                      color: ModernTheme.textSub,
                      onTap: () {}, // TODO
                      delay: 600,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Stats Row
              Container(
                padding: const EdgeInsets.all(24),
                decoration: ModernTheme.cardDecoration,
                child: Row(
                  children: [
                    Expanded(
                      child: _buildStatItem(
                        'Energy',
                        displayUser.energyDNA?.type?.split(' ').first ?? 'None',
                        Icons.bolt,
                        Color(0xFFFFB84C),
                      ),
                    ),
                    Container(width: 1, height: 40, color: ModernTheme.border),
                    Expanded(
                      child: _buildStatItem(
                        'Streak',
                        '1 Day',
                        Icons.local_fire_department,
                        Color(0xFFEF4444),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 700.ms),

              const SizedBox(height: 32),

              // Description Quote
              Container(
                padding: const EdgeInsets.all(24),
                decoration: ModernTheme.cardDecoration,
                child: Column(
                  children: [
                    Icon(Icons.format_quote, color: ModernTheme.primary.withOpacity(0.5), size: 30),
                    const SizedBox(height: 8),
                    Text(
                      displayUser.soulID?.quote ?? 'Your journey is just beginning.',
                      style: ModernTheme.body.copyWith(
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 800.ms),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditProfileDialog(BuildContext context, AppState appState) {
    final nameController = TextEditingController(text: appState.currentUser?.petName ?? '');
    // Simple edit dialog to update name
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text('Edit Profile', style: ModernTheme.subHeader),
        content: TextField(
          controller: nameController,
          decoration: InputDecoration(
            hintText: 'Enter your name',
            filled: true,
            fillColor: ModernTheme.background,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: ModernTheme.textSub)),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                 appState.completeOnboarding(
                   dateOfBirth: appState.currentUser?.dateOfBirth ?? DateTime(2000, 1, 1), 
                   petName: nameController.text, 
                   petType: 'Spirit'
                 );
                 Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildToolCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required int delay,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: ModernTheme.cardDecoration,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: ModernTheme.body.copyWith(
                fontWeight: FontWeight.w600,
                color: ModernTheme.textMain,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: delay.ms).scale();
  }

  Widget _buildStatItem(String title, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: ModernTheme.subHeader.copyWith(fontSize: 16),
        ),
        Text(
          title,
          style: ModernTheme.caption,
        ),
      ],
    );
  }
}
