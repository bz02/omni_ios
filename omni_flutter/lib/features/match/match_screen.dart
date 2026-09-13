/// Compatibility.
///
/// This screen is the growth engine: a result needs a second birthday, so every
/// use is a reason to message someone. The two traditions are scored and shown
/// separately, because "Chinese astrology rates you 88 and Western rates you
/// 41" is a far more shareable result than a single averaged number.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/billing/entitlements.dart';
import '../../core/engine/compatibility.dart';
import '../../core/engine/soul_blueprint.dart';
import '../../core/theme/modern_theme.dart';
import '../../state/profile_controller.dart';
import '../onboarding/birth_form_screen.dart';
import '../paywall/paywall_screen.dart';

class MatchScreen extends StatelessWidget {
  const MatchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileController>();

    if (!profile.hasProfile) {
      return Scaffold(
        appBar: AppBar(title: const Text('Match')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Text('Add your own birth details first.',
                textAlign: TextAlign.center, style: ModernTheme.body),
          ),
        ),
      );
    }

    final people = profile.people;
    return Scaffold(
      appBar: AppBar(title: const Text('Match')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _add(context),
        icon: const Icon(Icons.add),
        label: const Text('Add someone'),
      ),
      body: people.isEmpty
          ? _Empty(onAdd: () => _add(context))
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 96),
              itemCount: people.length,
              itemBuilder: (context, index) {
                final person = people[index];
                final result = profile.matchWith(person);
                if (result == null) return const SizedBox.shrink();
                return _PersonTile(
                  person: person,
                  result: result,
                  onTap: () => _open(context, person, result),
                  onDelete: () => profile.removePerson(person.id),
                );
              },
            ),
    );
  }

  Future<void> _add(BuildContext context) async {
    final entitlements = context.read<EntitlementsController>();
    final decision = entitlements.check(PremiumFeature.compatibility);
    if (decision is AccessNeedsUpgrade) {
      await PaywallScreen.show(context,
          trigger: PremiumFeature.compatibility,
          coinPrice: decision.coinPrice);
      return;
    }

    if (!context.mounted) return;
    final birth = await Navigator.of(context).push<BirthData>(
      MaterialPageRoute(
        builder: (_) => const BirthFormScreen(
          title: 'Their birth moment',
          subtitle:
              'Both traditions need the same four things. A date alone still '
              'works, it just leaves the Moons out.',
          askForName: true,
        ),
      ),
    );
    if (birth == null || !context.mounted) return;

    await context.read<ProfileController>().addPerson(SavedPerson(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          name: birth.displayName ?? 'Them',
          birth: birth,
        ));
    await entitlements.recordUse(PremiumFeature.compatibility);
  }

  void _open(
          BuildContext context, SavedPerson person, CompatibilityResult result) =>
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => _MatchDetailScreen(person: person, result: result),
        ),
      );
}

class _Empty extends StatelessWidget {
  const _Empty({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('☯', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 18),
              Text('Two charts, two people',
                  style: ModernTheme.header.copyWith(fontSize: 22)),
              const SizedBox(height: 10),
              Text(
                'Add a birthday and we will score you against them twice — once '
                'the Chinese way, once the Western way — and show you where the '
                'two disagree.',
                textAlign: TextAlign.center,
                style: ModernTheme.body,
              ),
              const SizedBox(height: 24),
              ElevatedButton(onPressed: onAdd, child: const Text('Add someone')),
            ],
          ),
        ),
      );
}

class _PersonTile extends StatelessWidget {
  const _PersonTile({
    required this.person,
    required this.result,
    required this.onTap,
    required this.onDelete,
  });

  final SavedPerson person;
  final CompatibilityResult result;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => Dismissible(
        key: ValueKey(person.id),
        direction: DismissDirection.endToStart,
        onDismissed: (_) => onDelete(),
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 24),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: ModernTheme.vermilion,
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Icon(Icons.delete_outline, color: Colors.white),
        ),
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(18),
            decoration: ModernTheme.cardDecoration,
            child: Row(
              children: [
                _ScoreDot(score: result.score),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(person.name,
                          style: ModernTheme.subHeader.copyWith(fontSize: 17)),
                      const SizedBox(height: 4),
                      Text(
                        '${result.band} · east ${result.easternScore} / '
                        'west ${result.westernScore}',
                        style: ModernTheme.caption.copyWith(fontSize: 13),
                      ),
                    ],
                  ),
                ),
                if (result.disagreement >= 25)
                  const Padding(
                    padding: EdgeInsets.only(right: 6),
                    child: Text('⚖️', style: TextStyle(fontSize: 18)),
                  ),
                const Icon(Icons.chevron_right, color: ModernTheme.textSub),
              ],
            ),
          ),
        ),
      );
}

class _ScoreDot extends StatelessWidget {
  const _ScoreDot({required this.score});
  final int score;

  @override
  Widget build(BuildContext context) => Container(
        width: 52,
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: ModernTheme.forScore(score).withOpacity(0.12),
          shape: BoxShape.circle,
          border: Border.all(color: ModernTheme.forScore(score), width: 2),
        ),
        child: Text('$score',
            style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: ModernTheme.forScore(score))),
      );
}

class _MatchDetailScreen extends StatelessWidget {
  const _MatchDetailScreen({required this.person, required this.result});

  final SavedPerson person;
  final CompatibilityResult result;

  @override
  Widget build(BuildContext context) {
    final east = result.factors.where((f) => f.tradition == 'east').toList();
    final west = result.factors.where((f) => f.tradition == 'west').toList();

    return Scaffold(
      appBar: AppBar(title: Text('You and ${person.name}')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: ModernTheme.ink,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              children: [
                Text('${result.score}',
                    style: TextStyle(
                      fontSize: 56,
                      fontWeight: FontWeight.w800,
                      color: ModernTheme.forScore(result.score),
                      height: 1,
                    )),
                Text(result.band.toUpperCase(),
                    style: ModernTheme.caption.copyWith(
                        letterSpacing: 2,
                        fontSize: 11,
                        color: Colors.white70,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: _Half(
                        label: '東 Chinese',
                        score: result.easternScore,
                        color: ModernTheme.jade,
                      ),
                    ),
                    Expanded(
                      child: _Half(
                        label: '西 Western',
                        score: result.westernScore,
                        color: ModernTheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(result.headline,
                    textAlign: TextAlign.center,
                    style: ModernTheme.body
                        .copyWith(color: Colors.white70, fontSize: 14)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _Flag(
              label: 'GREEN FLAG',
              body: result.greenFlag,
              color: ModernTheme.jade),
          const SizedBox(height: 12),
          _Flag(
              label: 'WATCH THIS',
              body: result.redFlag,
              color: ModernTheme.vermilion),
          const SizedBox(height: 24),
          _FactorGroup(title: 'Chinese reading', factors: east),
          const SizedBox(height: 20),
          _FactorGroup(title: 'Western reading', factors: west),
        ],
      ),
    );
  }
}

class _Half extends StatelessWidget {
  const _Half({required this.label, required this.score, required this.color});
  final String label;
  final int score;
  final Color color;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Text(label,
              style: ModernTheme.caption
                  .copyWith(color: Colors.white54, fontSize: 11)),
          const SizedBox(height: 4),
          Text('$score',
              style: TextStyle(
                  fontSize: 26, fontWeight: FontWeight.w700, color: color)),
        ],
      );
}

class _Flag extends StatelessWidget {
  const _Flag(
      {required this.label, required this.body, required this.color});
  final String label;
  final String body;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 10,
                    letterSpacing: 1.6,
                    fontWeight: FontWeight.w700,
                    color: color)),
            const SizedBox(height: 8),
            Text(body, style: ModernTheme.body.copyWith(fontSize: 14)),
          ],
        ),
      );
}

class _FactorGroup extends StatelessWidget {
  const _FactorGroup({required this.title, required this.factors});
  final String title;
  final List<MatchFactor> factors;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title.toUpperCase(),
              style: ModernTheme.caption.copyWith(
                  fontSize: 11,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          for (final factor in factors)
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(16),
              decoration: ModernTheme.cardDecoration,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(factor.label,
                            style: ModernTheme.subHeader.copyWith(fontSize: 15)),
                      ),
                      Text('${factor.points}/${factor.maxPoints}',
                          style: ModernTheme.caption.copyWith(
                              fontWeight: FontWeight.w700,
                              color: ModernTheme.textMain)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: factor.points / factor.maxPoints,
                      minHeight: 5,
                      backgroundColor: ModernTheme.border,
                      valueColor: AlwaysStoppedAnimation(
                        ModernTheme.forScore(
                            (factor.points * 100 / factor.maxPoints).round()),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(factor.verdict,
                      style: ModernTheme.body.copyWith(fontSize: 14)),
                ],
              ),
            ),
        ],
      );
}
