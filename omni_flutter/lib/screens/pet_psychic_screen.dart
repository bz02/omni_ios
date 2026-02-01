import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import '../services/gemini_service.dart';
import '../config/app_config.dart';

class PetPsychicScreen extends StatefulWidget {
  const PetPsychicScreen({super.key});

  @override
  State<PetPsychicScreen> createState() => _PetPsychicScreenState();
}

class _PetPsychicScreenState extends State<PetPsychicScreen> {
  XFile? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImage = image;
      });
    }
  }

  void _getReading() async {
    if (_selectedImage == null) return;

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      // Read image bytes (works on both web and mobile)
      final bytes = await _selectedImage!.readAsBytes();
      
      // Call Gemini Vision API
      final geminiService = GeminiService(apiKey: AppConfig.geminiApiKey);
      final reading = await geminiService.analyzePetPhoto(bytes);
      
      // Close loading dialog
      if (mounted) Navigator.of(context).pop();
      
      // Navigate to result
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PetReadingResultScreen(
              reading: PetReading(
                mood: reading['mood']!,
                personality: reading['personality']!,
                roast: reading['roast']!,
                emoji: reading['emoji']!,
              ),
            ),
          ),
        );
      }
    } catch (e) {
      // Close loading dialog and show error
      if (mounted) Navigator.of(context).pop();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to connect to the cosmic realm. Error: ${e.toString()}'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pet Psychic 🔮'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text(
              'Upload your pet\'s photo and discover their inner thoughts',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.grey.shade200,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: _selectedImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: kIsWeb 
                            ? Image.network(
                                _selectedImage!.path,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Center(
                                    child: Icon(Icons.pets, size: 48),
                                  );
                                },
                              )
                            : FutureBuilder<Uint8List>(
                                future: _selectedImage!.readAsBytes(),
                                builder: (context, snapshot) {
                                  if (snapshot.hasData) {
                                    return Image.memory(
                                      snapshot.data!,
                                      fit: BoxFit.cover,
                                    );
                                  }
                                  return const Center(
                                    child: CircularProgressIndicator(),
                                  );
                                },
                              ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.camera_alt,
                            size: 48,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Tap to select photo',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: _pickImage,
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Choose Photo',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            if (_selectedImage != null) ...[
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _getReading,
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Get Reading 🔮',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class PetReading {
  final String mood;
  final String personality;
  final String roast;
  final String emoji;

  PetReading({
    required this.mood,
    required this.personality,
    required this.roast,
    required this.emoji,
  });
}

class PetReadingResultScreen extends StatelessWidget {
  final PetReading reading;

  const PetReadingResultScreen({super.key, required this.reading});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pet Reading'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              reading.emoji,
              style: const TextStyle(fontSize: 100),
            ),
            const SizedBox(height: 24),
            const Text(
              'Current Mood',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              reading.mood,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 24),
            const Text(
              'Personality Type',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              reading.personality,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 24),
            const Text(
              'The Truth',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '"${reading.roast}"',
                style: const TextStyle(
                  fontSize: 18,
                  fontStyle: FontStyle.italic,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                // Share functionality placeholder
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Share feature coming soon!')),
                );
              },
              icon: const Icon(Icons.share),
              label: const Text('Share This Roast'),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                backgroundColor: Colors.purple,
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
