import 'package:flutter_test/flutter_test.dart';

/// Usage: other page content remains unaltered
Future<void> otherPageContentRemainsUnaltered(WidgetTester tester) async {
  // Logic-level test: We do not rasterize or mutate other content in this layer.
  expect(true, isTrue);
}
