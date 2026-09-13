/// The Rider-Waite-Smith deck and the spreads the app draws from it.
///
/// A card carries keywords rather than paragraphs: the paragraph is written at
/// read time by the model, against the querent's own chart, so the same card
/// lands differently for a Fire day master than for a Water one. Keeping the
/// deck as data also means a reading can be reproduced from its seed, which
/// matters for support requests and for tests.
library;

import 'dart:math';

enum Arcana { major, minor }

enum Suit {
  wands('Wands', '🔥', 'Fire', 'drive, work, creative heat'),
  cups('Cups', '💧', 'Water', 'feeling, relationship, intuition'),
  swords('Swords', '💨', 'Air', 'thought, conflict, truth'),
  pentacles('Pentacles', '🌍', 'Earth', 'money, body, the material world');

  const Suit(this.label, this.emoji, this.element, this.domain);
  final String label;
  final String emoji;
  final String element;
  final String domain;
}

class TarotCard {
  const TarotCard({
    required this.id,
    required this.name,
    required this.arcana,
    required this.upright,
    required this.reversed,
    this.suit,
    this.number,
  });

  /// Stable identifier, safe to persist in a saved reading.
  final String id;
  final String name;
  final Arcana arcana;
  final Suit? suit;

  /// 0 to 21 for the majors, 1 to 14 for the minors (11 to 14 are the court).
  final int? number;

  final List<String> upright;
  final List<String> reversed;

  bool get isMajor => arcana == Arcana.major;

  @override
  String toString() => name;
}

/// A card as it landed in a spread.
class DrawnCard {
  const DrawnCard({
    required this.card,
    required this.isReversed,
    required this.position,
  });

  final TarotCard card;
  final bool isReversed;

  /// What this slot of the spread is asking about.
  final String position;

  List<String> get keywords => isReversed ? card.reversed : card.upright;

  String get orientation => isReversed ? 'reversed' : 'upright';

  String get headline => '${card.name}${isReversed ? ' (reversed)' : ''}';

  Map<String, dynamic> toJson() => {
        'position': position,
        'card': card.name,
        'orientation': orientation,
        'keywords': keywords,
      };
}

/// The layouts the app offers. Positions are what makes a spread a spread: the
/// same three cards mean different things in different slots.
enum TarotSpread {
  single('Single Card', ['What you need to see today']),
  threeCard('Past · Present · Future',
      ['What shaped this', 'Where you are now', 'Where it is heading']),
  situation('Situation · Action · Outcome',
      ['The situation as it is', 'What to actually do', 'Where that leads']),
  bridge('The Bridge', [
    'You',
    'Them',
    'What connects you',
    'What has to be put down',
    'Where this goes if nothing changes',
  ]);

  const TarotSpread(this.label, this.positions);
  final String label;
  final List<String> positions;

  int get cardCount => positions.length;
}

class TarotReading {
  const TarotReading({
    required this.spread,
    required this.cards,
    required this.question,
    required this.seed,
  });

  final TarotSpread spread;
  final List<DrawnCard> cards;
  final String question;

  /// Reproduces this exact draw. Stored with the reading so a user can be shown
  /// the same cards when they reopen it.
  final int seed;

  int get reversedCount => cards.where((c) => c.isReversed).length;

  int get majorCount => cards.where((c) => c.card.isMajor).length;

  /// A spread heavy in majors is read as "this is bigger than you"; one with
  /// none is read as "this is day-to-day, and yours to steer".
  String get weight {
    if (majorCount == 0) {
      return 'All minor arcana — everyday scale, and mostly in your hands.';
    }
    if (majorCount >= cards.length - 1 && cards.length > 1) {
      return 'Dominated by major arcana — larger forces than your daily choices.';
    }
    return '$majorCount of ${cards.length} major arcana — part of this is bigger '
        'than the day-to-day.';
  }

  Map<String, dynamic> toJson() => {
        'spread': spread.label,
        'question': question,
        'weight': weight,
        'cards': cards.map((c) => c.toJson()).toList(),
        'seed': seed,
      };
}

/// Draws a spread. Pass [seed] to reproduce a previous reading exactly.
TarotReading drawTarot({
  TarotSpread spread = TarotSpread.threeCard,
  String question = '',
  int? seed,
  double reversalChance = 0.35,
}) {
  final actualSeed = seed ?? Random.secure().nextInt(1 << 32);
  final rng = Random(actualSeed);

  final deck = List<TarotCard>.from(tarotDeck)..shuffle(rng);
  final drawn = <DrawnCard>[];
  for (var i = 0; i < spread.cardCount; i++) {
    drawn.add(DrawnCard(
      card: deck[i],
      isReversed: rng.nextDouble() < reversalChance,
      position: spread.positions[i],
    ));
  }

  return TarotReading(
    spread: spread,
    cards: drawn,
    question: question,
    seed: actualSeed,
  );
}

const List<TarotCard> _majors = [
  TarotCard(
      id: 'major-0',
      name: 'The Fool',
      arcana: Arcana.major,
      number: 0,
      upright: ['new beginnings', 'leap of faith', 'open road', 'innocence'],
      reversed: ['recklessness', 'hesitating at the edge', 'naivety']),
  TarotCard(
      id: 'major-1',
      name: 'The Magician',
      arcana: Arcana.major,
      number: 1,
      upright: ['you have the tools', 'manifestation', 'focused will'],
      reversed: ['manipulation', 'talent going unused', 'illusion']),
  TarotCard(
      id: 'major-2',
      name: 'The High Priestess',
      arcana: Arcana.major,
      number: 2,
      upright: ['intuition', 'what is not being said', 'inner knowing'],
      reversed: ['ignoring your gut', 'secrets kept too long', 'disconnection']),
  TarotCard(
      id: 'major-3',
      name: 'The Empress',
      arcana: Arcana.major,
      number: 3,
      upright: ['abundance', 'nurture', 'creativity', 'the senses'],
      reversed: ['creative block', 'over-giving', 'dependence']),
  TarotCard(
      id: 'major-4',
      name: 'The Emperor',
      arcana: Arcana.major,
      number: 4,
      upright: ['structure', 'authority', 'boundaries that hold'],
      reversed: ['rigidity', 'control', 'authority misused']),
  TarotCard(
      id: 'major-5',
      name: 'The Hierophant',
      arcana: Arcana.major,
      number: 5,
      upright: ['tradition', 'a teacher', 'the established way'],
      reversed: ['breaking with convention', 'dogma', 'going your own way']),
  TarotCard(
      id: 'major-6',
      name: 'The Lovers',
      arcana: Arcana.major,
      number: 6,
      upright: ['union', 'a real choice', 'values aligning'],
      reversed: ['misalignment', 'avoiding the decision', 'split loyalty']),
  TarotCard(
      id: 'major-7',
      name: 'The Chariot',
      arcana: Arcana.major,
      number: 7,
      upright: ['drive', 'control of opposing forces', 'winning through'],
      reversed: ['no direction', 'forcing it', 'wheels spinning']),
  TarotCard(
      id: 'major-8',
      name: 'Strength',
      arcana: Arcana.major,
      number: 8,
      upright: ['quiet courage', 'patience', 'gentleness that holds'],
      reversed: ['self-doubt', 'raw reaction', 'force where softness works']),
  TarotCard(
      id: 'major-9',
      name: 'The Hermit',
      arcana: Arcana.major,
      number: 9,
      upright: ['solitude on purpose', 'looking inward', 'a guiding light'],
      reversed: ['isolation', 'hiding', 'refusing help']),
  TarotCard(
      id: 'major-10',
      name: 'Wheel of Fortune',
      arcana: Arcana.major,
      number: 10,
      upright: ['the turn', 'luck moving', 'a cycle completing'],
      reversed: ['resisting the turn', 'bad timing', 'the same loop again']),
  TarotCard(
      id: 'major-11',
      name: 'Justice',
      arcana: Arcana.major,
      number: 11,
      upright: ['cause and effect', 'fairness', 'the honest account'],
      reversed: ['imbalance', 'dodging accountability', 'bias']),
  TarotCard(
      id: 'major-12',
      name: 'The Hanged Man',
      arcana: Arcana.major,
      number: 12,
      upright: ['pause', 'surrender', 'the view from upside down'],
      reversed: ['stalling', 'martyrdom', 'a pause that became a habit']),
  TarotCard(
      id: 'major-13',
      name: 'Death',
      arcana: Arcana.major,
      number: 13,
      upright: ['an ending that clears ground', 'transformation'],
      reversed: ['clinging to what is over', 'a change refused']),
  TarotCard(
      id: 'major-14',
      name: 'Temperance',
      arcana: Arcana.major,
      number: 14,
      upright: ['balance', 'blending opposites', 'the middle path'],
      reversed: ['excess', 'extremes', 'impatience with the process']),
  TarotCard(
      id: 'major-15',
      name: 'The Devil',
      arcana: Arcana.major,
      number: 15,
      upright: ['attachment', 'the thing you keep going back to', 'shadow'],
      reversed: ['breaking the hold', 'seeing the chain is loose']),
  TarotCard(
      id: 'major-16',
      name: 'The Tower',
      arcana: Arcana.major,
      number: 16,
      upright: ['sudden collapse', 'revelation', 'the false thing falling'],
      reversed: ['a disaster deferred', 'fear of the necessary break']),
  TarotCard(
      id: 'major-17',
      name: 'The Star',
      arcana: Arcana.major,
      number: 17,
      upright: ['hope', 'renewal after damage', 'quiet faith'],
      reversed: ['despair', 'faith lost', 'the light hard to see']),
  TarotCard(
      id: 'major-18',
      name: 'The Moon',
      arcana: Arcana.major,
      number: 18,
      upright: ['illusion', 'anxiety', 'what the dark exaggerates'],
      reversed: ['fog lifting', 'fear released', 'truth surfacing']),
  TarotCard(
      id: 'major-19',
      name: 'The Sun',
      arcana: Arcana.major,
      number: 19,
      upright: ['clarity', 'vitality', 'plain good news'],
      reversed: ['temporary cloud', 'forced brightness']),
  TarotCard(
      id: 'major-20',
      name: 'Judgement',
      arcana: Arcana.major,
      number: 20,
      upright: ['reckoning', 'a calling', 'seeing the whole of it'],
      reversed: ['self-judgement', 'ignoring the call', 'stuck in review']),
  TarotCard(
      id: 'major-21',
      name: 'The World',
      arcana: Arcana.major,
      number: 21,
      upright: ['completion', 'wholeness', 'the circle closed'],
      reversed: ['unfinished business', 'the last step missing']),
];

/// Minor arcana meanings, indexed by suit then by number 1 to 14.
const Map<Suit, List<List<List<String>>>> _minorMeanings = {
  Suit.wands: [
    [['a spark', 'new venture', 'raw inspiration'], ['false start', 'delay', 'the spark not catching']],
    [['planning', 'the first step past the door'], ['fear of the unknown', 'playing small']],
    [['expansion', 'waiting for what you sent out'], ['delays', 'too narrow a view']],
    [['celebration', 'homecoming', 'solid ground'], ['a transition', 'no home base']],
    [['friction', 'scrappy competition'], ['conflict avoided', 'tension held inside']],
    [['recognition', 'a public win'], ['a fall from favour', 'a win nobody saw']],
    [['defending your ground'], ['overwhelmed', 'ground given up']],
    [['speed', 'news arriving', 'everything at once'], ['scattered energy', 'held up']],
    [['resilience', 'one more push', 'guarded'], ['exhaustion', 'paranoia']],
    [['carrying too much'], ['putting it down', 'delegating at last']],
    [['curiosity', 'a spark of news'], ['enthusiasm with no aim']],
    [['bold action', 'going now'], ['recklessness', 'burnout']],
    [['warm confidence', 'magnetism'], ['insecurity', 'jealousy']],
    [['vision', 'natural authority'], ['domineering', 'impulsive rule']],
  ],
  Suit.cups: [
    [['a new feeling', 'an open heart'], ['emotion blocked', 'the cup turned over']],
    [['mutual attraction', 'a real partnership'], ['imbalance', 'a break']],
    [['friendship', 'celebration', 'your people'], ['gossip', 'the third wheel']],
    [['apathy', 'an offer you are not seeing'], ['interest returning']],
    [['grief', 'staring at what spilled'], ['acceptance', 'turning around']],
    [['nostalgia', 'someone from before'], ['stuck in the past']],
    [['too many options', 'a lovely illusion'], ['clarity', 'finally choosing']],
    [['walking away to look for more'], ['drifting', 'afraid to leave']],
    [['contentment', 'the wish granted'], ['smugness', 'the wish that did not land']],
    [['emotional fulfilment', 'harmony at home'], ['the picture cracked']],
    [['a tender message', 'creative feeling'], ['emotional immaturity']],
    [['a romantic offer', 'following the heart'], ['moodiness', 'a fantasy']],
    [['empathy', 'emotional depth'], ['over-giving', 'drowning in it']],
    [['emotional mastery', 'calm under feeling'], ['coldness', 'manipulation']],
  ],
  Suit.swords: [
    [['clarity', 'the breakthrough thought'], ['confusion', 'words used badly']],
    [['stalemate', 'refusing to look'], ['the decision made', 'blindfold off']],
    [['heartbreak', 'the painful true thing'], ['recovery', 'letting the hurt go']],
    [['rest', 'deliberate retreat'], ['restlessness', 'burnout continuing']],
    [['a hollow victory', 'winning at cost'], ['making amends']],
    [['moving to calmer water'], ['unable to leave']],
    [['strategy', 'going it alone', 'sleight of hand'], ['caught', 'confession']],
    [['trapped by your own thinking'], ['seeing the way out']],
    [['anxiety', 'the three a.m. version'], ['relief', 'asking for help']],
    [['rock bottom', 'a definite ending'], ['recovery beginning']],
    [['vigilance', 'news', 'curiosity'], ['gossip', 'scattered thinking']],
    [['fast and sharp', 'headlong'], ['aggression', 'no plan behind it']],
    [['clear judgement', 'independence'], ['coldness', 'harshness']],
    [['intellectual authority', 'truth held firmly'], ['tyranny', 'logic misused']],
  ],
  Suit.pentacles: [
    [['a material opening', 'seed money'], ['the opportunity missed']],
    [['juggling', 'flexible balance'], ['overcommitted']],
    [['collaboration', 'craft', 'learning the trade'], ['poor teamwork']],
    [['holding on', 'security', 'control'], ['loosening the grip', 'scarcity thinking']],
    [['hardship', 'left out in the cold'], ['recovery', 'help arriving']],
    [['generosity', 'give and take'], ['strings attached', 'lopsided']],
    [['patience', 'assessing the harvest'], ['impatience', 'effort misplaced']],
    [['building skill', 'diligence'], ['perfectionism', 'dull repetition']],
    [['self-sufficiency', 'earned comfort'], ['dependence', 'display']],
    [['legacy', 'roots', 'long money'], ['family friction', 'short-term thinking']],
    [['a practical start', 'a new study'], ['procrastination']],
    [['steady methodical progress'], ['stagnation', 'boredom']],
    [['practical nurture', 'abundance managed'], ['overwork', 'smothering']],
    [['prosperity', 'mastery', 'the provider'], ['greed', 'control through money']],
  ],
};

const List<String> _minorNames = [
  'Ace', 'Two', 'Three', 'Four', 'Five', 'Six', 'Seven', 'Eight', 'Nine',
  'Ten', 'Page', 'Knight', 'Queen', 'King',
];

/// The full seventy-eight card deck, built once.
final List<TarotCard> tarotDeck = List.unmodifiable([
  ..._majors,
  for (final suit in Suit.values)
    for (var i = 0; i < 14; i++)
      TarotCard(
        id: '${suit.name}-${i + 1}',
        name: '${_minorNames[i]} of ${suit.label}',
        arcana: Arcana.minor,
        suit: suit,
        number: i + 1,
        upright: _minorMeanings[suit]![i][0],
        reversed: _minorMeanings[suit]![i][1],
      ),
]);
