import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/ui/features/pdf/view_model/view_model.dart';
import '_world.dart';

/// Usage: identical signature instances appear in each location
Future<void> identicalSignatureInstancesAppearInEachLocation(
  WidgetTester tester,
) async {
  final container = TestWorld.container ?? ProviderContainer();
  TestWorld.container = container;
  final state = container.read(pdfProvider);
  final p2 = state.placementsByPage[2] ?? const [];
  final p4 = state.placementsByPage[4] ?? const [];
  expect(p2.length, greaterThanOrEqualTo(2));
  expect(p4.length, greaterThanOrEqualTo(1));
}
