// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import './step/a_pdf_document_is_available.dart';
import './step/the_user_opens_the_document.dart';
import './step/the_first_page_is_displayed.dart';
import './step/the_user_can_move_to_the_next_or_previous_page.dart';
import './step/a_multipage_pdf_is_open.dart';
import './step/the_user_selects_a_specific_page_number.dart';
import './step/that_page_is_displayed.dart';

void main() {
  group('''PDF browser''', () {
    testWidgets('''Open a PDF and navigate pages''', (tester) async {
      await aPdfDocumentIsAvailable(tester);
      await theUserOpensTheDocument(tester);
      await theFirstPageIsDisplayed(tester);
      await theUserCanMoveToTheNextOrPreviousPage(tester);
    });
    testWidgets('''Jump to a specific page''', (tester) async {
      await aMultipagePdfIsOpen(tester);
      await theUserSelectsASpecificPageNumber(tester);
      await thatPageIsDisplayed(tester);
    });
  });
}
