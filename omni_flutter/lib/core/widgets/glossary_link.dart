/// A term the reader can tap to find out what it means.
///
/// Used everywhere an Eastern term appears. The gloss sits next to the term
/// already; tapping is for the reader who wants the paragraph. Nothing is
/// hidden behind the tap that is needed to follow the screen.
library;

import 'package:flutter/material.dart';

import '../content/glossary.dart';
import '../theme/modern_theme.dart';

class GlossaryLink extends StatelessWidget {
  const GlossaryLink(this.id, {super.key, this.style, this.label});

  /// Id from `glossary.dart`.
  final String id;
  final TextStyle? style;

  /// Overrides the entry's own label, for places where the sentence needs
  /// different wording.
  final String? label;

  @override
  Widget build(BuildContext context) {
    final entry = requireGlossary(id);
    final base = style ?? ModernTheme.subHeader.copyWith(fontSize: 17);

    return GestureDetector(
      onTap: () => showGlossary(context, id),
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              label ?? entry.label,
              style: base.copyWith(
                decoration: TextDecoration.underline,
                decorationStyle: TextDecorationStyle.dotted,
                decorationColor: ModernTheme.textSub,
              ),
            ),
          ),
          const SizedBox(width: 5),
          Icon(Icons.info_outline,
              size: (base.fontSize ?? 15) * 0.8, color: ModernTheme.textSub),
        ],
      ),
    );
  }
}

/// The one-line gloss, for placing directly under a heading.
class GlossaryGloss extends StatelessWidget {
  const GlossaryGloss(this.id, {super.key});
  final String id;

  @override
  Widget build(BuildContext context) => Text(
        requireGlossary(id).oneLine,
        style: ModernTheme.caption.copyWith(fontSize: 12.5),
      );
}

Future<void> showGlossary(BuildContext context, String id) {
  final entry = requireGlossary(id);
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => Container(
      decoration: const BoxDecoration(
        color: ModernTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
          24, 20, 24, 24 + MediaQuery.of(context).padding.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: ModernTheme.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: Text(entry.term,
                    style: ModernTheme.header.copyWith(fontSize: 22)),
              ),
              const SizedBox(width: 10),
              Text(entry.chinese,
                  style: ModernTheme.header
                      .copyWith(fontSize: 20, color: ModernTheme.jade)),
            ],
          ),
          const SizedBox(height: 2),
          Text(entry.pinyin,
              style: ModernTheme.caption
                  .copyWith(fontSize: 13, fontStyle: FontStyle.italic)),
          const SizedBox(height: 16),
          Text(entry.detail, style: ModernTheme.body.copyWith(fontSize: 15)),
          if (entry.westernAnchor case final anchor?) ...[
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: ModernTheme.primary.withOpacity(0.06),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('IF YOU KNOW WESTERN ASTROLOGY',
                      style: ModernTheme.caption.copyWith(
                          fontSize: 10,
                          letterSpacing: 1.4,
                          fontWeight: FontWeight.w700,
                          color: ModernTheme.primary)),
                  const SizedBox(height: 8),
                  Text(anchor, style: ModernTheme.body.copyWith(fontSize: 14)),
                ],
              ),
            ),
          ],
        ],
      ),
    ),
  );
}
