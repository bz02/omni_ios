/// The luck cycle and the year ahead.
///
/// This is the content that makes a subscription worth more than a daily
/// score. It is also the report the coin prices already name, so leaving it
/// unbuilt meant charging for something that did not exist.
///
/// Free users see the cycle itself — the decades, their pillars, which one
/// they are standing in. That is the moment the app stops looking like a
/// horoscope generator. What sits behind the gate is the year-by-year
/// forecast, which is the part with ongoing value.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/analytics/analytics.dart';
import '../../core/billing/entitlements.dart';
import '../../core/engine/luck_pillars.dart';
import '../../core/theme/modern_theme.dart';
import '../../state/profile_controller.dart';
import '../paywall/paywall_screen.dart';

class TimelineScreen extends StatelessWidget {
  const TimelineScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileController>();
    final blueprint = profile.blueprint;
    if (blueprint == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Timeline')),
        body: const SizedBox.shrink(),
      );
    }

    if (profile.polarity == null) {
      return const _PolarityGate();
    }

    final cycle = profile.luckCycle!;
    final age = _ageOf(blueprint.birth.localDateTime);
    final thisYear = DateTime.now().year;

    final unlocked =
        context.watch<EntitlementsController>().check(PremiumFeature.yearAhead)
            .isAllowed;

    return Scaffold(
      appBar: AppBar(title: const Text('Timeline')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          _CycleHeader(cycle: cycle, age: age),
          const SizedBox(height: 20),
          Text('THE DECADES 大运',
              style: ModernTheme.caption.copyWith(
                  fontSize: 11, letterSpacing: 2, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          for (final pillar in cycle.pillars)
            _DecadeRow(pillar: pillar, isCurrent: pillar.containsAge(age)),
          const SizedBox(height: 28),
          Text('YEAR BY YEAR 流年',
              style: ModernTheme.caption.copyWith(
                  fontSize: 11, letterSpacing: 2, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          // This year is free — the taste that makes the rest worth buying.
          _YearCard(
            forecast: profile.forecastFor(thisYear)!,
            expanded: true,
          ),
          const SizedBox(height: 12),
          if (unlocked)
            for (var year = thisYear + 1; year <= thisYear + 9; year++)
              _YearCard(forecast: profile.forecastFor(year)!, expanded: false)
          else
            _LockedYears(
              onTap: () {
                context.read<Analytics>().quotaExhausted(
                    PremiumFeature.yearAhead);
                PaywallScreen.show(context,
                    trigger: PremiumFeature.yearAhead,
                    coinPrice: coinPrices[PremiumFeature.yearAhead]);
              },
            ),
        ],
      ),
    );
  }

  static int _ageOf(DateTime birth) {
    final now = DateTime.now();
    var age = now.year - birth.year;
    if (now.month < birth.month ||
        (now.month == birth.month && now.day < birth.day)) {
      age -= 1;
    }
    return age;
  }
}

/// Asks for the polarity the cycle runs against.
///
/// The classical rule pairs the birth year's polarity with the person's own.
/// Rather than asking for a gender and quietly mapping it, this states what
/// the rule actually does and lets someone choose — or see both sequences and
/// decide for themselves.
class _PolarityGate extends StatelessWidget {
  const _PolarityGate();

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileController>();
    final yearIsYang = profile.blueprint!.bazi.year.stem.isYang;

    return Scaffold(
      appBar: AppBar(title: const Text('Timeline')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          Text('Which way does your cycle run?',
              style: ModernTheme.header.copyWith(fontSize: 24)),
          const SizedBox(height: 12),
          Text(
            'Your ten-year periods run forward or backward through the cycle, '
            'and which one decides every decade of the reading. The classical '
            'rule pairs the polarity of your birth year with your own: matched, '
            'it runs forward; mixed, it runs backward.',
            style: ModernTheme.body,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: ModernTheme.background,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: ModernTheme.border),
            ),
            child: Text(
              'Your birth year is '
              '${yearIsYang ? 'yang 阳' : 'yin 阴'} '
              '(${profile.blueprint!.bazi.year.chinese}), so choosing '
              '${yearIsYang ? 'yang' : 'yin'} runs the cycle forward and '
              '${yearIsYang ? 'yin' : 'yang'} runs it backward.',
              style: ModernTheme.caption.copyWith(fontSize: 13),
            ),
          ),
          const SizedBox(height: 20),
          for (final polarity in ChartPolarity.values)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _PolarityOption(
                polarity: polarity,
                runsForward: luckRunsForward(
                    yearStemIsYang: yearIsYang, polarity: polarity),
                onTap: () =>
                    context.read<ProfileController>().setPolarity(polarity),
              ),
            ),
          const SizedBox(height: 8),
          Text(
            'Traditional texts phrase this as male and female. What the rule '
            'uses is the polarity, so that is what we ask for. You can change '
            'it any time.',
            style: ModernTheme.caption.copyWith(fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _PolarityOption extends StatelessWidget {
  const _PolarityOption({
    required this.polarity,
    required this.runsForward,
    required this.onTap,
  });

  final ChartPolarity polarity;
  final bool runsForward;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: ModernTheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: ModernTheme.border),
          ),
          child: Row(
            children: [
              Text(polarity.chinese,
                  style: const TextStyle(
                      fontSize: 26, fontWeight: FontWeight.w600)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(polarity.english,
                        style: ModernTheme.subHeader.copyWith(fontSize: 16)),
                    Text(
                      runsForward
                          ? 'Cycle runs forward'
                          : 'Cycle runs backward',
                      style: ModernTheme.caption.copyWith(fontSize: 13),
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

class _CycleHeader extends StatelessWidget {
  const _CycleHeader({required this.cycle, required this.age});
  final LuckCycle cycle;
  final int age;

  @override
  Widget build(BuildContext context) {
    final current = cycle.pillarForAge(age);
    return Container(
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
            current == null ? 'BEFORE THE CYCLE OPENS' : 'YOU ARE HERE',
            style: ModernTheme.caption.copyWith(
                fontSize: 10,
                letterSpacing: 2,
                fontWeight: FontWeight.w700,
                color: ModernTheme.jade),
          ),
          const SizedBox(height: 12),
          if (current != null) ...[
            Text(current.pillar.chinese,
                style: const TextStyle(
                    fontSize: 40,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    height: 1.1)),
            const SizedBox(height: 8),
            Text(
              '${current.tenGod.chinese} ${current.tenGod.english} · '
              'ages ${current.ageRange} · '
              '${current.startYear}–${current.endYear}',
              style: ModernTheme.caption
                  .copyWith(color: ModernTheme.gold, fontSize: 13),
            ),
          ] else
            Text('Your cycle opens at ${cycle.startDescription}.',
                style: ModernTheme.subHeader
                    .copyWith(color: Colors.white, fontSize: 18)),
          const SizedBox(height: 14),
          const Divider(color: Colors.white12),
          const SizedBox(height: 10),
          Text(
            'Running ${cycle.runsForward ? 'forward' : 'backward'}, opening at '
            '${cycle.startDescription}, measured from '
            '${cycle.anchorTerm.chinese} ${cycle.anchorTerm.english} at three '
            'days to the year.',
            style: ModernTheme.caption.copyWith(color: Colors.white60, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _DecadeRow extends StatelessWidget {
  const _DecadeRow({required this.pillar, required this.isCurrent});
  final LuckPillar pillar;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isCurrent
              ? ModernTheme.jade.withOpacity(0.08)
              : ModernTheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isCurrent ? ModernTheme.jade : ModernTheme.border,
            width: isCurrent ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 46,
              child: Text(pillar.pillar.chinese,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w600)),
            ),
            SizedBox(
              width: 62,
              child: Text(pillar.ageRange,
                  style: ModernTheme.caption.copyWith(fontSize: 13)),
            ),
            Expanded(
              child: Text(
                '${pillar.tenGod.chinese} ${pillar.tenGod.english}',
                style: ModernTheme.caption.copyWith(
                    fontSize: 13, color: ModernTheme.textMain),
              ),
            ),
            Text('${pillar.startYear}',
                style: ModernTheme.caption.copyWith(fontSize: 12)),
          ],
        ),
      );
}

class _YearCard extends StatelessWidget {
  const _YearCard({required this.forecast, required this.expanded});
  final AnnualForecast forecast;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final color = ModernTheme.forScore(forecast.score);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(18),
      decoration: ModernTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: 2),
                ),
                child: Text('${forecast.score}',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: color)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${forecast.year} · ${forecast.pillar.chinese}',
                        style: ModernTheme.subHeader.copyWith(fontSize: 16)),
                    Text(
                      '${forecast.band} · ${forecast.tenGod.chinese} '
                      '${forecast.tenGod.english}',
                      style: ModernTheme.caption.copyWith(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(forecast.headline,
              style: ModernTheme.body.copyWith(fontSize: 14)),
          if (expanded) ...[
            const SizedBox(height: 12),
            const Divider(color: ModernTheme.border),
            const SizedBox(height: 8),
            for (final factor in forecast.factors)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(factor,
                    style: ModernTheme.caption.copyWith(fontSize: 12.5)),
              ),
          ],
        ],
      ),
    );
  }
}

class _LockedYears extends StatelessWidget {
  const _LockedYears({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: ModernTheme.primary.withOpacity(0.05),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: ModernTheme.primary.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              const Icon(Icons.lock_outline, color: ModernTheme.primary),
              const SizedBox(height: 10),
              Text('The next nine years',
                  style: ModernTheme.subHeader.copyWith(fontSize: 16)),
              const SizedBox(height: 6),
              Text(
                'Each year scored against your chart and the decade it falls '
                'in, with the reasoning behind every number.',
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
