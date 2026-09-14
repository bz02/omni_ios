/// The product catalogue, mirroring `lib/core/billing/products.dart`.
///
/// The client sends a product id and nothing else. It never sends a price, a
/// tier, or a coin count: anything the client can name, a modified client can
/// name differently, so the only thing it is allowed to choose is *which* of
/// our products to buy.
///
/// Stripe price ids live in the environment rather than here, so the same
/// worker code runs against test and live keys without edits.

export const PRODUCTS = {
  'omni.plus.monthly': {
    mode: 'subscription',
    tier: 'plus',
    priceEnv: 'STRIPE_PRICE_MONTHLY',
    trialDays: 3,
  },
  'omni.plus.annual': {
    mode: 'subscription',
    tier: 'plus',
    priceEnv: 'STRIPE_PRICE_ANNUAL',
    trialDays: 7,
  },
  'omni.plus.lifetime': {
    mode: 'payment',
    tier: 'vip',
    priceEnv: 'STRIPE_PRICE_LIFETIME',
  },
  'omni.coins.60': {
    mode: 'payment',
    coins: 60,
    priceEnv: 'STRIPE_PRICE_COINS_60',
  },
  'omni.coins.180': {
    mode: 'payment',
    coins: 180,
    priceEnv: 'STRIPE_PRICE_COINS_180',
  },
  'omni.coins.400': {
    mode: 'payment',
    coins: 400,
    priceEnv: 'STRIPE_PRICE_COINS_400',
  },
};

export function resolveProduct(productId) {
  return Object.prototype.hasOwnProperty.call(PRODUCTS, productId)
    ? PRODUCTS[productId]
    : null;
}

/// The reading kinds the proxy will generate. An open-ended prompt field would
/// turn this endpoint into a free general-purpose model for anyone who found
/// the URL, so the client picks a kind and supplies a chart, and the prompt is
/// assembled here.
export const READING_KINDS = {
  blueprint: {
    tier: 'plus',
    instruction:
      'Write a personality reading from these two charts. Name where the ' +
      'Western chart and the Ba Zi agree and where they contradict each ' +
      'other, and say what that contradiction feels like from the inside. ' +
      'Around 300 words, warm but not flattering, no hedging.',
  },
  daily: {
    tier: 'free',
    instruction:
      'Write two sentences on what today asks of this person, using the ' +
      'score factors given. Concrete, not mystical filler.',
  },
  oracle: {
    tier: 'free',
    instruction:
      'Read these tarot cards and this hexagram together as answers to the ' +
      "same question. Say plainly where they agree and where they don't. " +
      'Around 200 words.',
  },
  compatibility: {
    tier: 'plus',
    instruction:
      'Read this pairing. The two traditions scored it separately; if they ' +
      'disagree, that disagreement is the most interesting thing here and ' +
      'should lead. Around 250 words.',
  },
  chat: {
    tier: 'free',
    instruction:
      "Answer the question against this person's charts. Reference actual " +
      'placements rather than generic astrology. Under 150 words.',
  },
};

export function resolveReadingKind(kind) {
  return Object.prototype.hasOwnProperty.call(READING_KINDS, kind)
    ? READING_KINDS[kind]
    : null;
}
