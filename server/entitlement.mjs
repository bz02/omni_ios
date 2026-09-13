/// Turning Stripe's view of the world into the app's.
///
/// Kept as pure functions with no network and no Cloudflare bindings so they
/// can be tested directly — this is the code that decides whether somebody is
/// a paying customer, and it is not a thing to find out about in production.

/// Subscription statuses that should unlock the app.
///
/// `past_due` is deliberately included: the card failed but Stripe is still
/// retrying, and locking a paying customer out during the retry window turns a
/// recoverable payment into a cancellation.
const ACTIVE_SUBSCRIPTION_STATUSES = new Set([
  'active',
  'trialing',
  'past_due',
]);

export function isActiveSubscription(status) {
  return ACTIVE_SUBSCRIPTION_STATUSES.has(status);
}

export const FREE = { tier: 'free', expiresAt: null, jadeCoins: 0 };

/// Builds an entitlement from a completed Checkout Session and, for
/// subscriptions, the subscription it created.
export function entitlementFromCheckout(session, product, subscription) {
  if (!session || session.payment_status === 'unpaid') return { ...FREE };

  if (product.mode === 'subscription') {
    if (!subscription || !isActiveSubscription(subscription.status)) {
      return { ...FREE };
    }
    return {
      tier: product.tier,
      // Stripe reports seconds; the client speaks ISO 8601.
      expiresAt: secondsToIso(subscription.current_period_end),
      jadeCoins: 0,
    };
  }

  // One-off payments: either lifetime access or a coin pack.
  if (session.payment_status !== 'paid') return { ...FREE };

  if (product.coins) {
    return { tier: 'free', expiresAt: null, jadeCoins: product.coins };
  }
  return { tier: product.tier, expiresAt: null, jadeCoins: 0 };
}

export function secondsToIso(seconds) {
  if (!seconds && seconds !== 0) return null;
  return new Date(seconds * 1000).toISOString();
}

/// Combines what is stored for an install with anything a restore code proves.
///
/// Coins add up across purchases; the tier is whichever is highest, and the
/// expiry is whichever runs longest. A user who bought a month and then a year
/// should not lose the year because the month is listed first.
export function mergeEntitlements(a, b) {
  const left = a ?? FREE;
  const right = b ?? FREE;

  const rank = { free: 0, plus: 1, vip: 2 };
  const tier = rank[right.tier] > rank[left.tier] ? right.tier : left.tier;

  let expiresAt = null;
  if (tier !== 'free') {
    const candidates = [left, right]
      .filter((e) => e.tier !== 'free')
      .map((e) => e.expiresAt);
    // A null expiry on an active tier means lifetime, which beats any date.
    expiresAt = candidates.includes(null)
      ? null
      : candidates.sort().at(-1) ?? null;
  }

  // Carry the Stripe linkage through. Dropping it here meant a subscription
  // redeemed via the entitlement endpoint had no reverse index, so when it was
  // later canceled the webhook could not find the install to revoke — the
  // subscription stayed unlocked forever.
  const linkage = {};
  for (const key of ['customerId', 'subscriptionId', 'lastSession', 'installId']) {
    const value = right[key] ?? left[key] ?? null;
    if (value) linkage[key] = value;
  }

  return {
    tier,
    expiresAt,
    jadeCoins: (left.jadeCoins ?? 0) + (right.jadeCoins ?? 0),
    ...linkage,
  };
}

/// Has a stored entitlement lapsed?
export function isExpired(entitlement, now = new Date()) {
  if (!entitlement || entitlement.tier === 'free') return false;
  if (!entitlement.expiresAt) return false;
  return new Date(entitlement.expiresAt) < now;
}

/// What the client is told. Never leaks the Stripe customer or subscription id.
export function toClientEntitlement(entitlement, extras = {}) {
  const effective = isExpired(entitlement)
    ? { ...FREE, jadeCoins: entitlement.jadeCoins ?? 0 }
    : entitlement ?? FREE;

  return {
    tier: effective.tier,
    expiresAt: effective.expiresAt ?? null,
    jadeCoins: effective.jadeCoins ?? 0,
    ...extras,
  };
}
