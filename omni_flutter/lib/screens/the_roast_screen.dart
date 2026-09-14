import 'package:flutter/material.dart';

class TheRoastScreen extends StatefulWidget {
  const TheRoastScreen({super.key});

  @override
  State<TheRoastScreen> createState() => _TheRoastScreenState();
}

class _TheRoastScreenState extends State<TheRoastScreen> {
  String _selectedZodiac = 'Aries';

  final List<String> _zodiacSigns = [
    'Aries',
    'Taurus',
    'Gemini',
    'Cancer',
    'Leo',
    'Virgo',
    'Libra',
    'Scorpio',
    'Sagittarius',
    'Capricorn',
    'Aquarius',
    'Pisces'
  ];

  void _getRoast() {
    final roast = _generateRoast(_selectedZodiac);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RoastResultScreen(roast: roast),
      ),
    );
  }

  RoastResult _generateRoast(String zodiac) {
    final roasts = {
      'Aries': RoastResult(
        title: 'Too Hot to Handle (Literally)',
        reason:
            'You\'re so intense, people need a fire extinguisher just to date you. Your energy is intimidating, and not in a sexy way.',
        advice: 'Chill. Like, genuinely. Try yoga or something.',
        emoji: '🔥',
      ),
      'Taurus': RoastResult(
        title: 'Stubbornness Level: Expert',
        reason:
            'You refuse to compromise on anything. Your standards are so high, even you can\'t reach them.',
        advice: 'Maybe lower the bar just a little? Like 1%?',
        emoji: '🐂',
      ),
      'Gemini': RoastResult(
        title: 'Double Personality Disorder',
        reason:
            'Nobody knows which version of you will show up on a date. It\'s exhausting.',
        advice: 'Pick a personality and stick with it for at least 24 hours.',
        emoji: '👯',
      ),
      'Cancer': RoastResult(
        title: 'Too Many Feelings',
        reason:
            'You cry at Netflix commercials. Potential partners are scared they\'ll break you.',
        advice: 'Build some emotional walls. Not too many, but like... a fence.',
        emoji: '🦀',
      ),
      'Leo': RoastResult(
        title: 'Main Character Syndrome',
        reason:
            'You need constant validation and the spotlight. Relationships require... other people existing too.',
        advice: 'Learn to share the stage. Or at least pretend to care about their day.',
        emoji: '🦁',
      ),
      'Virgo': RoastResult(
        title: 'Perfectionist Nightmare',
        reason:
            'You\'ll critique their grammar on dating apps. Nothing is ever good enough for you.',
        advice: 'Accept that humans are flawed. Even you (gasp!).',
        emoji: '✨',
      ),
    };

    return roasts[zodiac] ??
        RoastResult(
          title: 'Cosmic Chaos Energy',
          reason:
              'The stars literally have no idea what you\'re doing. That\'s how single you are.',
          advice: 'Maybe ask the universe for help? Or therapy.',
          emoji: '⭐️',
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('The Roast 🔥'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text(
              'Based on your cosmic energy, let\'s find out why you\'re still single',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select Your Zodiac Sign',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 200,
                    child: ListWheelScrollView(
                      itemExtent: 50,
                      physics: const FixedExtentScrollPhysics(),
                      onSelectedItemChanged: (index) {
                        setState(() {
                          _selectedZodiac = _zodiacSigns[index];
                        });
                      },
                      children: _zodiacSigns.map((sign) {
                        return Center(
                          child: Text(
                            sign,
                            style: TextStyle(
                              fontSize: sign == _selectedZodiac ? 24 : 18,
                              fontWeight: sign == _selectedZodiac
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: sign == _selectedZodiac
                                  ? Colors.black
                                  : Colors.grey,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: _getRoast,
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                backgroundColor: Colors.deepOrange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Roast Me 🔥',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class RoastResult {
  final String title;
  final String reason;
  final String advice;
  final String emoji;

  RoastResult({
    required this.title,
    required this.reason,
    required this.advice,
    required this.emoji,
  });
}

class RoastResultScreen extends StatelessWidget {
  final RoastResult roast;

  const RoastResultScreen({super.key, required this.roast});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Roast'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              roast.emoji,
              style: const TextStyle(fontSize: 100),
            ),
            const SizedBox(height: 24),
            const Text(
              'Why You\'re Single:',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              roast.title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: Colors.deepOrange,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'The Reason:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    roast.reason,
                    style: const TextStyle(fontSize: 15),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'The Advice:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    roast.advice,
                    style: const TextStyle(fontSize: 15),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Share feature coming soon!')),
                );
              },
              icon: const Icon(Icons.share),
              label: const Text('Share This Roast'),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                backgroundColor: Colors.deepOrange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
