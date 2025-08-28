// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import './step/a_new_provider_container.dart';
import './step/i_openpicked_with_path_and_pagecount.dart';
import './step/pdf_state_is_loaded.dart';
import './step/pdf_picked_path_is.dart';
import './step/pdf_page_count_is.dart';
import './step/pdf_current_page_is.dart';
import './step/pdf_marked_for_signing_is.dart';
import './step/a_pdf_is_open_with_path_and_pagecount.dart';
import './step/i_jumpto.dart';
import './step/i_toggle_mark.dart';
import './step/i_set_page_count.dart';

void main() {
  group('''PDF state logic''', () {
    testWidgets('''openPicked loads document and initializes state''',
        (tester) async {
      await aNewProviderContainer(tester);
      await iOpenpickedWithPathAndPagecount(tester, 'test.pdf', 7);
      await pdfStateIsLoaded(tester, true);
      await pdfPickedPathIs(tester, 'test.pdf');
      await pdfPageCountIs(tester, 7);
      await pdfCurrentPageIs(tester, 1);
      await pdfMarkedForSigningIs(tester, false);
    });
    testWidgets('''jumpTo clamps within page boundaries''', (tester) async {
      await aNewProviderContainer(tester);
      await aPdfIsOpenWithPathAndPagecount(tester, 'test.pdf', 5);
      await iJumpto(tester, 10);
      await pdfCurrentPageIs(tester, 5);
      await iJumpto(tester, 0);
      await pdfCurrentPageIs(tester, 1);
      await iJumpto(tester, 3);
      await pdfCurrentPageIs(tester, 3);
    });
    testWidgets('''setPageCount updates count without toggling other flags''',
        (tester) async {
      await aNewProviderContainer(tester);
      await aPdfIsOpenWithPathAndPagecount(tester, 'test.pdf', 2);
      await iToggleMark(tester);
      await iSetPageCount(tester, 9);
      await pdfPageCountIs(tester, 9);
      await pdfStateIsLoaded(tester, true);
      await pdfMarkedForSigningIs(tester, true);
    });
  });
}
