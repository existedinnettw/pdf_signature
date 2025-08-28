import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/features/pdf/viewer.dart';
import '_world.dart';

/// Usage: the signature remains within the page area
Future<void> theSignatureRemainsWithinThePageArea(WidgetTester tester) async {
  final container = TestWorld.container ?? ProviderContainer();
  final sig = container.read(signatureProvider);
  final r = sig.rect!;
  expect(r.left >= 0 && r.top >= 0, isTrue);
  expect(r.right <= SignatureController.pageSize.width, isTrue);
  expect(r.bottom <= SignatureController.pageSize.height, isTrue);
}
