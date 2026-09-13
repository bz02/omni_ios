/// Talking to the app stores.
///
/// The app never touches `in_app_purchase` directly. Everything goes through
/// [PurchaseService], which has two implementations: one that drives the real
/// store, and one that fakes it so the paywall can be built, demoed and tested
/// on a machine with no store account attached.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import 'entitlements.dart';
import 'products.dart';

/// A product with the price the store actually charges.
class PricedProduct {
  const PricedProduct({required this.product, required this.displayPrice});

  final OmniProduct product;

  /// Localised, straight from the store. Never assembled from a hard-coded
  /// number: showing a price the store will not charge fails App Store review
  /// and, worse, reads as a bait and switch.
  final String displayPrice;
}

enum PurchaseOutcome { purchased, restored, cancelled, pending, failed }

class PurchaseResult {
  const PurchaseResult(this.outcome, {this.product, this.message});
  final PurchaseOutcome outcome;
  final OmniProduct? product;
  final String? message;

  bool get isSuccess =>
      outcome == PurchaseOutcome.purchased || outcome == PurchaseOutcome.restored;
}

abstract class PurchaseService extends ChangeNotifier {
  /// Products with live prices. Empty until [initialise] resolves.
  List<PricedProduct> get products;

  /// False when the device cannot buy anything — no store, or purchases are
  /// restricted. The paywall must not show buttons that cannot work.
  bool get isAvailable;

  bool get isBusy;

  Future<void> initialise();

  Future<PurchaseResult> buy(OmniProduct product);

  /// Required by App Store review: a visible way to restore purchases.
  Future<PurchaseResult> restore();

  PricedProduct? priced(String productId) {
    for (final p in products) {
      if (p.product.id == productId) return p;
    }
    return null;
  }

  /// Store price when known, the hard-coded fallback when not.
  String priceLabel(OmniProduct product) =>
      priced(product.id)?.displayPrice ?? product.fallbackPrice;
}

/// Drives the real store through `in_app_purchase`.
///
/// Receipts are applied locally here. Before launch this must be paired with
/// server-side validation: a purchase stream event is not proof of payment, and
/// a jailbroken device can synthesise one. See docs/LAUNCH.md.
class StorePurchaseService extends PurchaseService {
  StorePurchaseService({
    required EntitlementsController entitlements,
    InAppPurchase? iap,
  })  : _entitlements = entitlements,
        _iap = iap ?? InAppPurchase.instance;

  final EntitlementsController _entitlements;
  final InAppPurchase _iap;

  StreamSubscription<List<PurchaseDetails>>? _subscription;
  final List<PricedProduct> _products = [];
  bool _available = false;
  bool _busy = false;

  /// Completes the purchase the user is currently waiting on.
  Completer<PurchaseResult>? _pending;

  @override
  List<PricedProduct> get products => List.unmodifiable(_products);

  @override
  bool get isAvailable => _available;

  @override
  bool get isBusy => _busy;

  @override
  Future<void> initialise() async {
    _available = await _iap.isAvailable();
    if (!_available) {
      notifyListeners();
      return;
    }

    _subscription = _iap.purchaseStream.listen(
      _onPurchaseUpdate,
      onError: (Object error) {
        _pending?.complete(
            PurchaseResult(PurchaseOutcome.failed, message: '$error'));
        _pending = null;
        _busy = false;
        notifyListeners();
      },
    );

    final response = await _iap.queryProductDetails(allProductIds);
    if (response.notFoundIDs.isNotEmpty) {
      // Normal before the products are approved in App Store Connect, and a
      // configuration error afterwards. Worth logging either way.
      debugPrint('Store did not recognise: ${response.notFoundIDs.join(', ')}');
    }

    _products
      ..clear()
      ..addAll([
        for (final details in response.productDetails)
          if (productById(details.id) case final product?)
            PricedProduct(product: product, displayPrice: details.price),
      ]);
    notifyListeners();
  }

  @override
  Future<PurchaseResult> buy(OmniProduct product) async {
    if (!_available) {
      return const PurchaseResult(PurchaseOutcome.failed,
          message: 'In-app purchases are not available on this device.');
    }

    final response = await _iap.queryProductDetails({product.id});
    if (response.productDetails.isEmpty) {
      return PurchaseResult(PurchaseOutcome.failed,
          message: 'The store does not have ${product.name} configured yet.');
    }

    _busy = true;
    notifyListeners();

    _pending = Completer<PurchaseResult>();
    final param = PurchaseParam(productDetails: response.productDetails.first);

    // Consumables and subscriptions take different store calls.
    if (product.kind == ProductKind.consumable) {
      await _iap.buyConsumable(purchaseParam: param);
    } else {
      await _iap.buyNonConsumable(purchaseParam: param);
    }

    return _pending!.future.timeout(
      const Duration(minutes: 5),
      onTimeout: () {
        _busy = false;
        notifyListeners();
        return const PurchaseResult(PurchaseOutcome.pending,
            message: 'Still waiting on the store. Nothing has been charged '
                'twice — reopen the app to pick it up.');
      },
    );
  }

  @override
  Future<PurchaseResult> restore() async {
    if (!_available) {
      return const PurchaseResult(PurchaseOutcome.failed,
          message: 'In-app purchases are not available on this device.');
    }
    _busy = true;
    notifyListeners();
    await _iap.restorePurchases();
    _busy = false;
    notifyListeners();
    return const PurchaseResult(PurchaseOutcome.restored);
  }

  Future<void> _onPurchaseUpdate(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.pending:
          _busy = true;
          notifyListeners();

        case PurchaseStatus.error:
          _finish(PurchaseResult(PurchaseOutcome.failed,
              message: purchase.error?.message ?? 'The purchase failed.'));

        case PurchaseStatus.canceled:
          _finish(const PurchaseResult(PurchaseOutcome.cancelled));

        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          final product = productById(purchase.productID);
          if (product != null) {
            await _entitlements.applyPurchase(product);
          }
          _finish(PurchaseResult(
            purchase.status == PurchaseStatus.restored
                ? PurchaseOutcome.restored
                : PurchaseOutcome.purchased,
            product: product,
          ));
      }

      // Always acknowledge, or the store keeps re-delivering and, on Android,
      // refunds the purchase after three days.
      if (purchase.pendingCompletePurchase) {
        await _iap.completePurchase(purchase);
      }
    }
  }

  void _finish(PurchaseResult result) {
    _busy = false;
    if (_pending != null && !_pending!.isCompleted) {
      _pending!.complete(result);
    }
    _pending = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

/// A store that is not a store. Grants entitlements immediately so the paywall
/// and every gate behind it can be exercised in tests, on the simulator and in
/// a demo without App Store Connect being set up.
///
/// Never wired up in a release build — [chooseService] picks the real one.
class SandboxPurchaseService extends PurchaseService {
  SandboxPurchaseService({required EntitlementsController entitlements})
      : _entitlements = entitlements;

  final EntitlementsController _entitlements;
  bool _busy = false;

  @override
  List<PricedProduct> get products => [
        for (final product in allProducts)
          PricedProduct(product: product, displayPrice: product.fallbackPrice),
      ];

  @override
  bool get isAvailable => true;

  @override
  bool get isBusy => _busy;

  @override
  Future<void> initialise() async {}

  @override
  Future<PurchaseResult> buy(OmniProduct product) async {
    _busy = true;
    notifyListeners();
    await Future<void>.delayed(const Duration(milliseconds: 400));
    await _entitlements.applyPurchase(product);
    _busy = false;
    notifyListeners();
    return PurchaseResult(PurchaseOutcome.purchased, product: product);
  }

  @override
  Future<PurchaseResult> restore() async =>
      const PurchaseResult(PurchaseOutcome.restored);
}

/// Picks an implementation. Release builds always get the real store.
PurchaseService chooseService({
  required EntitlementsController entitlements,
  bool useSandbox = false,
}) {
  if (useSandbox && !kReleaseMode) {
    return SandboxPurchaseService(entitlements: entitlements);
  }
  return StorePurchaseService(entitlements: entitlements);
}
