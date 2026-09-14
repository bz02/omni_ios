/// A stable, anonymous identifier for this installation.
///
/// Checkout is anonymous — there is no sign-up, because asking for an account
/// before a user has seen a single reading is the largest drop-off a divination
/// app has. So a purchase is tied to this identifier, and the receipt the
/// server hands back afterwards is what moves it to another device.
///
/// The limitation is real and worth stating plainly: delete the app without
/// keeping the restore code and the subscription is stranded until support
/// looks it up in Stripe. Magic-link email is the fix, and it is the first
/// thing to add once there is revenue to protect.
library;

import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

class InstallIdentity {
  InstallIdentity({SharedPreferences? preferences}) : _prefs = preferences;

  static const _installKey = 'omni.installId';
  static const _restoreKey = 'omni.restoreCode';

  SharedPreferences? _prefs;
  String? _installId;
  String? _restoreCode;

  /// Never empty after [load].
  String get installId => _installId ?? '';

  /// The receipt from the last successful purchase, if there was one.
  String? get restoreCode => _restoreCode;

  Future<String> load() async {
    _prefs ??= await SharedPreferences.getInstance();
    _restoreCode = _prefs!.getString(_restoreKey);

    final existing = _prefs!.getString(_installKey);
    if (existing != null && existing.isNotEmpty) {
      return _installId = existing;
    }

    final generated = _generate();
    await _prefs!.setString(_installKey, generated);
    return _installId = generated;
  }

  Future<void> setRestoreCode(String? code) async {
    _prefs ??= await SharedPreferences.getInstance();
    _restoreCode = code;
    if (code == null || code.isEmpty) {
      await _prefs!.remove(_restoreKey);
    } else {
      await _prefs!.setString(_restoreKey, code);
    }
  }

  /// 128 bits from a cryptographic source. It is only an identifier, never a
  /// secret, but it must not be guessable: anyone who can guess one could ask
  /// the server about somebody else's subscription.
  static String _generate() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }
}
