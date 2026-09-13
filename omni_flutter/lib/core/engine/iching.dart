/// I Ching: the eight trigrams, the sixty-four hexagrams in King Wen order, and
/// the three-coin casting method.
///
/// The coin method is not a uniform draw over the sixty-four: a line comes out
/// old yin one time in eight, young yang three times in eight, young yin three
/// in eight and old yang one in eight. Getting that distribution right is the
/// difference between a reading and a random number, and it is what produces
/// changing lines and therefore a second hexagram.
library;

import 'dart:math';

enum Trigram {
  qian('乾', 'Heaven', '☰', 0x7),
  dui('兑', 'Lake', '☱', 0x6),
  li('离', 'Fire', '☲', 0x5),
  zhen('震', 'Thunder', '☳', 0x4),
  xun('巽', 'Wind', '☴', 0x3),
  kan('坎', 'Water', '☵', 0x2),
  gen('艮', 'Mountain', '☶', 0x1),
  kun('坤', 'Earth', '☷', 0x0);

  const Trigram(this.chinese, this.english, this.symbol, this.bits);
  final String chinese;
  final String english;
  final String symbol;

  /// Three bits, bottom line in the high bit.
  final int bits;

  static Trigram fromBits(int bits) =>
      Trigram.values.firstWhere((t) => t.bits == (bits & 0x7));
}

/// A cast line. The two "old" values are the ones that change.
enum LineValue {
  oldYin(6, '老阴', true, false),
  youngYang(7, '少阳', false, true),
  youngYin(8, '少阴', false, false),
  oldYang(9, '老阳', true, true);

  const LineValue(this.number, this.chinese, this.isChanging, this.isYang);
  final int number;
  final String chinese;
  final bool isChanging;
  final bool isYang;

  /// What this line becomes in the resulting hexagram.
  bool get transformedIsYang => isChanging ? !isYang : isYang;
}

class Hexagram {
  const Hexagram(this.number, this.chinese, this.english, this.gist);

  /// King Wen number, 1 to 64.
  final int number;
  final String chinese;
  final String english;

  /// A single modern sentence. This is the line the share card shows, so it has
  /// to stand on its own without the classical commentary around it.
  final String gist;

  Trigram get lowerTrigram => Trigram.fromBits(_lowerBits[number]!);
  Trigram get upperTrigram => Trigram.fromBits(_upperBits[number]!);

  String get symbolPair => '${upperTrigram.symbol}${lowerTrigram.symbol}';

  /// Upper over lower, the way a hexagram is named in Chinese.
  String get composition =>
      '${upperTrigram.chinese}${upperTrigram.english} over '
      '${lowerTrigram.chinese}${lowerTrigram.english}';

  static Hexagram byNumber(int n) => _hexagrams[n - 1];

  /// Looks up the hexagram for a set of six lines, bottom first.
  static Hexagram fromLines(List<bool> yangFromBottom) {
    assert(yangFromBottom.length == 6);
    var lower = 0;
    var upper = 0;
    for (var i = 0; i < 3; i++) {
      // Bottom line occupies the high bit of the trigram.
      if (yangFromBottom[i]) lower |= 1 << (2 - i);
      if (yangFromBottom[i + 3]) upper |= 1 << (2 - i);
    }
    return byNumber(_kingWen[Trigram.fromBits(lower)]![Trigram.fromBits(upper)]!);
  }

  @override
  String toString() => '$number $chinese $english';
}

/// The result of a casting: six lines, the hexagram they form, and — when any
/// line changed — the hexagram they turn into.
class IChingReading {
  const IChingReading({
    required this.lines,
    required this.primary,
    required this.transformed,
    required this.question,
  });

  /// Bottom line first, the order they are cast in.
  final List<LineValue> lines;
  final Hexagram primary;

  /// Null when nothing changed, which happens about one cast in eighteen.
  final Hexagram? transformed;

  final String question;

  List<int> get changingLinePositions => [
        for (var i = 0; i < lines.length; i++)
          if (lines[i].isChanging) i + 1,
      ];

  bool get hasChange => transformed != null;

  /// A reading with no changing lines is a settled situation; one with several
  /// is a situation in motion. Users read this as "how much is up in the air".
  String get movement => switch (changingLinePositions.length) {
        0 => 'Settled — the situation is what it is.',
        1 => 'One line moving — a single hinge decides this.',
        2 || 3 => 'In motion — several things are shifting at once.',
        _ => 'Volatile — almost everything here is in flux.',
      };

  Map<String, dynamic> toJson() => {
        'question': question,
        'primary': '${primary.number} ${primary.chinese} ${primary.english}',
        'primaryGist': primary.gist,
        'composition': primary.composition,
        'lines': lines.map((l) => l.number).toList(),
        'changingLines': changingLinePositions,
        'transformed': transformed == null
            ? null
            : '${transformed!.number} ${transformed!.chinese} '
                '${transformed!.english}',
        'transformedGist': transformed?.gist,
        'movement': movement,
      };
}

/// Casts a hexagram by the three-coin method.
///
/// [random] is injectable so the casting can be tested; leave it null in the
/// app so every consultation is genuinely its own throw.
IChingReading castHexagram({String question = '', Random? random}) {
  final rng = random ?? Random.secure();
  final lines = <LineValue>[];

  for (var i = 0; i < 6; i++) {
    // Heads counts three, tails two, so the sum runs from six to nine.
    var sum = 0;
    for (var coin = 0; coin < 3; coin++) {
      sum += rng.nextBool() ? 3 : 2;
    }
    lines.add(LineValue.values.firstWhere((v) => v.number == sum));
  }

  final primary = Hexagram.fromLines([for (final l in lines) l.isYang]);
  final changed = lines.any((l) => l.isChanging);

  return IChingReading(
    lines: lines,
    primary: primary,
    transformed: changed
        ? Hexagram.fromLines([for (final l in lines) l.transformedIsYang])
        : null,
    question: question,
  );
}

/// King Wen numbers indexed by lower trigram then upper trigram.
const Map<Trigram, Map<Trigram, int>> _kingWen = {
  Trigram.qian: {
    Trigram.qian: 1, Trigram.dui: 43, Trigram.li: 14, Trigram.zhen: 34,
    Trigram.xun: 9, Trigram.kan: 5, Trigram.gen: 26, Trigram.kun: 11,
  },
  Trigram.dui: {
    Trigram.qian: 10, Trigram.dui: 58, Trigram.li: 38, Trigram.zhen: 54,
    Trigram.xun: 61, Trigram.kan: 60, Trigram.gen: 41, Trigram.kun: 19,
  },
  Trigram.li: {
    Trigram.qian: 13, Trigram.dui: 49, Trigram.li: 30, Trigram.zhen: 55,
    Trigram.xun: 37, Trigram.kan: 63, Trigram.gen: 22, Trigram.kun: 36,
  },
  Trigram.zhen: {
    Trigram.qian: 25, Trigram.dui: 17, Trigram.li: 21, Trigram.zhen: 51,
    Trigram.xun: 42, Trigram.kan: 3, Trigram.gen: 27, Trigram.kun: 24,
  },
  Trigram.xun: {
    Trigram.qian: 44, Trigram.dui: 28, Trigram.li: 50, Trigram.zhen: 32,
    Trigram.xun: 57, Trigram.kan: 48, Trigram.gen: 18, Trigram.kun: 46,
  },
  Trigram.kan: {
    Trigram.qian: 6, Trigram.dui: 47, Trigram.li: 64, Trigram.zhen: 40,
    Trigram.xun: 59, Trigram.kan: 29, Trigram.gen: 4, Trigram.kun: 7,
  },
  Trigram.gen: {
    Trigram.qian: 33, Trigram.dui: 31, Trigram.li: 56, Trigram.zhen: 62,
    Trigram.xun: 53, Trigram.kan: 39, Trigram.gen: 52, Trigram.kun: 15,
  },
  Trigram.kun: {
    Trigram.qian: 12, Trigram.dui: 45, Trigram.li: 35, Trigram.zhen: 16,
    Trigram.xun: 20, Trigram.kan: 8, Trigram.gen: 23, Trigram.kun: 2,
  },
};

/// Reverse index, built once from [_kingWen].
final Map<int, int> _lowerBits = {
  for (final lower in _kingWen.entries)
    for (final upper in lower.value.entries) upper.value: lower.key.bits,
};

final Map<int, int> _upperBits = {
  for (final lower in _kingWen.entries)
    for (final upper in lower.value.entries) upper.value: upper.key.bits,
};

const List<Hexagram> _hexagrams = [
  Hexagram(1, '乾', 'The Creative',
      'Pure initiative. Nothing is stopping you but the size of the ask.'),
  Hexagram(2, '坤', 'The Receptive',
      'Support rather than lead. Following is the strong move here.'),
  Hexagram(3, '屯', 'Difficulty at the Beginning',
      'Chaotic starts are normal. Do not read the mess as a verdict.'),
  Hexagram(4, '蒙', 'Youthful Folly',
      'You do not know enough yet. Ask once, sincerely, then listen.'),
  Hexagram(5, '需', 'Waiting',
      'The timing is not yours to force. Prepare while you wait.'),
  Hexagram(6, '讼', 'Conflict',
      'You may be right and still lose. Settle before it hardens.'),
  Hexagram(7, '师', 'The Army',
      'This needs discipline and a clear chain of command, not passion.'),
  Hexagram(8, '比', 'Holding Together',
      'Pick your people deliberately. Alliance beats solo effort now.'),
  Hexagram(9, '小畜', 'Small Taming',
      'Small restraint, small gains. Not the season for the big swing.'),
  Hexagram(10, '履', 'Treading',
      'Walking a narrow line. Courtesy is what keeps you safe.'),
  Hexagram(11, '泰', 'Peace',
      'Things are flowing. Use the good stretch, do not just enjoy it.'),
  Hexagram(12, '否', 'Standstill',
      'Blocked on purpose. Withdraw rather than push against a wall.'),
  Hexagram(13, '同人', 'Fellowship',
      'Shared purpose with people unlike you. Keep it open, not clannish.'),
  Hexagram(14, '大有', 'Great Possession',
      'You have more than you think. The risk is carelessness.'),
  Hexagram(15, '谦', 'Modesty',
      'Understate it. Real weight does not need to announce itself.'),
  Hexagram(16, '豫', 'Enthusiasm',
      'Momentum is available. Set it moving before the mood passes.'),
  Hexagram(17, '随', 'Following',
      'Adapt to what is actually happening, not the plan you had.'),
  Hexagram(18, '蛊', 'Work on the Decayed',
      'Something was left to rot. Repair work now, and it will take time.'),
  Hexagram(19, '临', 'Approach',
      'A good window is opening. Move while it is open.'),
  Hexagram(20, '观', 'Contemplation',
      'Observe before acting. You are being watched too.'),
  Hexagram(21, '噬嗑', 'Biting Through',
      'An obstacle needs decisive force. Half measures prolong it.'),
  Hexagram(22, '贲', 'Grace',
      'Presentation matters, but do not mistake it for substance.'),
  Hexagram(23, '剥', 'Splitting Apart',
      'Something is coming apart. Do not prop up what is finished.'),
  Hexagram(24, '复', 'Return',
      'The turn has already happened, quietly. Begin again small.'),
  Hexagram(25, '无妄', 'Innocence',
      'Act from a clean motive. Cleverness backfires here.'),
  Hexagram(26, '大畜', 'Great Taming',
      'Hold your force in reserve. Stored strength compounds.'),
  Hexagram(27, '颐', 'Nourishment',
      'Watch what you feed yourself, in food, feed and company.'),
  Hexagram(28, '大过', 'Great Exceeding',
      'The load is past what the structure can hold. Lighten it now.'),
  Hexagram(29, '坎', 'The Abysmal',
      'Repeated danger. Consistency is what gets you through, not brilliance.'),
  Hexagram(30, '离', 'The Clinging',
      'You shine by depending on something. Know what you are attached to.'),
  Hexagram(31, '咸', 'Influence',
      'Mutual attraction, genuine. Respond without scheming.'),
  Hexagram(32, '恒', 'Duration',
      'Endurance over intensity. Keep the same direction long enough.'),
  Hexagram(33, '遁', 'Retreat',
      'Withdrawing is not losing. Leave while leaving is still cheap.'),
  Hexagram(34, '大壮', 'Great Power',
      'You have force. Power without restraint breaks what it touches.'),
  Hexagram(35, '晋', 'Progress',
      'Visible advancement. Let the recognition be earned, not chased.'),
  Hexagram(36, '明夷', 'Darkening of the Light',
      'Keep your brilliance hidden for now. It is not a safe room.'),
  Hexagram(37, '家人', 'The Family',
      'Order at home first. Roles clear, then everything else works.'),
  Hexagram(38, '睽', 'Opposition',
      'You are misaligned, not enemies. Find the small shared thing.'),
  Hexagram(39, '蹇', 'Obstruction',
      'The road is blocked. Turn inward and get help; do not ram it.'),
  Hexagram(40, '解', 'Deliverance',
      'The knot loosens. Clear the debris quickly, then rest.'),
  Hexagram(41, '损', 'Decrease',
      'Give something up on purpose. The subtraction is the gain.'),
  Hexagram(42, '益', 'Increase',
      'A generous season. Spend it on others and it multiplies.'),
  Hexagram(43, '夬', 'Breakthrough',
      'Say the thing out loud. Resolute, public, without malice.'),
  Hexagram(44, '姤', 'Coming to Meet',
      'Something small has entered. Harmless now, not harmless later.'),
  Hexagram(45, '萃', 'Gathering Together',
      'People are converging. Give them a centre or it scatters.'),
  Hexagram(46, '升', 'Pushing Upward',
      'Steady ascent, step by step. No leaps available.'),
  Hexagram(47, '困', 'Oppression',
      'Genuinely constrained. Conserve energy; words carry no weight now.'),
  Hexagram(48, '井', 'The Well',
      'The source is there but the access is broken. Fix the access.'),
  Hexagram(49, '革', 'Revolution',
      'The old form has to go. Change it once, at the right moment.'),
  Hexagram(50, '鼎', 'The Cauldron',
      'Something is being transformed. Give it heat and time.'),
  Hexagram(51, '震', 'The Arousing',
      'A shock arrives. Steady nerves are the whole test.'),
  Hexagram(52, '艮', 'Keeping Still',
      'Stop. Stillness at the right moment is an action.'),
  Hexagram(53, '渐', 'Development',
      'Gradual and orderly. Skipping a stage undoes the whole thing.'),
  Hexagram(54, '归妹', 'The Marrying Maiden',
      'You are entering on someone else terms. Know the position you take.'),
  Hexagram(55, '丰', 'Abundance',
      'Peak. Peaks are brief, so act at full light while it lasts.'),
  Hexagram(56, '旅', 'The Wanderer',
      'You are a guest here. Travel light and do not overstay.'),
  Hexagram(57, '巽', 'The Gentle',
      'Persistent, quiet influence. Repetition beats force.'),
  Hexagram(58, '兑', 'The Joyous',
      'Openness and pleasure shared. Say the honest, kind thing.'),
  Hexagram(59, '涣', 'Dispersion',
      'Rigidity dissolves. Let the blockage break up and scatter.'),
  Hexagram(60, '节', 'Limitation',
      'Set the limit yourself, or one gets set for you.'),
  Hexagram(61, '中孚', 'Inner Truth',
      'Sincerity carries further than argument. Mean it and they feel it.'),
  Hexagram(62, '小过', 'Small Exceeding',
      'Attend to small things carefully. Not the moment for grand gestures.'),
  Hexagram(63, '既济', 'After Completion',
      'You have arrived, and that is when it starts to slip. Maintain.'),
  Hexagram(64, '未济', 'Before Completion',
      'Almost. The last stretch is where care matters most.'),
];
