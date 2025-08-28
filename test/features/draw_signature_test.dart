// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import './step/an_empty_signature_canvas.dart';
import './step/the_user_draws_strokes_and_confirms.dart';
import './step/a_signature_image_is_created.dart';
import './step/it_is_placed_on_the_selected_page.dart';
import './step/a_drawn_signature_exists_in_the_canvas.dart';
import './step/the_user_clears_the_canvas.dart';
import './step/the_canvas_becomes_blank.dart';
import './step/multiple_strokes_were_drawn.dart';
import './step/the_user_chooses_undo.dart';
import './step/the_last_stroke_is_removed.dart';

void main() {
  group('''draw signature''', () {
    testWidgets('''Draw with mouse or touch and place on page''',
        (tester) async {
      await anEmptySignatureCanvas(tester);
      await theUserDrawsStrokesAndConfirms(tester);
      await aSignatureImageIsCreated(tester);
      await itIsPlacedOnTheSelectedPage(tester);
    });
    testWidgets('''Clear and redraw''', (tester) async {
      await aDrawnSignatureExistsInTheCanvas(tester);
      await theUserClearsTheCanvas(tester);
      await theCanvasBecomesBlank(tester);
    });
    testWidgets('''Undo the last stroke''', (tester) async {
      await multipleStrokesWereDrawn(tester);
      await theUserChoosesUndo(tester);
      await theLastStrokeIsRemoved(tester);
    });
  });
}
