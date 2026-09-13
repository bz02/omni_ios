/// Taking money on the web.
///
/// There is no `in_app_purchase` implementation for web, and even where there
/// were one, the App Store's cut is 15 to 30% against Stripe's 2.9% plus 30
/// cents, and Stripe pays out in days rather than after a review queue. For a
/// product that needs cash flow now, the web build is the one that earns first.
///
/// The flow is deliberately boring: ask the server for a Checkout session,
/// hand the browser to Stripe, and when it comes back ask the server what the
/// user is now entitled to. The client never sees a secret and never decides
/// for itself that a payment succeeded.
library;

import 'package:url_launcher/url_launcher.dart';

import '../net/omni_api.dart';
import 'entitlements.dart';
import 'install_identity.dart';
import 'products.dart';
import 'purchase_service.dart';

class StripeCheckoutService extends PurchaseService {
  StripeCheckoutService({
    required EntitlementsController entitlements,
    required InstallIdentity identity,
    required OmniApi api,
    required this.returnUrl,
  })  : _entitlements = entitlements,
        _identity = identity,
        _api = api;

  final EntitlementsController _entitlements;
  final InstallIdentity _identity;
  final OmniApi _api;

  /// Where Stripe sends the browser back to. Stripe appends the session id,
  /// which [completePendingCheckout] turns into an entitlement.
  final String returnUrl;

  bool _busy = false;

  @override
  List<PricedProduct> get products => [
        // Stripe's prices are configured against the same product ids in the
        // dashboard. Until a price lookup is wired up, the catalogue's own
        // figures are shown, which is safe here in a way it is not on the App
        // Store: this build charges exactly what the dashboard says, and the
        // Checkout page restates the price before anyone pays.
        for (final product in allProducts)
          PricedProduct(product: product, displayPrice: product.fallbackPrice),
      ];

  @override
  bool get isAvailable => _api.isConfigured;

  @override
  bool get isBusy => _busy;

  @override
  Future<void> initialise() async {
    if (!_api.isConfigured) return;
    await _refreshEntitlement();
  }

  @override
  Future<PurchaseResult> buy(OmniProduct product) async {
    if (!_api.isConfigured) {
      return const PurchaseResult(
        PurchaseOutcome.failed,
        message: 'This build has no payment backend configured.',
      );
    }

    _busy = true;
    notifyListeners();

    try {
      final url = await _api.createCheckout(
        productId: product.id,
        installId: _identity.installId,
        returnUrl: returnUrl,
      );

      final launched = await launchUrl(
        Uri.parse(url),
        // Same tab: Stripe has to come back to us, and a popup would be
        // blocked about as often as it worked.
        webOnlyWindowName: '_self',
        mode: LaunchMode.platformDefault,
      );

      if (!launched) {
        return const PurchaseResult(
          PurchaseOutcome.failed,
          message: 'Could not open the payment page.',
        );
      }

      // The browser is navigating away. Whatever happens next is picked up by
      // completePendingCheckout when Stripe returns.
      return const PurchaseResult(PurchaseOutcome.pending);
    } on OmniApiException catch (error) {
      return PurchaseResult(PurchaseOutcome.failed, message: error.message);
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  /// Called on startup with the `session_id` Stripe appended to the return URL.
  Future<PurchaseResult> completePendingCheckout(String sessionId) async {
    if (sessionId.isEmpty) {
      return const PurchaseResult(PurchaseOutcome.canceled);
    }

    _busy = true;
    notifyListeners();
    try {
      final entitlement = await _api.fetchEntitlement(
        installId: _identity.installId,
        restoreCode: sessionId,
      );

      if (entitlement.tier == Tier.free && entitlement.jadeCoins == 0) {
        // Stripe sent us back but the payment has not settled. Common with
        // bank redirect methods, and not an error.
        return const PurchaseResult(
          PurchaseOutcome.pending,
          message: 'Payment is still processing. It will appear shortly.',
        );
      }

      await _identity.setRestoreCode(sessionId);
      await _apply(entitlement);
      return const PurchaseResult(PurchaseOutcome.purchased);
    } on OmniApiException catch (error) {
      return PurchaseResult(PurchaseOutcome.failed, message: error.message);
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  @override
  Future<PurchaseResult> restore() async {
    if (!_api.isConfigured) {
      return const PurchaseResult(
        PurchaseOutcome.failed,
        message: 'This build has no payment backend configured.',
      );
    }

    _busy = true;
    notifyListeners();
    try {
      final entitlement = await _refreshEntitlement();
      if (entitlement.tier == Tier.free) {
        return const PurchaseResult(
          PurchaseOutcome.failed,
          message: 'No active subscription found for this device. If you paid '
              'on another one, enter the restore code from your receipt.',
        );
      }
      return const PurchaseResult(PurchaseOutcome.restored);
    } on OmniApiException catch (error) {
      return PurchaseResult(PurchaseOutcome.failed, message: error.message);
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  /// Moves a subscription bought on another device onto this one.
  Future<PurchaseResult> redeemRestoreCode(String code) async {
    _busy = true;
    notifyListeners();
    try {
      final entitlement = await _api.fetchEntitlement(
        installId: _identity.installId,
        restoreCode: code.trim(),
      );
      if (entitlement.tier == Tier.free) {
        return const PurchaseResult(
          PurchaseOutcome.failed,
          message: 'That code does not match an active subscription.',
        );
      }
      await _identity.setRestoreCode(code.trim());
      await _apply(entitlement);
      return const PurchaseResult(PurchaseOutcome.restored);
    } on OmniApiException catch (error) {
      return PurchaseResult(PurchaseOutcome.failed, message: error.message);
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<ServerEntitlement> _refreshEntitlement() async {
    final entitlement = await _api.fetchEntitlement(
      installId: _identity.installId,
      restoreCode: _identity.restoreCode,
    );
    await _apply(entitlement);
    return entitlement;
  }

  Future<void> _apply(ServerEntitlement entitlement) async {
    await _entitlements.syncFromStore(
      tier: entitlement.tier,
      expiresAt: entitlement.expiresAt,
    );
    if (entitlement.jadeCoins > 0) {
      await _entitlements.setCoinBalance(entitlement.jadeCoins);
    }
  }
}
