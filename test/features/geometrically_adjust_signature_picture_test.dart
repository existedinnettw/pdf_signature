// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import './step/a_signature_image_is_placed_on_the_page.dart';
import './step/the_user_drags_handles_to_resize_and_drags_to_reposition.dart';
import './step/the_size_and_position_update_in_real_time.dart';
import './step/the_signature_remains_within_the_page_area.dart';
import './step/a_signature_image_is_selected.dart';
import './step/the_user_enables_aspect_ratio_lock_and_resizes.dart';
import './step/the_image_scales_proportionally.dart';

void main() {
  group('''geometrically adjust signature picture''', () {
    testWidgets('''Resize and move the signature within page bounds''',
        (tester) async {
      await aSignatureImageIsPlacedOnThePage(tester);
      await theUserDragsHandlesToResizeAndDragsToReposition(tester);
      await theSizeAndPositionUpdateInRealTime(tester);
      await theSignatureRemainsWithinThePageArea(tester);
    });
    testWidgets('''Lock aspect ratio while resizing''', (tester) async {
      await aSignatureImageIsSelected(tester);
      await theUserEnablesAspectRatioLockAndResizes(tester);
      await theImageScalesProportionally(tester);
    });
  });
}
