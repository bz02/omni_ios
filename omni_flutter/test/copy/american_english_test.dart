// The audience is American, and British spelling in a US consumer app reads
// as "this wasn't made for me". The whole codebase was written in British
// English on the first pass, so this guards the correction.
//
// Flutter's own API is exempt: `Colors.grey`, `PurchaseStatus.canceled` and
// friends are identifiers, not prose.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// British spelling → the American one the app should use.
const _britishSpellings = {
  'colour': 'color',
  'colours': 'colors',
  'coloured': 'colored',
  'centre': 'center',
  'centres': 'centers',
  'harmonise': 'harmonize',
  'harmonises': 'harmonizes',
  'recognise': 'recognize',
  'recognised': 'recognized',
  'neighbour': 'neighbor',
  'neighbouring': 'neighboring',
  'behaviour': 'behavior',
  'favourable': 'favorable',
  'unfavourable': 'unfavorable',
  'favour': 'favor',
  'favours': 'favors',
  'modelled': 'modeled',
  'travelled': 'traveled',
  'apologise': 'apologize',
  'organise': 'organize',
  'practise': 'practice',
  'fulfilment': 'fulfillment',
  'judgement': 'judgment',
  'licence': 'license',
  'defence': 'defense',
  'offence': 'offense',
  'analyse': 'analyze',
  'analysed': 'analyzed',
  'summarise': 'summarize',
  'personalise': 'personalize',
  'customise': 'customize',
  'prioritise': 'prioritize',
  'utilise': 'utilize',
  'signalling': 'signaling',
  'sceptical': 'skeptical',
  'programme': 'program',
};

/// Identifiers and proper nouns that cannot be respelled.
///
/// `Judgement` is the title printed on the Rider-Waite-Smith card. It is the
/// card's name, not a spelling of a word, so americanizing it would rename a
/// tarot card.
final _exemptions = RegExp(
  r'Colors?\.\w+|PurchaseStatus\.\w+|PurchaseOutcome\.\w+|'
  r'\bgrey\b|grey\[|Colors\b|Judgement',
);

void main() {
  test('user-facing source uses American spelling', () {
    final offenders = <String>[];

    for (final directory in ['lib', 'test']) {
      final dir = Directory(directory);
      if (!dir.existsSync()) continue;

      for (final entity in dir.listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        // This file necessarily contains the words it forbids.
        if (entity.path.endsWith('american_english_test.dart')) continue;

        final lines = entity.readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          final line = lines[i].replaceAll(_exemptions, '');
          for (final entry in _britishSpellings.entries) {
            if (RegExp('\\b${entry.key}\\b', caseSensitive: false)
                .hasMatch(line)) {
              offenders.add(
                  '${entity.path}:${i + 1} "${entry.key}" → "${entry.value}"');
            }
          }
        }
      }
    }

    expect(offenders, isEmpty,
        reason: 'British spelling found:\n${offenders.join('\n')}');
  });
}
