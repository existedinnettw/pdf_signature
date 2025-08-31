import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/ui/features/pdf/view_model/view_model.dart';
import '_world.dart';

/// Usage: the user types {3} into the Go to input and presses Enter
Future<void> theUserTypesIntoTheGoToInputAndPressesEnter(
  WidgetTester tester,
  num param1,
) async {
  final target = param1.toInt();
  final c = TestWorld.container ?? ProviderContainer();
  TestWorld.container = c;
  c.read(pdfProvider.notifier).jumpTo(target);
  await tester.pump();
}
