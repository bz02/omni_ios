/// The daily screen — the reason to open the app on a day with no question.
///
/// Every number on it can be traced: tapping "why this score" opens the list of
/// named factors that produced it. That is the whole argument against a
/// competitor that rolls dice, so it is one tap away rather than buried.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/analytics/analytics.dart';
import '../../core/engine/daily_fortune.dart';
import '../../core/engine/transits.dart';
import '../../core/theme/modern_theme.dart';
import '../../core/widgets/glossary_link.dart';
import '../../state/profile_controller.dart';
import '../onboarding/birth_form_screen.dart';

class TodayScreen extends StatelessWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileController>();
    final fortune = profile.today;
    final blueprint = profile.blueprint;

    if (fortune == null || blueprint == null) {
      return const _EmptyState();
    }

    final now = DateTime.now();
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            Text(
              _weekday(now.weekday).toUpperCase(),
              style: ModernTheme.caption.copyWith(
                  letterSpacing: 2, fontSize: 11, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text('${_month(now.month)} ${now.day}',
                style: ModernTheme.header.copyWith(fontSize: 30)),
            const SizedBox(height: 20),
            if (profile.sky case final sky?) ...[
              _SkyCard(sky: sky),
              const SizedBox(height: 16),
            ],
            _ScoreCard(fortune: fortune),
            const SizedBox(height: 16),
            _AlmanacCard(fortune: fortune),
            const SizedBox(height: 16),
            _LuckyCard(fortune: fortune),
            const SizedBox(height: 16),
            _WhyCard(fortune: fortune),
          ],
        ),
      ),
    );
  }

  static String _weekday(int w) => const [
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
        'Sunday'
      ][w - 1];

  static String _month(int m) => const [
        'January',
        'February',
        'March',
        'April',
        'May',
        'June',
        'July',
        'August',
        'September',
        'October',
        'November',
        'December'
      ][m - 1];
}

/// The sky right now. First card on the screen because "is Mercury
/// retrograde" and "what's the moon doing" are the two things this audience
/// already checks, and meeting them where they are beats teaching them
/// something new above the fold.
class _SkyCard extends StatelessWidget {
  const _SkyCard({required this.sky});
  final SkyNow sky;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: ModernTheme.cardDecoration,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(sky.moon.phase.emoji,
                    style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(sky.headline,
                          style:
                              ModernTheme.subHeader.copyWith(fontSize: 17)),
                      Text(
                        '${sky.moon.phase.label} in ${sky.moon.sign.label} · '
                        '${sky.moon.illuminationLabel}',
                        style: ModernTheme.caption.copyWith(fontSize: 12.5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(sky.moon.phase.gist,
                style: ModernTheme.body.copyWith(fontSize: 14)),
            if (sky.retrogrades.isNotEmpty) ...[
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final planet in sky.retrogrades)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: planet == Planet.mercury
                            ? ModernTheme.vermilion.withOpacity(0.1)
                            : ModernTheme.background,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: planet == Planet.mercury
                              ? ModernTheme.vermilion
                              : ModernTheme.border,
                        ),
                      ),
                      child: Text(
                        '${planet.glyph} ${planet.label} ℞',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: planet == Planet.mercury
                              ? ModernTheme.vermilion
                              : ModernTheme.textSub,
                        ),
                      ),
                    ),
                ],
              ),
            ],
            if (sky.supportingTransits.isNotEmpty) ...[
              const SizedBox(height: 14),
              const Divider(color: ModernTheme.border),
              const SizedBox(height: 10),
              for (final transit in sky.supportingTransits.take(2))
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(transit.headline,
                          style: ModernTheme.caption.copyWith(
                              fontSize: 13,
                              color: ModernTheme.textMain,
                              fontWeight: FontWeight.w600)),
                      Text(transit.detail,
                          style:
                              ModernTheme.caption.copyWith(fontSize: 12.5)),
                    ],
                  ),
                ),
            ],
          ],
        ),
      );
}

class _ScoreCard extends StatelessWidget {
  const _ScoreCard({required this.fortune});
  final DailyFortune fortune;

  @override
  Widget build(BuildContext context) {
    final color = ModernTheme.forScore(fortune.score);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: ModernTheme.ink,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 148,
            width: 148,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  height: 148,
                  width: 148,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: fortune.score / 100),
                    duration: const Duration(milliseconds: 900),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, _) => CircularProgressIndicator(
                      value: value,
                      strokeWidth: 10,
                      backgroundColor: Colors.white12,
                      valueColor: AlwaysStoppedAnimation(color),
                      strokeCap: StrokeCap.round,
                    ),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('${fortune.score}',
                        style: const TextStyle(
                          fontSize: 46,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          height: 1,
                        )),
                    Text(fortune.band.toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          letterSpacing: 2,
                          fontWeight: FontWeight.w700,
                          color: color,
                        )),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text(fortune.headline,
              textAlign: TextAlign.center,
              style: ModernTheme.subHeader
                  .copyWith(color: Colors.white, fontSize: 17)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${fortune.dayPillar.chinese} · '
              '${fortune.dayPillar.branch.animal} day',
              style: ModernTheme.caption
                  .copyWith(color: ModernTheme.gold, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _AlmanacCard extends StatelessWidget {
  const _AlmanacCard({required this.fortune});
  final DailyFortune fortune;

  @override
  Widget build(BuildContext context) => Container(
        decoration: ModernTheme.cardDecoration,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // An American reader has never seen an almanac, so the two
            // columns say what they are before showing their glyphs.
            GlossaryLink('yiJi',
                label: 'What today is for',
                style: ModernTheme.subHeader.copyWith(fontSize: 15)),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _Column(
                    glyph: '宜',
                    label: 'Good for',
                    color: ModernTheme.jade,
                    items: fortune.favorable,
                  ),
                ),
                Container(
                    width: 1,
                    height: 110,
                    color: ModernTheme.border,
                    margin: const EdgeInsets.symmetric(horizontal: 16)),
                Expanded(
                  child: _Column(
                    glyph: '忌',
                    label: 'Not today',
                    color: ModernTheme.vermilion,
                    items: fortune.unfavorable,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
}

class _Column extends StatelessWidget {
  const _Column({
    required this.glyph,
    required this.label,
    required this.color,
    required this.items,
  });

  final String glyph;
  final String label;
  final Color color;
  final List<String> items;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(glyph,
                  style: TextStyle(
                      fontSize: 22, color: color, fontWeight: FontWeight.w700)),
              const SizedBox(width: 8),
              // The card splits the width in two, so this label has about half
              // a phone to live in.
              Expanded(
                child: Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: ModernTheme.caption
                        .copyWith(fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (final item in items.take(4))
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text('· $item',
                  style: ModernTheme.body
                      .copyWith(fontSize: 14, color: ModernTheme.textMain)),
            ),
        ],
      );
}

class _LuckyCard extends StatelessWidget {
  const _LuckyCard({required this.fortune});
  final DailyFortune fortune;

  @override
  Widget build(BuildContext context) => Container(
        decoration: ModernTheme.cardDecoration,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Each takes a third: 'deep blue' and 'Center' are wide enough
                // to overflow a spaceAround row on a narrow phone.
                Expanded(
                    child: _Lucky(label: 'Color', value: fortune.luckyColor)),
                Expanded(
                    child: _Lucky(
                        label: 'Number', value: '${fortune.luckyNumber}')),
                Expanded(
                    child: _Lucky(
                        label: 'Direction', value: fortune.luckyDirection)),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(color: ModernTheme.border),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('👗', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 10),
                Expanded(
                    child: Text(fortune.outfitNote,
                        style: ModernTheme.body.copyWith(fontSize: 14))),
              ],
            ),
          ],
        ),
      );
}

class _Lucky extends StatelessWidget {
  const _Lucky({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Text(label.toUpperCase(),
              style: ModernTheme.caption
                  .copyWith(fontSize: 10, letterSpacing: 1.4)),
          const SizedBox(height: 6),
          Text(value,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: ModernTheme.subHeader
                  .copyWith(fontSize: 17, color: ModernTheme.primary)),
        ],
      );
}

/// The trust card. Nothing else in the category shows its working.
class _WhyCard extends StatelessWidget {
  const _WhyCard({required this.fortune});
  final DailyFortune fortune;

  @override
  Widget build(BuildContext context) => Container(
        decoration: ModernTheme.cardDecoration,
        clipBehavior: Clip.antiAlias,
        child: ExpansionTile(
          shape: const Border(),
          collapsedShape: const Border(),
          title: Text('Why ${fortune.score}?',
              style: ModernTheme.subHeader.copyWith(fontSize: 16)),
          subtitle: Text('Computed, not rolled',
              style: ModernTheme.caption.copyWith(fontSize: 12)),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const SizedBox(width: 44, child: Text('50')),
                      Expanded(
                        child: Text('baseline',
                            style: ModernTheme.caption.copyWith(fontSize: 13)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  for (final factor in fortune.factors)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 44,
                            child: Text(
                              factor.signed,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: factor.points >= 0
                                    ? ModernTheme.jade
                                    : ModernTheme.vermilion,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(factor.label,
                                    style: ModernTheme.caption.copyWith(
                                        color: ModernTheme.textMain,
                                        fontWeight: FontWeight.w600)),
                                Text(factor.detail,
                                    style: ModernTheme.caption
                                        .copyWith(fontSize: 12)),
                              ],
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
      );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('☯', style: TextStyle(fontSize: 56)),
                const SizedBox(height: 20),
                Text('Two charts, one you',
                    style: ModernTheme.header, textAlign: TextAlign.center),
                const SizedBox(height: 10),
                Text(
                  'Give us the moment you were born and we will compute your '
                  'Western chart and your Ba Zi, and tell you where they '
                  'disagree.',
                  textAlign: TextAlign.center,
                  style: ModernTheme.body,
                ),
                const SizedBox(height: 28),
                ElevatedButton(
                  onPressed: () async {
                    context.read<Analytics>().onboardingStarted();
                    final birth = await Navigator.of(context).push(
                      MaterialPageRoute<dynamic>(
                          builder: (_) => const BirthFormScreen()),
                    );
                    if (birth != null && context.mounted) {
                      await context.read<ProfileController>().setBirth(birth);
                      if (context.mounted) {
                        // The biggest drop-off in the funnel ends here.
                        context.read<Analytics>().onboardingCompleted(
                              hasBirthTime: birth.timeIsKnown,
                              hasBirthPlace: birth.placeIsKnown,
                            );
                      }
                    }
                  },
                  child: const Text('Start'),
                ),
              ],
            ),
          ),
        ),
      );
}
