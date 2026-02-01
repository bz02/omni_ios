import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/chat_models.dart';
import '../widgets/energy_score_card.dart';
import '../services/gemini_service.dart';
import '../config/app_config.dart';
import '../providers/app_state.dart';

class DailyVibeScreen extends StatefulWidget {
  const DailyVibeScreen({super.key});

  @override
  State<DailyVibeScreen> createState() => _DailyVibeScreenState();
}

class _DailyVibeScreenState extends State<DailyVibeScreen> {
  late Future<DailyVibe> _dailyVibeFuture;

  @override
  void initState() {
    super.initState();
    _dailyVibeFuture = _generateDailyVibe();
  }

  Future<DailyVibe> _generateDailyVibe() async {
    final appState = context.read<AppState>();
    final energyDNA = appState.currentUser?.energyDNA?.type ?? 'Mystic Purple';
    
    final geminiService = GeminiService(apiKey: AppConfig.geminiApiKey);
    
    try {
      final result = await geminiService.generateDailyVibe(
        energyDNA: energyDNA,
        date: DateTime.now(),
      );
      
      return DailyVibe(
        energyScore: result['energyScore'] as int,
        ootd: result['ootd'] as Outfit,
        advice: result['advice'] as String,
      );
    } catch (e) {
      // Fallback to default vibe
      return DailyVibe(
        energyScore: 75,
        ootd: Outfit(color: 'Purple', style: 'Mystical Vibes', emoji: '🔮'),
        advice: 'Today is your day to shine! ✨',
      );
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning ☀️';
    if (hour < 18) return 'Good Afternoon 🌤️';
    return 'Good Evening 🌙';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Vibe'),
        centerTitle: true,
      ),
      body: FutureBuilder<DailyVibe>(
        future: _dailyVibeFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (!snapshot.hasData) {
            return const Center(child: Text('Failed to load daily vibe'));
          }
          
          final dailyVibe = snapshot.data!;
          
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF4A4E69).withOpacity(0.1),
                  Colors.white,
                ],
              ),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  Text(
                    _getGreeting(),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('EEEE, MMMM d, yyyy').format(DateTime.now()),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 24),
                  EnergyScoreCard(score: dailyVibe.energyScore),
                  const SizedBox(height: 16),
                  _buildOOTDCard(dailyVibe.ootd),
                  const SizedBox(height: 16),
                  _buildAdviceCard(dailyVibe.advice),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildOOTDCard(Outfit ootd) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _getColorFromName(ootd.color).withOpacity(0.2),
            Colors.white,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                '👗 OOTD (Outfit of the Day)',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                ootd.emoji,
                style: const TextStyle(fontSize: 24),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _getColorFromName(ootd.color),
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ootd.color,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    ootd.style,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAdviceCard(String advice) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.indigo.withOpacity(0.2),
            Colors.pink.withOpacity(0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '💬 Today\'s Wisdom',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '"$advice"',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              fontStyle: FontStyle.italic,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Color _getColorFromName(String name) {
    switch (name.toLowerCase()) {
      case 'purple':
        return Colors.purple;
      case 'gold':
        return Colors.amber.shade700;
      case 'black':
        return Colors.black;
      case 'white':
        return Colors.grey.shade200;
      case 'red':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }
}
