/// Preview a share card and hand it to the system share sheet.
///
/// The card is laid out at its true 1080 by 1920 and scaled down for the
/// preview, so what the user sees is exactly what gets captured — no separate
/// render path that can drift from the preview.
library;

import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/analytics/analytics.dart';
import '../../core/engine/compatibility.dart';
import '../../core/theme/modern_theme.dart';
import 'share_card.dart';

Future<void> showCompatibilityShareSheet(
  BuildContext context, {
  required CompatibilityResult result,
  required String yourName,
  required String theirName,
}) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ShareSheet(
        result: result,
        yourName: yourName,
        theirName: theirName,
      ),
    );

class _ShareSheet extends StatefulWidget {
  const _ShareSheet({
    required this.result,
    required this.yourName,
    required this.theirName,
  });

  final CompatibilityResult result;
  final String yourName;
  final String theirName;

  @override
  State<_ShareSheet> createState() => _ShareSheetState();
}

class _ShareSheetState extends State<_ShareSheet> {
  final GlobalKey _cardKey = GlobalKey();
  bool _busy = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      maxChildSize: 0.96,
      minChildSize: 0.5,
      expand: false,
      builder: (context, controller) => Container(
        decoration: const BoxDecoration(
          color: ModernTheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: ModernTheme.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
                children: [
                  Text('Share this',
                      style: ModernTheme.header.copyWith(fontSize: 22)),
                  const SizedBox(height: 6),
                  Text(
                    'Sized for a story. The split score is the part people ask '
                    'about.',
                    style: ModernTheme.caption.copyWith(fontSize: 13),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: SizedBox(
                        width: 260,
                        height: 260 * shareCardHeight / shareCardWidth,
                        // The card lays out at full size inside the fitted
                        // box, so the capture below is pixel-identical to
                        // this preview.
                        child: FittedBox(
                          fit: BoxFit.contain,
                          child: RepaintBoundary(
                            key: _cardKey,
                            child: CompatibilityShareCard(
                              result: widget.result,
                              yourName: widget.yourName,
                              theirName: widget.theirName,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    Text(_error!,
                        textAlign: TextAlign.center,
                        style: ModernTheme.caption
                            .copyWith(color: ModernTheme.error)),
                  ],
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                  24, 12, 24, 16 + MediaQuery.of(context).padding.bottom),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _busy ? null : _share,
                  icon: _busy
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.ios_share, size: 20),
                  label: Text(_busy ? 'Preparing…' : 'Share'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _share() async {
    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final bytes = await _capture();
      final name =
          'omni-${widget.yourName}-${widget.theirName}.png'.replaceAll(' ', '-');

      // In-memory on every platform: share_plus writes the bytes to a temp
      // file itself where the OS share sheet needs a real path, and hands
      // them to the Web Share API where it does not. No filesystem code here,
      // which is also what keeps this file compiling for web.
      final file = XFile.fromData(bytes, name: name, mimeType: 'image/png');

      await Share.shareXFiles(
        [file],
        text: '${widget.yourName} × ${widget.theirName}: '
            '${widget.result.score}. Chinese astrology says '
            '${widget.result.easternScore}, Western says '
            '${widget.result.westernScore}.',
      );

      if (mounted) context.read<Analytics>().shared('compatibility');
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = 'Could not build the image. $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Renders the boundary at its layout size, which is the card's true
  /// 1080 by 1920.
  Future<Uint8List> _capture() async {
    final boundary =
        _cardKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage();
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    if (data == null) {
      throw StateError('The card produced no image data.');
    }
    return data.buffer.asUint8List();
  }
}
