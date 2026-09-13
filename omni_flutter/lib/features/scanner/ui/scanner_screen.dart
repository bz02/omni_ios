import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/modern_theme.dart';
import '../providers/scanner_provider.dart';
import '../widgets/bagua_painter.dart';
import 'result_card.dart';

class ScannerScreen extends ConsumerStatefulWidget {
  const ScannerScreen({super.key});

  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<ScannerScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  Future<void> _captureImage() async {
    HapticFeedback.heavyImpact();

    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        await ref.read(scannerControllerProvider.notifier).analyzePet(bytes);
        
        final result = ref.read(scannerControllerProvider);
        if (result != null && mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ResultCard(analysis: result),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: ModernTheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Camera feel
      body: Stack(
        children: [
          // Basic container for now, assuming camera preview would go here
          Container(
            color: Colors.black,
          ),

          // Scanning Reticle (White/Modern)
          Center(
            child: AnimatedBuilder(
              animation: _rotationController,
              builder: (context, child) {
                return Opacity(
                  opacity: 0.5,
                  child: CustomPaint(
                    size: Size(
                      MediaQuery.of(context).size.width,
                      MediaQuery.of(context).size.height,
                    ),
                    painter: BaguaPainter(
                      rotation: _rotationController.value * 2 * 3.14159,
                      color: Colors.white, // Modern clean white
                    ),
                  ),
                );
              },
            ),
          ),

          // Header
          Positioned(
            top: MediaQuery.of(context).padding.top + 20,
            left: 0,
            right: 0,
            child: Text(
              'SCANNER',
              textAlign: TextAlign.center,
              style: ModernTheme.header.copyWith(
                color: Colors.white,
                letterSpacing: 2,
              ),
            ),
          ),

          // Scan Button
          Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: _captureImage,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    color: Colors.black, // Modern contrast
                    size: 32,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
