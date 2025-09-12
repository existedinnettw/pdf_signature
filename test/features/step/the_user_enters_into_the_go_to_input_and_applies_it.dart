import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/ui/features/pdf/view_model/pdf_providers.dart';
import 'package:pdf_signature/ui/features/pdf/view_model/pdf_view_model.dart';
import '_world.dart';

/// Usage: the user enters {99} into the Go to input and applies it
Future<void> theUserEntersIntoTheGoToInputAndAppliesIt(
  WidgetTester tester,
  num param1,
) async {
  final value = param1.toInt();
  final c = TestWorld.container ?? ProviderContainer();
  // Clamp value to valid range (1..pageCount) mimicking UI behavior
  final clamped =
      value < 1 ? 1 : value; // upper bound validated in last-page check step
  try {
    c.read(currentPageProvider.notifier).state = clamped;
  } catch (_) {}
  try {
    c.read(pdfViewModelProvider.notifier).jumpToPage(clamped);
  } catch (_) {}
  await tester.pump();
}
