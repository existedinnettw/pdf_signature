import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_signature/features/pdf/viewer.dart';
import '_world.dart';

/// Usage: I place default signature rect
Future<void> iPlaceDefaultSignatureRect(WidgetTester tester) async {
  final c = TestWorld.container!;
  c.read(signatureProvider.notifier).placeDefaultRect();
}
