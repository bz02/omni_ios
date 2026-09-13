// Tests for the client half of the payment path.
//
// The server decides who has paid; this code decides what to ask it and what
// to believe. The cases worth holding are the ones where the answer is "no"
// or "not yet", because those are the ones a hopeful implementation gets
// wrong by unlocking anyway.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:omni_flutter/core/billing/entitlements.dart';
import 'package:omni_flutter/core/billing/install_identity.dart';
import 'package:omni_flutter/core/billing/products.dart';
import 'package:omni_flutter/core/billing/purchase_service.dart';
import 'package:omni_flutter/core/billing/stripe_checkout_service.dart';
import 'package:omni_flutter/core/net/omni_api.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _base = 'https://api.omni.test';

/// Routes requests by path, recording each one.
({http.Client client, List<http.BaseRequest> requests}) mockApi(
  Map<String, Object Function(http.Request)> routes,
) {
  final requests = <http.BaseRequest>[];
  final client = MockClient((request) async {
    requests.add(request);
    for (final entry in routes.entries) {
      if (request.url.path == entry.key) {
        final result = entry.value(request);
        if (result is http.Response) return result;
        return http.Response(jsonEncode(result), 200,
            headers: {'content-type': 'application/json'});
      }
    }
    return http.Response('{"error":"no route"}', 404);
  });
  return (client: client, requests: requests);
}

Future<({EntitlementsController entitlements, InstallIdentity identity})>
    _state() async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final entitlements = EntitlementsController(preferences: prefs);
  await entitlements.load();
  final identity = InstallIdentity(preferences: prefs);
  await identity.load();
  return (entitlements: entitlements, identity: identity);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('install identity', () {
    test('is stable across loads', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final first = InstallIdentity(preferences: prefs);
      final id = await first.load();

      final second = InstallIdentity(preferences: prefs);
      expect(await second.load(), id);
    });

    test('is 128 bits of hex, not something guessable', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final id = await InstallIdentity(preferences: prefs).load();
      expect(id, matches(RegExp(r'^[a-f0-9]{32}$')));
    });

    test('two installs do not collide', () async {
      final ids = <String>{};
      for (var i = 0; i < 50; i++) {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        ids.add(await InstallIdentity(preferences: prefs).load());
      }
      expect(ids, hasLength(50));
    });

    test('remembers and clears the restore code', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final identity = InstallIdentity(preferences: prefs);
      await identity.load();

      await identity.setRestoreCode('cs_123');
      final reloaded = InstallIdentity(preferences: prefs);
      await reloaded.load();
      expect(reloaded.restoreCode, 'cs_123');

      await reloaded.setRestoreCode(null);
      final again = InstallIdentity(preferences: prefs);
      await again.load();
      expect(again.restoreCode, isNull);
    });
  });

  group('api client', () {
    test('does nothing when no backend is configured', () {
      final api = OmniApi(baseUrl: '');
      expect(api.isConfigured, isFalse);
      expect(
        () => api.fetchEntitlement(installId: 'x'),
        throwsA(isA<OmniApiException>()),
      );
    });

    test('sends the product id and never a price', () async {
      final mock = mockApi({
        '/v1/checkout': (_) => {'url': 'https://checkout.stripe/pay'},
      });
      final api = OmniApi(client: mock.client, baseUrl: _base);

      final url = await api.createCheckout(
        productId: 'omni.plus.annual',
        installId: 'abc',
        returnUrl: 'https://omni.test',
      );

      expect(url, 'https://checkout.stripe/pay');
      final body = jsonDecode((mock.requests.single as http.Request).body)
          as Map<String, dynamic>;
      expect(body['productId'], 'omni.plus.annual');
      expect(body.containsKey('price'), isFalse);
      expect(body.containsKey('amount'), isFalse);
    });

    test('surfaces the server error message', () async {
      final api = OmniApi(
        client: MockClient((_) async =>
            http.Response('{"error":"Unknown product."}', 400)),
        baseUrl: _base,
      );
      await expectLater(
        api.createCheckout(
            productId: 'nope', installId: 'abc', returnUrl: 'https://omni.test'),
        throwsA(isA<OmniApiException>()
            .having((e) => e.message, 'message', 'Unknown product.')
            .having((e) => e.statusCode, 'status', 400)),
      );
    });

    test('a non-JSON reply is an error, not a crash', () async {
      final api = OmniApi(
        client: MockClient((_) async => http.Response('<html>502</html>', 502)),
        baseUrl: _base,
      );
      await expectLater(
        api.fetchEntitlement(installId: 'abc'),
        throwsA(isA<OmniApiException>()),
      );
    });

    test('parses an entitlement', () async {
      final api = OmniApi(
        client: MockClient((request) async {
          expect(request.url.queryParameters['installId'], 'abc');
          expect(request.url.queryParameters['code'], 'cs_1');
          return http.Response(
            jsonEncode({
              'tier': 'plus',
              'expiresAt': '2030-01-01T00:00:00.000Z',
              'jadeCoins': 60,
            }),
            200,
          );
        }),
        baseUrl: _base,
      );

      final entitlement =
          await api.fetchEntitlement(installId: 'abc', restoreCode: 'cs_1');
      expect(entitlement.tier, Tier.plus);
      expect(entitlement.jadeCoins, 60);
      expect(entitlement.expiresAt!.year, 2030);
    });

    test('an unrecognised tier falls back to free rather than guessing',
        () async {
      final api = OmniApi(
        client: MockClient(
            (_) async => http.Response('{"tier":"platinum"}', 200)),
        baseUrl: _base,
      );
      expect((await api.fetchEntitlement(installId: 'abc')).tier, Tier.free);
    });
  });

  group('stripe checkout service', () {
    test('is unavailable without a backend', () async {
      final state = await _state();
      final service = StripeCheckoutService(
        entitlements: state.entitlements,
        identity: state.identity,
        api: OmniApi(baseUrl: ''),
        returnUrl: 'https://omni.test',
      );
      expect(service.isAvailable, isFalse);

      final result = await service.buy(subscriptionProducts.first);
      expect(result.outcome, PurchaseOutcome.failed);
      expect(state.entitlements.tier, Tier.free);
    });

    test('a returning session that has paid unlocks and is remembered',
        () async {
      final state = await _state();
      final mock = mockApi({
        '/v1/entitlement': (_) => {
              'tier': 'plus',
              'expiresAt': '2030-01-01T00:00:00.000Z',
              'jadeCoins': 0,
            },
      });
      final service = StripeCheckoutService(
        entitlements: state.entitlements,
        identity: state.identity,
        api: OmniApi(client: mock.client, baseUrl: _base),
        returnUrl: 'https://omni.test',
      );

      final result = await service.completePendingCheckout('cs_paid');
      expect(result.outcome, PurchaseOutcome.purchased);
      expect(state.entitlements.tier, Tier.plus);
      // Kept so the subscription can be moved to another device.
      expect(state.identity.restoreCode, 'cs_paid');
    });

    test('a returning session that has not settled stays locked', () async {
      final state = await _state();
      final mock = mockApi({
        '/v1/entitlement': (_) => {'tier': 'free', 'jadeCoins': 0},
      });
      final service = StripeCheckoutService(
        entitlements: state.entitlements,
        identity: state.identity,
        api: OmniApi(client: mock.client, baseUrl: _base),
        returnUrl: 'https://omni.test',
      );

      final result = await service.completePendingCheckout('cs_pending');
      expect(result.outcome, PurchaseOutcome.pending);
      expect(state.entitlements.tier, Tier.free,
          reason: 'returning from Stripe is not the same as having paid');
      expect(state.identity.restoreCode, isNull);
    });

    test('coins from the server replace the balance rather than adding to it',
        () async {
      final state = await _state();
      await state.entitlements.grantCoins(180);

      final mock = mockApi({
        '/v1/entitlement': (_) => {'tier': 'free', 'jadeCoins': 180},
      });
      final service = StripeCheckoutService(
        entitlements: state.entitlements,
        identity: state.identity,
        api: OmniApi(client: mock.client, baseUrl: _base),
        returnUrl: 'https://omni.test',
      );

      await service.completePendingCheckout('cs_coins');
      await service.restore();
      await service.restore();

      // Syncing repeatedly must not mint coins.
      expect(state.entitlements.jadeCoins, 180);
    });

    test('restoring with no subscription reports it instead of unlocking',
        () async {
      final state = await _state();
      final mock = mockApi({
        '/v1/entitlement': (_) => {'tier': 'free', 'jadeCoins': 0},
      });
      final service = StripeCheckoutService(
        entitlements: state.entitlements,
        identity: state.identity,
        api: OmniApi(client: mock.client, baseUrl: _base),
        returnUrl: 'https://omni.test',
      );

      final result = await service.restore();
      expect(result.outcome, PurchaseOutcome.failed);
      expect(result.message, contains('restore code'));
      expect(state.entitlements.tier, Tier.free);
    });

    test('a valid restore code moves the subscription to this device',
        () async {
      final state = await _state();
      final mock = mockApi({
        '/v1/entitlement': (request) {
          expect(request.url.queryParameters['code'], 'cs_other_device');
          return {'tier': 'vip', 'expiresAt': null, 'jadeCoins': 0};
        },
      });
      final service = StripeCheckoutService(
        entitlements: state.entitlements,
        identity: state.identity,
        api: OmniApi(client: mock.client, baseUrl: _base),
        returnUrl: 'https://omni.test',
      );

      final result = await service.redeemRestoreCode('  cs_other_device  ');
      expect(result.outcome, PurchaseOutcome.restored);
      expect(state.entitlements.tier, Tier.vip);
      expect(state.entitlements.entitlements.expiresAt, isNull);
    });

    test('a bad restore code changes nothing', () async {
      final state = await _state();
      final mock = mockApi({
        '/v1/entitlement': (_) => {'tier': 'free', 'jadeCoins': 0},
      });
      final service = StripeCheckoutService(
        entitlements: state.entitlements,
        identity: state.identity,
        api: OmniApi(client: mock.client, baseUrl: _base),
        returnUrl: 'https://omni.test',
      );

      final result = await service.redeemRestoreCode('nonsense');
      expect(result.outcome, PurchaseOutcome.failed);
      expect(state.entitlements.tier, Tier.free);
      expect(state.identity.restoreCode, isNull);
    });

    test('a server outage leaves the local entitlement alone', () async {
      final state = await _state();
      await state.entitlements
          .applyPurchase(subscriptionProducts.first); // already paid
      expect(state.entitlements.tier, Tier.plus);

      final service = StripeCheckoutService(
        entitlements: state.entitlements,
        identity: state.identity,
        api: OmniApi(
          client: MockClient((_) async => http.Response('{"error":"down"}', 503)),
          baseUrl: _base,
        ),
        returnUrl: 'https://omni.test',
      );

      final result = await service.restore();
      expect(result.outcome, PurchaseOutcome.failed);
      // A paying customer must not be locked out because the server blinked.
      expect(state.entitlements.tier, Tier.plus);
    });

    test('an expired server entitlement does lock the app', () async {
      final state = await _state();
      await state.entitlements.applyPurchase(subscriptionProducts.first);

      final mock = mockApi({
        '/v1/entitlement': (_) => {
              'tier': 'free',
              'expiresAt': null,
              'jadeCoins': 0,
            },
      });
      final service = StripeCheckoutService(
        entitlements: state.entitlements,
        identity: state.identity,
        api: OmniApi(client: mock.client, baseUrl: _base),
        returnUrl: 'https://omni.test',
      );

      await service.initialise();
      expect(state.entitlements.tier, Tier.free,
          reason: 'the server is authoritative when it answers');
    });
  });
}
