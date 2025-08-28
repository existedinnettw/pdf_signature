// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import './step/a_signature_image_is_selected.dart';
import './step/the_user_enables_background_removal.dart';
import './step/nearwhite_background_becomes_transparent_in_the_preview.dart';
import './step/the_user_can_apply_the_change.dart';
import './step/the_user_changes_contrast_and_brightness_controls.dart';
import './step/the_preview_updates_immediately.dart';
import './step/the_user_can_apply_or_reset_adjustments.dart';

void main() {
  group('''graphically adjust signature picture''', () {
    testWidgets('''Remove background''', (tester) async {
      await aSignatureImageIsSelected(tester);
      await theUserEnablesBackgroundRemoval(tester);
      await nearwhiteBackgroundBecomesTransparentInThePreview(tester);
      await theUserCanApplyTheChange(tester);
    });
    testWidgets('''Adjust contrast and brightness''', (tester) async {
      await aSignatureImageIsSelected(tester);
      await theUserChangesContrastAndBrightnessControls(tester);
      await thePreviewUpdatesImmediately(tester);
      await theUserCanApplyOrResetAdjustments(tester);
    });
  });
}
