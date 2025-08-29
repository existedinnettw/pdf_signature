import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';
import 'package:pdf_signature/ui/features/pdf/widgets/pdf_screen.dart';

void main() {
  testWidgets('Show invalid/unsupported file SnackBar via test hook', (
    tester,
  ) async {
    await pumpWithOpenPdf(tester);
    final dynamic state =
        tester.state(find.byType(PdfSignatureHomePage)) as dynamic;
    state.debugShowInvalidSignatureSnackBar();
    await tester.pump();
    expect(find.text('Invalid or unsupported file'), findsOneWidget);
  });
}
