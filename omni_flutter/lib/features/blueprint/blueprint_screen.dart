/// The chart screen: both traditions side by side, then what falls out of
/// reading them together.
///
/// The free tier sees the two charts and the first cross-system insight. The
/// rest sit behind the paywall, which is the right place for it: by the time a
/// user scrolls this far they have seen their real pillars and their real
/// placements, so the upsell is for more of something they already believe.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/billing/entitlements.dart';
import '../../core/engine/soul_blueprint.dart';
import '../../core/theme/modern_theme.dart';
import '../../state/profile_controller.dart';
import '../onboarding/birth_form_screen.dart';
import '../paywall/paywall_screen.dart';
import '../timeline/timeline_screen.dart';

class BlueprintScreen extends StatelessWidget {
  const BlueprintScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileController>();
    final blueprint = profile.blueprint;

    if (blueprint == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chart')),
        body: Center(
          child: TextButton(
            onPressed: () => _edit(context, null),
            child: const Text('Add your birth details'),
          ),
        ),
      );
    }

    final entitlements = context.watch<EntitlementsController>();
    final unlocked =
        entitlements.check(PremiumFeature.fullBlueprint).isAllowed;
    final insights = blueprint.insights;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chart'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => _edit(context, blueprint.birth),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          _SignatureCard(blueprint: blueprint),
          const SizedBox(height: 16),
          _WesternCard(blueprint: blueprint),
          const SizedBox(height: 16),
          _PillarsCard(blueprint: blueprint),
          const SizedBox(height: 16),
          _ElementBar(blueprint: blueprint),
          const SizedBox(height: 16),
          const _TimelineEntry(),
          const SizedBox(height: 24),
          Text('WHERE THE TWO MEET',
              style: ModernTheme.caption.copyWith(
                  fontSize: 11,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          for (var i = 0; i < insights.length; i++)
            if (unlocked || i == 0)
              _InsightCard(insight: insights[i])
            else if (i == 1)
              _LockedInsights(
                count: insights.length - 1,
                onTap: () => PaywallScreen.show(context,
                    trigger: PremiumFeature.fullBlueprint),
              ),
          if (blueprint.caveats.isNotEmpty) ...[
            const SizedBox(height: 24),
            _CaveatsCard(caveats: blueprint.caveats),
          ],
        ],
      ),
    );
  }

  Future<void> _edit(BuildContext context, BirthData? initial) async {
    final birth = await Navigator.of(context).push<BirthData>(
      MaterialPageRoute(builder: (_) => BirthFormScreen(initial: initial)),
    );
    if (birth != null && context.mounted) {
      await context.read<ProfileController>().setBirth(birth);
    }
  }
}

class _SignatureCard extends StatelessWidget {
  const _SignatureCard({required this.blueprint});
  final SoulBlueprint blueprint;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: ModernTheme.ink,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              blueprint.systemsAgree
                  ? 'BOTH TRADITIONS AGREE'
                  : 'THE TRADITIONS DISAGREE',
              style: ModernTheme.caption.copyWith(
                fontSize: 10,
                letterSpacing: 2,
                fontWeight: FontWeight.w700,
                color: blueprint.systemsAgree
                    ? ModernTheme.jade
                    : ModernTheme.gold,
              ),
            ),
            const SizedBox(height: 12),
            Text(blueprint.signature,
                style: ModernTheme.header
                    .copyWith(color: Colors.white, fontSize: 22, height: 1.35)),
          ],
        ),
      );
}

class _WesternCard extends StatelessWidget {
  const _WesternCard({required this.blueprint});
  final SoulBlueprint blueprint;

  @override
  Widget build(BuildContext context) {
    final chart = blueprint.western;
    return Container(
      decoration: ModernTheme.cardDecoration,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardTitle(title: 'Natal chart', tag: 'WEST', color: ModernTheme.primary),
          const SizedBox(height: 16),
          _Placement(label: 'Sun', placement: chart.sun.formatted, note: 'what you are'),
          if (chart.moon != null)
            _Placement(
                label: 'Moon',
                placement: chart.moon!.formatted,
                note: 'what you feel'),
          if (chart.ascendant != null)
            _Placement(
                label: 'Rising',
                placement: chart.ascendant!.formatted,
                note: 'what they meet first'),
          if (chart.sunMoonAspect case final aspect?) ...[
            const SizedBox(height: 12),
            Text(
              'Sun ${aspect.aspect.label.toLowerCase()} Moon — '
              '${aspect.aspect.gist}, ${aspect.orb.toStringAsFixed(1)}° from '
              'exact.',
              style: ModernTheme.caption.copyWith(fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }
}

class _Placement extends StatelessWidget {
  const _Placement({
    required this.label,
    required this.placement,
    required this.note,
  });

  final String label;
  final String placement;
  final String note;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            SizedBox(
              width: 64,
              child: Text(label,
                  style: ModernTheme.caption
                      .copyWith(fontSize: 12, letterSpacing: 1)),
            ),
            Expanded(
              child: Text(placement,
                  style: ModernTheme.subHeader.copyWith(fontSize: 16)),
            ),
            Text(note,
                style: ModernTheme.caption.copyWith(fontSize: 11)),
          ],
        ),
      );
}

class _PillarsCard extends StatelessWidget {
  const _PillarsCard({required this.blueprint});
  final SoulBlueprint blueprint;

  @override
  Widget build(BuildContext context) {
    final bazi = blueprint.bazi;
    final labels = ['Year', 'Month', 'Day', 'Hour'];
    final pillars = [bazi.year, bazi.month, bazi.day, bazi.hour];

    return Container(
      decoration: ModernTheme.cardDecoration,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardTitle(title: 'Four pillars 四柱', tag: 'EAST', color: ModernTheme.jade),
          const SizedBox(height: 18),
          Row(
            children: [
              for (var i = 0; i < 4; i++)
                Expanded(
                  child: Column(
                    children: [
                      Text(labels[i].toUpperCase(),
                          style: ModernTheme.caption
                              .copyWith(fontSize: 10, letterSpacing: 1)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          color: i == 2
                              ? ModernTheme.jade.withOpacity(0.1)
                              : ModernTheme.background,
                          borderRadius: BorderRadius.circular(12),
                          border: i == 2
                              ? Border.all(color: ModernTheme.jade, width: 1.5)
                              : null,
                        ),
                        child: Column(
                          children: [
                            Text(
                              pillars[i]?.stem.chinese ?? '?',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w600,
                                color: pillars[i] == null
                                    ? ModernTheme.textSub
                                    : ModernTheme.textMain,
                              ),
                            ),
                            Text(
                              pillars[i]?.branch.chinese ?? '?',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w600,
                                color: pillars[i] == null
                                    ? ModernTheme.textSub
                                    : ModernTheme.textMain,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Day master ${bazi.dayMaster.chinese} '
            '${bazi.dayMaster.pinyin} — ${bazi.dayMaster.element.english}, '
            '${_strength(bazi.dayMasterStrength)}.',
            style: ModernTheme.body.copyWith(fontSize: 14),
          ),
          const SizedBox(height: 6),
          Text(
            '${bazi.zodiacAnimal} year · ${bazi.year.naYin.chinese} '
            '${bazi.year.naYin.english} · born in '
            '${bazi.solarTerm.chinese} ${bazi.solarTerm.english}',
            style: ModernTheme.caption.copyWith(fontSize: 13),
          ),
        ],
      ),
    );
  }

  static String _strength(double s) {
    if (s >= 0.62) return 'strong, well supported by the rest of the chart';
    if (s <= 0.38) return 'weak, and the chart pulls against it';
    return 'balanced against the rest of the chart';
  }
}

class _ElementBar extends StatelessWidget {
  const _ElementBar({required this.blueprint});
  final SoulBlueprint blueprint;

  @override
  Widget build(BuildContext context) {
    final weights = blueprint.bazi.elementWeights;
    final total = weights.values.fold<double>(0, (a, b) => a + b);
    const colors = {
      WuXing.wood: Color(0xFF2E9E5B),
      WuXing.fire: ModernTheme.vermilion,
      WuXing.earth: ModernTheme.gold,
      WuXing.metal: Color(0xFF9AA3AF),
      WuXing.water: Color(0xFF2D6CDF),
    };

    return Container(
      decoration: ModernTheme.cardDecoration,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardTitle(
              title: 'Five phases 五行', tag: 'EAST', color: ModernTheme.jade),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 14,
              child: Row(
                children: [
                  for (final element in WuXing.values)
                    if ((weights[element] ?? 0) > 0)
                      Expanded(
                        flex: ((weights[element]! / total) * 1000).round(),
                        child: Container(color: colors[element]),
                      ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              for (final element in WuXing.values)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: (weights[element] ?? 0) > 0
                            ? colors[element]
                            : ModernTheme.border,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${element.chinese} ${element.english} '
                      '${(weights[element] ?? 0).toStringAsFixed(1)}',
                      style: ModernTheme.caption.copyWith(
                        fontSize: 12,
                        color: (weights[element] ?? 0) > 0
                            ? ModernTheme.textMain
                            : ModernTheme.textSub,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Your remedy phase is ${blueprint.remedialElement.chinese} '
            '${blueprint.remedialElement.english}: '
            '${blueprint.affinity.colors.join(' and ')}, the '
            '${blueprint.affinity.direction.toLowerCase()}, '
            '${blueprint.affinity.numbers.join(' and ')}.',
            style: ModernTheme.body.copyWith(fontSize: 14),
          ),
        ],
      ),
    );
  }
}

/// The way into the ten-year cycle. Sits directly under the chart because
/// that is where the question "so what happens next" arrives.
class _TimelineEntry extends StatelessWidget {
  const _TimelineEntry();

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const TimelineScreen()),
        ),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: ModernTheme.cardDecoration,
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: ModernTheme.gold.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('運',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: ModernTheme.gold)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Your decades 大运',
                        style: ModernTheme.subHeader.copyWith(fontSize: 16)),
                    Text(
                      'Which ten-year period you are standing in, and what the '
                      'years ahead do to it',
                      style: ModernTheme.caption.copyWith(fontSize: 12.5),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: ModernTheme.textSub),
            ],
          ),
        ),
      );
}

class _CardTitle extends StatelessWidget {
  const _CardTitle(
      {required this.title, required this.tag, required this.color});
  final String title;
  final String tag;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(
              child: Text(title,
                  style: ModernTheme.subHeader.copyWith(fontSize: 17))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(tag,
                style: TextStyle(
                    fontSize: 10,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w700,
                    color: color)),
          ),
        ],
      );
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({required this.insight});
  final CrossInsight insight;

  @override
  Widget build(BuildContext context) {
    // The accent stripe is a child rather than a coloured left border:
    // Flutter refuses to paint a rounded box whose sides differ in colour.
    final accent = insight.isTension ? ModernTheme.gold : ModernTheme.jade;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: ModernTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: ModernTheme.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 3, color: accent),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(insight.title,
                        style: ModernTheme.subHeader.copyWith(fontSize: 16)),
                    const SizedBox(height: 8),
                    Text(insight.body,
                        style: ModernTheme.body.copyWith(fontSize: 14)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LockedInsights extends StatelessWidget {
  const _LockedInsights({required this.count, required this.onTap});
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: ModernTheme.primary.withOpacity(0.05),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: ModernTheme.primary.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              const Icon(Icons.lock_outline, color: ModernTheme.primary),
              const SizedBox(height: 10),
              Text('$count more readings of your chart',
                  style: ModernTheme.subHeader.copyWith(fontSize: 16)),
              const SizedBox(height: 6),
              Text(
                'Including where the two traditions contradict each other, and '
                'what that means for how people read you.',
                textAlign: TextAlign.center,
                style: ModernTheme.caption.copyWith(fontSize: 13),
              ),
              const SizedBox(height: 14),
              const Text('Unlock with Omni Plus',
                  style: TextStyle(
                      color: ModernTheme.primary, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      );
}

class _CaveatsCard extends StatelessWidget {
  const _CaveatsCard({required this.caveats});
  final List<String> caveats;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: ModernTheme.background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: ModernTheme.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('WHAT WE ARE NOT SURE OF',
                style: ModernTheme.caption.copyWith(
                    fontSize: 10,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            for (final caveat in caveats)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text('· $caveat',
                    style: ModernTheme.caption.copyWith(fontSize: 12.5)),
              ),
          ],
        ),
      );
}
