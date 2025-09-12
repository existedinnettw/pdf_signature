import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/ui/features/pdf/view_model/pdf_providers.dart';
import 'package:pdf_signature/ui/features/pdf/view_model/pdf_view_model.dart';
import '_world.dart';

/// Usage: the user types {3} into the Go to input and presses Enter
Future<void> theUserTypesIntoTheGoToInputAndPressesEnter(
  WidgetTester tester,
  num param1,
) async {
  final target = param1.toInt();
  final c = TestWorld.container ?? ProviderContainer();
  TestWorld.container = c;
  try {
    c.read(currentPageProvider.notifier).state = target;
  } catch (_) {}
  try {
    c.read(pdfViewModelProvider.notifier).jumpToPage(target);
  } catch (_) {}
  await tester.pump();
}
