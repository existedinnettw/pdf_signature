import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/ui/features/pdf/view_model/view_model.dart';
import '_world.dart';

/// Usage: the signature on page 5 is shown on page 5
Future<void> theSignatureOnPage5IsShownOnPage5(WidgetTester tester) async {
  final container = TestWorld.container ?? ProviderContainer();
  expect(container.read(pdfProvider.notifier).placementsOn(5), isNotEmpty);
}
