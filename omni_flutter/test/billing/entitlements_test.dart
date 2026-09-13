import 'package:flutter_test/flutter_test.dart';
import 'package:omni_flutter/core/billing/entitlements.dart';
import 'package:omni_flutter/core/billing/products.dart';
import 'package:omni_flutter/core/billing/purchase_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<EntitlementsController> _fresh() async {
  SharedPreferences.setMockInitialValues({});
  final controller = EntitlementsController();
  await controller.load();
  return controller;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('free tier allowances', () {
    test('a fresh user starts free with no coins', () async {
      final e = await _fresh();
      expect(e.tier, Tier.free);
      expect(e.jadeCoins, 0);
      expect(e.isSubscribed, isFalse);
    });

    test('chat is allowed until the daily allowance runs out', () async {
      final e = await _fresh();
      final cap = freeDailyAllowance[PremiumFeature.chat]!;

      for (var i = 0; i < cap; i++) {
        final decision = e.check(PremiumFeature.chat);
        expect(decision, isA<AccessAllowed>(), reason: 'use ${i + 1}');
        expect((decision as AccessAllowed).remaining, cap - i);
        await e.recordUse(PremiumFeature.chat);
      }

      final blocked = e.check(PremiumFeature.chat);
      expect(blocked, isA<AccessNeedsUpgrade>());
      expect((blocked as AccessNeedsUpgrade).resetsAt, isNotNull);
    });

    test('the block names when the allowance comes back', () async {
      final e = await _fresh();
      for (var i = 0; i < freeDailyAllowance[PremiumFeature.chat]!; i++) {
        await e.recordUse(PremiumFeature.chat);
      }
      final blocked = e.check(PremiumFeature.chat) as AccessNeedsUpgrade;
      expect(blocked.resetsAt!.isAfter(DateTime.now()), isTrue);
      expect(blocked.reason, contains('today'));
    });

    test('features with no free allowance are gated outright', () async {
      final e = await _fresh();
      final decision = e.check(PremiumFeature.fullBlueprint);
      expect(decision, isA<AccessNeedsUpgrade>());
      expect((decision as AccessNeedsUpgrade).resetsAt, isNull);
    });

    test('one-off reports quote a coin price alongside the upgrade', () async {
      final e = await _fresh();
      final decision = e.check(PremiumFeature.deepDive) as AccessNeedsUpgrade;
      expect(decision.coinPrice, coinPrices[PremiumFeature.deepDive]);
    });

    test('compatibility runs on a monthly window', () async {
      final e = await _fresh();
      final cap = freeMonthlyAllowance[PremiumFeature.compatibility]!;
      for (var i = 0; i < cap; i++) {
        expect(e.check(PremiumFeature.compatibility), isA<AccessAllowed>());
        await e.recordUse(PremiumFeature.compatibility);
      }
      final blocked =
          e.check(PremiumFeature.compatibility) as AccessNeedsUpgrade;
      expect(blocked.reason, contains('month'));
    });
  });

  group('subscriptions', () {
    test('a monthly purchase unlocks everything and stops the counting',
        () async {
      final e = await _fresh();
      for (var i = 0; i < freeDailyAllowance[PremiumFeature.chat]!; i++) {
        await e.recordUse(PremiumFeature.chat);
      }
      expect(e.check(PremiumFeature.chat), isA<AccessNeedsUpgrade>());

      await e.applyPurchase(subscriptionProducts.first);

      expect(e.tier, Tier.plus);
      for (final feature in PremiumFeature.values) {
        expect(e.check(feature), isA<AccessAllowed>(), reason: feature.name);
      }
    });

    test('an expired subscription falls back to free', () async {
      final e = await _fresh();
      await e.syncFromStore(
        tier: Tier.plus,
        expiresAt: DateTime.now().subtract(const Duration(days: 1)),
      );
      expect(e.tier, Tier.free);
      expect(e.check(PremiumFeature.fullBlueprint), isA<AccessNeedsUpgrade>());
    });

    test('renewing early extends rather than truncates', () async {
      final e = await _fresh();
      final monthly =
          subscriptionProducts.firstWhere((p) => p.id == 'omni.plus.monthly');
      await e.applyPurchase(monthly);
      final first = e.entitlements.expiresAt!;
      await e.applyPurchase(monthly);
      final second = e.entitlements.expiresAt!;
      expect(second.difference(first).inDays, closeTo(30, 1));
    });

    test('lifetime never expires', () async {
      final e = await _fresh();
      await e.applyPurchase(
          subscriptionProducts.firstWhere((p) => p.id == 'omni.plus.lifetime'));
      expect(e.entitlements.expiresAt, isNull);
      expect(e.tier, Tier.vip);
      expect(e.isSubscribed, isTrue);
    });

    test('VIP covers everything Plus covers', () {
      expect(Tier.vip.covers(Tier.plus), isTrue);
      expect(Tier.plus.covers(Tier.vip), isFalse);
      expect(Tier.free.covers(Tier.free), isTrue);
    });
  });

  group('jade coins', () {
    test('a coin pack credits the balance without changing the tier', () async {
      final e = await _fresh();
      await e.applyPurchase(
          coinProducts.firstWhere((p) => p.id == 'omni.coins.180'));
      expect(e.jadeCoins, 180);
      expect(e.tier, Tier.free);
    });

    test('spending deducts, and an over-spend is refused', () async {
      final e = await _fresh();
      await e.grantCoins(100);
      expect(await e.spendCoins(60), isTrue);
      expect(e.jadeCoins, 40);
      expect(await e.spendCoins(60), isFalse);
      expect(e.jadeCoins, 40);
    });

    test('two reports always cost more than a month of Plus', () {
      // The pricing lever that pushes repeat coin buyers into subscribing. It
      // has to hold at the *cheapest* coin rate, because that is the rate a
      // motivated user will find. If this ever inverts, coins start
      // cannibalising the subscription.
      final cheapestCentsPerCoin = coinProducts
          .map((p) => double.parse(p.fallbackPrice.substring(1)) * 100 / p.coins!)
          .reduce((a, b) => a < b ? a : b);
      final monthlyCents = double.parse(subscriptionProducts
              .firstWhere((p) => p.id == 'omni.plus.monthly')
              .fallbackPrice
              .substring(1)) *
          100;

      for (final entry in coinPrices.entries) {
        expect(2 * entry.value * cheapestCentsPerCoin,
            greaterThan(monthlyCents),
            reason: 'two ${entry.key.name} purchases undercut the monthly');
      }
    });

    test('a deep dive is exactly one mid coin pack', () {
      expect(coinPrices[PremiumFeature.deepDive],
          coinProducts.firstWhere((p) => p.id == 'omni.coins.180').coins);
    });
  });

  group('persistence', () {
    test('entitlements and counters survive a reload', () async {
      SharedPreferences.setMockInitialValues({});
      final first = EntitlementsController();
      await first.load();
      await first.grantCoins(120);
      await first.recordUse(PremiumFeature.chat);

      final second = EntitlementsController();
      await second.load();
      expect(second.jadeCoins, 120);
      final decision = second.check(PremiumFeature.chat) as AccessAllowed;
      expect(decision.remaining,
          freeDailyAllowance[PremiumFeature.chat]! - 1);
    });

    test('corrupt stored state degrades to free instead of crashing', () async {
      SharedPreferences.setMockInitialValues({
        'omni.entitlements': 'not json at all',
        'omni.usage': '{{{',
      });
      final e = EntitlementsController();
      await e.load();
      expect(e.tier, Tier.free);
      expect(e.check(PremiumFeature.chat), isA<AccessAllowed>());
    });

    test('reset clears purchases and counters', () async {
      final e = await _fresh();
      await e.applyPurchase(subscriptionProducts.first);
      await e.grantCoins(50);
      await e.resetForTesting();
      expect(e.tier, Tier.free);
      expect(e.jadeCoins, 0);
    });
  });

  group('product catalogue', () {
    test('ids are unique and namespaced', () {
      expect(allProductIds.length, allProducts.length);
      for (final product in allProducts) {
        expect(product.id, startsWith('omni.'));
        expect(product.fallbackPrice, startsWith(r'$'));
      }
    });

    test('annual is cheaper per month than monthly', () {
      double price(String id) => double.parse(allProducts
          .firstWhere((p) => p.id == id)
          .fallbackPrice
          .substring(1));
      expect(price('omni.plus.annual') / 12,
          lessThan(price('omni.plus.monthly')));
    });

    test('bigger coin packs give more coins per dollar', () {
      double perDollar(String id) {
        final p = allProducts.firstWhere((x) => x.id == id);
        return p.coins! / double.parse(p.fallbackPrice.substring(1));
      }

      expect(perDollar('omni.coins.180'), greaterThan(perDollar('omni.coins.60')));
      expect(
          perDollar('omni.coins.400'), greaterThan(perDollar('omni.coins.180')));
    });

    test('every product resolves by id', () {
      for (final id in allProductIds) {
        expect(productById(id), isNotNull);
      }
      expect(productById('omni.nope'), isNull);
    });
  });

  group('sandbox purchase service', () {
    test('grants the product and reports success', () async {
      final e = await _fresh();
      final service = SandboxPurchaseService(entitlements: e);
      await service.initialise();

      expect(service.isAvailable, isTrue);
      expect(service.products, hasLength(allProducts.length));

      final result = await service.buy(subscriptionProducts.first);
      expect(result.isSuccess, isTrue);
      expect(e.tier, Tier.plus);
    });

    test('falls back to the hard-coded price when the store is silent',
        () async {
      final e = await _fresh();
      final service = SandboxPurchaseService(entitlements: e);
      final product = subscriptionProducts.first;
      expect(service.priceLabel(product), product.fallbackPrice);
    });
  });
}
