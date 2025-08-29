import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

void main() {
  testWidgets('Open a PDF and navigate pages', (tester) async {
    await pumpWithOpenPdf(tester);
    final pageInfo = find.byKey(const Key('lbl_page_info'));
    expect(pageInfo, findsOneWidget);
    expect((tester.widget<Text>(pageInfo)).data, 'Page 1/5');

    await tester.tap(find.byKey(const Key('btn_next')));
    await tester.pump();
    expect((tester.widget<Text>(pageInfo)).data, 'Page 2/5');

    await tester.tap(find.byKey(const Key('btn_prev')));
    await tester.pump();
    expect((tester.widget<Text>(pageInfo)).data, 'Page 1/5');
  });

  testWidgets('Jump to a specific page', (tester) async {
    await pumpWithOpenPdf(tester);

    final goto = find.byKey(const Key('txt_goto'));
    await tester.enterText(goto, '4');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    final pageInfo = find.byKey(const Key('lbl_page_info'));
    expect((tester.widget<Text>(pageInfo)).data, 'Page 4/5');
  });
}
