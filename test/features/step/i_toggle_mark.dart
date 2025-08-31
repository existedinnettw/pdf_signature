import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/ui/features/pdf/view_model/view_model.dart';
import '_world.dart';

/// Usage: I toggle mark
Future<void> iToggleMark(WidgetTester tester) async {
  final container = TestWorld.container ?? ProviderContainer();
  TestWorld.container = container;
  final state = container.read(pdfProvider);
  final notifier = container.read(pdfProvider.notifier);
  if (state.signedPage == null) {
    notifier.setSignedPage(state.currentPage);
  } else {
    notifier.setSignedPage(null);
  }
}
