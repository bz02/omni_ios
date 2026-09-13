/// Ask a question, get an answer from both traditions at once: three tarot
/// cards and a cast hexagram, side by side.
///
/// Drawing both is the differentiator. A tarot app gives cards; an I Ching app
/// gives a hexagram; this one shows you what happens when a Western oracle and
/// a Chinese one are asked the same question in the same minute.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/analytics/analytics.dart';
import '../../core/billing/entitlements.dart';
import '../../core/engine/iching.dart';
import '../../core/engine/tarot.dart';
import '../../core/theme/modern_theme.dart';
import '../../screens/pet_psychic_screen.dart';
import '../../screens/the_roast_screen.dart';
import '../../features/scanner/ui/scanner_screen.dart';
import '../paywall/paywall_screen.dart';

class OracleScreen extends StatefulWidget {
  const OracleScreen({super.key});

  @override
  State<OracleScreen> createState() => _OracleScreenState();
}

class _OracleScreenState extends State<OracleScreen> {
  final _controller = TextEditingController();
  TarotSpread _spread = TarotSpread.situation;
  TarotReading? _tarot;
  IChingReading? _iching;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final entitlements = context.watch<EntitlementsController>();
    final decision = entitlements.check(PremiumFeature.oracle);
    final remaining = decision is AccessAllowed ? decision.remaining : 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Oracle'),
        actions: [
          if (remaining != null && remaining > 0)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Text('$remaining free left',
                    style: ModernTheme.caption.copyWith(fontSize: 12)),
              ),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          if (_tarot == null) ...[
            Text('One question. Two oracles.',
                style: ModernTheme.header.copyWith(fontSize: 24)),
            const SizedBox(height: 8),
            Text(
              'Three tarot cards and a hexagram cast with three coins, asked at '
              'the same moment. Where they agree, take it seriously.',
              style: ModernTheme.body,
            ),
            const SizedBox(height: 24),
          ],
          TextField(
            controller: _controller,
            maxLines: 3,
            minLines: 2,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: 'What do you actually want to know?',
              filled: true,
              fillColor: ModernTheme.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: ModernTheme.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: ModernTheme.border),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            children: [
              for (final spread in TarotSpread.values)
                ChoiceChip(
                  label: Text(spread.label),
                  selected: _spread == spread,
                  onSelected: (_) => setState(() => _spread = spread),
                ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _draw(entitlements),
              child: Text(_tarot == null ? 'Draw' : 'Ask again'),
            ),
          ),
          if (_tarot != null) ...[
            const SizedBox(height: 28),
            _TarotResult(reading: _tarot!),
            const SizedBox(height: 20),
            if (_iching != null) _IChingResult(reading: _iching!),
            const SizedBox(height: 20),
            _Convergence(tarot: _tarot!, iching: _iching!),
          ],
          const SizedBox(height: 32),
          const _MoreReadings(),
        ],
      ),
    );
  }

  Future<void> _draw(EntitlementsController entitlements) async {
    final decision = entitlements.check(PremiumFeature.oracle);
    if (decision is AccessNeedsUpgrade) {
      context.read<Analytics>().quotaExhausted(PremiumFeature.oracle);
      await PaywallScreen.show(context,
          trigger: PremiumFeature.oracle, coinPrice: decision.coinPrice);
      return;
    }

    final question = _controller.text.trim();
    setState(() {
      _tarot = drawTarot(spread: _spread, question: question);
      _iching = castHexagram(question: question);
    });
    // Recorded only after the draw actually happened, so a canceled or failed
    // attempt never burns a free use.
    await entitlements.recordUse(PremiumFeature.oracle);
    if (mounted) context.read<Analytics>().readingViewed('oracle');
  }
}

class _TarotResult extends StatelessWidget {
  const _TarotResult({required this.reading});
  final TarotReading reading;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('TAROT · ${reading.spread.label.toUpperCase()}',
              style: ModernTheme.caption.copyWith(
                  fontSize: 10,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w700,
                  color: ModernTheme.primary)),
          const SizedBox(height: 12),
          for (final drawn in reading.cards)
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(16),
              decoration: ModernTheme.cardDecoration,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(drawn.position.toUpperCase(),
                      style: ModernTheme.caption
                          .copyWith(fontSize: 10, letterSpacing: 1.4)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: Text(drawn.card.name,
                            style:
                                ModernTheme.subHeader.copyWith(fontSize: 17)),
                      ),
                      if (drawn.isReversed)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: ModernTheme.vermilion.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text('reversed',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: ModernTheme.vermilion,
                                  fontWeight: FontWeight.w600)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(drawn.keywords.join(' · '),
                      style: ModernTheme.body.copyWith(fontSize: 14)),
                ],
              ),
            ),
          Text(reading.weight, style: ModernTheme.caption.copyWith(fontSize: 12)),
        ],
      );
}

class _IChingResult extends StatelessWidget {
  const _IChingResult({required this.reading});
  final IChingReading reading;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: ModernTheme.ink,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('I CHING · THREE COINS',
                style: ModernTheme.caption.copyWith(
                    fontSize: 10,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w700,
                    color: ModernTheme.jade)),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Lines(reading: reading),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${reading.primary.number} '
                        '${reading.primary.chinese} '
                        '${reading.primary.english}',
                        style: ModernTheme.subHeader
                            .copyWith(color: Colors.white, fontSize: 18),
                      ),
                      const SizedBox(height: 6),
                      Text(reading.primary.composition,
                          style: ModernTheme.caption
                              .copyWith(color: ModernTheme.gold, fontSize: 12)),
                      const SizedBox(height: 10),
                      Text(reading.primary.gist,
                          style: ModernTheme.body
                              .copyWith(color: Colors.white70, fontSize: 14)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(color: Colors.white12),
            const SizedBox(height: 12),
            Text(reading.movement,
                style: ModernTheme.caption
                    .copyWith(color: Colors.white60, fontSize: 12)),
            if (reading.transformed case final transformed?) ...[
              const SizedBox(height: 12),
              Text(
                'Changing into ${transformed.number} '
                '${transformed.chinese} ${transformed.english}',
                style: ModernTheme.subHeader
                    .copyWith(color: ModernTheme.jade, fontSize: 15),
              ),
              const SizedBox(height: 6),
              Text(transformed.gist,
                  style: ModernTheme.body
                      .copyWith(color: Colors.white70, fontSize: 14)),
            ],
          ],
        ),
      );
}

/// Draws the six lines bottom to top, the way a hexagram is built.
class _Lines extends StatelessWidget {
  const _Lines({required this.reading});
  final IChingReading reading;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          for (final line in reading.lines.reversed)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  SizedBox(
                    width: 48,
                    child: line.isYang
                        ? Container(
                            height: 8,
                            decoration: BoxDecoration(
                              color: line.isChanging
                                  ? ModernTheme.gold
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          )
                        : Row(
                            children: [
                              for (var i = 0; i < 2; i++) ...[
                                if (i == 1) const SizedBox(width: 8),
                                Expanded(
                                  child: Container(
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: line.isChanging
                                          ? ModernTheme.gold
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                  ),
                  if (line.isChanging)
                    const Padding(
                      padding: EdgeInsets.only(left: 4),
                      child: Text('◦',
                          style:
                              TextStyle(color: ModernTheme.gold, fontSize: 12)),
                    ),
                ],
              ),
            ),
        ],
      );
}

/// Names the one thing neither oracle gives on its own: whether they agree.
class _Convergence extends StatelessWidget {
  const _Convergence({required this.tarot, required this.iching});
  final TarotReading tarot;
  final IChingReading iching;

  @override
  Widget build(BuildContext context) {
    final tarotSaysChange = tarot.cards.any((c) =>
        c.card.isMajor &&
        const {'Death', 'The Tower', 'Wheel of Fortune', 'Judgement'}
            .contains(c.card.name));
    final ichingSaysChange = iching.changingLinePositions.length >= 2;

    final String verdict;
    if (tarotSaysChange && ichingSaysChange) {
      return _wrap(
        context,
        'Both oracles say the same thing',
        'The cards turned up transformation and the coins gave you '
            '${iching.changingLinePositions.length} moving lines. Two systems '
            'built on completely different assumptions agree that this is not '
            'staying as it is.',
        ModernTheme.jade,
      );
    } else if (!tarotSaysChange && !ichingSaysChange) {
      verdict = 'Neither oracle sees upheaval. The cards are working at '
          'everyday scale and the hexagram is close to settled. Whatever you '
          'are bracing for is probably not coming this week.';
      return _wrap(context, 'Both oracles say hold', verdict, ModernTheme.jade);
    }
    return _wrap(
      context,
      'The two oracles disagree',
      tarotSaysChange
          ? 'The cards point at a turn, the coins say the situation is settled. '
              'Read that as change you want more than change that is arriving.'
          : 'The coins are full of moving lines while the cards stay ordinary. '
              'Something is shifting underneath a surface that still looks '
              'normal.',
      ModernTheme.gold,
    );
  }

  Widget _wrap(
          BuildContext context, String title, String body, Color color) =>
      Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: ModernTheme.subHeader.copyWith(fontSize: 16)),
            const SizedBox(height: 8),
            Text(body, style: ModernTheme.body.copyWith(fontSize: 14)),
          ],
        ),
      );
}

/// The lighter, shareable readings. They are the viral surface — a pet roast
/// gets screenshotted in a way a four-pillar chart never will — so they stay
/// one tap from the oracle rather than being buried.
class _MoreReadings extends StatelessWidget {
  const _MoreReadings();

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ALSO TRY',
              style: ModernTheme.caption.copyWith(
                  fontSize: 11,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          _MoreTile(
            emoji: '🐾',
            title: 'Pet psychic',
            subtitle: 'What your animal is actually thinking',
            builder: (_) => const PetPsychicScreen(),
          ),
          _MoreTile(
            emoji: '🔥',
            title: 'The roast',
            subtitle: 'Your chart, read back to you without mercy',
            builder: (_) => const TheRoastScreen(),
          ),
          _MoreTile(
            emoji: '📷',
            title: 'Energy scanner',
            subtitle: 'Point the camera at anything',
            builder: (_) => const ScannerScreen(),
          ),
        ],
      );
}

class _MoreTile extends StatelessWidget {
  const _MoreTile({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.builder,
  });

  final String emoji;
  final String title;
  final String subtitle;
  final WidgetBuilder builder;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () => Navigator.of(context)
            .push(MaterialPageRoute(builder: builder)),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(16),
          decoration: ModernTheme.cardDecoration,
          child: Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: ModernTheme.subHeader.copyWith(fontSize: 15)),
                    Text(subtitle,
                        style: ModernTheme.caption.copyWith(fontSize: 12)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: ModernTheme.textSub),
            ],
          ),
        ),
      );
}
