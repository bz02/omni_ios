import 'package:flutter/foundation.dart';

/// Simple UserService for demo purposes
class UserService extends ChangeNotifier {
  String? _userName;
  Map<String, dynamic>? _userProfile;

  String? get userName => _userName;
  Map<String, dynamic>? get userProfile => _userProfile;

  void setUserName(String name) {
    _userName = name;
    notifyListeners();
  }

  void setUserProfile(Map<String, dynamic> profile) {
    _userProfile = profile;
    notifyListeners();
  }

  void clearUser() {
    _userName = null;
    _userProfile = null;
    notifyListeners();
  }
}
