/// Account, subscription state, and the disclosures the app has to carry.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_config.dart';
import '../../core/billing/entitlements.dart';
import '../../core/billing/products.dart';
import '../../core/billing/purchase_service.dart';
import '../../core/theme/modern_theme.dart';
import '../../screens/chat_screen.dart';
import '../../state/profile_controller.dart';
import '../onboarding/birth_form_screen.dart';
import '../paywall/paywall_screen.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileController>();
    final entitlements = context.watch<EntitlementsController>();
    final blueprint = profile.blueprint;

    return Scaffold(
      appBar: AppBar(title: const Text('You')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          if (blueprint != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: ModernTheme.ink,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(blueprint.signature,
                      style: ModernTheme.subHeader
                          .copyWith(color: Colors.white, fontSize: 17)),
                  const SizedBox(height: 8),
                  Text(
                    '${blueprint.birth.placeName ?? 'Unknown place'} · '
                    '${blueprint.birth.localDateTime.toIso8601String().split('T').first}',
                    style: ModernTheme.caption
                        .copyWith(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          _SubscriptionCard(entitlements: entitlements),
          const SizedBox(height: 16),
          _CoinCard(entitlements: entitlements),
          const SizedBox(height: 24),
          _Section(title: 'Readings', children: [
            _Tile(
              icon: Icons.chat_bubble_outline,
              label: 'Ask about your chart',
              subtitle: AppConfig.hasModelAccess
                  ? 'Conversational reading, grounded in your two charts'
                  : 'Needs a model key in this build',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ChatScreen()),
              ),
            ),
            _Tile(
              icon: Icons.cake_outlined,
              label: 'Birth details',
              subtitle: 'Everything is recomputed when you change these',
              onTap: () async {
                final birth = await Navigator.of(context).push(
                  MaterialPageRoute<dynamic>(
                    builder: (_) => BirthFormScreen(initial: profile.birth),
                  ),
                );
                if (birth != null && context.mounted) {
                  await context.read<ProfileController>().setBirth(birth);
                }
              },
            ),
          ]),
          const SizedBox(height: 16),
          _Section(title: 'Purchases', children: [
            _Tile(
              icon: Icons.restore,
              label: 'Restore purchases',
              subtitle: 'If you have subscribed before on this Apple ID',
              onTap: () async {
                final result =
                    await context.read<PurchaseService>().restore();
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      context.read<EntitlementsController>().isSubscribed
                          ? 'Restored.'
                          : result.message ?? 'Nothing to restore.',
                    ),
                  ),
                );
              },
            ),
          ]),
          const SizedBox(height: 16),
          _Section(title: 'About', children: [
            _Tile(
              icon: Icons.calculate_outlined,
              label: 'How the numbers are worked out',
              subtitle: 'Real ephemeris, real solar terms, no dice',
              onTap: () => _showMethod(context),
            ),
            const _Tile(
              icon: Icons.info_outline,
              label: 'Version',
              subtitle: AppConfig.appVersion,
              onTap: null,
            ),
          ]),
          const SizedBox(height: 24),
          // Required for an App Store listing in this category, and honest
          // besides.
          Text(
            'Omni is for reflection and entertainment. It is not medical, '
            'legal, financial or psychological advice, and no reading here '
            'should stand in for a professional you would otherwise consult.',
            style: ModernTheme.caption.copyWith(fontSize: 12),
          ),
        ],
      ),
    );
  }

  void _showMethod(BuildContext context) => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (_) => DraggableScrollableSheet(
          initialChildSize: 0.8,
          expand: false,
          builder: (context, controller) => ListView(
            controller: controller,
            padding: const EdgeInsets.all(24),
            children: [
              Text('How this is computed', style: ModernTheme.header),
              const SizedBox(height: 16),
              for (final (title, body) in _method)
                Padding(
                  padding: const EdgeInsets.only(bottom: 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: ModernTheme.subHeader.copyWith(fontSize: 16)),
                      const SizedBox(height: 6),
                      Text(body, style: ModernTheme.body.copyWith(fontSize: 14)),
                    ],
                  ),
                ),
            ],
          ),
        ),
      );

  static const List<(String, String)> _method = [
    (
      'The Sun',
      'Positioned from a truncated VSOP87 series with nutation, aberration and '
          'a Delta-T correction. Checked against published equinox, solstice '
          'and solar-term times: the worst error across eight of them is under '
          'forty seconds.'
    ),
    (
      'Solar terms and your month pillar',
      'The twenty-four terms are the instants the Sun reaches exact multiples '
          'of fifteen degrees, so they come out of the same calculation as your '
          'Sun sign. Your Ba Zi year turns over at Start of Spring and your '
          'month on a solar term — not on 1 January and not on calendar '
          'months.'
    ),
    (
      'Your day pillar',
      'Taken from the Julian Day Number, anchored on two independently '
          'published dates: 1 October 1949 was Jia-Zi and 1 January 2000 was '
          'Wu-Wu.'
    ),
    (
      'The Moon and your rising sign',
      'The Moon comes from an abbreviated lunar series accurate to about a '
          'third of a degree; the ascendant from local sidereal time and the '
          'latitude of your birthplace. Both depend on the clock time you '
          'entered more than on the arithmetic, which is why the app tells you '
          'when a placement is near a boundary instead of asserting one.'
    ),
    (
      'Your daily score',
      'Derived, never rolled. Every point traces to a named relationship — the '
          "day's stem against your day master, its branch against yours, "
          'whether the day carries the phase your chart lacks, and where the '
          'transiting Sun sits. Open "Why this score" to see the arithmetic.'
    ),
  ];
}

class _SubscriptionCard extends StatelessWidget {
  const _SubscriptionCard({required this.entitlements});
  final EntitlementsController entitlements;

  @override
  Widget build(BuildContext context) {
    final subscribed = entitlements.isSubscribed;
    final expires = entitlements.entitlements.expiresAt;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: subscribed
            ? ModernTheme.jade.withOpacity(0.08)
            : ModernTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: subscribed ? ModernTheme.jade : ModernTheme.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(subscribed ? entitlements.tier.label : 'Free plan',
                    style: ModernTheme.subHeader.copyWith(fontSize: 17)),
                const SizedBox(height: 4),
                Text(
                  subscribed
                      ? expires == null
                          ? 'Lifetime. Nothing renews.'
                          : 'Renews '
                              '${expires.toIso8601String().split('T').first}'
                      : '${entitlements.remainingToday(PremiumFeature.chat)} '
                          'readings and '
                          '${entitlements.remainingToday(PremiumFeature.oracle)} '
                          'oracle draws left today',
                  style: ModernTheme.caption.copyWith(fontSize: 13),
                ),
              ],
            ),
          ),
          if (!subscribed)
            ElevatedButton(
              onPressed: () => PaywallScreen.show(context),
              child: const Text('Upgrade'),
            ),
        ],
      ),
    );
  }
}

class _CoinCard extends StatelessWidget {
  const _CoinCard({required this.entitlements});
  final EntitlementsController entitlements;

  @override
  Widget build(BuildContext context) {
    final purchases = context.watch<PurchaseService>();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: ModernTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🪙', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Expanded(
                child: Text('${entitlements.jadeCoins} Jade Coins',
                    style: ModernTheme.subHeader.copyWith(fontSize: 17)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text('For one-off reports without a subscription.',
              style: ModernTheme.caption.copyWith(fontSize: 13)),
          const SizedBox(height: 14),
          Row(
            children: [
              for (final product in coinProducts)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: OutlinedButton(
                      onPressed: purchases.isBusy
                          ? null
                          : () => purchases.buy(product),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: ModernTheme.border),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Column(
                        children: [
                          Text('${product.coins}',
                              style: ModernTheme.subHeader.copyWith(
                                  fontSize: 15,
                                  color: ModernTheme.textMain)),
                          Text(purchases.priceLabel(product),
                              style: ModernTheme.caption.copyWith(fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(title.toUpperCase(),
                style: ModernTheme.caption.copyWith(
                    fontSize: 11,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w700)),
          ),
          Container(
            decoration: ModernTheme.cardDecoration,
            clipBehavior: Clip.antiAlias,
            child: Column(children: children),
          ),
        ],
      );
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => ListTile(
        leading: Icon(icon, color: ModernTheme.textSub),
        title: Text(label, style: ModernTheme.body.copyWith(
            color: ModernTheme.textMain, fontSize: 15)),
        subtitle: Text(subtitle,
            style: ModernTheme.caption.copyWith(fontSize: 12)),
        trailing: onTap == null
            ? null
            : const Icon(Icons.chevron_right, color: ModernTheme.textSub),
        onTap: onTap,
      );
}
