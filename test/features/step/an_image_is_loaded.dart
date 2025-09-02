import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/ui/features/pdf/view_model/view_model.dart';
import '_world.dart';

/// Usage: an image {"bob.png"} is loaded
Future<void> anImageIsLoaded(WidgetTester tester, String param1) async {
  final container = TestWorld.container ?? ProviderContainer();
  TestWorld.container = container;
  // Remember current image name
  TestWorld.currentImageName = param1;
  // Map name to deterministic bytes for testing
  Uint8List bytes;
  switch (param1) {
    case 'alice.png':
      bytes = Uint8List.fromList([1, 2, 3]);
      break;
    case 'bob.png':
      bytes = Uint8List.fromList([4, 5, 6]);
      break;
    default:
      bytes = Uint8List.fromList(param1.codeUnits.take(10).toList());
  }
  container.read(signatureProvider.notifier).setImageBytes(bytes);
}
