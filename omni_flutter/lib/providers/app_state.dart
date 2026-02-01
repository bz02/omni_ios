import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../services/memory_service.dart';

class AppState extends ChangeNotifier {
  UserProfile? _currentUser;
  bool _isOnboarding = true;
  final MemoryService _memoryService = MemoryService();

  UserProfile? get currentUser => _currentUser;
  bool get isOnboarding => _isOnboarding;

  AppState() {
    _loadUserData();
  }

  // Load user data from memory on app start
  Future<void> _loadUserData() async {
    final profile = await _memoryService.getUserProfile();
    if (profile != null) {
      _isOnboarding = false;
      _currentUser = UserProfile(
        dateOfBirth: DateTime.parse(profile['birthday']),
        petName: profile['petName'],
        petType: profile['petType'],
        petImage: null,
        energyDNA: EnergyDNA(
          type: profile['energyDNA'] ?? 'Unknown',
          description: profile['energyDescription'] ?? '',
          colorHex: int.tryParse(profile['colorHex'] ?? '0xFF4A4E69') ?? 0xFF4A4E69,
        ),
        soulID: SoulID(
          id: profile['soulID'] ?? 'OMNI-0000',
          archetype: profile['archetype'] ?? 'Unknown',
          quote: profile['quote'] ?? '',
        ),
      );
      notifyListeners();
    }
  }

  void completeOnboarding({
    required DateTime dateOfBirth,
    required String petName,
    required String petType,
    Uint8List? petImage,
  }) async {
    final dna = _generateMockDNA(dateOfBirth);
    final soul = _generateMockSoulID(petType);

    _currentUser = UserProfile(
      dateOfBirth: dateOfBirth,
      petName: petName,
      petType: petType,
      petImage: petImage,
      energyDNA: dna,
      soulID: soul,
    );

    _isOnboarding = false;

    // Save to memory
    await _memoryService.saveUserProfile({
      'birthday': dateOfBirth.toIso8601String(),
      'petName': petName,
      'petType': petType,
      'energyDNA': dna.type,
      'energyDescription': dna.description,
      'colorHex': dna.colorHex.toString(),
      'soulID': soul.id,
      'archetype': soul.archetype,
      'quote': soul.quote,
    });

    notifyListeners();
  }

  EnergyDNA _generateMockDNA(DateTime dob) {
    final day = dob.day;

    if (day % 2 == 0) {
      return EnergyDNA(
        type: 'Void Walker',
        description: 'You thrive in chaos and silence.',
        colorHex: 0xFF4A4E69,
      );
    } else {
      return EnergyDNA(
        type: 'Solar Flare',
        description: 'You burn bright and exhaust quickly.',
        colorHex: 0xFFFFB84C,
      );
    }
  }

  SoulID _generateMockSoulID(String petType) {
    final random = Random();
    final suffix = 1000 + random.nextInt(9000);
    final archetype = petType.toLowerCase() == 'cat'
        ? 'Master Manipulator'
        : 'Loyal Goofball';

    return SoulID(
      id: 'OMNI-$suffix',
      archetype: archetype,
      quote: 'Judge me all you want, I know where you sleep.',
    );
  }
}
