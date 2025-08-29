// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import './step/a_pdf_page_is_selected_for_signing.dart';
import './step/the_user_chooses_a_signature_image_file.dart';
import './step/the_image_is_loaded_and_shown_as_a_signature_asset.dart';
import './step/the_user_selects.dart';
import './step/the_app_attempts_to_load_the_image.dart';
import './step/the_user_is_notified_of_the_issue.dart';
import './step/the_image_is_not_added_to_the_document.dart';

void main() {
  group('''load signature picture''', () {
    testWidgets('''Import a signature image''', (tester) async {
      await aPdfPageIsSelectedForSigning(tester);
      await theUserChoosesASignatureImageFile(tester);
      await theImageIsLoadedAndShownAsASignatureAsset(tester);
    });
    testWidgets(
        '''Outline: Handle invalid or unsupported files ('corrupted.png')''',
        (tester) async {
      await theUserSelects(tester, 'corrupted.png');
      await theAppAttemptsToLoadTheImage(tester);
      await theUserIsNotifiedOfTheIssue(tester);
      await theImageIsNotAddedToTheDocument(tester);
    });
    testWidgets(
        '''Outline: Handle invalid or unsupported files ('signature.bmp')''',
        (tester) async {
      await theUserSelects(tester, 'signature.bmp');
      await theAppAttemptsToLoadTheImage(tester);
      await theUserIsNotifiedOfTheIssue(tester);
      await theImageIsNotAddedToTheDocument(tester);
    });
    testWidgets(
        '''Outline: Handle invalid or unsupported files ('empty.jpg')''',
        (tester) async {
      await theUserSelects(tester, 'empty.jpg');
      await theAppAttemptsToLoadTheImage(tester);
      await theUserIsNotifiedOfTheIssue(tester);
      await theImageIsNotAddedToTheDocument(tester);
    });
  });
}
