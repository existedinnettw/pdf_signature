import 'package:flutter/material.dart';
import 'package:pdf_signature/l10n/app_localizations.dart';

class AdjustmentsPanel extends StatelessWidget {
  const AdjustmentsPanel({
    super.key,
    required this.aspectLocked,
    required this.bgRemoval,
    required this.contrast,
    required this.brightness,
    required this.onAspectLockedChanged,
    required this.onBgRemovalChanged,
    required this.onContrastChanged,
    required this.onBrightnessChanged,
  });

  final bool aspectLocked;
  final bool bgRemoval;
  final double contrast;
  final double brightness;
  final ValueChanged<bool> onAspectLockedChanged;
  final ValueChanged<bool> onBgRemovalChanged;
  final ValueChanged<double> onContrastChanged;
  final ValueChanged<double> onBrightnessChanged;

  @override
  Widget build(BuildContext context) {
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
              value: aspectLocked,
              onChanged: (v) => onAspectLockedChanged(v ?? false),
            ),
            Text(AppLocalizations.of(context).lockAspectRatio),
            const SizedBox(width: 16),
            Switch(
              key: const Key('swt_bg_removal'),
              value: bgRemoval,
              onChanged: (v) => onBgRemovalChanged(v),
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
              child: Text(contrast.toStringAsFixed(2)),
            ),
            Slider(
              key: const Key('sld_contrast'),
              min: 0.0,
              max: 2.0,
              value: contrast,
              onChanged: onContrastChanged,
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
              child: Text(brightness.toStringAsFixed(2)),
            ),
            Slider(
              key: const Key('sld_brightness'),
              min: -1.0,
              max: 1.0,
              value: brightness,
              onChanged: onBrightnessChanged,
            ),
          ],
        ),
      ],
    );
  }
}
