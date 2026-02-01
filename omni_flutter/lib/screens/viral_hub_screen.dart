import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/gemini_service.dart';
import '../config/app_config.dart';
import '../providers/app_state.dart';

class ViralHubScreen extends StatefulWidget {
  const ViralHubScreen({super.key});

  @override
  State<ViralHubScreen> createState() => _ViralHubScreenState();
}

class _ViralHubScreenState extends State<ViralHubScreen> {
  final _textController = TextEditingController();
  List<Map<String, String>> _viralVariations = [];
  bool _isGenerating = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _generateViralContent() async {
    if (_textController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter some text first!')),
      );
      return;
    }

    setState(() {
      _isGenerating = true;
    });

    try {
      final gemini = GeminiService(apiKey: AppConfig.geminiApiKey);
      final variations = await gemini.generateViralContent(_textController.text);
      
      setState(() {
        _viralVariations = variations;
        _isGenerating = false;
      });
    } catch (e) {
      setState(() {
        _isGenerating = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to generate. Try again!')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Go Viral 🚀'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Transform any thought into viral content',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _textController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Enter any text...\n\nExamples:\n"feeling burnt out"\n"my cat judges me"',
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isGenerating ? null : _generateViralContent,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isGenerating
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Generate Viral Versions 🚀',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
            const SizedBox(height: 32),
            if (_viralVariations.isNotEmpty) ...[
              const Text(
                'Your Viral Variations:',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ..._viralVariations.map((variation) => _buildVariationCard(variation)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildVariationCard(Map<String, String> variation) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _getPlatformIcon(variation['platform'] ?? ''),
                const SizedBox(width: 8),
                Text(
                  variation['platform'] ?? '',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.copy),
                  onPressed: () {
                    // Copy to clipboard functionality
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Copied to clipboard!')),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              variation['content'] ?? '',
              style: const TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 8),
            Text(
              variation['hashtags'] ?? '',
              style: TextStyle(
                fontSize: 14,
                color: Colors.blue.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _getPlatformIcon(String platform) {
    final icons = {
      'Instagram': Icons.photo_camera,
      'TikTok': Icons.music_note,
      'Twitter': Icons.alternate_email,
    };
    return Icon(icons[platform] ?? Icons.share, color: Colors.purple);
  }
}
