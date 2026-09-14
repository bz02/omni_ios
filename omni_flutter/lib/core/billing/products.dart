/// The things a user can buy, and what each one unlocks.
///
/// Prices here are display fallbacks only. The real price always comes from the
/// store, because Apple and Google localise it and the App Store will reject a
/// paywall that shows a price the store does not charge.
library;

enum ProductKind { subscription, consumable }

enum Tier {
  free(0, 'Free'),
  plus(1, 'Omni Plus'),
  vip(2, 'Omni VIP');

  const Tier(this.rank, this.label);
  final int rank;
  final String label;

  bool covers(Tier required) => rank >= required.rank;
}

class OmniProduct {
  const OmniProduct({
    required this.id,
    required this.name,
    required this.blurb,
    required this.fallbackPrice,
    required this.kind,
    this.grantsTier,
    this.period,
    this.coins,
    this.badge,
    this.trialDays = 0,
  });

  /// Store product identifier. Must match App Store Connect and Play Console
  /// exactly, so it is defined once here and nowhere else.
  final String id;

  final String name;
  final String blurb;

  /// Shown only until the store responds with the localised price.
  final String fallbackPrice;

  final ProductKind kind;
  final Tier? grantsTier;
  final Duration? period;
  final int? coins;

  /// Short marketing flag, e.g. "Best value".
  final String? badge;

  final int trialDays;

  bool get isSubscription => kind == ProductKind.subscription;
}

/// Subscriptions. Priced deliberately under The Pattern and Chani so the
/// monthly reads as an impulse rather than a decision, with the annual carrying
/// the margin.
const List<OmniProduct> subscriptionProducts = [
  OmniProduct(
    id: 'omni.plus.monthly',
    name: 'Monthly',
    blurb: 'Everything unlocked, cancel any time.',
    fallbackPrice: r'$7.99',
    kind: ProductKind.subscription,
    grantsTier: Tier.plus,
    period: Duration(days: 30),
    trialDays: 3,
  ),
  OmniProduct(
    id: 'omni.plus.annual',
    name: 'Annual',
    blurb: r'Works out at $3.33 a month.',
    fallbackPrice: r'$39.99',
    kind: ProductKind.subscription,
    grantsTier: Tier.plus,
    period: Duration(days: 365),
    badge: 'Save 58%',
    trialDays: 7,
  ),
  OmniProduct(
    id: 'omni.plus.lifetime',
    name: 'Lifetime',
    blurb: 'One payment. Every future reading included.',
    fallbackPrice: r'$99.99',
    kind: ProductKind.subscription,
    grantsTier: Tier.vip,
  ),
];

/// Consumables. These carry the impulse purchases that lift revenue per user
/// well above the subscription on its own.
const List<OmniProduct> coinProducts = [
  OmniProduct(
    id: 'omni.coins.60',
    name: '60 Jade Coins',
    blurb: 'One deep reading.',
    fallbackPrice: r'$1.99',
    kind: ProductKind.consumable,
    coins: 60,
  ),
  OmniProduct(
    id: 'omni.coins.180',
    name: '180 Jade Coins',
    blurb: '20% more coins per dollar.',
    fallbackPrice: r'$4.99',
    kind: ProductKind.consumable,
    coins: 180,
    badge: 'Popular',
  ),
  OmniProduct(
    id: 'omni.coins.400',
    name: '400 Jade Coins',
    blurb: '33% more coins per dollar.',
    fallbackPrice: r'$9.99',
    kind: ProductKind.consumable,
    coins: 400,
    badge: 'Best value',
  ),
];

List<OmniProduct> get allProducts => [...subscriptionProducts, ...coinProducts];

Set<String> get allProductIds => {for (final p in allProducts) p.id};

OmniProduct? productById(String id) {
  for (final product in allProducts) {
    if (product.id == id) return product;
  }
  return null;
}
