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
import '../core/engine/luck_pillars.dart';
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
  static const _polarityKey = 'omni.polarity';

  SharedPreferences? _prefs;

  BirthData? _birth;
  SoulBlueprint? _blueprint;
  DailyFortune? _todayCache;
  DateTime? _todayCacheDate;
  List<SavedPerson> _people = [];
  ChartPolarity? _polarity;
  LuckCycle? _cycleCache;

  BirthData? get birth => _birth;
  SoulBlueprint? get blueprint => _blueprint;
  bool get hasProfile => _blueprint != null;

  /// Other people the user has saved for compatibility checks. Each one is a
  /// reason to come back, and each one started as an invitation.
  List<SavedPerson> get people => List.unmodifiable(_people);

  /// Which polarity the luck cycle is read against. Null until asked, and it
  /// is asked where it is used rather than during onboarding: one more
  /// question on the first screen costs more installs than it is worth.
  ChartPolarity? get polarity => _polarity;

  /// The ten-year luck cycle, computed once. Null until a polarity is chosen,
  /// because the direction of the cycle depends on it and guessing would give
  /// half of all users the reversed sequence.
  LuckCycle? get luckCycle {
    final blueprint = _blueprint;
    final polarity = _polarity;
    if (blueprint == null || polarity == null) return null;
    return _cycleCache ??= computeLuckCycle(
      birth: blueprint.birth,
      chart: blueprint.bazi,
      polarity: polarity,
    );
  }

  /// The cycle as it would run under the other polarity, for users who would
  /// rather see both than answer the question.
  LuckCycle? cycleFor(ChartPolarity polarity) {
    final blueprint = _blueprint;
    if (blueprint == null) return null;
    return computeLuckCycle(
      birth: blueprint.birth,
      chart: blueprint.bazi,
      polarity: polarity,
    );
  }

  AnnualForecast? forecastFor(int year) {
    final blueprint = _blueprint;
    final cycle = luckCycle;
    if (blueprint == null || cycle == null) return null;
    return computeAnnualForecast(
        blueprint: blueprint, cycle: cycle, year: year);
  }

  Future<void> setPolarity(ChartPolarity polarity) async {
    _polarity = polarity;
    _cycleCache = null;
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setString(_polarityKey, polarity.name);
    notifyListeners();
  }

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

    final storedPolarity = _prefs!.getString(_polarityKey);
    if (storedPolarity != null) {
      for (final value in ChartPolarity.values) {
        if (value.name == storedPolarity) _polarity = value;
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
    _cycleCache = null;
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
    _cycleCache = null;
    _polarity = null;
    _people = [];
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.remove(_birthKey);
    await _prefs!.remove(_peopleKey);
    await _prefs!.remove(_polarityKey);
    notifyListeners();
  }

  Future<void> _persistPeople() async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setString(
        _peopleKey, jsonEncode([for (final p in _people) p.toJson()]));
  }
}
