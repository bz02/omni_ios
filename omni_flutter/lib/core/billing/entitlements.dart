/// What a user is allowed to do, and what to offer them when they are not.
///
/// Every gate in the app goes through [EntitlementsController.check]. Keeping
/// the decision in one place is what makes it possible to move the free tier
/// around during launch without hunting for `if (isPremium)` scattered through
/// the UI.
library;

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../config/app_config.dart';
import 'products.dart';

/// Everything that can be gated.
enum PremiumFeature {
  /// The conversational reading. Free users get a few turns a day.
  chat('Unlimited readings', Tier.plus),

  /// The complete blueprint rather than the summary card.
  fullBlueprint('Your full chart', Tier.plus),

  /// Tarot and I Ching consultations.
  oracle('Unlimited oracle draws', Tier.plus),

  /// Running a compatibility check against another person.
  compatibility('Unlimited compatibility', Tier.plus),

  /// One-off long-form reports, also purchasable with coins.
  deepDive('Deep dive report', Tier.plus),
  yearAhead('Year ahead report', Tier.plus),

  /// Transit and solar-term notifications.
  alerts('Timing alerts', Tier.plus);

  const PremiumFeature(this.label, this.requiredTier);
  final String label;
  final Tier requiredTier;
}

/// What a one-off report costs in coins instead of a subscription.
///
/// The constraint these numbers have to satisfy: **two reports must cost more
/// than a month of Plus, priced at the cheapest coin rate available.** Anything
/// else and coins cannibalise the subscription, because the user who wants two
/// readings a month is better off never subscribing. At the best pack rate
/// (400 coins for \$9.99, so 2.5 cents a coin) two deep dives come to \$8.99
/// against \$7.99 for the month, so the subscription always wins on the second
/// purchase. `entitlements_test.dart` holds that invariant.
///
/// A deep dive is priced at exactly one mid coin pack, so the purchase is one
/// tap rather than an arithmetic problem.
const Map<PremiumFeature, int> coinPrices = {
  PremiumFeature.deepDive: 180,
  PremiumFeature.yearAhead: 320,
  PremiumFeature.compatibility: 240,
};

/// Free-tier allowances, keyed by feature. Absent means unlimited on free.
const Map<PremiumFeature, int> freeDailyAllowance = {
  PremiumFeature.chat: AppConfig.freeChatMessagesPerDay,
  PremiumFeature.oracle: AppConfig.freeOracleDrawsPerDay,
};

const Map<PremiumFeature, int> freeMonthlyAllowance = {
  PremiumFeature.compatibility: AppConfig.freeCompatibilityChecksPerMonth,
};

/// The answer to "can they do this right now".
sealed class AccessDecision {
  const AccessDecision();

  bool get isAllowed => this is AccessAllowed;
}

class AccessAllowed extends AccessDecision {
  const AccessAllowed({this.remaining});

  /// Uses left in the current window, or null when unlimited. Shown as
  /// "2 left today", which converts better than showing nothing.
  final int? remaining;
}

/// The user has run out of a free allowance. This is the good conversion
/// moment: they have just seen the feature work.
class AccessNeedsUpgrade extends AccessDecision {
  const AccessNeedsUpgrade({
    required this.feature,
    required this.reason,
    this.resetsAt,
    this.coinPrice,
  });

  final PremiumFeature feature;
  final String reason;

  /// When the free allowance comes back, so the paywall can offer waiting as a
  /// real alternative. Hiding it reads as a trap and costs trust.
  final DateTime? resetsAt;

  /// Set when the feature can also be unlocked with coins.
  final int? coinPrice;
}

class Entitlements {
  const Entitlements({
    this.tier = Tier.free,
    this.expiresAt,
    this.jadeCoins = 0,
    this.trialUsed = false,
  });

  final Tier tier;

  /// Null for free users and for lifetime purchases.
  final DateTime? expiresAt;

  final int jadeCoins;
  final bool trialUsed;

  /// A subscription that has run out drops back to free without any server
  /// round trip. Store receipts are re-checked on launch and after a purchase.
  Tier get effectiveTier {
    if (tier == Tier.free) return Tier.free;
    if (expiresAt != null && DateTime.now().isAfter(expiresAt!)) {
      return Tier.free;
    }
    return tier;
  }

  bool get isSubscribed => effectiveTier != Tier.free;

  Entitlements copyWith({
    Tier? tier,
    DateTime? expiresAt,
    bool clearExpiry = false,
    int? jadeCoins,
    bool? trialUsed,
  }) =>
      Entitlements(
        tier: tier ?? this.tier,
        expiresAt: clearExpiry ? null : (expiresAt ?? this.expiresAt),
        jadeCoins: jadeCoins ?? this.jadeCoins,
        trialUsed: trialUsed ?? this.trialUsed,
      );

  Map<String, dynamic> toJson() => {
        'tier': tier.name,
        'expiresAt': expiresAt?.toIso8601String(),
        'jadeCoins': jadeCoins,
        'trialUsed': trialUsed,
      };

  factory Entitlements.fromJson(Map<String, dynamic> json) => Entitlements(
        tier: Tier.values.firstWhere(
          (t) => t.name == json['tier'],
          orElse: () => Tier.free,
        ),
        expiresAt: json['expiresAt'] == null
            ? null
            : DateTime.tryParse(json['expiresAt'] as String),
        jadeCoins: (json['jadeCoins'] as num?)?.toInt() ?? 0,
        trialUsed: json['trialUsed'] as bool? ?? false,
      );
}

/// Holds entitlements and the free-tier counters, and persists both.
///
/// The counters live on the device. That is spoofable by a determined user, and
/// deliberately accepted for v1: the cost of a server-side quota ledger is not
/// worth it while the marginal cost of a reading is a fraction of a cent. The
/// *entitlement* is a different matter and must be validated server-side before
/// launch, because that is what people actually try to forge.
class EntitlementsController extends ChangeNotifier {
  EntitlementsController({SharedPreferences? preferences})
      : _prefs = preferences;

  static const _entitlementsKey = 'omni.entitlements';
  static const _usageKey = 'omni.usage';

  SharedPreferences? _prefs;
  Entitlements _entitlements = const Entitlements();

  /// Feature name to window key to count, e.g. `chat -> 2026-03-14 -> 2`.
  Map<String, Map<String, int>> _usage = {};

  Entitlements get entitlements => _entitlements;
  Tier get tier => _entitlements.effectiveTier;
  bool get isSubscribed => _entitlements.isSubscribed;
  int get jadeCoins => _entitlements.jadeCoins;

  Future<void> load() async {
    _prefs ??= await SharedPreferences.getInstance();

    final raw = _prefs!.getString(_entitlementsKey);
    if (raw != null) {
      try {
        _entitlements =
            Entitlements.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      } on FormatException {
        _entitlements = const Entitlements();
      }
    }

    final usageRaw = _prefs!.getString(_usageKey);
    if (usageRaw != null) {
      try {
        final decoded = jsonDecode(usageRaw) as Map<String, dynamic>;
        _usage = {
          for (final entry in decoded.entries)
            entry.key: Map<String, int>.from(entry.value as Map),
        };
      } on FormatException {
        _usage = {};
      }
    }
    _pruneOldWindows();
    notifyListeners();
  }

  /// Can the user use [feature] right now?
  AccessDecision check(PremiumFeature feature) {
    if (tier.covers(feature.requiredTier)) {
      return const AccessAllowed();
    }

    final dailyCap = freeDailyAllowance[feature];
    if (dailyCap != null) {
      final used = _countFor(feature, _dayWindow());
      if (used < dailyCap) {
        return AccessAllowed(remaining: dailyCap - used);
      }
      return AccessNeedsUpgrade(
        feature: feature,
        reason: 'You have used all $dailyCap free ${feature.label.toLowerCase()} '
            'for today.',
        resetsAt: _startOfTomorrow(),
        coinPrice: coinPrices[feature],
      );
    }

    final monthlyCap = freeMonthlyAllowance[feature];
    if (monthlyCap != null) {
      final used = _countFor(feature, _monthWindow());
      if (used < monthlyCap) {
        return AccessAllowed(remaining: monthlyCap - used);
      }
      return AccessNeedsUpgrade(
        feature: feature,
        reason: 'Free accounts get $monthlyCap of these a month.',
        resetsAt: _startOfNextMonth(),
        coinPrice: coinPrices[feature],
      );
    }

    return AccessNeedsUpgrade(
      feature: feature,
      reason: '${feature.label} is part of Omni Plus.',
      coinPrice: coinPrices[feature],
    );
  }

  /// Records one use. Call this only after the feature actually delivered — a
  /// reading that failed should not burn a free turn.
  Future<void> recordUse(PremiumFeature feature) async {
    if (tier.covers(feature.requiredTier)) return;

    final window = freeMonthlyAllowance.containsKey(feature)
        ? _monthWindow()
        : _dayWindow();
    final byWindow = _usage.putIfAbsent(feature.name, () => {});
    byWindow[window] = (byWindow[window] ?? 0) + 1;
    await _persistUsage();
    notifyListeners();
  }

  /// Spends coins on a one-off unlock. Returns false when the balance is short.
  Future<bool> spendCoins(int amount) async {
    if (amount <= 0) return true;
    if (_entitlements.jadeCoins < amount) return false;
    _entitlements =
        _entitlements.copyWith(jadeCoins: _entitlements.jadeCoins - amount);
    await _persistEntitlements();
    notifyListeners();
    return true;
  }

  Future<void> grantCoins(int amount) async {
    _entitlements =
        _entitlements.copyWith(jadeCoins: _entitlements.jadeCoins + amount);
    await _persistEntitlements();
    notifyListeners();
  }

  /// Applies a completed purchase.
  Future<void> applyPurchase(OmniProduct product) async {
    if (product.coins != null) {
      await grantCoins(product.coins!);
      return;
    }

    final grantedTier = product.grantsTier ?? Tier.plus;
    if (product.period == null) {
      // Lifetime.
      _entitlements = _entitlements.copyWith(
        tier: grantedTier,
        clearExpiry: true,
      );
    } else {
      // Extend from whichever is later, so renewing early does not lose time.
      final now = DateTime.now();
      final base = (_entitlements.expiresAt?.isAfter(now) ?? false)
          ? _entitlements.expiresAt!
          : now;
      _entitlements = _entitlements.copyWith(
        tier: grantedTier,
        expiresAt: base.add(product.period!),
        trialUsed: product.trialDays > 0 ? true : _entitlements.trialUsed,
      );
    }
    await _persistEntitlements();
    notifyListeners();
  }

  /// Replaces local state with what the store says is active. Called after a
  /// restore and on launch.
  Future<void> syncFromStore({
    required Tier tier,
    DateTime? expiresAt,
  }) async {
    _entitlements = _entitlements.copyWith(
      tier: tier,
      expiresAt: expiresAt,
      clearExpiry: expiresAt == null && tier != Tier.free,
    );
    await _persistEntitlements();
    notifyListeners();
  }

  /// Test and support hook: wipes purchases and counters on this device.
  Future<void> resetForTesting() async {
    _entitlements = const Entitlements();
    _usage = {};
    await _persistEntitlements();
    await _persistUsage();
    notifyListeners();
  }

  int remainingToday(PremiumFeature feature) {
    if (tier.covers(feature.requiredTier)) return -1;
    final cap = freeDailyAllowance[feature];
    if (cap == null) return -1;
    return (cap - _countFor(feature, _dayWindow())).clamp(0, cap);
  }

  int _countFor(PremiumFeature feature, String window) =>
      _usage[feature.name]?[window] ?? 0;

  static String _dayWindow([DateTime? at]) {
    final now = at ?? DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
  }

  static String _monthWindow([DateTime? at]) {
    final now = at ?? DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }

  static DateTime _startOfTomorrow() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
  }

  static DateTime _startOfNextMonth() {
    final now = DateTime.now();
    return now.month == 12
        ? DateTime(now.year + 1, 1)
        : DateTime(now.year, now.month + 1);
  }

  /// Keeps the stored counters from growing without bound.
  void _pruneOldWindows() {
    final keepDay = _dayWindow();
    final keepMonth = _monthWindow();
    for (final byWindow in _usage.values) {
      byWindow.removeWhere((window, _) =>
          window != keepDay && window != keepMonth);
    }
    _usage.removeWhere((_, byWindow) => byWindow.isEmpty);
  }

  Future<void> _persistEntitlements() async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!
        .setString(_entitlementsKey, jsonEncode(_entitlements.toJson()));
  }

  Future<void> _persistUsage() async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setString(_usageKey, jsonEncode(_usage));
  }
}
