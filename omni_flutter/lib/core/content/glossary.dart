/// Plain-English explanations for every Eastern term the app shows.
///
/// The audience is American and mostly has no prior exposure to Chinese
/// metaphysics. They arrive knowing Sun, Moon and Rising, and knowing roughly
/// what tarot is. Everything on the Eastern side is new.
///
/// So the rule this file exists to enforce: **no term appears without its
/// meaning within reach.** A chart that says "比肩 Friend" and leaves it there
/// is not mysterious, it is unreadable, and an unreadable screen does not get
/// screenshotted or subscribed to.
///
/// Where there is an honest Western parallel, [westernAnchor] gives it. Where
/// there is not — Metal has no counterpart in a four-element system — saying
/// so is more interesting than forcing one.
library;

class GlossaryEntry {
  const GlossaryEntry({
    required this.id,
    required this.term,
    required this.chinese,
    required this.pinyin,
    required this.oneLine,
    required this.detail,
    this.westernAnchor,
  });

  /// Stable key used by the UI.
  final String id;

  /// The English label the app shows.
  final String term;

  final String chinese;
  final String pinyin;

  /// Under a dozen words. This is what sits next to the term on screen.
  final String oneLine;

  /// Two or three sentences, for when someone taps.
  final String detail;

  /// The closest thing a Western astrology reader already knows, when one
  /// honestly exists.
  final String? westernAnchor;

  String get label => '$term $chinese';
}

const List<GlossaryEntry> glossaryEntries = [
  GlossaryEntry(
    id: 'dayMaster',
    term: 'Day master',
    chinese: '日主',
    pinyin: 'rì zhǔ',
    oneLine: 'The one character your whole chart is read around.',
    detail:
        'Of the eight characters in your Ba Zi, the one for the day you were '
        'born stands for you. Everything else in the chart is described by how '
        'it treats that character — feeding it, draining it, competing with '
        'it. Ask a practitioner what you are and this is the answer they give.',
    westernAnchor:
        'Nearest thing you already know: your Sun sign. The difference is that '
        'a Sun sign describes what you are like, and a day master describes '
        'what everything else in your life is doing to you.',
  ),
  GlossaryEntry(
    id: 'fourPillars',
    term: 'Four pillars',
    chinese: '四柱',
    pinyin: 'sì zhù',
    oneLine: 'Your year, month, day and hour, two characters each.',
    detail:
        'Chinese astrology writes a birth moment as eight characters in four '
        'columns — hence Ba Zi, "eight characters". The year pillar is the one '
        'you already know, because its second character is your zodiac animal. '
        'The day pillar is the one that describes you.',
    westernAnchor:
        'Structurally it plays the role a natal chart does: one snapshot of a '
        'moment, read for what it says about a person.',
  ),
  GlossaryEntry(
    id: 'tenGods',
    term: 'Ten gods',
    chinese: '十神',
    pinyin: 'shí shén',
    oneLine: 'How each character in the chart treats your day master.',
    detail:
        'There are exactly ten ways one element can relate to another once you '
        'account for yin and yang, and each has a name — Direct Wealth, Seven '
        'Killings, Eating God. They are not deities. They are relationships, '
        'and they are what turns a chart from a list of characters into a '
        'reading.',
    westernAnchor:
        'The closest parallel is aspects: not what a planet is, but what it '
        'does to another one.',
  ),
  GlossaryEntry(
    id: 'fivePhases',
    term: 'Five phases',
    chinese: '五行',
    pinyin: 'wǔ xíng',
    oneLine: 'Wood, Fire, Earth, Metal and Water, in balance or not.',
    detail:
        'Everything in the chart is sorted into five phases that feed and '
        'restrain each other in a fixed cycle: Wood feeds Fire, Fire makes '
        'Earth, Earth holds Metal, Metal carries Water, Water grows Wood. What '
        'your chart is short of matters more than what it has plenty of.',
    westernAnchor:
        'Western astrology has four elements and no Metal. That missing fifth '
        'is precision, boundaries and the ability to cut — a whole register a '
        'Western chart structurally cannot describe.',
  ),
  GlossaryEntry(
    id: 'solarTerm',
    term: 'Solar term',
    chinese: '节气',
    pinyin: 'jié qì',
    oneLine: 'One of 24 exact points in the sun’s year.',
    detail:
        'The solar year is cut into 24 named segments by where the sun '
        'actually is, not by the calendar. Half of them open a Chinese month, '
        'which is why your month pillar can change on the 5th of a month '
        'rather than the 1st.',
    westernAnchor:
        'Two of them you already use: the equinoxes and the solstices are '
        'solar terms.',
  ),
  GlossaryEntry(
    id: 'startOfSpring',
    term: 'Start of Spring',
    chinese: '立春',
    pinyin: 'lì chūn',
    oneLine: 'Where the Chinese astrological year actually turns.',
    detail:
        'Not 1 January, and not Chinese New Year either. The astrological year '
        'turns at Start of Spring, around 4 February. Someone born in late '
        'January belongs to the previous animal, which is why plenty of people '
        'have the wrong zodiac sign written down.',
  ),
  GlossaryEntry(
    id: 'luckPillars',
    term: 'Luck pillars',
    chinese: '大运',
    pinyin: 'dà yùn',
    oneLine: 'Ten-year chapters your life moves through.',
    detail:
        'Your chart is fixed, but you move through it. Every ten years a new '
        'pillar takes over and changes what the same chart produces. The '
        'sequence runs forward or backward depending on your birth year, and '
        'it does not start at birth — it opens at an age worked out from how '
        'far your birth sat from a solar term.',
    westernAnchor:
        'Progressions and transits do a similar job: the birth chart stays '
        'still and time moves across it.',
  ),
  GlossaryEntry(
    id: 'annualPillar',
    term: 'Annual pillar',
    chinese: '流年',
    pinyin: 'liú nián',
    oneLine: 'The character of one specific year.',
    detail:
        'Each year has its own two characters, and the reading comes from how '
        'they meet your chart and the ten-year pillar you are currently in. '
        'This is why the same year can be excellent for one person and brutal '
        'for another.',
  ),
  GlossaryEntry(
    id: 'naYin',
    term: 'Sound element',
    chinese: '纳音',
    pinyin: 'nà yīn',
    oneLine: 'A poetic name for your birth year, like "Sea Gold".',
    detail:
        'The sixty-year cycle carries thirty image-names, two years each — '
        'Furnace Fire, Willow Wood, Great Sea Water. It is the most quoted and '
        'least technical part of a chart, and the part people actually '
        'remember about themselves.',
  ),
  GlossaryEntry(
    id: 'clash',
    term: 'Clash',
    chinese: '冲',
    pinyin: 'chōng',
    oneLine: 'Two signs sitting directly opposite each other.',
    detail:
        'Six positions apart on the twelve-animal wheel means a clash: Rat '
        'against Horse, Tiger against Monkey. It reads as disruption and '
        'movement rather than doom — things get shaken loose.',
    westernAnchor:
        'It is the same geometry as an opposition, and it means much the same '
        'thing.',
  ),
  GlossaryEntry(
    id: 'harmony',
    term: 'Six harmony',
    chinese: '六合',
    pinyin: 'liù hé',
    oneLine: 'A pair of signs that get on without trying.',
    detail:
        'Six specific animal pairings are read as naturally cooperative — Rat '
        'with Ox, Tiger with Pig. In a compatibility reading this is the '
        'strongest single thing two charts can share.',
  ),
  GlossaryEntry(
    id: 'trine',
    term: 'Trine',
    chinese: '三合',
    pinyin: 'sān hé',
    oneLine: 'Three signs four apart that pull in one direction.',
    detail:
        'The twelve animals split into four groups of three, each spaced '
        'evenly around the wheel and each pooling into one element. People in '
        'the same trine tend to understand each other without explaining '
        'themselves.',
    westernAnchor:
        'Literally the same shape as a Western trine: an equilateral triangle '
        'on the wheel, and the same easy reading.',
  ),
  GlossaryEntry(
    id: 'benmingYear',
    term: 'Your animal year',
    chinese: '本命年',
    pinyin: 'běn mìng nián',
    oneLine: 'Your own zodiac year, which comes round every twelve.',
    detail:
        'Western readers usually assume the year of your own animal is your '
        'lucky one. It is the opposite: tradition treats it as an exposed '
        'year, and it is why people in China wear red on it.',
  ),
  GlossaryEntry(
    id: 'taiSui',
    term: 'Clashing the year',
    chinese: '冲太岁',
    pinyin: 'chōng tài suì',
    oneLine: 'The year sitting opposite your own animal.',
    detail:
        'Six years after your animal year comes the year directly across the '
        'wheel from it. Traditionally the most disruptive year in the twelve — '
        'moves, job changes, relationships ending or starting abruptly.',
  ),
  GlossaryEntry(
    id: 'yiJi',
    term: 'Good for / Not today',
    chinese: '宜 / 忌',
    pinyin: 'yí / jì',
    oneLine: 'What today supports, and what it pushes back on.',
    detail:
        'Chinese almanacs have printed a two-column list for every day for '
        'centuries: things the day favors on one side, things to leave alone '
        'on the other. Here the lists come from how today’s characters '
        'meet yours, so they are yours rather than everyone’s.',
  ),
  GlossaryEntry(
    id: 'hiddenStems',
    term: 'Hidden stems',
    chinese: '藏干',
    pinyin: 'cáng gān',
    oneLine: 'Extra elements concealed inside each animal sign.',
    detail:
        'Each of the twelve signs hides one to three more elements inside it, '
        'left over from the season it belongs to. They carry most of the '
        'weight in a real reading, which is why a chart cannot be scored from '
        'the eight visible characters alone.',
  ),
  GlossaryEntry(
    id: 'yinYang',
    term: 'Yin and yang',
    chinese: '阴阳',
    pinyin: 'yīn yáng',
    oneLine: 'The two polarities every character carries.',
    detail:
        'Every stem and branch is either yang (active, outward) or yin '
        '(receptive, inward). It is not good and bad, and it is not male and '
        'female — it is the direction a thing moves in, and it decides several '
        'rules including which way your ten-year cycle runs.',
  ),
];

final Map<String, GlossaryEntry> _byId = {
  for (final entry in glossaryEntries) entry.id: entry,
};

GlossaryEntry? glossaryFor(String id) => _byId[id];

/// Throws in debug if a screen references a term that does not exist, so a
/// typo in an id surfaces during development rather than as a dead tap.
GlossaryEntry requireGlossary(String id) {
  final entry = _byId[id];
  assert(entry != null, 'No glossary entry for "$id"');
  return entry!;
}
