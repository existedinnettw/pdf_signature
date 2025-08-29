import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_signature/ui/features/pdf/view_model/view_model.dart';
import '_world.dart';

/// Usage: I place default signature rect
Future<void> iPlaceDefaultSignatureRect(WidgetTester tester) async {
  final c = TestWorld.container!;
  c.read(signatureProvider.notifier).placeDefaultRect();
}
