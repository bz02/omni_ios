/// Omni backend — a single Cloudflare Worker.
///
/// It exists to hold two secrets the client must never have (the Stripe secret
/// key and the model key) and to be the thing that decides whether someone has
/// paid. A purchase recorded on a phone is a number in shared preferences; a
/// purchase recorded here was confirmed with Stripe.
///
/// Bindings (see wrangler.toml):
///   ENTITLEMENTS   KV namespace, install id -> entitlement
///   RATE           KV namespace, short-lived request counters
/// Secrets:
///   STRIPE_SECRET_KEY, STRIPE_WEBHOOK_SECRET, GEMINI_API_KEY
/// Vars:
///   ALLOWED_ORIGIN, STRIPE_PRICE_* (one per product)

import { resolveProduct, resolveReadingKind } from './catalogue.mjs';
import {
  entitlementFromCheckout,
  FREE,
  isActiveSubscription,
  mergeEntitlements,
  secondsToIso,
  toClientEntitlement,
} from './entitlement.mjs';
import { buildPrompt } from './prompt.mjs';

const INSTALL_ID_PATTERN = /^[a-f0-9]{32}$/;

/// Readings a free user may generate per day, enforced here as well as on the
/// device. The client counter is a UX affordance; this one is the limit.
const FREE_READINGS_PER_DAY = 12;
const PLUS_READINGS_PER_DAY = 300;

export default {
  async fetch(request, env, ctx) {
    const url = new URL(request.url);

    if (request.method === 'OPTIONS') {
      return new Response(null, { status: 204, headers: cors(env) });
    }

    try {
      switch (`${request.method} ${url.pathname}`) {
        case 'POST /v1/checkout':
          return json(await createCheckout(request, env), env);
        case 'GET /v1/entitlement':
          return json(await readEntitlement(url, env), env);
        case 'POST /v1/reading':
          return json(await generateReading(request, env), env);
        case 'POST /v1/stripe-webhook':
          return await handleWebhook(request, env, ctx);
        case 'GET /v1/health':
          return json({ ok: true }, env);
        default:
          return json({ error: 'Not found' }, env, 404);
      }
    } catch (error) {
      if (error instanceof HttpError) {
        return json({ error: error.message }, env, error.status);
      }
      console.error('unhandled', error);
      return json({ error: 'Something went wrong.' }, env, 500);
    }
  },
};

class HttpError extends Error {
  constructor(status, message) {
    super(message);
    this.status = status;
  }
}

// ---------------------------------------------------------------- checkout

async function createCheckout(request, env) {
  const body = await readJson(request);
  const installId = requireInstallId(body.installId);

  const product = resolveProduct(body.productId);
  if (!product) throw new HttpError(400, 'Unknown product.');

  const price = env[product.priceEnv];
  if (!price) {
    throw new HttpError(
      500,
      `No Stripe price configured for ${body.productId}.`,
    );
  }

  const returnUrl = safeReturnUrl(body.returnUrl, env);

  const form = {
    mode: product.mode,
    'line_items[0][price]': price,
    'line_items[0][quantity]': '1',
    // Ties the payment to this install without an account.
    client_reference_id: installId,
    success_url: `${returnUrl}?session_id={CHECKOUT_SESSION_ID}`,
    cancel_url: `${returnUrl}?checkout=cancelled`,
    'metadata[installId]': installId,
    'metadata[productId]': body.productId,
  };

  if (product.mode === 'subscription') {
    form['subscription_data[metadata][installId]'] = installId;
    form['subscription_data[metadata][productId]'] = body.productId;
    if (product.trialDays) {
      form['subscription_data[trial_period_days]'] = String(product.trialDays);
    }
  }

  const session = await stripe(env, 'POST', '/v1/checkout/sessions', form);
  return { url: session.url, sessionId: session.id };
}

/// Only ever redirect back to our own origin. Echoing a client-supplied URL
/// would make this an open redirect with a Stripe receipt attached to it.
function safeReturnUrl(candidate, env) {
  const allowed = env.ALLOWED_ORIGIN;
  if (!allowed) throw new HttpError(500, 'ALLOWED_ORIGIN is not set.');
  if (!candidate) return allowed;

  let parsed;
  try {
    parsed = new URL(candidate);
  } catch {
    return allowed;
  }
  return parsed.origin === new URL(allowed).origin ? parsed.toString() : allowed;
}

// ------------------------------------------------------------- entitlement

async function readEntitlement(url, env) {
  const installId = requireInstallId(url.searchParams.get('installId'));
  const code = url.searchParams.get('code');

  const stored = await loadEntitlement(env, installId);
  let combined = stored ?? FREE;

  if (code) {
    const redeemed = await redeemCheckoutSession(env, code, installId);
    combined = mergeEntitlements(combined, redeemed);
    if (redeemed.tier !== 'free' || redeemed.jadeCoins > 0) {
      await saveEntitlement(env, installId, combined);
    }
  }

  return toClientEntitlement(combined, {
    restoreCode: combined.tier === 'free' ? null : (code ?? stored?.lastSession ?? null),
  });
}

/// Looks a Checkout Session up with Stripe and converts it to an entitlement.
///
/// The session id doubles as the restore credential: it is unguessable, and
/// possession of it is what a receipt is. That is why this reads the session
/// from Stripe every time rather than trusting anything stored alongside it.
async function redeemCheckoutSession(env, sessionId, installId) {
  let session;
  try {
    session = await stripe(
      env,
      'GET',
      `/v1/checkout/sessions/${encodeURIComponent(sessionId)}`,
    );
  } catch {
    return { ...FREE };
  }

  const productId = session.metadata?.productId;
  const product = resolveProduct(productId);
  if (!product) return { ...FREE };

  let subscription = null;
  if (product.mode === 'subscription' && session.subscription) {
    subscription = await stripe(
      env,
      'GET',
      `/v1/subscriptions/${encodeURIComponent(session.subscription)}`,
    );
  }

  const entitlement = entitlementFromCheckout(session, product, subscription);
  if (entitlement.tier !== 'free' || entitlement.jadeCoins > 0) {
    entitlement.lastSession = sessionId;
    entitlement.customerId = session.customer ?? null;
    entitlement.subscriptionId = session.subscription ?? null;
    // Bind the session to the install that redeemed it, so the same receipt
    // cannot be passed around indefinitely.
    entitlement.installId = installId;
  }
  return entitlement;
}

async function loadEntitlement(env, installId) {
  const raw = await env.ENTITLEMENTS.get(`install:${installId}`);
  if (!raw) return null;
  try {
    return JSON.parse(raw);
  } catch {
    return null;
  }
}

async function saveEntitlement(env, installId, entitlement) {
  await env.ENTITLEMENTS.put(
    `install:${installId}`,
    JSON.stringify(entitlement),
  );
  if (entitlement.subscriptionId) {
    // Reverse index so a webhook can find the install without a scan.
    await env.ENTITLEMENTS.put(
      `sub:${entitlement.subscriptionId}`,
      installId,
    );
  }
}

// ----------------------------------------------------------------- reading

async function generateReading(request, env) {
  const body = await readJson(request);
  const installId = requireInstallId(body.installId);

  const spec = resolveReadingKind(body.kind);
  if (!spec) throw new HttpError(400, 'Unknown reading kind.');

  const entitlement = toClientEntitlement(await loadEntitlement(env, installId));
  const subscribed = entitlement.tier !== 'free';

  if (spec.tier === 'plus' && !subscribed) {
    throw new HttpError(402, 'That reading is part of Omni Plus.');
  }

  const limit = subscribed ? PLUS_READINGS_PER_DAY : FREE_READINGS_PER_DAY;
  if (!(await withinRateLimit(env, installId, limit))) {
    throw new HttpError(429, 'Too many readings today. Try again tomorrow.');
  }

  if (!env.GEMINI_API_KEY) {
    throw new HttpError(503, 'No model is configured on this server.');
  }

  const prompt = buildPrompt({
    kind: body.kind,
    chart: body.chart,
    question: body.question,
  });

  const response = await fetch(
    'https://generativelanguage.googleapis.com/v1beta/models/' +
      'gemini-2.0-flash:generateContent',
    {
      method: 'POST',
      headers: {
        'content-type': 'application/json',
        'x-goog-api-key': env.GEMINI_API_KEY,
      },
      body: JSON.stringify({
        contents: [{ parts: [{ text: prompt }] }],
        generationConfig: { temperature: 0.9, maxOutputTokens: 800 },
      }),
    },
  );

  if (!response.ok) {
    console.error('model error', response.status, await response.text());
    throw new HttpError(502, 'The reading could not be generated.');
  }

  const payload = await response.json();
  const text =
    payload.candidates?.[0]?.content?.parts?.map((p) => p.text).join('') ?? '';
  return { text };
}

/// A fixed window per install per UTC day. Crude, and correct enough: the point
/// is to cap what one device can spend of the model budget, not to be fair to
/// the millisecond.
async function withinRateLimit(env, installId, limit) {
  const day = new Date().toISOString().slice(0, 10);
  const key = `rate:${installId}:${day}`;
  const current = Number((await env.RATE.get(key)) ?? '0');
  if (current >= limit) return false;
  await env.RATE.put(key, String(current + 1), { expirationTtl: 60 * 60 * 36 });
  return true;
}

// ----------------------------------------------------------------- webhook

async function handleWebhook(request, env, ctx) {
  const signature = request.headers.get('stripe-signature');
  const payload = await request.text();

  if (!(await verifyStripeSignature(payload, signature, env.STRIPE_WEBHOOK_SECRET))) {
    return new Response('Bad signature', { status: 400 });
  }

  const event = JSON.parse(payload);
  ctx.waitUntil(applyWebhook(event, env));
  return new Response('ok', { status: 200 });
}

async function applyWebhook(event, env) {
  const object = event.data?.object;
  if (!object) return;

  switch (event.type) {
    case 'checkout.session.completed': {
      const installId = object.metadata?.installId;
      if (installId) await redeemAndStore(env, object.id, installId);
      break;
    }
    case 'customer.subscription.updated':
    case 'customer.subscription.deleted': {
      const installId =
        object.metadata?.installId ??
        (await env.ENTITLEMENTS.get(`sub:${object.id}`));
      if (!installId) break;

      const stored = (await loadEntitlement(env, installId)) ?? { ...FREE };
      if (isActiveSubscription(object.status)) {
        stored.expiresAt = secondsToIso(object.current_period_end);
      } else {
        stored.tier = 'free';
        stored.expiresAt = null;
      }
      await saveEntitlement(env, installId, stored);
      break;
    }
    default:
      break;
  }
}

async function redeemAndStore(env, sessionId, installId) {
  const redeemed = await redeemCheckoutSession(env, sessionId, installId);
  const stored = await loadEntitlement(env, installId);
  await saveEntitlement(env, installId, mergeEntitlements(stored, redeemed));
}

/// Verifies Stripe's `t=...,v1=...` header.
///
/// Without this, anyone who finds the webhook URL can post themselves a
/// lifetime subscription.
export async function verifyStripeSignature(payload, header, secret, nowSeconds) {
  if (!header || !secret) return false;

  const parts = Object.fromEntries(
    header.split(',').map((part) => {
      const index = part.indexOf('=');
      return [part.slice(0, index), part.slice(index + 1)];
    }),
  );
  if (!parts.t || !parts.v1) return false;

  // Reject replays of an old, legitimately signed payload.
  const now = nowSeconds ?? Math.floor(Date.now() / 1000);
  if (Math.abs(now - Number(parts.t)) > 300) return false;

  const key = await crypto.subtle.importKey(
    'raw',
    new TextEncoder().encode(secret),
    { name: 'HMAC', hash: 'SHA-256' },
    false,
    ['sign'],
  );
  const signed = await crypto.subtle.sign(
    'HMAC',
    key,
    new TextEncoder().encode(`${parts.t}.${payload}`),
  );
  const expected = [...new Uint8Array(signed)]
    .map((b) => b.toString(16).padStart(2, '0'))
    .join('');

  return timingSafeEqual(expected, parts.v1);
}

function timingSafeEqual(a, b) {
  if (a.length !== b.length) return false;
  let diff = 0;
  for (let i = 0; i < a.length; i++) diff |= a.charCodeAt(i) ^ b.charCodeAt(i);
  return diff === 0;
}

// ------------------------------------------------------------------ shared

async function stripe(env, method, path, form) {
  if (!env.STRIPE_SECRET_KEY) {
    throw new HttpError(500, 'Stripe is not configured on this server.');
  }

  const response = await fetch(`https://api.stripe.com${path}`, {
    method,
    headers: {
      authorization: `Bearer ${env.STRIPE_SECRET_KEY}`,
      'content-type': 'application/x-www-form-urlencoded',
    },
    body: form ? new URLSearchParams(form).toString() : undefined,
  });

  const payload = await response.json();
  if (!response.ok) {
    console.error('stripe error', payload);
    throw new HttpError(502, payload.error?.message ?? 'Payment error.');
  }
  return payload;
}

async function readJson(request) {
  try {
    return await request.json();
  } catch {
    throw new HttpError(400, 'Expected a JSON body.');
  }
}

function requireInstallId(value) {
  if (typeof value !== 'string' || !INSTALL_ID_PATTERN.test(value)) {
    throw new HttpError(400, 'Missing or malformed install id.');
  }
  return value;
}

function cors(env) {
  return {
    'access-control-allow-origin': env.ALLOWED_ORIGIN ?? '*',
    'access-control-allow-methods': 'GET,POST,OPTIONS',
    'access-control-allow-headers': 'content-type',
    'access-control-max-age': '86400',
  };
}

function json(body, env, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { 'content-type': 'application/json', ...cors(env) },
  });
}
