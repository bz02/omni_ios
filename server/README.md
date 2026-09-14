# Omni backend

One Cloudflare Worker. It exists because three launch blockers all need a
server, and one server solves all three:

| Blocker | Why a server |
|---|---|
| The model key | A key compiled into a client can be extracted by anyone who downloads the app. Here it never ships. |
| Proof of payment | A purchase recorded on a phone is a number in shared preferences. This asks Stripe. |
| Taking money on the web | There is no `in_app_purchase` for web, and Stripe Checkout needs a secret key to create a session. |

## Endpoints

| | |
|---|---|
| `POST /v1/checkout` | `{installId, productId, returnUrl}` → a Stripe Checkout URL. The client names a **product**, never a price. |
| `GET /v1/entitlement` | `?installId=&code=` → the authoritative tier, expiry and coin balance. |
| `POST /v1/reading` | `{installId, kind, chart, question}` → model text. The prompt is assembled here. |
| `POST /v1/stripe-webhook` | Subscription lifecycle. Signature-verified, replay-windowed. |

## Setup

```bash
npm install
npx wrangler kv:namespace create ENTITLEMENTS
npx wrangler kv:namespace create RATE
# put the two ids into wrangler.toml

npx wrangler secret put STRIPE_SECRET_KEY
npx wrangler secret put STRIPE_WEBHOOK_SECRET
npx wrangler secret put GEMINI_API_KEY

npm test          # 31 tests, no network
npx wrangler deploy
```

In the Stripe dashboard create one price per product id in `catalogue.mjs`,
put those price ids in `wrangler.toml`, and point a webhook at
`/v1/stripe-webhook` for `checkout.session.completed`,
`customer.subscription.updated` and `customer.subscription.deleted`.

Then build the client against it:

```bash
flutter build web --release \
  --dart-define=OMNI_API_BASE_URL=https://omni-api.<you>.workers.dev \
  --dart-define=OMNI_WEB_RETURN_URL=https://omni.example
```

## Design notes

**The client is never trusted with anything that costs money.** It sends a
product id; the price, the mode, the tier and the coin count are all looked up
here. A modified client can pick which product to buy and nothing else.

**The session id is the receipt.** Checkout is anonymous — no sign-up before a
user has seen a reading — so the unguessable Stripe session id is what proves
a purchase and what moves it to a second device. Every redemption re-reads the
session from Stripe rather than trusting anything stored next to it.

**`past_due` still unlocks the app.** The card failed and Stripe is retrying;
locking a paying customer out during the retry window converts a recoverable
payment into a cancellation.

**Rate limits are enforced here as well as on the device.** The client's free
counter is a UX affordance. This one is the limit, and it is what stops one
install from spending the whole model budget.

## Known limitation

Losing the device without keeping the restore code strands the subscription
until someone looks it up in Stripe by hand. Magic-link email is the fix and is
the first thing to add once there is revenue worth protecting.
