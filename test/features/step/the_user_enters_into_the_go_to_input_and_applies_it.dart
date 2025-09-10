import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_signature/data/repositories/document_repository.dart';
import '_world.dart';

/// Usage: the user enters {99} into the Go to input and applies it
Future<void> theUserEntersIntoTheGoToInputAndAppliesIt(
  WidgetTester tester,
  num param1,
) async {
  final value = param1.toInt();
  final c = TestWorld.container ?? ProviderContainer();
  c.read(documentRepositoryProvider.notifier).jumpTo(value);
  await tester.pump();
}
