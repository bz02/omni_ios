/// Holds the user's birth record and the charts derived from it.
///
/// The blueprint is computed once and cached: it is pure arithmetic over an
/// immutable birth moment, so recomputing it on every rebuild would burn
/// battery for no reason.
library;

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/engine/compatibility.dart';
import '../core/engine/daily_fortune.dart';
import '../core/engine/soul_blueprint.dart';

class SavedPerson {
  const SavedPerson({required this.id, required this.name, required this.birth});

  final String id;
  final String name;
  final BirthData birth;

  Map<String, dynamic> toJson() =>
      {'id': id, 'name': name, 'birth': birth.toJson()};

  factory SavedPerson.fromJson(Map<String, dynamic> json) => SavedPerson(
        id: json['id'] as String,
        name: json['name'] as String,
        birth: BirthData.fromJson(json['birth'] as Map<String, dynamic>),
      );
}

class ProfileController extends ChangeNotifier {
  ProfileController({SharedPreferences? preferences}) : _prefs = preferences;

  static const _birthKey = 'omni.birth';
  static const _peopleKey = 'omni.people';

  SharedPreferences? _prefs;

  BirthData? _birth;
  SoulBlueprint? _blueprint;
  DailyFortune? _todayCache;
  DateTime? _todayCacheDate;
  List<SavedPerson> _people = [];

  BirthData? get birth => _birth;
  SoulBlueprint? get blueprint => _blueprint;
  bool get hasProfile => _blueprint != null;

  /// Other people the user has saved for compatibility checks. Each one is a
  /// reason to come back, and each one started as an invitation.
  List<SavedPerson> get people => List.unmodifiable(_people);

  Future<void> load() async {
    _prefs ??= await SharedPreferences.getInstance();

    final raw = _prefs!.getString(_birthKey);
    if (raw != null) {
      try {
        _birth = BirthData.fromJson(jsonDecode(raw) as Map<String, dynamic>);
        _blueprint = computeSoulBlueprint(_birth!);
      } on FormatException {
        _birth = null;
      }
    }

    final peopleRaw = _prefs!.getString(_peopleKey);
    if (peopleRaw != null) {
      try {
        _people = [
          for (final entry in jsonDecode(peopleRaw) as List)
            SavedPerson.fromJson(entry as Map<String, dynamic>),
        ];
      } on FormatException {
        _people = [];
      }
    }

    notifyListeners();
  }

  Future<void> setBirth(BirthData birth) async {
    _birth = birth;
    _blueprint = computeSoulBlueprint(birth);
    _todayCache = null;
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setString(_birthKey, jsonEncode(birth.toJson()));
    notifyListeners();
  }

  /// Today's fortune, computed once per calendar day.
  DailyFortune? get today {
    final blueprint = _blueprint;
    if (blueprint == null) return null;

    final now = DateTime.now();
    final date = DateTime(now.year, now.month, now.day);
    if (_todayCache != null && _todayCacheDate == date) return _todayCache;

    _todayCache = computeDailyFortune(
      blueprint: blueprint,
      date: date,
      utcOffsetHours: now.timeZoneOffset.inMinutes / 60.0,
    );
    _todayCacheDate = date;
    return _todayCache;
  }

  DailyFortune? fortuneOn(DateTime date) {
    final blueprint = _blueprint;
    if (blueprint == null) return null;
    return computeDailyFortune(
      blueprint: blueprint,
      date: date,
      utcOffsetHours: DateTime.now().timeZoneOffset.inMinutes / 60.0,
    );
  }

  CompatibilityResult? matchWith(SavedPerson person) {
    final mine = _blueprint;
    if (mine == null) return null;
    return computeCompatibility(mine, computeSoulBlueprint(person.birth));
  }

  Future<void> addPerson(SavedPerson person) async {
    _people = [..._people.where((p) => p.id != person.id), person];
    await _persistPeople();
    notifyListeners();
  }

  Future<void> removePerson(String id) async {
    _people = _people.where((p) => p.id != id).toList();
    await _persistPeople();
    notifyListeners();
  }

  Future<void> clear() async {
    _birth = null;
    _blueprint = null;
    _todayCache = null;
    _people = [];
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.remove(_birthKey);
    await _prefs!.remove(_peopleKey);
    notifyListeners();
  }

  Future<void> _persistPeople() async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setString(
        _peopleKey, jsonEncode([for (final p in _people) p.toJson()]));
  }
}
