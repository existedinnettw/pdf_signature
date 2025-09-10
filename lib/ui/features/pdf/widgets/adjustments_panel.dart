import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/l10n/app_localizations.dart';

import '../../../../domain/models/model.dart';
import 'package:pdf_signature/data/repositories/signature_card_repository.dart';

class AdjustmentsPanel extends ConsumerWidget {
  const AdjustmentsPanel({super.key, required this.sig});

  final SignatureCard sig;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      key: const Key('adjustments_panel'),
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Checkbox(
              key: const Key('chk_aspect_lock'),
              value: ref.watch(aspectLockedProvider),
              onChanged:
                  (v) => ref
                      .read(signatureCardProvider.notifier)
                      .toggleAspect(v ?? false),
            ),
            Text(AppLocalizations.of(context).lockAspectRatio),
            const SizedBox(width: 16),
            Switch(
              key: const Key('swt_bg_removal'),
              value: sig.graphicAdjust.bgRemoval,
              onChanged:
                  (v) =>
                      ref.read(signatureCardProvider.notifier).setBgRemoval(v),
            ),
            Text(AppLocalizations.of(context).backgroundRemoval),
          ],
        ),
        const SizedBox(height: 8),
        // Contrast control
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(AppLocalizations.of(context).contrast),
            Align(
              alignment: Alignment.centerRight,
              child: Text(sig.graphicAdjust.contrast.toStringAsFixed(2)),
            ),
            Slider(
              key: const Key('sld_contrast'),
              min: 0.0,
              max: 2.0,
              value: sig.graphicAdjust.contrast,
              onChanged:
                  (v) =>
                      ref.read(signatureCardProvider.notifier).setContrast(v),
            ),
          ],
        ),
        // Brightness control
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(AppLocalizations.of(context).brightness),
            Align(
              alignment: Alignment.centerRight,
              child: Text(sig.graphicAdjust.brightness.toStringAsFixed(2)),
            ),
            Slider(
              key: const Key('sld_brightness'),
              min: -1.0,
              max: 1.0,
              value: sig.graphicAdjust.brightness,
              onChanged:
                  (v) =>
                      ref.read(signatureCardProvider.notifier).setBrightness(v),
            ),
          ],
        ),
      ],
    );
  }
}
