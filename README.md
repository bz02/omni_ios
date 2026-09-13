# Omni

> **Two ancient systems. One you.**
> The only app that computes your Western natal chart and your Chinese Ba Zi
> from the same birth moment, and tells you where the two disagree.

## What it is

Most astrology apps ship one tradition. Omni computes both from a single
ephemeris and reads them against each other — which is a kind of content no
single-tradition app can produce.

| | |
|---|---|
| **Today** | Energy score, the almanac's 宜/忌, lucky colour, number and direction — and the arithmetic behind the score, one tap away |
| **Chart** | Sun / Moon / Rising alongside the four pillars, five-phase balance, and the cross-system readings |
| **Timeline** | The ten-year luck pillars and the year-by-year forecast, with the starting age measured off a real solar term |
| **Oracle** | One question, three tarot cards and a cast hexagram, plus a verdict on whether the two oracles agree |
| **Match** | Compatibility scored separately by each tradition |
| **You** | Plan, Jade Coins, and how every number is worked out |

## Why the numbers are trustworthy

The differentiator is that the readings are **computed, not generated**:

- The Sun comes from a truncated **VSOP87** series with nutation, aberration and
  a Delta-T correction. Across eight published equinox, solstice and solar-term
  times the worst error is **under forty seconds**. (The first cut used Meeus'
  abbreviated series and missed by up to seven minutes.)
- The same solar longitude that places a Western Sun sign locates the
  twenty-four **solar terms**, so the Ba Zi year turns over at Start of Spring
  and the month on a real solar term — not on 1 January and not on calendar
  months. That is the thing toy implementations get wrong.
- Day pillars come off the Julian Day Number, anchored on two independently
  published dates.
- The daily score is **derived**: every point traces to a named relationship
  between the day's pillar and the user's chart, and the app shows the list.
- Charts **degrade honestly**. No birthplace drops the ascendant, no birth time
  drops the Moon and the hour pillar, and placements near a cusp are flagged
  rather than asserted.

`lib/core/engine/` is pure Dart with no Flutter dependency, and 84 tests check
it against published reference times, Meeus' worked examples, and the physical
identity that the Sun sits on the ascendant at sunrise.

## Running it

```bash
cd omni_flutter
flutter pub get
flutter run                                        # works fully offline
flutter run --dart-define=GEMINI_API_KEY=...       # adds the chat layer
flutter test                                       # 166 tests
cd ../server && node --test                        # 31 more
```

No key is required. Every reading is computed on the device; the model only
turns a computed chart into prose.

## Taking money

The web build charges through Stripe: 2.9% and days to payout, against the App
Store's 15–30% and a review queue. iOS and Android go through StoreKit and Play
Billing, because Apple rejects apps that route digital goods around them —
`chooseService()` picks by platform.

`server/` is one Cloudflare Worker covering the three things that need a server:
the model key (a client-side key is extractable), proof of payment (a purchase
recorded on a phone is a number a jailbroken device can edit), and Stripe
Checkout itself. The client sends a product id and nothing else — the price,
the tier and the coin count are all looked up server-side.

## Layout

```
omni_flutter/lib/
├── core/engine/     pure Dart, no Flutter — the calculations
│   ├── astro_math       Julian day, solar and lunar longitude, ascendant,
│   │                    and a solver for solar-term instants
│   ├── vsop87_earth     truncated VSOP87D series and Delta-T
│   ├── western_chart    Sun, Moon, Ascendant, elements, aspects
│   ├── bazi             four pillars, five phases, ten gods, na yin
│   ├── iching           64 hexagrams and three-coin casting
│   ├── tarot            the 78-card deck and four spreads
│   ├── soul_blueprint   the East/West synthesis
│   ├── daily_fortune    the derived daily score
│   ├── luck_pillars     the ten-year cycle and the annual forecast
│   └── compatibility    both traditions, scored separately
├── core/billing/    subscriptions, Jade Coins, and one gate for every feature
├── core/net/        the backend client
├── core/analytics/  the conversion funnel, provider-agnostic
├── features/        the screens
└── state/           birth record and saved people

server/              Cloudflare Worker: Stripe, entitlements, model proxy
```

## Docs

- [`docs/PRD.md`](docs/PRD.md) — positioning, competitors, feature scope,
  pricing and the unit economics
- [`docs/LAUNCH.md`](docs/LAUNCH.md) — what still needs your accounts and keys
  before this can take money

## Disclaimer

For reflection and entertainment. Not medical, legal, financial or
psychological advice.
