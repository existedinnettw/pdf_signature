import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/l10n/app_localizations.dart';

import '../../../../data/model/model.dart';
import '../view_model/view_model.dart';

class AdjustmentsPanel extends ConsumerWidget {
  const AdjustmentsPanel({super.key, required this.sig});

  final SignatureState sig;

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
              value: sig.aspectLocked,
              onChanged:
                  (v) => ref
                      .read(signatureProvider.notifier)
                      .toggleAspect(v ?? false),
            ),
            Text(AppLocalizations.of(context).lockAspectRatio),
            const SizedBox(width: 16),
            Switch(
              key: const Key('swt_bg_removal'),
              value: sig.bgRemoval,
              onChanged:
                  (v) => ref.read(signatureProvider.notifier).setBgRemoval(v),
            ),
            Text(AppLocalizations.of(context).backgroundRemoval),
          ],
        ),
        Row(
          children: [
            Text(AppLocalizations.of(context).contrast),
            Expanded(
              child: Slider(
                key: const Key('sld_contrast'),
                min: 0.0,
                max: 2.0,
                value: sig.contrast,
                onChanged:
                    (v) => ref.read(signatureProvider.notifier).setContrast(v),
              ),
            ),
            Text(sig.contrast.toStringAsFixed(2)),
          ],
        ),
        Row(
          children: [
            Text(AppLocalizations.of(context).brightness),
            Expanded(
              child: Slider(
                key: const Key('sld_brightness'),
                min: -1.0,
                max: 1.0,
                value: sig.brightness,
                onChanged:
                    (v) =>
                        ref.read(signatureProvider.notifier).setBrightness(v),
              ),
            ),
            Text(sig.brightness.toStringAsFixed(2)),
          ],
        ),
      ],
    );
  }
}
