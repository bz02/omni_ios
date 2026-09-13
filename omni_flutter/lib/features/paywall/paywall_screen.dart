/// The paywall.
///
/// Three rules this screen follows, all of them learned from App Store
/// rejections and from what actually converts:
///
///   1. It never appears before the user has seen a real reading. The caller
///      passes the [trigger] so the headline names the thing they just hit.
///   2. Prices come from the store, never from a constant, and the renewal
///      terms are on the screen rather than behind a link.
///   3. Restore Purchases, Terms and Privacy are always visible. Review
///      rejects subscription screens that hide them, and users distrust them.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/billing/entitlements.dart';
import '../../core/billing/products.dart';
import '../../core/billing/purchase_service.dart';
import '../../core/theme/modern_theme.dart';

class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key, this.trigger, this.coinPrice});

  /// What the user was trying to do. Naming it lifts conversion sharply over a
  /// generic "Go Premium".
  final PremiumFeature? trigger;

  /// When the blocked feature can also be bought outright with coins.
  final int? coinPrice;

  static Future<bool?> show(
    BuildContext context, {
    PremiumFeature? trigger,
    int? coinPrice,
  }) =>
      showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => PaywallScreen(trigger: trigger, coinPrice: coinPrice),
      );

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  String _selectedId = 'omni.plus.annual';
  String? _error;

  @override
  Widget build(BuildContext context) {
    final purchases = context.watch<PurchaseService>();
    final entitlements = context.watch<EntitlementsController>();
    final selected =
        subscriptionProducts.firstWhere((p) => p.id == _selectedId);

    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      maxChildSize: 0.96,
      minChildSize: 0.6,
      expand: false,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: ModernTheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: ModernTheme.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                children: [
                  _Header(trigger: widget.trigger),
                  const SizedBox(height: 24),
                  const _BenefitList(),
                  const SizedBox(height: 24),
                  for (final product in subscriptionProducts)
                    _PlanTile(
                      product: product,
                      price: purchases.priceLabel(product),
                      selected: product.id == _selectedId,
                      onTap: () => setState(() => _selectedId = product.id),
                    ),
                  if (widget.coinPrice != null) ...[
                    const SizedBox(height: 16),
                    _CoinAlternative(
                      cost: widget.coinPrice!,
                      balance: entitlements.jadeCoins,
                    ),
                  ],
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      _error!,
                      style: ModernTheme.caption
                          .copyWith(color: ModernTheme.error),
                    ),
                  ],
                ],
              ),
            ),
            _Footer(
              product: selected,
              price: purchases.priceLabel(selected),
              busy: purchases.isBusy,
              onBuy: () => _buy(selected),
              onRestore: _restore,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _buy(OmniProduct product) async {
    setState(() => _error = null);
    final service = context.read<PurchaseService>();
    final result = await service.buy(product);
    if (!mounted) return;

    if (result.isSuccess) {
      Navigator.of(context).pop(true);
      return;
    }
    if (result.outcome == PurchaseOutcome.cancelled) return;
    setState(() => _error = result.message ?? 'That did not go through.');
  }

  Future<void> _restore() async {
    setState(() => _error = null);
    final service = context.read<PurchaseService>();
    final result = await service.restore();
    if (!mounted) return;

    final entitlements = context.read<EntitlementsController>();
    if (entitlements.isSubscribed) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() => _error =
        result.message ?? 'Nothing to restore on this Apple ID.');
  }
}

class _Header extends StatelessWidget {
  const _Header({this.trigger});
  final PremiumFeature? trigger;

  @override
  Widget build(BuildContext context) {
    final title = trigger == null
        ? 'Both charts. Every day.'
        : 'Unlock ${trigger!.label.toLowerCase()}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('☰', style: TextStyle(fontSize: 20)),
            const SizedBox(width: 6),
            Text('OMNI PLUS',
                style: ModernTheme.caption.copyWith(
                  letterSpacing: 2,
                  fontWeight: FontWeight.w700,
                  color: ModernTheme.jade,
                )),
          ],
        ),
        const SizedBox(height: 10),
        Text(title, style: ModernTheme.header.copyWith(fontSize: 28)),
        const SizedBox(height: 8),
        Text(
          'Your Western chart and your Ba Zi, read together. '
          'Most apps give you one of the two.',
          style: ModernTheme.body,
        ),
      ],
    );
  }
}

class _BenefitList extends StatelessWidget {
  const _BenefitList();

  static const _benefits = [
    ('🀄', 'Your complete Ba Zi', 'Four pillars, ten gods, five-phase balance'),
    ('♃', 'Your full natal chart', 'Sun, Moon, Rising and the aspects between'),
    ('⚖️', 'Where the two disagree', 'The read no single-tradition app can give'),
    ('🔮', 'Unlimited tarot and I Ching', 'Draw as often as you need to'),
    ('💞', 'Unlimited compatibility', 'Both traditions, scored separately'),
    ('🔔', 'Timing alerts', 'Solar terms, transits, the days that matter'),
  ];

  @override
  Widget build(BuildContext context) => Column(
        children: [
          for (final (icon, title, detail) in _benefits)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                      width: 30, child: Text(icon, style: const TextStyle(fontSize: 18))),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title,
                            style: ModernTheme.caption.copyWith(
                                color: ModernTheme.textMain,
                                fontWeight: FontWeight.w600)),
                        Text(detail,
                            style: ModernTheme.caption
                                .copyWith(fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      );
}

class _PlanTile extends StatelessWidget {
  const _PlanTile({
    required this.product,
    required this.price,
    required this.selected,
    required this.onTap,
  });

  final OmniProduct product;
  final String price;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: selected
                ? ModernTheme.primary.withOpacity(0.06)
                : ModernTheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? ModernTheme.primary : ModernTheme.border,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: selected ? ModernTheme.primary : ModernTheme.textSub,
                size: 22,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        Text(product.name,
                            style: ModernTheme.subHeader.copyWith(fontSize: 16)),
                        if (product.badge != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: ModernTheme.jade,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(product.badge!,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(product.blurb,
                        style: ModernTheme.caption.copyWith(fontSize: 13)),
                  ],
                ),
              ),
              Text(price,
                  style: ModernTheme.subHeader.copyWith(
                      fontSize: 17, color: ModernTheme.textMain)),
            ],
          ),
        ),
      );
}

class _CoinAlternative extends StatelessWidget {
  const _CoinAlternative({required this.cost, required this.balance});
  final int cost;
  final int balance;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: ModernTheme.gold.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            const Text('🪙', style: TextStyle(fontSize: 20)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                balance >= cost
                    ? 'Or unlock just this one for $cost Jade Coins. '
                        'You have $balance.'
                    : 'This one alone costs $cost Jade Coins. '
                        'You have $balance.',
                style: ModernTheme.caption.copyWith(fontSize: 13),
              ),
            ),
          ],
        ),
      );
}

class _Footer extends StatelessWidget {
  const _Footer({
    required this.product,
    required this.price,
    required this.busy,
    required this.onBuy,
    required this.onRestore,
  });

  final OmniProduct product;
  final String price;
  final bool busy;
  final VoidCallback onBuy;
  final VoidCallback onRestore;

  @override
  Widget build(BuildContext context) {
    // Apple requires the renewal terms on the purchase screen itself.
    final terms = product.period == null
        ? 'One payment of $price. No subscription, nothing renews.'
        : product.trialDays > 0
            ? '${product.trialDays} days free, then $price '
                '${product.period!.inDays >= 365 ? 'a year' : 'a month'}. '
                'Renews automatically until cancelled. Cancel any time in your '
                'App Store settings.'
            : '$price ${product.period!.inDays >= 365 ? 'a year' : 'a month'}, '
                'renewing automatically until cancelled.';

    return Container(
      padding: EdgeInsets.fromLTRB(
          24, 12, 24, 16 + MediaQuery.of(context).padding.bottom),
      decoration: const BoxDecoration(
        color: ModernTheme.surface,
        border: Border(top: BorderSide(color: ModernTheme.border)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: busy ? null : onBuy,
              child: busy
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Text(product.trialDays > 0
                      ? 'Start ${product.trialDays} days free'
                      : 'Continue — $price'),
            ),
          ),
          const SizedBox(height: 10),
          Text(terms,
              textAlign: TextAlign.center,
              style: ModernTheme.caption.copyWith(fontSize: 11)),
          const SizedBox(height: 6),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              TextButton(
                onPressed: busy ? null : onRestore,
                style: _linkStyle,
                child: const Text('Restore'),
              ),
              const Text('·', style: TextStyle(color: ModernTheme.textSub)),
              TextButton(
                onPressed: () => _openLegal(context, 'Terms of Service'),
                style: _linkStyle,
                child: const Text('Terms'),
              ),
              const Text('·', style: TextStyle(color: ModernTheme.textSub)),
              TextButton(
                onPressed: () => _openLegal(context, 'Privacy Policy'),
                style: _linkStyle,
                child: const Text('Privacy'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static final ButtonStyle _linkStyle = TextButton.styleFrom(
    padding: const EdgeInsets.symmetric(horizontal: 10),
    minimumSize: Size.zero,
    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
  );

  void _openLegal(BuildContext context, String which) {
    // Wired to the hosted documents once they are published; see docs/LAUNCH.md.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$which opens once the site is live.')),
    );
  }
}
