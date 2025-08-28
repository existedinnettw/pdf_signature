// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import './step/a_pdf_is_open_and_contains_at_least_one_placed_signature.dart';
import './step/the_user_savesexports_the_document.dart';
import './step/a_new_pdf_file_is_saved_at_specified_full_path_location_and_file_name.dart';
import './step/the_signatures_appear_on_the_corresponding_page_in_the_output.dart';
import './step/keep_other_unchanged_contentpages_intact_in_the_output.dart';
import './step/a_signature_is_placed_with_a_position_and_size_relative_to_the_page.dart';
import './step/the_signature_is_stamped_at_the_exact_pdf_page_coordinates_and_size.dart';
import './step/the_stamp_remains_crisp_at_any_zoom_level_not_rasterized_by_the_screen.dart';
import './step/other_page_content_remains_vector_and_unaltered.dart';
import './step/a_pdf_is_open_with_no_signatures_placed.dart';
import './step/the_user_attempts_to_save.dart';
import './step/the_user_is_notified_there_is_nothing_to_save.dart';
import './step/the_user_starts_exporting_the_document.dart';
import './step/the_export_process_is_not_yet_finished.dart';
import './step/the_user_is_notified_that_the_export_is_still_in_progress.dart';
import './step/the_user_cannot_edit_the_document.dart';

void main() {
  group('''save signed PDF''', () {
    testWidgets(
      '''Export the signed document to a new file''',
      (tester) async {
        await aPdfIsOpenAndContainsAtLeastOnePlacedSignature(tester);
        await theUserSavesexportsTheDocument(tester);
        await aNewPdfFileIsSavedAtSpecifiedFullPathLocationAndFileName(tester);
        await theSignaturesAppearOnTheCorrespondingPageInTheOutput(tester);
        await keepOtherUnchangedContentpagesIntactInTheOutput(tester);
      },
      timeout: const Timeout(Duration(seconds: 30)),
    );
    testWidgets(
      '''Vector-accurate stamping into PDF page coordinates''',
      (tester) async {
        await aSignatureIsPlacedWithAPositionAndSizeRelativeToThePage(tester);
        await theUserSavesexportsTheDocument(tester);
        await theSignatureIsStampedAtTheExactPdfPageCoordinatesAndSize(tester);
        await theStampRemainsCrispAtAnyZoomLevelNotRasterizedByTheScreen(
          tester,
        );
        await otherPageContentRemainsVectorAndUnaltered(tester);
      },
      timeout: const Timeout(Duration(seconds: 30)),
    );
    testWidgets(
      '''Prevent saving when nothing is placed''',
      (tester) async {
        await aPdfIsOpenWithNoSignaturesPlaced(tester);
        await theUserAttemptsToSave(tester);
        await theUserIsNotifiedThereIsNothingToSave(tester);
      },
      timeout: const Timeout(Duration(seconds: 30)),
    );
    testWidgets(
      '''Loading sign when exporting/saving files''',
      (tester) async {
        await aSignatureIsPlacedWithAPositionAndSizeRelativeToThePage(tester);
        await theUserStartsExportingTheDocument(tester);
        await theExportProcessIsNotYetFinished(tester);
        await theUserIsNotifiedThatTheExportIsStillInProgress(tester);
        await theUserCannotEditTheDocument(tester);
      },
      timeout: const Timeout(Duration(seconds: 30)),
    );
  });
}
