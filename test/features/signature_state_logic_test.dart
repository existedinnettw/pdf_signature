// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import './step/a_new_provider_container.dart';
import './step/signature_rect_is_null.dart';
import './step/i_place_default_signature_rect.dart';
import './step/signature_rect_left.dart';
import './step/signature_rect_top.dart';
import './step/signature_rect_right.dart';
import './step/signature_rect_bottom.dart';
import './step/signature_rect_width.dart';
import './step/signature_rect_height.dart';
import './step/a_default_signature_rect_is_placed.dart';
import './step/i_drag_signature_by.dart';
import './step/signature_rect_moved_from_center.dart';
import './step/aspect_lock_is.dart';
import './step/i_resize_signature_by.dart';
import './step/signature_aspect_ratio_is_preserved_within.dart';
import './step/i_set_tiny_signature_image_bytes.dart';
import './step/signature_image_bytes_is_not_null.dart';
import './step/signature_rect_is_not_null.dart';

void main() {
  group('''Signature state logic''', () {
    testWidgets('''placeDefaultRect centers a reasonable default rect''',
        (tester) async {
      await aNewProviderContainer(tester);
      await signatureRectIsNull(tester);
      await iPlaceDefaultSignatureRect(tester);
      await signatureRectLeft(tester, 0);
      await signatureRectTop(tester, 0);
      await signatureRectRight(tester, 400);
      await signatureRectBottom(tester, 560);
      await signatureRectWidth(tester, 50);
      await signatureRectHeight(tester, 20);
    });
    testWidgets('''drag clamps to canvas bounds''', (tester) async {
      await aNewProviderContainer(tester);
      await aDefaultSignatureRectIsPlaced(tester);
      await iDragSignatureBy(tester, Offset(10000, -10000));
      await signatureRectLeft(tester, 0);
      await signatureRectTop(tester, 0);
      await signatureRectRight(tester, 400);
      await signatureRectBottom(tester, 560);
      await signatureRectMovedFromCenter(tester);
    });
    testWidgets('''resize respects aspect lock and clamps''', (tester) async {
      await aNewProviderContainer(tester);
      await aDefaultSignatureRectIsPlaced(tester);
      await aspectLockIs(tester, true);
      await iResizeSignatureBy(tester, Offset(1000, 1000));
      await signatureAspectRatioIsPreservedWithin(tester, 0.05);
      await signatureRectLeft(tester, 0);
      await signatureRectTop(tester, 0);
      await signatureRectRight(tester, 400);
      await signatureRectBottom(tester, 560);
    });
    testWidgets('''setImageBytes ensures a rect exists for display''',
        (tester) async {
      await aNewProviderContainer(tester);
      await signatureRectIsNull(tester);
      await iSetTinySignatureImageBytes(tester);
      await signatureImageBytesIsNotNull(tester);
      await signatureRectIsNotNull(tester);
    });
  });
}
