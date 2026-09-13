import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class MemoryService {
  static const String _keyConversationHistory = 'conversation_history';
  static const String _keyUserProfile = 'user_profile';
  static const String _keyDailyVibes = 'daily_vibes';
  static const String _keyRoastHistory = 'roast_history';
  static const String _keyPetReadings = 'pet_readings';

  // Save conversation history
  Future<void> saveConversation(List<Map<String, dynamic>> messages) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyConversationHistory, jsonEncode(messages));
  }

  // Get conversation history
  Future<List<Map<String, dynamic>>> getConversationHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_keyConversationHistory);
    if (data == null) return [];
    return List<Map<String, dynamic>>.from(jsonDecode(data));
  }

  // Save user profile
  Future<void> saveUserProfile(Map<String, dynamic> profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserProfile, jsonEncode(profile));
  }

  // Get user profile
  Future<Map<String, dynamic>?> getUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_keyUserProfile);
    if (data == null) return null;
    return Map<String, dynamic>.from(jsonDecode(data));
  }

  // Save daily vibe
  Future<void> saveDailyVibe(String date, Map<String, dynamic> vibe) async {
    final prefs = await SharedPreferences.getInstance();
    final vibes = await _getVibeHistory();
    vibes[date] = vibe;
    await prefs.setString(_keyDailyVibes, jsonEncode(vibes));
  }

  // Get vibe history
  Future<Map<String, dynamic>> _getVibeHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_keyDailyVibes);
    if (data == null) return {};
    return Map<String, dynamic>.from(jsonDecode(data));
  }

  // Get today's vibe if exists
  Future<Map<String, dynamic>?> getTodayVibe() async {
    final today = DateTime.now().toString().split(' ')[0];
    final vibes = await _getVibeHistory();
    return vibes[today];
  }

  // Save roast
  Future<void> saveRoast(Map<String, dynamic> roast) async {
    final prefs = await SharedPreferences.getInstance();
    final roasts = await _getRoastHistory();
    roasts.add({...roast, 'timestamp': DateTime.now().toIso8601String()});
    await prefs.setString(_keyRoastHistory, jsonEncode(roasts));
  }

  // Get roast history
  Future<List<Map<String, dynamic>>> _getRoastHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_keyRoastHistory);
    if (data == null) return [];
    return List<Map<String, dynamic>>.from(jsonDecode(data));
  }

  // Save pet reading
  Future<void> savePetReading(Map<String, dynamic> reading) async {
    final prefs = await SharedPreferences.getInstance();
    final readings = await _getPetReadings();
    readings.add({...reading, 'timestamp': DateTime.now().toIso8601String()});
    await prefs.setString(_keyPetReadings, jsonEncode(readings));
  }

  // Get pet readings
  Future<List<Map<String, dynamic>>> _getPetReadings() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_keyPetReadings);
    if (data == null) return [];
    return List<Map<String, dynamic>>.from(jsonDecode(data));
  }

  // Get user context for Gemini (recent activity summary)
  Future<Map<String, dynamic>> getUserContext() async {
    final profile = await getUserProfile();
    final conversations = await getConversationHistory();
    final todayVibe = await getTodayVibe();
    
    // Get recent topics from last 5 messages
    final recentTopics = conversations
        .where((m) => m['isUser'] == true)
        .take(5)
        .map((m) => m['content'] as String)
        .join(', ');

    return {
      'energyDNA': profile?['energyDNA'] ?? 'Unknown',
      'petName': profile?['petName'] ?? 'None',
      'petType': profile?['petType'] ?? 'Unknown',
      'birthday': profile?['birthday'] ?? 'Unknown',
      'recentTopics': recentTopics,
      'todayEnergyScore': todayVibe?['energyScore'] ?? 'Not set',
      'conversationCount': conversations.length,
    };
  }

  // Clear all data
  Future<void> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
