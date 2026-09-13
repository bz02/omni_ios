/// Tests for the backend.
///
/// This is the code that decides who has paid and who has not, so the cases
/// that matter are the adversarial ones: a forged webhook, a replayed one, a
/// client naming a price, a redirect pointed at somebody else's domain.

import assert from 'node:assert/strict';
import test from 'node:test';

import worker, { verifyStripeSignature } from './worker.mjs';
import { resolveProduct, PRODUCTS } from './catalogue.mjs';
import {
  entitlementFromCheckout,
  isActiveSubscription,
  isExpired,
  mergeEntitlements,
  toClientEntitlement,
} from './entitlement.mjs';
import { buildPrompt, MAX_QUESTION_LENGTH } from './prompt.mjs';

const INSTALL = 'a'.repeat(32);

function kv(initial = {}) {
  const store = new Map(Object.entries(initial));
  return {
    store,
    get: async (key) => store.get(key) ?? null,
    put: async (key, value) => void store.set(key, value),
    delete: async (key) => void store.delete(key),
  };
}

function makeEnv(overrides = {}) {
  return {
    ENTITLEMENTS: kv(),
    RATE: kv(),
    STRIPE_SECRET_KEY: 'sk_test_123',
    STRIPE_WEBHOOK_SECRET: 'whsec_test',
    GEMINI_API_KEY: 'model-key',
    ALLOWED_ORIGIN: 'https://omni.example',
    STRIPE_PRICE_MONTHLY: 'price_monthly',
    STRIPE_PRICE_ANNUAL: 'price_annual',
    STRIPE_PRICE_LIFETIME: 'price_lifetime',
    STRIPE_PRICE_COINS_60: 'price_coins_60',
    STRIPE_PRICE_COINS_180: 'price_coins_180',
    STRIPE_PRICE_COINS_400: 'price_coins_400',
    ...overrides,
  };
}

/// Collects the promises the worker hands to waitUntil so a test can wait for
/// background work. Cloudflare keeps the isolate alive for them; a stub that
/// drops them makes webhook handling look like it silently did nothing.
function makeCtx() {
  const pending = [];
  return {
    ctx: { waitUntil: (promise) => pending.push(promise) },
    settle: () => Promise.all(pending),
  };
}

/// An explicit non-200 from a stubbed endpoint.
///
/// A marker class rather than a `{status, body}` object on purpose: Stripe's
/// own subscription payload has a `status` field, and treating that as an HTTP
/// status quietly turned `status: 'active'` into an invalid Response.
class StubResponse {
  constructor(status, body) {
    this.status = status;
    this.body = body;
  }
}

/// Replaces global fetch with a router over [routes], recording every call.
function stubFetch(routes) {
  const calls = [];
  globalThis.fetch = async (url, init = {}) => {
    const href = typeof url === 'string' ? url : url.toString();
    calls.push({ href, init });
    for (const [pattern, respond] of routes) {
      if (href.includes(pattern)) {
        const result = await respond(init, href);
        const stubbed =
          result instanceof StubResponse
            ? result
            : new StubResponse(200, result);
        return new Response(JSON.stringify(stubbed.body), {
          status: stubbed.status,
          headers: { 'content-type': 'application/json' },
        });
      }
    }
    throw new Error(`Unstubbed fetch: ${href}`);
  };
  return calls;
}

function post(path, body) {
  return new Request(`https://api.omni.example${path}`, {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify(body),
  });
}

function get(path) {
  return new Request(`https://api.omni.example${path}`);
}

// -------------------------------------------------------------- catalogue

test('the catalogue only answers for products it defines', () => {
  assert.equal(resolveProduct('omni.plus.monthly').tier, 'plus');
  assert.equal(resolveProduct('omni.coins.180').coins, 180);
  assert.equal(resolveProduct('omni.free.everything'), null);
  assert.equal(resolveProduct('__proto__'), null);
  assert.equal(resolveProduct('constructor'), null);
});

test('every product names a price environment variable', () => {
  for (const [id, product] of Object.entries(PRODUCTS)) {
    assert.ok(product.priceEnv, `${id} has no priceEnv`);
    assert.ok(
      product.mode === 'subscription' || product.mode === 'payment',
      `${id} has an odd mode`,
    );
  }
});

// ------------------------------------------------------------ entitlement

test('an unpaid session grants nothing', () => {
  const result = entitlementFromCheckout(
    { payment_status: 'unpaid' },
    PRODUCTS['omni.plus.monthly'],
    { status: 'active' },
  );
  assert.equal(result.tier, 'free');
});

test('a trialing subscription is active', () => {
  assert.ok(isActiveSubscription('trialing'));
  assert.ok(isActiveSubscription('active'));
  // Still retrying the card: locking them out now loses a recoverable payment.
  assert.ok(isActiveSubscription('past_due'));
  assert.ok(!isActiveSubscription('canceled'));
  assert.ok(!isActiveSubscription('incomplete_expired'));
});

test('a subscription checkout carries the period end', () => {
  const end = Math.floor(Date.UTC(2027, 0, 1) / 1000);
  const result = entitlementFromCheckout(
    { payment_status: 'paid' },
    PRODUCTS['omni.plus.annual'],
    { status: 'active', current_period_end: end },
  );
  assert.equal(result.tier, 'plus');
  assert.equal(result.expiresAt, '2027-01-01T00:00:00.000Z');
});

test('a coin pack grants coins and no tier', () => {
  const result = entitlementFromCheckout(
    { payment_status: 'paid' },
    PRODUCTS['omni.coins.400'],
    null,
  );
  assert.equal(result.tier, 'free');
  assert.equal(result.jadeCoins, 400);
});

test('lifetime grants vip with no expiry', () => {
  const result = entitlementFromCheckout(
    { payment_status: 'paid' },
    PRODUCTS['omni.plus.lifetime'],
    null,
  );
  assert.equal(result.tier, 'vip');
  assert.equal(result.expiresAt, null);
});

test('merging keeps the better tier, the longer expiry and all the coins', () => {
  const merged = mergeEntitlements(
    { tier: 'plus', expiresAt: '2027-01-01T00:00:00.000Z', jadeCoins: 60 },
    { tier: 'plus', expiresAt: '2027-06-01T00:00:00.000Z', jadeCoins: 180 },
  );
  assert.equal(merged.expiresAt, '2027-06-01T00:00:00.000Z');
  assert.equal(merged.jadeCoins, 240);

  const withLifetime = mergeEntitlements(
    { tier: 'plus', expiresAt: '2027-01-01T00:00:00.000Z', jadeCoins: 0 },
    { tier: 'vip', expiresAt: null, jadeCoins: 0 },
  );
  assert.equal(withLifetime.tier, 'vip');
  assert.equal(withLifetime.expiresAt, null, 'lifetime beats any date');
});

test('an expired subscription reads as free but keeps its coins', () => {
  const lapsed = {
    tier: 'plus',
    expiresAt: '2020-01-01T00:00:00.000Z',
    jadeCoins: 60,
  };
  assert.ok(isExpired(lapsed));
  const client = toClientEntitlement(lapsed);
  assert.equal(client.tier, 'free');
  assert.equal(client.jadeCoins, 60);
});

test('the client is never told the Stripe ids', () => {
  const client = toClientEntitlement({
    tier: 'plus',
    expiresAt: '2099-01-01T00:00:00.000Z',
    jadeCoins: 0,
    customerId: 'cus_secret',
    subscriptionId: 'sub_secret',
  });
  assert.ok(!('customerId' in client));
  assert.ok(!('subscriptionId' in client));
});

// ---------------------------------------------------------------- prompts

test('the prompt embeds the chart and caps the question', () => {
  const prompt = buildPrompt({
    kind: 'chat',
    chart: { sun: '12 Cancer' },
    question: 'x'.repeat(MAX_QUESTION_LENGTH + 500),
  });
  assert.ok(prompt.includes('12 Cancer'));
  const quoted = prompt.split('"""')[1];
  assert.equal(quoted.length, MAX_QUESTION_LENGTH);
});

test('the prompt tells the model not to obey the question', () => {
  const prompt = buildPrompt({ kind: 'chat', chart: {}, question: 'hi' });
  assert.ok(prompt.includes('not direction to obey'));
});

test('an unknown reading kind is refused', () => {
  assert.throws(() => buildPrompt({ kind: 'anything', chart: {} }));
});

// --------------------------------------------------------------- checkout

test('checkout sends our price, never the client’s', async () => {
  const calls = stubFetch([
    ['/v1/checkout/sessions', () => ({ id: 'cs_1', url: 'https://stripe/pay' })],
  ]);

  const response = await worker.fetch(
    post('/v1/checkout', {
      installId: INSTALL,
      productId: 'omni.plus.annual',
      returnUrl: 'https://omni.example/done',
      // A modified client trying to set its own terms.
      price: 'price_free',
      amount: 0,
      tier: 'vip',
    }),
    makeEnv(),
    makeCtx().ctx,
  );

  assert.equal(response.status, 200);
  assert.equal((await response.json()).url, 'https://stripe/pay');

  const sent = new URLSearchParams(calls[0].init.body);
  assert.equal(sent.get('line_items[0][price]'), 'price_annual');
  assert.equal(sent.get('mode'), 'subscription');
  assert.equal(sent.get('client_reference_id'), INSTALL);
  assert.equal(sent.get('subscription_data[trial_period_days]'), '7');
  assert.ok(!calls[0].init.body.includes('price_free'));
});

test('checkout refuses an unknown product', async () => {
  stubFetch([]);
  const response = await worker.fetch(
    post('/v1/checkout', { installId: INSTALL, productId: 'omni.free.all' }),
    makeEnv(),
    makeCtx().ctx,
  );
  assert.equal(response.status, 400);
});

test('checkout refuses a malformed install id', async () => {
  stubFetch([]);
  for (const bad of ['', 'abc', null, 42, 'z'.repeat(32), `${INSTALL}extra`]) {
    const response = await worker.fetch(
      post('/v1/checkout', { installId: bad, productId: 'omni.plus.monthly' }),
      makeEnv(),
      makeCtx().ctx,
    );
    assert.equal(response.status, 400, `accepted ${bad}`);
  }
});

test('a return URL on another origin is replaced with ours', async () => {
  const calls = stubFetch([
    ['/v1/checkout/sessions', () => ({ id: 'cs_1', url: 'https://stripe/pay' })],
  ]);

  await worker.fetch(
    post('/v1/checkout', {
      installId: INSTALL,
      productId: 'omni.plus.monthly',
      returnUrl: 'https://evil.example/steal',
    }),
    makeEnv(),
    makeCtx().ctx,
  );

  const sent = new URLSearchParams(calls[0].init.body);
  assert.ok(sent.get('success_url').startsWith('https://omni.example'));
  assert.ok(!sent.get('success_url').includes('evil.example'));
});

// ------------------------------------------------------------ entitlement

test('an unknown install is free', async () => {
  stubFetch([]);
  const response = await worker.fetch(
    get(`/v1/entitlement?installId=${INSTALL}`),
    makeEnv(),
    makeCtx().ctx,
  );
  const body = await response.json();
  assert.equal(body.tier, 'free');
  assert.equal(body.jadeCoins, 0);
});

test('a valid session id redeems into a stored entitlement', async () => {
  const end = Math.floor(Date.UTC(2030, 0, 1) / 1000);
  stubFetch([
    [
      '/v1/checkout/sessions/cs_paid',
      () => ({
        id: 'cs_paid',
        payment_status: 'paid',
        subscription: 'sub_1',
        customer: 'cus_1',
        metadata: { installId: INSTALL, productId: 'omni.plus.annual' },
      }),
    ],
    [
      '/v1/subscriptions/sub_1',
      () => ({ status: 'active', current_period_end: end }),
    ],
  ]);

  const env = makeEnv();
  const response = await worker.fetch(
    get(`/v1/entitlement?installId=${INSTALL}&code=cs_paid`),
    env,
    makeCtx().ctx,
  );

  const body = await response.json();
  assert.equal(body.tier, 'plus');
  assert.equal(body.expiresAt, '2030-01-01T00:00:00.000Z');

  // Stored, so the next call needs no code.
  const stored = JSON.parse(env.ENTITLEMENTS.store.get(`install:${INSTALL}`));
  assert.equal(stored.tier, 'plus');
  // The reverse index is what lets a later cancellation webhook find this
  // install. Without it the subscription could never be revoked.
  assert.equal(env.ENTITLEMENTS.store.get('sub:sub_1'), INSTALL);
  assert.equal(stored.subscriptionId, 'sub_1');
});

test('a session Stripe does not recognise grants nothing', async () => {
  stubFetch([
    ['/v1/checkout/sessions/', () => new StubResponse(404, { error: {} })],
  ]);
  const response = await worker.fetch(
    get(`/v1/entitlement?installId=${INSTALL}&code=cs_made_up`),
    makeEnv(),
    makeCtx().ctx,
  );
  assert.equal((await response.json()).tier, 'free');
});

// ----------------------------------------------------------------- reading

test('a plus-only reading is refused for a free install', async () => {
  stubFetch([]);
  const response = await worker.fetch(
    post('/v1/reading', {
      installId: INSTALL,
      kind: 'blueprint',
      chart: {},
    }),
    makeEnv(),
    makeCtx().ctx,
  );
  assert.equal(response.status, 402);
});

test('a free reading reaches the model and returns its text', async () => {
  const calls = stubFetch([
    [
      'generativelanguage',
      () => ({ candidates: [{ content: { parts: [{ text: 'A reading.' }] } }] }),
    ],
  ]);

  const response = await worker.fetch(
    post('/v1/reading', {
      installId: INSTALL,
      kind: 'daily',
      chart: { dayPillar: '戊午' },
    }),
    makeEnv(),
    makeCtx().ctx,
  );

  assert.equal((await response.json()).text, 'A reading.');
  // The key travels in a header from the server, never from the client.
  assert.equal(calls[0].init.headers['x-goog-api-key'], 'model-key');
  assert.ok(calls[0].init.body.includes('戊午'));
});

test('a free install is rate limited within the day', async () => {
  stubFetch([
    [
      'generativelanguage',
      () => ({ candidates: [{ content: { parts: [{ text: 'ok' }] } }] }),
    ],
  ]);
  const env = makeEnv();

  let lastStatus = 0;
  for (let i = 0; i < 14; i++) {
    const response = await worker.fetch(
      post('/v1/reading', { installId: INSTALL, kind: 'daily', chart: {} }),
      env,
      makeCtx().ctx,
    );
    lastStatus = response.status;
  }
  assert.equal(lastStatus, 429);
});

// ----------------------------------------------------------------- webhook

async function sign(payload, secret, timestamp) {
  const key = await crypto.subtle.importKey(
    'raw',
    new TextEncoder().encode(secret),
    { name: 'HMAC', hash: 'SHA-256' },
    false,
    ['sign'],
  );
  const mac = await crypto.subtle.sign(
    'HMAC',
    key,
    new TextEncoder().encode(`${timestamp}.${payload}`),
  );
  const hex = [...new Uint8Array(mac)]
    .map((b) => b.toString(16).padStart(2, '0'))
    .join('');
  return `t=${timestamp},v1=${hex}`;
}

test('a correctly signed webhook verifies', async () => {
  const now = Math.floor(Date.now() / 1000);
  const payload = JSON.stringify({ type: 'ping' });
  const header = await sign(payload, 'whsec_test', now);
  assert.ok(await verifyStripeSignature(payload, header, 'whsec_test', now));
});

test('a forged signature is rejected', async () => {
  const now = Math.floor(Date.now() / 1000);
  const payload = JSON.stringify({ type: 'ping' });
  const header = await sign(payload, 'the_wrong_secret', now);
  assert.ok(!(await verifyStripeSignature(payload, header, 'whsec_test', now)));
});

test('an old but genuine signature is rejected as a replay', async () => {
  const then = Math.floor(Date.now() / 1000) - 4000;
  const payload = JSON.stringify({ type: 'ping' });
  const header = await sign(payload, 'whsec_test', then);
  assert.ok(!(await verifyStripeSignature(payload, header, 'whsec_test')));
});

test('a webhook with no signature is refused', async () => {
  stubFetch([]);
  const response = await worker.fetch(
    new Request('https://api.omni.example/v1/stripe-webhook', {
      method: 'POST',
      body: JSON.stringify({ type: 'checkout.session.completed' }),
    }),
    makeEnv(),
    makeCtx().ctx,
  );
  assert.equal(response.status, 400);
});

test('a cancelled subscription drops the install back to free', async () => {
  stubFetch([]);
  const env = makeEnv();
  env.ENTITLEMENTS.store.set(
    `install:${INSTALL}`,
    JSON.stringify({
      tier: 'plus',
      expiresAt: '2030-01-01T00:00:00.000Z',
      jadeCoins: 0,
      subscriptionId: 'sub_1',
    }),
  );
  env.ENTITLEMENTS.store.set('sub:sub_1', INSTALL);

  const payload = JSON.stringify({
    type: 'customer.subscription.deleted',
    data: { object: { id: 'sub_1', status: 'canceled' } },
  });
  const now = Math.floor(Date.now() / 1000);

  const { ctx, settle } = makeCtx();
  const response = await worker.fetch(
    new Request('https://api.omni.example/v1/stripe-webhook', {
      method: 'POST',
      headers: { 'stripe-signature': await sign(payload, 'whsec_test', now) },
      body: payload,
    }),
    env,
    ctx,
  );

  assert.equal(response.status, 200);
  // The worker acknowledges Stripe immediately and finishes the write in the
  // background, so wait for it before reading the store.
  await settle();
  const stored = JSON.parse(env.ENTITLEMENTS.store.get(`install:${INSTALL}`));
  assert.equal(stored.tier, 'free');
});

test('a subscription redeemed by code can still be revoked later', async () => {
  // The regression this guards: merging the redeemed entitlement into the
  // stored one used to drop the Stripe subscription id, so the cancellation
  // webhook had no way back to this install and the user kept full access.
  const end = Math.floor(Date.UTC(2030, 0, 1) / 1000);
  stubFetch([
    [
      '/v1/checkout/sessions/cs_paid',
      () => ({
        id: 'cs_paid',
        payment_status: 'paid',
        subscription: 'sub_9',
        customer: 'cus_9',
        metadata: { installId: INSTALL, productId: 'omni.plus.monthly' },
      }),
    ],
    [
      '/v1/subscriptions/sub_9',
      () => ({ status: 'active', current_period_end: end }),
    ],
  ]);

  const env = makeEnv();
  const redeemed = await worker.fetch(
    get(`/v1/entitlement?installId=${INSTALL}&code=cs_paid`),
    env,
    makeCtx().ctx,
  );
  assert.equal((await redeemed.json()).tier, 'plus');

  const payload = JSON.stringify({
    type: 'customer.subscription.deleted',
    data: { object: { id: 'sub_9', status: 'canceled' } },
  });
  const now = Math.floor(Date.now() / 1000);
  const { ctx: hookCtx, settle } = makeCtx();
  await worker.fetch(
    new Request('https://api.omni.example/v1/stripe-webhook', {
      method: 'POST',
      headers: { 'stripe-signature': await sign(payload, 'whsec_test', now) },
      body: payload,
    }),
    env,
    hookCtx,
  );
  await settle();

  const after = await worker.fetch(
    get(`/v1/entitlement?installId=${INSTALL}`),
    env,
    makeCtx().ctx,
  );
  assert.equal((await after.json()).tier, 'free');
});

// -------------------------------------------------------------------- misc

test('CORS is restricted to the configured origin', async () => {
  stubFetch([]);
  const response = await worker.fetch(
    new Request('https://api.omni.example/v1/health', { method: 'OPTIONS' }),
    makeEnv(),
    makeCtx().ctx,
  );
  assert.equal(
    response.headers.get('access-control-allow-origin'),
    'https://omni.example',
  );
});

test('an unknown route is a 404, not a crash', async () => {
  stubFetch([]);
  const response = await worker.fetch(get('/v1/nope'), makeEnv(), makeCtx().ctx);
  assert.equal(response.status, 404);
});
